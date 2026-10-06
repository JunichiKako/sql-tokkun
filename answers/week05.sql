-- # Week 5: 文字列・日付・NULL 処理・CASE 応用

-- ## Day 1: 文字列関数

-- [W05-D1-1] ★★
-- 問: メールアドレスのドメイン（@ より後ろ）ごとに顧客数を求めよ。大文字・小文字の違いは無視し、ドメインは小文字で出すこと。メール未登録の顧客は除く。
-- 出力: domain, cnt
-- ヒント: SQLite は instr() と substr()。PostgreSQL なら split_part(email, '@', 2)。
SELECT lower(substr(email, instr(email, '@') + 1)) AS domain, COUNT(*) AS cnt
FROM customers
WHERE email IS NOT NULL
GROUP BY domain;

-- [W05-D1-2] ★★
-- 問: 顧客名（'姓 名' の形式）を姓と名に分割せよ。
-- 出力: customer_id, last_name, first_name
SELECT customer_id,
       substr(name, 1, instr(name, ' ') - 1) AS last_name,
       substr(name, instr(name, ' ') + 1) AS first_name
FROM customers;

-- [W05-D1-3] ★★
-- 問: 全商品について「商品名（カテゴリ名）」という形式のラベルを作れ。括弧は全角の（ ）を使うこと。例: 電気ケトル（キッチン家電）
-- 出力: product_id, label
SELECT p.product_id, p.name || '（' || c.name || '）' AS label
FROM products p
JOIN categories c ON c.category_id = p.category_id;

-- ## Day 1 定着: 文字列関数

-- [W05-D1-R1] ★ ordered
-- 問: 商品名の文字数を求め、文字数の多い順（同じなら product_id 順）に上位5件を取得せよ。
-- 出力: product_id, name, name_length
-- ヒント: 文字数は length()。
SELECT product_id, name, length(name) AS name_length
FROM products
ORDER BY name_length DESC, product_id
LIMIT 5;

-- [W05-D1-R2] ★★
-- 問: 社員名（'姓 名' の形式）を姓と名に分割せよ。
-- 出力: employee_id, last_name, first_name
SELECT employee_id,
       substr(name, 1, instr(name, ' ') - 1) AS last_name,
       substr(name, instr(name, ' ') + 1) AS first_name
FROM employees;

-- [W05-D1-R3] ★★
-- 問: メールアドレスのドメインが example.com の顧客について、メールアドレスの @ より前の部分を小文字にして取得せよ。大文字・小文字の違いは無視して判定すること。
-- 出力: customer_id, local_part
-- ヒント: 判定にも取り出しにも lower() を使う。@ の位置は instr()。
SELECT customer_id,
       lower(substr(email, 1, instr(email, '@') - 1)) AS local_part
FROM customers
WHERE lower(substr(email, instr(email, '@') + 1)) = 'example.com';

-- ## Day 2: 日付関数

-- [W05-D2-1] ★ ordered
-- 問: 注文された時間帯（0〜23 の整数）ごとの注文件数を、時間帯の昇順に求めよ。
-- 出力: hour, cnt
SELECT CAST(strftime('%H', ordered_at) AS INTEGER) AS hour, COUNT(*) AS cnt
FROM orders
GROUP BY hour
ORDER BY hour;

-- [W05-D2-2] ★★
-- 問: 生年月日が登録されている顧客について、2026年1月1日時点の満年齢を求めよ。
-- 出力: customer_id, name, age
-- ヒント: (基準日を YYYYMMDD の整数にしたもの − 生年月日を YYYYMMDD の整数にしたもの) ÷ 10000 の切り捨てが満年齢になる。
-- 解説: PostgreSQL なら date_part('year', age(DATE '2026-01-01', birth_date))。
SELECT customer_id, name,
       (20260101 - CAST(strftime('%Y%m%d', birth_date) AS INTEGER)) / 10000 AS age
FROM customers
WHERE birth_date IS NOT NULL;

-- [W05-D2-3] ★★★
-- 問: 注文したことがある顧客について、会員登録から初回注文（ステータスは問わない）までの日数を求め、その平均（小数第1位まで）を出せ。日数は時刻も含めた実数（julianday の差）で計算すること。
-- 出力: avg_days
SELECT ROUND(AVG(julianday(f.first_order_at) - julianday(c.registered_at)), 1) AS avg_days
FROM customers c
JOIN (
  SELECT customer_id, MIN(ordered_at) AS first_order_at
  FROM orders
  GROUP BY customer_id
) AS f ON f.customer_id = c.customer_id;

-- ## Day 2 定着: 日付関数

-- [W05-D2-R1] ★ ordered
-- 問: 社員の入社年（整数）ごとの人数を、年の昇順で求めよ。
-- 出力: year, cnt
SELECT CAST(strftime('%Y', hired_on) AS INTEGER) AS year, COUNT(*) AS cnt
FROM employees
GROUP BY year
ORDER BY year;

-- [W05-D2-R2] ★★
-- 問: 全社員について、2026年1月1日時点の勤続年数（満年数）を求めよ。
-- 出力: employee_id, name, years
-- ヒント: 満年齢と同じ計算（YYYYMMDD の整数同士の差 ÷ 10000）。
SELECT employee_id, name,
       (20260101 - CAST(strftime('%Y%m%d', hired_on) AS INTEGER)) / 10000 AS years
FROM employees;

-- [W05-D2-R3] ★★★
-- 問: 各レビューについて、書いた顧客の会員登録日時からレビュー投稿日時までの日数（julianday の差）を求め、その平均（小数第1位まで）を出せ。
-- 出力: avg_days
SELECT ROUND(AVG(julianday(r.created_at) - julianday(c.registered_at)), 1) AS avg_days
FROM reviews r
JOIN customers c ON c.customer_id = r.customer_id;

-- ## Day 3: NULL 処理（COALESCE / NULLIF）

-- [W05-D3-1] ★★
-- 問: 全商品について平均評価（小数第2位まで）を求めよ。レビューがない商品は 0 と表示すること。
-- 出力: product_id, avg_rating
SELECT p.product_id, COALESCE(ROUND(AVG(r.rating), 2), 0) AS avg_rating
FROM products p
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id;

-- [W05-D3-2] ★★
-- 問: 全顧客について、キャンセル率（cancelled の注文数 ÷ 全注文数、小数第3位まで）を求めよ。注文が0件の顧客は NULL とすること。
-- 出力: customer_id, cancel_rate
-- ヒント: 分母を NULLIF(分母, 0) にすると 0 除算を NULL にできる。
-- 解説: SQLite は 0 除算が NULL になるが、PostgreSQL や MySQL(厳格モード) ではエラーになる。NULLIF を癖にしておく。
SELECT c.customer_id,
       ROUND(SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) * 1.0
             / NULLIF(COUNT(o.order_id), 0), 3) AS cancel_rate
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id;

-- [W05-D3-3] ★★
-- 問: 2026年1月1日時点の年代（'20代'、'30代' …）ごとの顧客数を求めよ。生年月日が NULL の顧客は '不明' にまとめること。
-- 出力: age_group, cnt
SELECT CASE WHEN birth_date IS NULL THEN '不明'
            ELSE ((20260101 - CAST(strftime('%Y%m%d', birth_date) AS INTEGER)) / 10000 / 10 * 10) || '代'
       END AS age_group,
       COUNT(*) AS cnt
FROM customers
GROUP BY age_group;

-- ## Day 3 定着: NULL 処理（COALESCE / NULLIF）

-- [W05-D3-R1] ★★
-- 問: 全商品について、completed の注文での販売数量の合計を求めよ。一度も売れていない商品は 0 と表示すること。
-- 出力: product_id, total_qty
-- ヒント: completed 以外の注文の明細も行としては残るので、SUM(CASE WHEN ... THEN quantity END) で completed の分だけ足す。売れていない商品は SUM が NULL になる。
SELECT p.product_id,
       COALESCE(SUM(CASE WHEN o.status = 'completed' THEN oi.quantity END), 0) AS total_qty
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id
GROUP BY p.product_id;

-- [W05-D3-R2] ★★
-- 問: 全カテゴリについて、直接属する商品の平均価格（価格の合計 ÷ 商品数、整数に四捨五入）を求めよ。商品が1つもないカテゴリは NULL とすること。AVG() は使わず、割り算で計算すること。
-- 出力: category_id, avg_price
-- ヒント: 分母を NULLIF(COUNT(...), 0) にする。
SELECT c.category_id,
       ROUND(SUM(p.price) * 1.0 / NULLIF(COUNT(p.product_id), 0)) AS avg_price
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id;

-- [W05-D3-R3] ★★
-- 問: 顧客を性別ラベル（'M'→'男性'、'F'→'女性'、NULL→'不明'）でまとめ、ラベルごとの人数と、生年月日が登録されている割合（百分率、小数第1位まで）を求めよ。
-- 出力: gender_label, cnt, birth_rate
-- ヒント: COUNT(列) は NULL を数えない。
SELECT CASE gender WHEN 'M' THEN '男性' WHEN 'F' THEN '女性' ELSE '不明' END AS gender_label,
       COUNT(*) AS cnt,
       ROUND(COUNT(birth_date) * 100.0 / COUNT(*), 1) AS birth_rate
FROM customers
GROUP BY gender_label;

-- ## Day 4: CASE 応用とピボット

-- [W05-D4-1] ★★
-- 問: 2025年の completed の売上を、四半期ごとに横に並べて1行で出せ（q1 = 1〜3月、…、q4 = 10〜12月）。
-- 出力: q1, q2, q3, q4
SELECT SUM(CASE WHEN m BETWEEN 1 AND 3 THEN amount ELSE 0 END) AS q1,
       SUM(CASE WHEN m BETWEEN 4 AND 6 THEN amount ELSE 0 END) AS q2,
       SUM(CASE WHEN m BETWEEN 7 AND 9 THEN amount ELSE 0 END) AS q3,
       SUM(CASE WHEN m BETWEEN 10 AND 12 THEN amount ELSE 0 END) AS q4
FROM (
  SELECT CAST(strftime('%m', o.ordered_at) AS INTEGER) AS m,
         oi.quantity * oi.unit_price AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
) AS t;

-- [W05-D4-2] ★★★
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとに、2024年と2025年の completed 売上を横に並べ、成長率（(2025 − 2024) ÷ 2024 の百分率、小数第1位まで）を求めよ。2024年の売上が 0 のカテゴリは成長率を NULL とする。
-- 出力: category_name, sales_2024, sales_2025, growth_rate
SELECT category_name, sales_2024, sales_2025,
       ROUND((sales_2025 - sales_2024) * 100.0 / NULLIF(sales_2024, 0), 1) AS growth_rate
FROM (
  SELECT c.name AS category_name,
         SUM(CASE WHEN o.ordered_at < '2025-01-01' THEN oi.quantity * oi.unit_price ELSE 0 END) AS sales_2024,
         SUM(CASE WHEN o.ordered_at >= '2025-01-01' THEN oi.quantity * oi.unit_price ELSE 0 END) AS sales_2025
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  JOIN categories c ON c.category_id = p.category_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2024-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY c.category_id, c.name
) AS t;

-- [W05-D4-3] ★★★ ordered
-- 問: ステータスごとの注文件数を、業務フローの順（pending → shipped → completed → cancelled）に並べて出せ。
-- 出力: status, cnt
-- ヒント: ORDER BY に CASE 式を書ける。
SELECT status, COUNT(*) AS cnt
FROM orders
GROUP BY status
ORDER BY CASE status
           WHEN 'pending' THEN 1
           WHEN 'shipped' THEN 2
           WHEN 'completed' THEN 3
           ELSE 4
         END;

-- ## Day 4 定着: CASE 応用とピボット

-- [W05-D4-R1] ★★
-- 問: 2024年の注文（ステータスは問わない）の件数を、支払方法ごとに横に並べて1行で出せ。
-- 出力: credit_card, e_money, convenience_store, bank_transfer, cod
SELECT SUM(CASE WHEN payment_method = 'credit_card' THEN 1 ELSE 0 END) AS credit_card,
       SUM(CASE WHEN payment_method = 'e_money' THEN 1 ELSE 0 END) AS e_money,
       SUM(CASE WHEN payment_method = 'convenience_store' THEN 1 ELSE 0 END) AS convenience_store,
       SUM(CASE WHEN payment_method = 'bank_transfer' THEN 1 ELSE 0 END) AS bank_transfer,
       SUM(CASE WHEN payment_method = 'cod' THEN 1 ELSE 0 END) AS cod
FROM orders
WHERE ordered_at >= '2024-01-01' AND ordered_at < '2025-01-01';

-- [W05-D4-R2] ★★★
-- 問: 都道府県ごとに、2024年と2025年に会員登録した顧客の数を横に並べ、増減（2025年 − 2024年）を求めよ。どちらの年にも登録がない都道府県は出さなくてよい。
-- 出力: prefecture, reg_2024, reg_2025, diff
SELECT prefecture, reg_2024, reg_2025, reg_2025 - reg_2024 AS diff
FROM (
  SELECT prefecture,
         SUM(CASE WHEN registered_at < '2025-01-01' THEN 1 ELSE 0 END) AS reg_2024,
         SUM(CASE WHEN registered_at >= '2025-01-01' THEN 1 ELSE 0 END) AS reg_2025
  FROM customers
  WHERE registered_at >= '2024-01-01' AND registered_at < '2026-01-01'
  GROUP BY prefecture
) AS t;

-- [W05-D4-R3] ★★★ ordered
-- 問: 支払方法ごとの注文件数を、credit_card → e_money → convenience_store → bank_transfer → cod の順に並べて出せ（ステータスは問わない）。
-- 出力: payment_method, cnt
SELECT payment_method, COUNT(*) AS cnt
FROM orders
GROUP BY payment_method
ORDER BY CASE payment_method
           WHEN 'credit_card' THEN 1
           WHEN 'e_money' THEN 2
           WHEN 'convenience_store' THEN 3
           WHEN 'bank_transfer' THEN 4
           ELSE 5
         END;

-- ## Day 5: 総合演習

-- [W05-D5-1] ★★ ordered
-- 問: 誕生月（1〜12 の整数）ごとの顧客数を、月の昇順で求めよ。生年月日が NULL の顧客は除く。
-- 出力: month, cnt
SELECT CAST(strftime('%m', birth_date) AS INTEGER) AS month, COUNT(*) AS cnt
FROM customers
WHERE birth_date IS NOT NULL
GROUP BY month
ORDER BY month;

-- [W05-D5-2] ★★★ ordered
-- 問: 「月末日」に行われた注文の件数を、月ごと（'YYYY-MM'）に求めよ（ステータスは問わない。月末日に注文がなかった月は出さなくてよい）。月の昇順。
-- 出力: ym, cnt
-- ヒント: SQLite では date(ordered_at, 'start of month', '+1 month', '-1 day') でその月の末日が得られる。
SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt
FROM orders
WHERE date(ordered_at) = date(ordered_at, 'start of month', '+1 month', '-1 day')
GROUP BY ym
ORDER BY ym;

-- [W05-D5-3] ★★★
-- 問: 社員を 2026年1月1日時点の勤続年数（満年数）で '3年未満'・'3年以上10年未満'・'10年以上' に分け、区分ごとの人数と平均年収（整数に四捨五入）を求めよ。
-- 出力: tenure_band, cnt, avg_salary
SELECT CASE WHEN years < 3 THEN '3年未満'
            WHEN years < 10 THEN '3年以上10年未満'
            ELSE '10年以上' END AS tenure_band,
       COUNT(*) AS cnt,
       ROUND(AVG(salary)) AS avg_salary
FROM (
  SELECT salary,
         (20260101 - CAST(strftime('%Y%m%d', hired_on) AS INTEGER)) / 10000 AS years
  FROM employees
) AS t
GROUP BY tenure_band;

-- ## Day 5 定着: 総合演習

-- [W05-D5-R1] ★★ ordered
-- 問: 注文月（1〜12 の整数。年は区別しない）ごとの注文件数（ステータスは問わない）を、月の昇順で求めよ。
-- 出力: month, cnt
SELECT CAST(strftime('%m', ordered_at) AS INTEGER) AS month, COUNT(*) AS cnt
FROM orders
GROUP BY month
ORDER BY month;

-- [W05-D5-R2] ★★★ ordered
-- 問: 「月初日（1日）」に行われた注文の件数を、月ごと（'YYYY-MM'）に求めよ（ステータスは問わない。1日に注文がなかった月は出さなくてよい）。月の昇順。
-- 出力: ym, cnt
-- ヒント: date(ordered_at, 'start of month') はその月の1日を返す。
SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt
FROM orders
WHERE date(ordered_at) = date(ordered_at, 'start of month')
GROUP BY ym
ORDER BY ym;

-- [W05-D5-R3] ★★★
-- 問: レビューを評価で '高評価'（4〜5）・'普通'（3）・'低評価'（1〜2）に分け、区分ごとのレビュー件数と、コメントが書かれている割合（百分率、小数第1位まで）を求めよ。
-- 出力: band, cnt, comment_rate
SELECT CASE WHEN rating >= 4 THEN '高評価'
            WHEN rating = 3 THEN '普通'
            ELSE '低評価' END AS band,
       COUNT(*) AS cnt,
       ROUND(COUNT(comment) * 100.0 / COUNT(*), 1) AS comment_rate
FROM reviews
GROUP BY band;
