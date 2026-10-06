-- # Week 11: インデックス・実行計画・クエリの書き換え

-- ## Day 1: 実行計画とインデックス

-- [W11-D1-1] ★★ nocheck
-- 問: `SELECT * FROM orders WHERE customer_id = 10;` の実行計画を `EXPLAIN QUERY PLAN` で確認せよ。全件走査（SCAN）になっているはずなので、インデックス検索（SEARCH）に変わるようインデックスを作成し、実行計画がどう変わったか確かめよ。
-- | （インデックスを作る文と EXPLAIN QUERY PLAN の文を、この順で解答ファイルに書いて実行する）
-- 解説: 作成前は `SCAN orders`、作成後は `SEARCH orders USING INDEX idx_orders_customer (customer_id=?)` になる。PostgreSQL / MySQL では EXPLAIN（実測は EXPLAIN ANALYZE）。
CREATE INDEX idx_orders_customer ON orders (customer_id);

EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE customer_id = 10;

-- [W11-D1-2] ★★ nocheck
-- 問: `SELECT order_id FROM orders WHERE status = 'completed' AND ordered_at >= '2025-12-01' AND ordered_at < '2026-01-01';` を速くする複合インデックスを作成せよ。列の順番は (status, ordered_at) と (ordered_at, status) のどちらがよいか、理由も考えること。
-- 解説: 等価条件の列を先、範囲条件の列を後にする。(status, ordered_at) なら「status = 'completed' の中の 12月分」という連続した範囲だけを読めば済む。逆順だと 12月分をすべて読んでから status を1件ずつ判定することになる。
CREATE INDEX idx_orders_status_ordered ON orders (status, ordered_at);

EXPLAIN QUERY PLAN
SELECT order_id
FROM orders
WHERE status = 'completed'
  AND ordered_at >= '2025-12-01' AND ordered_at < '2026-01-01';

-- [W11-D1-3] ★★ nocheck
-- 問: `SELECT product_id, SUM(quantity) FROM order_items GROUP BY product_id;` を、テーブル本体を読まずにインデックスだけで処理できる（カバリングインデックスになる）ようなインデックスを作成し、実行計画に COVERING INDEX と表示されることを確かめよ。
-- 解説: クエリが必要とする列（product_id, quantity）がすべてインデックスに含まれていれば、テーブル本体へのアクセスが不要になる。しかも product_id 順に並んでいるので GROUP BY のための一時領域やソートも不要になる。
CREATE INDEX idx_order_items_product_qty ON order_items (product_id, quantity);

EXPLAIN QUERY PLAN
SELECT product_id, SUM(quantity)
FROM order_items
GROUP BY product_id;

-- ## Day 1 定着: 実行計画とインデックス

-- [W11-D1-R1] ★★
-- 問: `SELECT * FROM reviews WHERE product_id = 5;` が全件走査（SCAN）ではなくインデックス検索（SEARCH）になるよう、インデックスを作成せよ。インデックス名は自由。作成後に EXPLAIN QUERY PLAN で変化も確かめること。
-- 確認: SELECT m.tbl_name, ii.seqno, ii.name FROM sqlite_master AS m, pragma_index_info(m.name) AS ii WHERE m.type = 'index'
-- 解説: 採点は「どのテーブルのどの列に、どの順番でインデックスがあるか」で行う（インデックス名は見ない）。
CREATE INDEX idx_reviews_product ON reviews (product_id);

EXPLAIN QUERY PLAN
SELECT * FROM reviews WHERE product_id = 5;

-- [W11-D1-R2] ★★
-- 問: `SELECT * FROM access_logs WHERE customer_id = 123 AND accessed_at >= '2025-12-01' AND accessed_at < '2026-01-01';` を速くする複合インデックスを1つ作成せよ。列の順番も考えること。
-- 確認: SELECT m.tbl_name, ii.seqno, ii.name FROM sqlite_master AS m, pragma_index_info(m.name) AS ii WHERE m.type = 'index'
-- 解説: 等価条件の customer_id を先、範囲条件の accessed_at を後にする。逆順だと12月のログを全部読んでから customer_id を1件ずつ判定することになる。
CREATE INDEX idx_access_logs_customer_accessed ON access_logs (customer_id, accessed_at);

EXPLAIN QUERY PLAN
SELECT * FROM access_logs
WHERE customer_id = 123
  AND accessed_at >= '2025-12-01' AND accessed_at < '2026-01-01';

-- [W11-D1-R3] ★★ nocheck
-- 問: `SELECT customer_id, COUNT(*) FROM reviews GROUP BY customer_id;` がテーブル本体を読まずにインデックスだけで処理できる（COVERING INDEX と表示される）ようなインデックスを作成し、作成前後の実行計画を比べよ。
-- 解説: COUNT(*) は列の値を使わないので、customer_id だけのインデックスでカバーできる。作成前は `SCAN reviews` と `USE TEMP B-TREE FOR GROUP BY`、作成後は `SCAN reviews USING COVERING INDEX ...` になり、GROUP BY のための一時領域も不要になる。
CREATE INDEX idx_reviews_customer ON reviews (customer_id);

EXPLAIN QUERY PLAN
SELECT customer_id, COUNT(*)
FROM reviews
GROUP BY customer_id;

-- ## Day 2: インデックスが効かない書き方

-- [W11-D2-1] ★★
-- 問: 次のクエリは、ordered_at にインデックスがあっても使えない。同じ結果を返しつつ、インデックスが使える条件に書き換えよ。
-- | ```sql
-- | SELECT COUNT(*) AS cnt FROM orders WHERE strftime('%Y', ordered_at) = '2025';
-- | ```
-- 出力: cnt
-- 解説: 列を関数や式で包むと、その列のインデックスは使えない（sargable でない）。列は裸のまま、比較する値の側を加工する。
SELECT COUNT(*) AS cnt
FROM orders
WHERE ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01';

-- [W11-D2-2] ★★ nocheck
-- 問: `SELECT customer_id FROM customers WHERE lower(email) = 'watanabe33@example.com';` は email 列に普通のインデックスを張っても速くならない。このクエリのままインデックスが使われるようにせよ。
-- 解説: 式インデックス（関数インデックス）を作る。PostgreSQL も同じ構文。MySQL 8.0 は ((lower(email))) と二重括弧で書く。
CREATE INDEX idx_customers_email_lower ON customers (lower(email));

EXPLAIN QUERY PLAN
SELECT customer_id FROM customers WHERE lower(email) = 'watanabe33@example.com';

-- [W11-D2-3] ★★
-- 問: 次のクエリを、price のインデックスが使える形に書き換えよ（結果は同じにすること）。
-- | ```sql
-- | SELECT product_id, name FROM products WHERE price * 1.1 > 5500;
-- | ```
-- 出力: product_id, name
-- 解説: 列側の計算を値側に移す（5500 ÷ 1.1 = 5000）。なお元の式は浮動小数点の誤差で、ちょうど 5000 円の商品を「5500 より大きい」と判定してしまう（このDBには該当商品なし）。金額を実数の掛け算で比較しない、という教訓でもある。
SELECT product_id, name
FROM products
WHERE price > 5000;

-- ## Day 2 定着: インデックスが効かない書き方

-- [W11-D2-R1] ★★
-- 問: 次のクエリを、ordered_at のインデックスが使える条件に書き換えよ（結果は同じにすること）。
-- | ```sql
-- | SELECT COUNT(*) AS cnt FROM orders WHERE date(ordered_at) = '2025-12-24';
-- | ```
-- 出力: cnt
SELECT COUNT(*) AS cnt
FROM orders
WHERE ordered_at >= '2025-12-24' AND ordered_at < '2025-12-25';

-- [W11-D2-R2] ★★
-- 問: 次のクエリを、name のインデックスが使える可能性のある前方一致の LIKE に書き換えよ（結果は同じにすること）。
-- | ```sql
-- | SELECT product_id, name FROM products WHERE substr(name, 1, 4) = 'コーヒー';
-- | ```
-- 出力: product_id, name
-- 解説: 前方一致（'コーヒー%'）なら索引の範囲検索に変換できる。中間一致（'%コーヒー%'）は変換できない。なお SQLite で LIKE がインデックスを使うには、大文字小文字の扱いに関する追加条件がある。
SELECT product_id, name
FROM products
WHERE name LIKE 'コーヒー%';

-- [W11-D2-R3] ★★
-- 問: 次のクエリを、salary のインデックスが使える形に書き換えよ（結果は同じにすること）。
-- | ```sql
-- | SELECT name, salary FROM employees WHERE salary / 12 >= 500000;
-- | ```
-- 出力: name, salary
-- 解説: salary は整数なので salary / 12 は切り捨ての整数。「切り捨てて 500000 以上」は「salary が 6,000,000 以上」と同じ。
SELECT name, salary
FROM employees
WHERE salary >= 6000000;

-- ## Day 3: 遅い書き方を直す

-- [W11-D3-1] ★★★
-- 問: 次のクエリは、顧客1人ごとにサブクエリが実行される。相関サブクエリを使わず、JOIN と GROUP BY で同じ結果を得よ。
-- | ```sql
-- | SELECT c.customer_id,
-- |        (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_cnt
-- | FROM customers c;
-- | ```
-- 出力: customer_id, order_cnt
SELECT c.customer_id, COUNT(o.order_id) AS order_cnt
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id;

-- [W11-D3-2] ★★★
-- 問: 「誰のことも紹介したことがない顧客」を出すつもりで書かれた次のクエリは、結果が 0 件になってしまう。原因を突き止め、正しく動くクエリに直せ。
-- | ```sql
-- | SELECT customer_id, name FROM customers
-- | WHERE customer_id NOT IN (SELECT referrer_id FROM customers);
-- | ```
-- 出力: customer_id, name
-- ヒント: サブクエリの結果に NULL が含まれている。`x NOT IN (1, 2, NULL)` は決して TRUE にならない。
-- 解説: NOT IN は「x <> 1 AND x <> 2 AND x <> NULL」と同じで、最後が UNKNOWN になるため全体が TRUE にならない。NOT EXISTS は NULL の影響を受けないので、否定の存在判定は NOT EXISTS を基本にする。
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
        SELECT 1
        FROM customers r
        WHERE r.referrer_id = c.customer_id
      );

-- [W11-D3-3] ★★★ ordered
-- 問: 次のクエリは、2025年の日ごとの注文件数とその累計を自己結合で求めているため、日数の2乗に比例して遅くなる。ウィンドウ関数で書き直せ。日付の昇順。
-- | ```sql
-- | WITH daily AS (
-- |   SELECT date(ordered_at) AS day, COUNT(*) AS cnt FROM orders
-- |   WHERE ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01' GROUP BY day
-- | )
-- | SELECT a.day, a.cnt, SUM(b.cnt) AS cumulative
-- | FROM daily a JOIN daily b ON b.day <= a.day
-- | GROUP BY a.day, a.cnt ORDER BY a.day;
-- | ```
-- 出力: day, cnt, cumulative
WITH daily AS (
  SELECT date(ordered_at) AS day, COUNT(*) AS cnt
  FROM orders
  WHERE ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01'
  GROUP BY day
)
SELECT day, cnt, SUM(cnt) OVER (ORDER BY day) AS cumulative
FROM daily
ORDER BY day;

-- ## Day 3 定着: 遅い書き方を直す

-- [W11-D3-R1] ★★★
-- 問: 次のクエリを、相関サブクエリを使わず JOIN と GROUP BY で書き直せ。
-- | ```sql
-- | SELECT p.product_id,
-- |        (SELECT COUNT(*) FROM reviews r WHERE r.product_id = p.product_id) AS review_cnt
-- | FROM products p;
-- | ```
-- 出力: product_id, review_cnt
SELECT p.product_id, COUNT(r.review_id) AS review_cnt
FROM products p
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id;

-- [W11-D3-R2] ★★★
-- 問: 「部下が1人もいない社員」を出すつもりで書かれた次のクエリは、結果が 0 件になってしまう。原因を突き止め、正しく動くクエリに直せ。
-- | ```sql
-- | SELECT employee_id, name FROM employees
-- | WHERE employee_id NOT IN (SELECT manager_id FROM employees);
-- | ```
-- 出力: employee_id, name
-- 解説: 社長の manager_id が NULL なので、サブクエリの結果に NULL が混ざり、NOT IN が決して TRUE にならない。
SELECT e.employee_id, e.name
FROM employees e
WHERE NOT EXISTS (
        SELECT 1
        FROM employees s
        WHERE s.manager_id = e.employee_id
      );

-- [W11-D3-R3] ★★★ ordered
-- 問: 次のクエリは、2025年の月ごとの completed 注文件数とその累計を自己結合で求めている。ウィンドウ関数で書き直せ。月の昇順。
-- | ```sql
-- | WITH monthly AS (
-- |   SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt FROM orders
-- |   WHERE status = 'completed' AND ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01'
-- |   GROUP BY ym
-- | )
-- | SELECT a.ym, a.cnt, SUM(b.cnt) AS cumulative
-- | FROM monthly a JOIN monthly b ON b.ym <= a.ym
-- | GROUP BY a.ym, a.cnt ORDER BY a.ym;
-- | ```
-- 出力: ym, cnt, cumulative
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt
  FROM orders
  WHERE status = 'completed'
    AND ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01'
  GROUP BY ym
)
SELECT ym, cnt, SUM(cnt) OVER (ORDER BY ym) AS cumulative
FROM monthly
ORDER BY ym;

-- ## Day 4: よくある落とし穴

-- [W11-D4-1] ★★★
-- 問: 次のクエリは、JOIN で増えた行を DISTINCT で消している。「存在するかどうか」だけを調べる形（EXISTS）に書き換えよ。
-- | ```sql
-- | SELECT DISTINCT c.customer_id, c.name
-- | FROM customers c JOIN orders o ON o.customer_id = c.customer_id
-- | WHERE o.status = 'completed' AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01';
-- | ```
-- 出力: customer_id, name
-- 解説: EXISTS は1件見つかった時点で探索を打ち切れる（セミジョイン）。JOIN + DISTINCT は全部結合してから重複を消すので無駄が多い。
SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = c.customer_id
          AND o.status = 'completed'
          AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
      );

-- [W11-D4-2] ★★★
-- 問: 全顧客の「注文数」と「レビュー数」を出すつもりの次のクエリは、数字が実際より大きくなる。原因を突き止め、正しい結果を返すクエリに直せ（どちらも 0 件の顧客は 0 と出す）。
-- | ```sql
-- | SELECT c.customer_id, COUNT(o.order_id) AS order_cnt, COUNT(r.review_id) AS review_cnt
-- | FROM customers c
-- | LEFT JOIN orders o ON o.customer_id = c.customer_id
-- | LEFT JOIN reviews r ON r.customer_id = c.customer_id
-- | GROUP BY c.customer_id;
-- | ```
-- 出力: customer_id, order_cnt, review_cnt
-- 解説: 注文 n 件 × レビュー m 件の顧客は n×m 行に膨らむ（ファンアウト）。それぞれ先に集計してから結合する。COUNT(DISTINCT ...) でも数は合うが、SUM などには使えないので事前集計が基本。
WITH order_counts AS (
  SELECT customer_id, COUNT(*) AS order_cnt
  FROM orders
  GROUP BY customer_id
),
review_counts AS (
  SELECT customer_id, COUNT(*) AS review_cnt
  FROM reviews
  GROUP BY customer_id
)
SELECT c.customer_id,
       COALESCE(oc.order_cnt, 0) AS order_cnt,
       COALESCE(rc.review_cnt, 0) AS review_cnt
FROM customers c
LEFT JOIN order_counts oc ON oc.customer_id = c.customer_id
LEFT JOIN review_counts rc ON rc.customer_id = c.customer_id;

-- [W11-D4-3] ★★★ ordered
-- 問: 注文一覧を order_id の昇順で20件ずつ表示する画面がある。`LIMIT 20 OFFSET 1000` のような OFFSET 方式は後ろのページほど遅くなる。「前のページの最後の order_id は 1000 だった」という情報を使い、OFFSET を使わずに次の20件を取得せよ。
-- 出力: order_id, ordered_at
-- 解説: キーセット（シーク）ページネーション。OFFSET は読み飛ばす行も実際には読むが、こちらは主キーのインデックスで開始位置に直接飛べる。
SELECT order_id, ordered_at
FROM orders
WHERE order_id > 1000
ORDER BY order_id
LIMIT 20;

-- ## Day 4 定着: よくある落とし穴

-- [W11-D4-R1] ★★★
-- 問: 次のクエリを、JOIN と DISTINCT ではなく EXISTS を使う形に書き換えよ。
-- | ```sql
-- | SELECT DISTINCT c.customer_id, c.name
-- | FROM customers c JOIN reviews r ON r.customer_id = c.customer_id
-- | WHERE r.rating <= 2;
-- | ```
-- 出力: customer_id, name
SELECT c.customer_id, c.name
FROM customers c
WHERE EXISTS (
        SELECT 1
        FROM reviews r
        WHERE r.customer_id = c.customer_id
          AND r.rating <= 2
      );

-- [W11-D4-R2] ★★★
-- 問: 全商品の「注文明細の行数」と「レビュー数」を出すつもりの次のクエリは、数字が実際より大きくなる。正しい結果を返すクエリに直せ（どちらも 0 件の商品は 0 と出す）。
-- | ```sql
-- | SELECT p.product_id, COUNT(oi.order_item_id) AS item_cnt, COUNT(r.review_id) AS review_cnt
-- | FROM products p
-- | LEFT JOIN order_items oi ON oi.product_id = p.product_id
-- | LEFT JOIN reviews r ON r.product_id = p.product_id
-- | GROUP BY p.product_id;
-- | ```
-- 出力: product_id, item_cnt, review_cnt
WITH item_counts AS (
  SELECT product_id, COUNT(*) AS item_cnt
  FROM order_items
  GROUP BY product_id
),
review_counts AS (
  SELECT product_id, COUNT(*) AS review_cnt
  FROM reviews
  GROUP BY product_id
)
SELECT p.product_id,
       COALESCE(i.item_cnt, 0) AS item_cnt,
       COALESCE(r.review_cnt, 0) AS review_cnt
FROM products p
LEFT JOIN item_counts i ON i.product_id = p.product_id
LEFT JOIN review_counts r ON r.product_id = p.product_id;

-- [W11-D4-R3] ★★★ ordered
-- 問: レビュー一覧を新しい順（created_at の降順、同時刻なら review_id の降順）に10件ずつ表示する画面がある。前のページの最後の行は created_at = '2025-12-31 09:24:49'、review_id = 573 だった。OFFSET を使わずに次の10件を取得せよ。
-- 出力: review_id, created_at
-- ヒント: 並び順のキーが2つあるので、「created_at がより古い」または「created_at が同じで review_id がより小さい」行が対象。
SELECT review_id, created_at
FROM reviews
WHERE created_at < '2025-12-31 09:24:49'
   OR (created_at = '2025-12-31 09:24:49' AND review_id < 573)
ORDER BY created_at DESC, review_id DESC
LIMIT 10;

-- ## Day 5: 総合演習

-- [W11-D5-1] ★★★ nocheck
-- 問: 次のクエリ（顧客 27 の completed 注文の商品別数量）を速くするために、どのテーブルのどの列にインデックスを張るべきか設計し、作成前後の実行計画を比べよ。
-- | ```sql
-- | SELECT oi.product_id, SUM(oi.quantity) AS qty
-- | FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
-- | WHERE o.customer_id = 27 AND o.status = 'completed'
-- | GROUP BY oi.product_id;
-- | ```
-- 解説: (1) orders を customer_id と status で絞るための複合インデックス、(2) 絞った注文から明細を引くための order_items(order_id)。外部キーの列には基本的にインデックスを張る、と覚えておく。作成後は両テーブルとも SEARCH になる。
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
CREATE INDEX idx_order_items_order ON order_items (order_id);

EXPLAIN QUERY PLAN
SELECT oi.product_id, SUM(oi.quantity) AS qty
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.customer_id = 27 AND o.status = 'completed'
GROUP BY oi.product_id;

-- [W11-D5-2] ★★★
-- 問: 各商品の最新のレビュー（同時刻なら review_id の大きい方）を取得する次のクエリを、相関サブクエリを使わずウィンドウ関数で書き直せ。
-- | ```sql
-- | SELECT r.product_id, r.review_id, r.rating, r.created_at
-- | FROM reviews r
-- | WHERE r.review_id = (SELECT r2.review_id FROM reviews r2 WHERE r2.product_id = r.product_id
-- |                      ORDER BY r2.created_at DESC, r2.review_id DESC LIMIT 1);
-- | ```
-- 出力: product_id, review_id, rating, created_at
WITH ranked AS (
  SELECT product_id, review_id, rating, created_at,
         ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY created_at DESC, review_id DESC) AS rn
  FROM reviews
)
SELECT product_id, review_id, rating, created_at
FROM ranked
WHERE rn = 1;

-- [W11-D5-3] ★★★
-- 問: 次のクエリは、全都道府県を集計してから HAVING で3県に絞っている。集計する前に行を絞るよう書き換えよ。
-- | ```sql
-- | SELECT prefecture, COUNT(*) AS cnt FROM customers
-- | GROUP BY prefecture HAVING prefecture IN ('東京都', '大阪府', '福岡県');
-- | ```
-- 出力: prefecture, cnt
-- 解説: 集約関数を使わない条件は WHERE に書く。HAVING は集計結果（COUNT や SUM）に対する条件のためのもの。
SELECT prefecture, COUNT(*) AS cnt
FROM customers
WHERE prefecture IN ('東京都', '大阪府', '福岡県')
GROUP BY prefecture;

-- ## Day 5 定着: 総合演習

-- [W11-D5-R1] ★★★ nocheck
-- 問: 次のクエリ（コーヒー豆カテゴリの評価別レビュー数）を速くするために、どのテーブルのどの列にインデックスを張るべきか設計し、作成前後の実行計画を比べよ。
-- | ```sql
-- | SELECT r.rating, COUNT(*) AS cnt
-- | FROM products p JOIN reviews r ON r.product_id = p.product_id
-- | WHERE p.category_id = 19
-- | GROUP BY r.rating;
-- | ```
-- 解説: products を category_id で絞るためのインデックスと、絞った商品からレビューを引くための reviews(product_id)。作成後は products が `SEARCH p USING INDEX ... (category_id=?)`、reviews が `SEARCH r USING INDEX ... (product_id=?)` になる。
CREATE INDEX idx_products_category ON products (category_id);
CREATE INDEX idx_reviews_product ON reviews (product_id);

EXPLAIN QUERY PLAN
SELECT r.rating, COUNT(*) AS cnt
FROM products p
JOIN reviews r ON r.product_id = p.product_id
WHERE p.category_id = 19
GROUP BY r.rating;

-- [W11-D5-R2] ★★★
-- 問: 各顧客の「最も金額の大きい completed の注文」（同額なら order_id の小さい方）を求める次のクエリを、相関サブクエリを使わずウィンドウ関数で書き直せ。
-- | ```sql
-- | WITH t AS (
-- |   SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS amount
-- |   FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
-- |   WHERE o.status = 'completed' GROUP BY o.order_id, o.customer_id
-- | )
-- | SELECT customer_id, order_id, amount FROM t
-- | WHERE order_id = (SELECT t2.order_id FROM t t2 WHERE t2.customer_id = t.customer_id
-- |                   ORDER BY t2.amount DESC, t2.order_id LIMIT 1);
-- | ```
-- 出力: customer_id, order_id, amount
WITH t AS (
  SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id
),
ranked AS (
  SELECT customer_id, order_id, amount,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC, order_id) AS rn
  FROM t
)
SELECT customer_id, order_id, amount
FROM ranked
WHERE rn = 1;

-- [W11-D5-R3] ★★★
-- 問: 次のクエリは、集計してから HAVING で cancelled を除いている。集計する前に行を絞るよう書き換えよ。
-- | ```sql
-- | SELECT status, COUNT(*) AS cnt FROM orders
-- | GROUP BY status HAVING status <> 'cancelled';
-- | ```
-- 出力: status, cnt
SELECT status, COUNT(*) AS cnt
FROM orders
WHERE status <> 'cancelled'
GROUP BY status;
