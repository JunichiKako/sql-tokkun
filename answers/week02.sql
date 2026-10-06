-- # Week 2: 集計（GROUP BY / HAVING）

-- ## Day 1: 集約関数

-- [W02-D1-1] ★
-- 問: 商品の件数、平均価格（小数第1位まで）、最高価格、最低価格を求めよ。
-- 出力: cnt, avg_price, max_price, min_price
SELECT COUNT(*) AS cnt,
       ROUND(AVG(price), 1) AS avg_price,
       MAX(price) AS max_price,
       MIN(price) AS min_price
FROM products;

-- [W02-D1-2] ★
-- 問: 顧客の総数、メールアドレスが登録されている顧客の数、顧客が住んでいる都道府県の種類数を求めよ。
-- 出力: total, with_email, prefectures
-- 解説: COUNT(*) は行数、COUNT(列) は NULL を除いた件数、COUNT(DISTINCT 列) は種類数。
SELECT COUNT(*) AS total,
       COUNT(email) AS with_email,
       COUNT(DISTINCT prefecture) AS prefectures
FROM customers;

-- [W02-D1-3] ★★
-- 問: 注文明細全体について、販売数量の合計、金額（quantity × unit_price）の合計、1明細あたりの平均金額（小数第1位まで）を求めよ。
-- 出力: total_qty, total_amount, avg_amount
SELECT SUM(quantity) AS total_qty,
       SUM(quantity * unit_price) AS total_amount,
       ROUND(AVG(quantity * unit_price), 1) AS avg_amount
FROM order_items;

-- ## Day 1 定着: 集約関数

-- [W02-D1-R1] ★
-- 問: 社員の人数、平均年収（整数に四捨五入）、最高年収、最低年収を求めよ。
-- 出力: cnt, avg_salary, max_salary, min_salary
SELECT COUNT(*) AS cnt,
       ROUND(AVG(salary)) AS avg_salary,
       MAX(salary) AS max_salary,
       MIN(salary) AS min_salary
FROM employees;

-- [W02-D1-R2] ★
-- 問: レビューの総数、コメント付きのレビューの数、レビューを書いた顧客の人数（同じ人は1人と数える）を求めよ。
-- 出力: total, with_comment, reviewers
SELECT COUNT(*) AS total,
       COUNT(comment) AS with_comment,
       COUNT(DISTINCT customer_id) AS reviewers
FROM reviews;

-- [W02-D1-R3] ★★
-- 問: 商品全体について、粗利（price - cost）の合計、1商品あたりの平均粗利（小数第1位まで）、原価率（cost ÷ price の百分率）の平均（小数第1位まで）を求めよ。
-- 出力: total_margin, avg_margin, avg_cost_rate
-- ヒント: 原価率は商品ごとに計算してから平均する。整数同士の割り算に注意。
SELECT SUM(price - cost) AS total_margin,
       ROUND(AVG(price - cost), 1) AS avg_margin,
       ROUND(AVG(cost * 100.0 / price), 1) AS avg_cost_rate
FROM products;

-- ## Day 2: GROUP BY

-- [W02-D2-1] ★ ordered
-- 問: 都道府県ごとの顧客数を、多い順（同数なら都道府県名の昇順）に求めよ。
-- 出力: prefecture, cnt
SELECT prefecture, COUNT(*) AS cnt
FROM customers
GROUP BY prefecture
ORDER BY cnt DESC, prefecture;

-- [W02-D2-2] ★
-- 問: 注文ステータスごとの注文件数を求めよ。
-- 出力: status, cnt
SELECT status, COUNT(*) AS cnt
FROM orders
GROUP BY status;

-- [W02-D2-3] ★★ ordered
-- 問: 月ごと（'YYYY-MM' 形式）の注文件数を、月の昇順で求めよ（ステータスは問わない）。
-- 出力: ym, cnt
-- ヒント: SQLite では strftime('%Y-%m', ordered_at)。PostgreSQL なら to_char(ordered_at, 'YYYY-MM')。
SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt
FROM orders
GROUP BY ym
ORDER BY ym;

-- ## Day 2 定着: GROUP BY

-- [W02-D2-R1] ★ ordered
-- 問: 役職ごとの社員数を、多い順（同数なら役職名の昇順）に求めよ。
-- 出力: job_title, cnt
SELECT job_title, COUNT(*) AS cnt
FROM employees
GROUP BY job_title
ORDER BY cnt DESC, job_title;

-- [W02-D2-R2] ★
-- 問: 評価（rating）ごとのレビュー件数を求めよ。
-- 出力: rating, cnt
SELECT rating, COUNT(*) AS cnt
FROM reviews
GROUP BY rating;

-- [W02-D2-R3] ★★ ordered
-- 問: 月ごと（'YYYY-MM' 形式）のレビュー投稿件数を、月の昇順で求めよ。
-- 出力: ym, cnt
SELECT strftime('%Y-%m', created_at) AS ym, COUNT(*) AS cnt
FROM reviews
GROUP BY strftime('%Y-%m', created_at)
ORDER BY ym;

-- ## Day 3: HAVING

-- [W02-D3-1] ★★
-- 問: キャンセル以外の注文が 30 回以上ある顧客の ID と注文回数を求めよ。
-- 出力: customer_id, order_cnt
-- 解説: WHERE は集計「前」の行の絞り込み、HAVING は集計「後」のグループの絞り込み。
SELECT customer_id, COUNT(*) AS order_cnt
FROM orders
WHERE status <> 'cancelled'
GROUP BY customer_id
HAVING COUNT(*) >= 30;

-- [W02-D3-2] ★★
-- 問: 明細の合計金額（quantity × unit_price の合計）が 30,000 円以上の注文を求めよ。
-- 出力: order_id, total
SELECT order_id, SUM(quantity * unit_price) AS total
FROM order_items
GROUP BY order_id
HAVING SUM(quantity * unit_price) >= 30000;

-- [W02-D3-3] ★★
-- 問: レビューが 5 件以上あり、平均評価が 4.0 以上の商品について、レビュー件数と平均評価（小数第2位まで）を求めよ。
-- 出力: product_id, review_cnt, avg_rating
SELECT product_id, COUNT(*) AS review_cnt, ROUND(AVG(rating), 2) AS avg_rating
FROM reviews
GROUP BY product_id
HAVING COUNT(*) >= 5 AND AVG(rating) >= 4.0;

-- ## Day 3 定着: HAVING

-- [W02-D3-R1] ★★
-- 問: コメント付きのレビューを 10 件以上書いた顧客の ID と、コメント付きレビューの件数を求めよ。
-- 出力: customer_id, review_cnt
-- 解説: 「コメント付き」は集計前の行の条件なので WHERE、「10 件以上」は集計後の条件なので HAVING。
SELECT customer_id, COUNT(*) AS review_cnt
FROM reviews
WHERE comment IS NOT NULL
GROUP BY customer_id
HAVING COUNT(*) >= 10;

-- [W02-D3-R2] ★★
-- 問: 販売数量（quantity）の合計が 300 個以上の商品を求めよ（ステータスは問わない）。
-- 出力: product_id, total_qty
SELECT product_id, SUM(quantity) AS total_qty
FROM order_items
GROUP BY product_id
HAVING SUM(quantity) >= 300;

-- [W02-D3-R3] ★★
-- 問: 社員が 5 人以上いて、平均年収が 650万円以上の部署について、社員数と平均年収（整数に四捨五入）を求めよ。
-- 出力: department_id, cnt, avg_salary
SELECT department_id, COUNT(*) AS cnt, ROUND(AVG(salary)) AS avg_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5 AND AVG(salary) >= 6500000;

-- ## Day 4: 条件付き集計

-- [W02-D4-1] ★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、completed の注文件数と cancelled の注文件数を横に並べて求めよ。月の昇順。
-- 出力: ym, completed_cnt, cancelled_cnt
-- ヒント: SUM(CASE WHEN 条件 THEN 1 ELSE 0 END)。
-- 解説: PostgreSQL なら COUNT(*) FILTER (WHERE status = 'completed') とも書ける（SQLite も 3.30 以降で対応）。
SELECT strftime('%Y-%m', ordered_at) AS ym,
       SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_cnt,
       SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt
FROM orders
GROUP BY ym
ORDER BY ym;

-- [W02-D4-2] ★★
-- 問: 支払方法ごとに、注文件数とキャンセル率（cancelled の件数 ÷ 全件数 の百分率、小数第1位まで）を求めよ。
-- 出力: payment_method, total_cnt, cancel_rate
SELECT payment_method,
       COUNT(*) AS total_cnt,
       ROUND(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate
FROM orders
GROUP BY payment_method;

-- [W02-D4-3] ★★★ ordered
-- 問: 顧客の登録年ごとに、男性・女性・性別不明（NULL）の人数を横に並べて求めよ。年の昇順。
-- 出力: year, male_cnt, female_cnt, unknown_cnt
SELECT strftime('%Y', registered_at) AS year,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_cnt,
       SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_cnt,
       SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS unknown_cnt
FROM customers
GROUP BY year
ORDER BY year;

-- ## Day 4 定着: 条件付き集計

-- [W02-D4-R1] ★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、送料が 0 円の注文件数と 550 円の注文件数を横に並べて求めよ。ステータスは問わない。月の昇順。
-- 出力: ym, free_cnt, paid_cnt
-- ヒント: SUM(CASE WHEN 条件 THEN 1 ELSE 0 END)。
SELECT strftime('%Y-%m', ordered_at) AS ym,
       SUM(CASE WHEN shipping_fee = 0 THEN 1 ELSE 0 END) AS free_cnt,
       SUM(CASE WHEN shipping_fee = 550 THEN 1 ELSE 0 END) AS paid_cnt
FROM orders
GROUP BY strftime('%Y-%m', ordered_at)
ORDER BY ym;

-- [W02-D4-R2] ★★
-- 問: デバイスごとに、アクセス件数とゲスト率（customer_id が NULL のアクセス件数 ÷ 全件数 の百分率、小数第1位まで）を求めよ。
-- 出力: device, total_cnt, guest_rate
SELECT device,
       COUNT(*) AS total_cnt,
       ROUND(SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS guest_rate
FROM access_logs
GROUP BY device;

-- [W02-D4-R3] ★★★ ordered
-- 問: レビューの投稿年ごとに、高評価（4 以上）の件数、低評価（2 以下）の件数、コメントなし（NULL）の件数を横に並べて求めよ。年の昇順。
-- 出力: year, high_cnt, low_cnt, no_comment_cnt
SELECT strftime('%Y', created_at) AS year,
       SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS high_cnt,
       SUM(CASE WHEN rating <= 2 THEN 1 ELSE 0 END) AS low_cnt,
       SUM(CASE WHEN comment IS NULL THEN 1 ELSE 0 END) AS no_comment_cnt
FROM reviews
GROUP BY strftime('%Y', created_at)
ORDER BY year;

-- ## Day 5: 総合演習

-- [W02-D5-1] ★★
-- 問: 部署ID ごとに、社員数・平均年収（整数に四捨五入）・最高年収を求めよ。部署未配属（NULL）の社員も1つのグループとして出すこと。
-- 出力: department_id, cnt, avg_salary, max_salary
-- 解説: GROUP BY では NULL 同士は同じグループにまとめられる。
SELECT department_id,
       COUNT(*) AS cnt,
       ROUND(AVG(salary)) AS avg_salary,
       MAX(salary) AS max_salary
FROM employees
GROUP BY department_id;

-- [W02-D5-2] ★★ ordered
-- 問: 曜日ごとの注文件数を求めよ。曜日は 0=日曜 〜 6=土曜 の整数で表し、その昇順に並べること。
-- 出力: dow, cnt
-- ヒント: strftime('%w', ordered_at) は文字列を返すので CAST する。
SELECT CAST(strftime('%w', ordered_at) AS INTEGER) AS dow, COUNT(*) AS cnt
FROM orders
GROUP BY dow
ORDER BY dow;

-- [W02-D5-3] ★★★ ordered
-- 問: クーポンコードごと（未使用は 'なし' と表示）に、注文件数と平均送料（小数第1位まで）を、件数の多い順（同数ならクーポン名の昇順）に求めよ。
-- 出力: coupon, cnt, avg_shipping
SELECT COALESCE(coupon_code, 'なし') AS coupon,
       COUNT(*) AS cnt,
       ROUND(AVG(shipping_fee), 1) AS avg_shipping
FROM orders
GROUP BY COALESCE(coupon_code, 'なし')
ORDER BY cnt DESC, coupon;

-- ## Day 5 定着: 総合演習

-- [W02-D5-R1] ★★
-- 問: 紹介者ID（referrer_id）ごとに、紹介された顧客の人数を求めよ。紹介なし（NULL）の顧客も1つのグループとして出すこと。
-- 出力: referrer_id, cnt
SELECT referrer_id, COUNT(*) AS cnt
FROM customers
GROUP BY referrer_id;

-- [W02-D5-R2] ★★ ordered
-- 問: 時間帯ごとのアクセス件数を求めよ。時間帯は 0〜23 の整数（アクセス日時の「時」）で表し、その昇順に並べること。
-- 出力: hour, cnt
-- ヒント: strftime('%H', accessed_at) は '07' のような文字列を返すので CAST する。
SELECT CAST(strftime('%H', accessed_at) AS INTEGER) AS hour, COUNT(*) AS cnt
FROM access_logs
GROUP BY CAST(strftime('%H', accessed_at) AS INTEGER)
ORDER BY hour;

-- [W02-D5-R3] ★★★ ordered
-- 問: 性別ごと（NULL は '不明' と表示）に、顧客数と、そのうち紹介経由で登録した（referrer_id が NULL でない）顧客数を、顧客数の多い順（同数なら性別の表示の昇順）に求めよ。
-- 出力: gender_label, cnt, referred_cnt
SELECT COALESCE(gender, '不明') AS gender_label,
       COUNT(*) AS cnt,
       COUNT(referrer_id) AS referred_cnt
FROM customers
GROUP BY COALESCE(gender, '不明')
ORDER BY cnt DESC, gender_label;
