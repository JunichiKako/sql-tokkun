-- # Week 9: 再帰 CTE・欠損の補完・連続区間

-- ## Day 1: 再帰 CTE の基本

-- [W09-D1-1] ★★ ordered
-- 問: テーブルを使わずに、1 から 10 までの連番を昇順で生成せよ。
-- 出力: n
-- ヒント: WITH RECURSIVE 名前(列) AS (初期行 UNION ALL 再帰部分)。再帰部分には必ず終了条件を付ける。
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 10
)
SELECT n FROM seq;

-- [W09-D1-2] ★★ ordered
-- 問: 2025年12月の全日付（'YYYY-MM-DD'、31行）を昇順で生成せよ。
-- 出力: day
-- 解説: PostgreSQL なら generate_series(DATE '2025-12-01', DATE '2025-12-31', INTERVAL '1 day') が使える。
WITH RECURSIVE cal(day) AS (
  SELECT '2025-12-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2025-12-31'
)
SELECT day FROM cal;

-- [W09-D1-3] ★★★ ordered
-- 問: 2024年2月の各日の注文件数（ステータスは問わない）を求めよ。注文が1件もなかった日も 0 として出すこと（29行）。日付の昇順。
-- 出力: day, cnt
-- 解説: GROUP BY だけでは「存在しない日」は行にならない。カレンダーを作って LEFT JOIN するのが定石。
WITH RECURSIVE cal(day) AS (
  SELECT '2024-02-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2024-02-29'
)
SELECT cal.day, COUNT(o.order_id) AS cnt
FROM cal
LEFT JOIN orders o ON date(o.ordered_at) = cal.day
GROUP BY cal.day
ORDER BY cal.day;

-- ## Day 1 定着: 再帰 CTE の基本

-- [W09-D1-R1] ★★ ordered
-- 問: テーブルを使わずに、2 から 20 までの偶数を昇順で生成せよ。
-- 出力: n
WITH RECURSIVE evens(n) AS (
  SELECT 2
  UNION ALL
  SELECT n + 2 FROM evens WHERE n < 20
)
SELECT n FROM evens;

-- [W09-D1-R2] ★★ ordered
-- 問: 2025年の各月の初日（'2025-01-01'、'2025-02-01' … '2025-12-01'、12行）を昇順で生成せよ。
-- 出力: day
WITH RECURSIVE months(day) AS (
  SELECT '2025-01-01'
  UNION ALL
  SELECT date(day, '+1 month') FROM months WHERE day < '2025-12-01'
)
SELECT day FROM months;

-- [W09-D1-R3] ★★★ ordered
-- 問: 2025年10月の各日のレビュー投稿件数を求めよ。投稿が1件もなかった日も 0 として出すこと（31行）。日付の昇順。
-- 出力: day, cnt
WITH RECURSIVE cal(day) AS (
  SELECT '2025-10-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2025-10-31'
)
SELECT cal.day, COUNT(r.review_id) AS cnt
FROM cal
LEFT JOIN reviews r ON date(r.created_at) = cal.day
GROUP BY cal.day
ORDER BY cal.day;

-- ## Day 2: 階層データ

-- [W09-D2-1] ★★★
-- 問: 全カテゴリについて、最上位からのパス（例: '家電 > PC周辺機器 > キーボード'）と階層の深さ（最上位を 1）を求めよ。
-- 出力: category_id, path, depth
WITH RECURSIVE tree(category_id, path, depth) AS (
  SELECT category_id, name, 1
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, t.path || ' > ' || c.name, t.depth + 1
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
)
SELECT category_id, path, depth
FROM tree;

-- [W09-D2-2] ★★★
-- 問: 社員ID 3（開発部の部長）の配下にいる社員を、間接の部下も含めてすべて取得せよ。直属の部下を level 1、その部下を level 2 とする。本人は含めない。
-- 出力: employee_id, name, level
WITH RECURSIVE subordinates(employee_id, name, level) AS (
  SELECT employee_id, name, 1
  FROM employees
  WHERE manager_id = 3
  UNION ALL
  SELECT e.employee_id, e.name, s.level + 1
  FROM employees e
  JOIN subordinates s ON s.employee_id = e.manager_id
)
SELECT employee_id, name, level
FROM subordinates;

-- [W09-D2-3] ★★★
-- 問: 最上位カテゴリ（家電・食品・ファッション・書籍）ごとの completed 売上を求めよ。子・孫カテゴリに属する商品の売上もすべて最上位カテゴリに集約すること。
-- 出力: top_category, sales
-- ヒント: 再帰 CTE で「各カテゴリ → その最上位カテゴリ名」の対応表を作る。
WITH RECURSIVE tree(category_id, top_category) AS (
  SELECT category_id, name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, t.top_category
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
)
SELECT t.top_category, SUM(oi.quantity * oi.unit_price) AS sales
FROM tree t
JOIN products p ON p.category_id = t.category_id
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY t.top_category;

-- ## Day 2 定着: 階層データ

-- [W09-D2-R1] ★★★
-- 問: 全カテゴリについて、そのカテゴリが属する最上位カテゴリの名前を求めよ（最上位カテゴリ自身は自分の名前）。
-- 出力: category_id, name, top_category
WITH RECURSIVE tree(category_id, name, top_category) AS (
  SELECT category_id, name, name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, c.name, t.top_category
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
)
SELECT category_id, name, top_category
FROM tree;

-- [W09-D2-R2] ★★★
-- 問: 社員ID 2（営業部の部長）の配下にいる社員を、間接の部下も含めてすべて取得せよ。直属の部下を level 1 とする。本人は含めない。
-- 出力: employee_id, name, level
WITH RECURSIVE subordinates(employee_id, name, level) AS (
  SELECT employee_id, name, 1
  FROM employees
  WHERE manager_id = 2
  UNION ALL
  SELECT e.employee_id, e.name, s.level + 1
  FROM employees e
  JOIN subordinates s ON s.employee_id = e.manager_id
)
SELECT employee_id, name, level
FROM subordinates;

-- [W09-D2-R3] ★★★
-- 問: 最上位カテゴリ（家電・食品・ファッション・書籍）ごとに、子・孫カテゴリも含めて属している商品の数を求めよ。
-- 出力: top_category, products
WITH RECURSIVE tree(category_id, top_category) AS (
  SELECT category_id, name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, t.top_category
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
)
SELECT t.top_category, COUNT(*) AS products
FROM tree t
JOIN products p ON p.category_id = t.category_id
GROUP BY t.top_category;

-- ## Day 3: 欠損の補完（ギャップフィル）

-- [W09-D3-1] ★★★ ordered
-- 問: カテゴリID 17（キーボード）の 2024年の月次 completed 売上を、売上がなかった月も 0 として12か月分出せ。月（'YYYY-MM'）の昇順。
-- 出力: ym, sales
WITH RECURSIVE months(ym) AS (
  SELECT '2024-01'
  UNION ALL
  SELECT strftime('%Y-%m', ym || '-01', '+1 month') FROM months WHERE ym < '2024-12'
),
sales AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed' AND p.category_id = 17
  GROUP BY ym
)
SELECT m.ym, COALESCE(s.sales, 0) AS sales
FROM months m
LEFT JOIN sales s ON s.ym = m.ym
ORDER BY m.ym;

-- [W09-D3-2] ★★★ ordered
-- 問: 2024年2月の各日について、completed の日次売上（なければ 0）と、その日を含む直近7日間の移動平均（整数に四捨五入）を求めよ。売上がない日も「0 円の日」として平均に含め、1月末の日も計算に使うこと。日付の昇順。
-- 出力: day, sales, ma7
-- ヒント: 売上のない日が抜けたまま ROWS BETWEEN 6 PRECEDING を使うと「直近7行」になり、7日間にならない。先にカレンダーで埋める。
WITH RECURSIVE cal(day) AS (
  SELECT '2024-01-26'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2024-02-29'
),
daily AS (
  SELECT date(o.ordered_at) AS day, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY day
),
filled AS (
  SELECT cal.day, COALESCE(d.sales, 0) AS sales
  FROM cal
  LEFT JOIN daily d ON d.day = cal.day
),
with_ma AS (
  SELECT day, sales,
         ROUND(AVG(sales) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS ma7
  FROM filled
)
SELECT day, sales, ma7
FROM with_ma
WHERE day >= '2024-02-01'
ORDER BY day;

-- [W09-D3-3] ★★★ ordered
-- 問: 2025年10月1日〜12月31日のうち、顧客ID 123 が一度もサイトにアクセスしなかった日を、日付の昇順ですべて挙げよ。
-- 出力: day
WITH RECURSIVE cal(day) AS (
  SELECT '2025-10-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2025-12-31'
)
SELECT cal.day
FROM cal
WHERE NOT EXISTS (
        SELECT 1
        FROM access_logs a
        WHERE a.customer_id = 123
          AND date(a.accessed_at) = cal.day
      )
ORDER BY cal.day;

-- ## Day 3 定着: 欠損の補完（ギャップフィル）

-- [W09-D3-R1] ★★★ ordered
-- 問: 顧客ID 1 の 2025年の月ごとの completed 注文回数を、注文がなかった月も 0 として12か月分出せ。月（'YYYY-MM'）の昇順。
-- 出力: ym, orders
WITH RECURSIVE months(ym) AS (
  SELECT '2025-01'
  UNION ALL
  SELECT strftime('%Y-%m', ym || '-01', '+1 month') FROM months WHERE ym < '2025-12'
),
monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS orders
  FROM orders
  WHERE customer_id = 1 AND status = 'completed'
  GROUP BY ym
)
SELECT m.ym, COALESCE(x.orders, 0) AS orders
FROM months m
LEFT JOIN monthly x ON x.ym = m.ym
ORDER BY m.ym;

-- [W09-D3-R2] ★★★ ordered
-- 問: 2024年2月の各日について、注文件数（ステータスは問わない。なければ 0）と、2月1日からの累計件数を求めよ（29行）。日付の昇順。
-- 出力: day, cnt, cumulative
WITH RECURSIVE cal(day) AS (
  SELECT '2024-02-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2024-02-29'
),
daily AS (
  SELECT cal.day, COUNT(o.order_id) AS cnt
  FROM cal
  LEFT JOIN orders o ON date(o.ordered_at) = cal.day
  GROUP BY cal.day
)
SELECT day, cnt, SUM(cnt) OVER (ORDER BY day) AS cumulative
FROM daily
ORDER BY day;

-- [W09-D3-R3] ★★★ ordered
-- 問: 2025年11月の各日のうち、顧客ID 108 が一度もサイトにアクセスしなかった日を、日付の昇順ですべて挙げよ。
-- 出力: day
WITH RECURSIVE cal(day) AS (
  SELECT '2025-11-01'
  UNION ALL
  SELECT date(day, '+1 day') FROM cal WHERE day < '2025-11-30'
)
SELECT cal.day
FROM cal
LEFT JOIN (
  SELECT DISTINCT date(accessed_at) AS day
  FROM access_logs
  WHERE customer_id = 108
) AS a ON a.day = cal.day
WHERE a.day IS NULL
ORDER BY cal.day;

-- ## Day 4: 連続区間（gaps and islands）とセッション化

-- [W09-D4-1] ★★★ ordered
-- 問: ログイン済み顧客ごとに「連続してアクセスした日数」の最長記録を求め、上位5人を取得せよ。記録の長い順、同じなら customer_id 順。
-- 出力: customer_id, streak
-- ヒント: 顧客ごとにアクセス日を重複なく並べ、「日付 − 通し番号」を計算すると、連続している日は同じ値になる。
-- 解説: gaps and islands 問題の定番解法。連続している間は日付も通し番号も 1 ずつ増えるので差が一定になる。
WITH days AS (
  SELECT DISTINCT customer_id, date(accessed_at) AS day
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
grouped AS (
  SELECT customer_id, day,
         julianday(day) - ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY day) AS grp
  FROM days
),
streaks AS (
  SELECT customer_id, grp, COUNT(*) AS streak
  FROM grouped
  GROUP BY customer_id, grp
)
SELECT customer_id, MAX(streak) AS streak
FROM streaks
GROUP BY customer_id
ORDER BY streak DESC, customer_id
LIMIT 5;

-- [W09-D4-2] ★★★
-- 問: ログイン済み顧客のアクセスログをセッションに区切れ。同じ顧客の直前のアクセスから 30 分（1800 秒）以上空いたら新しいセッションとする。総セッション数と、1セッションあたりの平均ページビュー数（小数第2位まで）を求めよ。
-- 出力: sessions, avg_pv
-- ヒント: LAG で直前のアクセス時刻を取り、「セッションの先頭かどうか」のフラグを立てる。フラグの合計がセッション数。秒数の差は strftime('%s', ...) で計算できる。
WITH lagged AS (
  SELECT customer_id, accessed_at,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
flagged AS (
  SELECT CASE WHEN prev_at IS NULL
                OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
              THEN 1 ELSE 0 END AS is_new_session
  FROM lagged
)
SELECT SUM(is_new_session) AS sessions,
       ROUND(COUNT(*) * 1.0 / SUM(is_new_session), 2) AS avg_pv
FROM flagged;

-- [W09-D4-3] ★★★
-- 問: 注文を時系列（注文日時順、同時刻なら order_id 順）に並べたとき、2回連続でキャンセル（cancelled）したことがある顧客の ID を求めよ。
-- 出力: customer_id
WITH lagged AS (
  SELECT customer_id, status,
         LAG(status) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev_status
  FROM orders
)
SELECT DISTINCT customer_id
FROM lagged
WHERE status = 'cancelled' AND prev_status = 'cancelled';

-- ## Day 4 定着: 連続区間（gaps and islands）とセッション化

-- [W09-D4-R1] ★★★ ordered
-- 問: 顧客ごとに「連続した日に注文した日数」の最長記録を求め（ステータスは問わない。同じ日の複数注文は1日と数える）、上位5人を取得せよ。記録の長い順、同じなら customer_id 順。
-- 出力: customer_id, streak
WITH days AS (
  SELECT DISTINCT customer_id, date(ordered_at) AS day
  FROM orders
),
grouped AS (
  SELECT customer_id, day,
         julianday(day) - ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY day) AS grp
  FROM days
),
streaks AS (
  SELECT customer_id, grp, COUNT(*) AS streak
  FROM grouped
  GROUP BY customer_id, grp
)
SELECT customer_id, MAX(streak) AS streak
FROM streaks
GROUP BY customer_id
ORDER BY streak DESC, customer_id
LIMIT 5;

-- [W09-D4-R2] ★★★
-- 問: ログイン済み顧客のアクセスログを、同じ顧客の直前のアクセスから 10 分（600 秒）以上空いたら新しいセッションとする基準で区切り、総セッション数と1セッションあたりの平均ページビュー数（小数第2位まで）を求めよ。
-- 出力: sessions, avg_pv
WITH lagged AS (
  SELECT customer_id, accessed_at,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
flagged AS (
  SELECT CASE WHEN prev_at IS NULL
                OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 600
              THEN 1 ELSE 0 END AS is_new_session
  FROM lagged
)
SELECT SUM(is_new_session) AS sessions,
       ROUND(COUNT(*) * 1.0 / SUM(is_new_session), 2) AS avg_pv
FROM flagged;

-- [W09-D4-R3] ★★★
-- 問: 注文を時系列（注文日時順、同時刻なら order_id 順）に並べたとき、3回連続で同じ支払方法を使ったことがある顧客の ID を求めよ（ステータスは問わない）。
-- 出力: customer_id
-- ヒント: LAG(列, 2) で2つ前の行を取れる。
WITH lagged AS (
  SELECT customer_id, payment_method,
         LAG(payment_method, 1) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev1,
         LAG(payment_method, 2) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev2
  FROM orders
)
SELECT DISTINCT customer_id
FROM lagged
WHERE payment_method = prev1 AND prev1 = prev2;

-- ## Day 5: 総合演習

-- [W09-D5-1] ★★★ ordered
-- 問: 顧客の紹介関係をたどり、紹介の「深さ」ごとの顧客数を求めよ。誰にも紹介されていない顧客を深さ 0、その顧客に紹介された顧客を深さ 1 … とする。深さの昇順。
-- 出力: depth, customers
WITH RECURSIVE chain(customer_id, depth) AS (
  SELECT customer_id, 0
  FROM customers
  WHERE referrer_id IS NULL
  UNION ALL
  SELECT c.customer_id, ch.depth + 1
  FROM customers c
  JOIN chain ch ON ch.customer_id = c.referrer_id
)
SELECT depth, COUNT(*) AS customers
FROM chain
GROUP BY depth
ORDER BY depth;

-- [W09-D5-2] ★★★ ordered
-- 問: 部下が1人以上いる社員について、配下の人数（間接の部下も含む）を求めよ。人数の多い順、同数なら employee_id 順。
-- 出力: employee_id, name, subordinates
-- ヒント: 「上司 → 部下」のペアを再帰で広げ、(祖先, 子孫) の全組み合わせを作ってから祖先ごとに数える。
WITH RECURSIVE rel(ancestor_id, employee_id) AS (
  SELECT manager_id, employee_id
  FROM employees
  WHERE manager_id IS NOT NULL
  UNION ALL
  SELECT r.ancestor_id, e.employee_id
  FROM rel r
  JOIN employees e ON e.manager_id = r.employee_id
)
SELECT m.employee_id, m.name, COUNT(*) AS subordinates
FROM rel
JOIN employees m ON m.employee_id = rel.ancestor_id
GROUP BY m.employee_id, m.name
ORDER BY subordinates DESC, m.employee_id;

-- [W09-D5-3] ★★★ ordered
-- 問: カンマ区切りの文字列 'SQL,Python,Go,Rust' を、再帰 CTE で1要素1行に分解せよ（元の並び順のまま）。
-- 出力: item
-- ヒント: (取り出した要素, 残りの文字列) の2列を持ち回り、残りが空になるまで先頭の要素を切り出し続ける。
WITH RECURSIVE split(item, rest, pos) AS (
  SELECT '', 'SQL,Python,Go,Rust' || ',', 0
  UNION ALL
  SELECT substr(rest, 1, instr(rest, ',') - 1),
         substr(rest, instr(rest, ',') + 1),
         pos + 1
  FROM split
  WHERE rest <> ''
)
SELECT item
FROM split
WHERE pos > 0
ORDER BY pos;

-- ## Day 5 定着: 総合演習

-- [W09-D5-R1] ★★★ ordered
-- 問: 紹介関係をたどり、各顧客が直接・間接に紹介した人数（自分が紹介した人、その人が紹介した人 … の合計）を求めよ。1人以上紹介している顧客について、人数の多い順、同数なら customer_id 順。
-- 出力: customer_id, referrals
WITH RECURSIVE rel(ancestor_id, customer_id) AS (
  SELECT referrer_id, customer_id
  FROM customers
  WHERE referrer_id IS NOT NULL
  UNION ALL
  SELECT r.ancestor_id, c.customer_id
  FROM rel r
  JOIN customers c ON c.referrer_id = r.customer_id
)
SELECT ancestor_id AS customer_id, COUNT(*) AS referrals
FROM rel
GROUP BY ancestor_id
ORDER BY referrals DESC, customer_id;

-- [W09-D5-R2] ★★★ ordered
-- 問: 社員ごとに、上司をたどって社長に行き着くまでの段数（社長を 0、社長の直属の部下を 1 …）を求め、段数ごとの人数を出せ。段数の昇順。
-- 出力: depth, employees
WITH RECURSIVE chain(employee_id, depth) AS (
  SELECT employee_id, 0
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.employee_id, ch.depth + 1
  FROM employees e
  JOIN chain ch ON ch.employee_id = e.manager_id
)
SELECT depth, COUNT(*) AS employees
FROM chain
GROUP BY depth
ORDER BY depth;

-- [W09-D5-R3] ★★★ ordered
-- 問: カンマ区切りの文字列 '2025-10-01,2025-10-15,2025-11-03' を再帰 CTE で日付ごとに分解し、各日のアクセスログの件数（ゲストも含む）を求めよ。元の並び順のまま出すこと。
-- 出力: day, cnt
WITH RECURSIVE split(day, rest, pos) AS (
  SELECT '', '2025-10-01,2025-10-15,2025-11-03' || ',', 0
  UNION ALL
  SELECT substr(rest, 1, instr(rest, ',') - 1),
         substr(rest, instr(rest, ',') + 1),
         pos + 1
  FROM split
  WHERE rest <> ''
)
SELECT s.day, COUNT(a.log_id) AS cnt
FROM split s
LEFT JOIN access_logs a ON date(a.accessed_at) = s.day
WHERE s.pos > 0
GROUP BY s.pos, s.day
ORDER BY s.pos;
