-- # Week 6: CTE（WITH 句）と多段集計

-- ## Day 1: CTE の基本

-- [W06-D1-1] ★★ ordered
-- 問: CTE で「顧客ごとの completed 購入総額」を作り、購入総額の上位10人を取得せよ。総額の高い順、同額なら customer_id 順。
-- 出力: customer_id, name, total
WITH customer_totals AS (
  SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
)
SELECT c.customer_id, c.name, t.total
FROM customer_totals t
JOIN customers c ON c.customer_id = t.customer_id
ORDER BY t.total DESC, c.customer_id
LIMIT 10;

-- [W06-D1-2] ★★
-- 問: 月ごと（'YYYY-MM'）の completed 売上を CTE で作り、「月次売上の平均」を上回った月を取得せよ。
-- 出力: ym, sales
-- 解説: 同じ CTE を本体とサブクエリの両方から参照できるのが、派生テーブルにない利点。
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY ym
)
SELECT ym, sales
FROM monthly
WHERE sales > (SELECT AVG(sales) FROM monthly);

-- [W06-D1-3] ★★★
-- 問: 全顧客を completed の注文回数で '0回'・'1回'・'2〜4回'・'5〜9回'・'10回以上' に分類し、区分ごとの顧客数を求めよ。
-- 出力: bucket, customers
WITH order_counts AS (
  SELECT c.customer_id, COUNT(o.order_id) AS cnt
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'completed'
  GROUP BY c.customer_id
)
SELECT CASE WHEN cnt = 0 THEN '0回'
            WHEN cnt = 1 THEN '1回'
            WHEN cnt <= 4 THEN '2〜4回'
            WHEN cnt <= 9 THEN '5〜9回'
            ELSE '10回以上' END AS bucket,
       COUNT(*) AS customers
FROM order_counts
GROUP BY bucket;

-- ## Day 1 定着: CTE の基本

-- [W06-D1-R1] ★★ ordered
-- 問: CTE で「商品ごとの completed 販売数量」を作り、販売数量の上位5商品を取得せよ。数量の多い順、同じなら product_id 順。
-- 出力: product_id, name, qty
WITH product_qty AS (
  SELECT oi.product_id, SUM(oi.quantity) AS qty
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY oi.product_id
)
SELECT p.product_id, p.name, q.qty
FROM product_qty q
JOIN products p ON p.product_id = q.product_id
ORDER BY q.qty DESC, p.product_id
LIMIT 5;

-- [W06-D1-R2] ★★
-- 問: CTE で部署ごとの平均年収を作り、全社員の平均年収を上回っている部署を取得せよ。部署未配属の社員は部署ごとの集計から除くが、全社員の平均には含める。平均年収は整数に四捨五入して出すこと。
-- 出力: department_id, avg_salary
WITH dept_avg AS (
  SELECT department_id, AVG(salary) AS avg_salary
  FROM employees
  WHERE department_id IS NOT NULL
  GROUP BY department_id
)
SELECT department_id, ROUND(avg_salary) AS avg_salary
FROM dept_avg
WHERE avg_salary > (SELECT AVG(salary) FROM employees);

-- [W06-D1-R3] ★★★
-- 問: 全商品をレビュー件数で '0件'・'1〜4件'・'5〜9件'・'10件以上' に分類し、区分ごとの商品数を求めよ。
-- 出力: bucket, products
WITH review_counts AS (
  SELECT p.product_id, COUNT(r.review_id) AS cnt
  FROM products p
  LEFT JOIN reviews r ON r.product_id = p.product_id
  GROUP BY p.product_id
)
SELECT CASE WHEN cnt = 0 THEN '0件'
            WHEN cnt <= 4 THEN '1〜4件'
            WHEN cnt <= 9 THEN '5〜9件'
            ELSE '10件以上' END AS bucket,
       COUNT(*) AS products
FROM review_counts
GROUP BY bucket;

-- ## Day 2: 多段集計

-- [W06-D2-1] ★★★
-- 問: 顧客ごとに平均注文金額（completed の注文1件あたりの金額の平均）を出し、それを都道府県ごとに平均した値（整数に四捨五入）を求めよ。
-- 出力: prefecture, avg_aov
-- ヒント: 注文単位 → 顧客単位 → 都道府県単位 の3段階。「平均の平均」は全体平均とは別物であることに注意。
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id
),
customer_aov AS (
  SELECT customer_id, AVG(amount) AS aov
  FROM order_totals
  GROUP BY customer_id
)
SELECT c.prefecture, ROUND(AVG(a.aov)) AS avg_aov
FROM customer_aov a
JOIN customers c ON c.customer_id = a.customer_id
GROUP BY c.prefecture;

-- [W06-D2-2] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）の新規購入顧客数（その月に初めて completed の注文をした顧客の数）を、月の昇順で求めよ。
-- 出力: ym, new_customers
WITH first_orders AS (
  SELECT customer_id, MIN(ordered_at) AS first_at
  FROM orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT strftime('%Y-%m', first_at) AS ym, COUNT(*) AS new_customers
FROM first_orders
GROUP BY ym
ORDER BY ym;

-- [W06-D2-3] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、completed の注文をした顧客数（buyers）と、その内訳として新規（その月が初購入月）と既存（それ以外）の人数を求めよ。月の昇順。
-- 出力: ym, buyers, new_buyers, repeat_buyers
WITH first_months AS (
  SELECT customer_id, MIN(strftime('%Y-%m', ordered_at)) AS first_ym
  FROM orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
monthly_buyers AS (
  SELECT DISTINCT strftime('%Y-%m', ordered_at) AS ym, customer_id
  FROM orders
  WHERE status = 'completed'
)
SELECT m.ym,
       COUNT(*) AS buyers,
       SUM(CASE WHEN m.ym = f.first_ym THEN 1 ELSE 0 END) AS new_buyers,
       SUM(CASE WHEN m.ym <> f.first_ym THEN 1 ELSE 0 END) AS repeat_buyers
FROM monthly_buyers m
JOIN first_months f ON f.customer_id = m.customer_id
GROUP BY m.ym
ORDER BY m.ym;

-- ## Day 2 定着: 多段集計

-- [W06-D2-R1] ★★★
-- 問: 支払方法ごとに、注文1件あたりの平均明細行数（小数第2位まで）を求めよ（ステータスは問わない）。
-- 出力: payment_method, avg_items
-- ヒント: まず注文ごとの明細行数を出し、それを支払方法ごとに平均する。
WITH order_items_cnt AS (
  SELECT o.order_id, o.payment_method, COUNT(*) AS items
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_id, o.payment_method
)
SELECT payment_method, ROUND(AVG(items), 2) AS avg_items
FROM order_items_cnt
GROUP BY payment_method;

-- [W06-D2-R2] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、その月に初めてレビューを書いた顧客の数を、月の昇順で求めよ。
-- 出力: ym, new_reviewers
WITH first_reviews AS (
  SELECT customer_id, MIN(created_at) AS first_at
  FROM reviews
  GROUP BY customer_id
)
SELECT strftime('%Y-%m', first_at) AS ym, COUNT(*) AS new_reviewers
FROM first_reviews
GROUP BY ym
ORDER BY ym;

-- [W06-D2-R3] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、レビューを書いた顧客数（reviewers）と、その内訳として初めてレビューを書いた月の顧客（new_reviewers）とそれ以外（repeat_reviewers）の人数を求めよ。月の昇順。
-- 出力: ym, reviewers, new_reviewers, repeat_reviewers
WITH first_months AS (
  SELECT customer_id, MIN(strftime('%Y-%m', created_at)) AS first_ym
  FROM reviews
  GROUP BY customer_id
),
monthly AS (
  SELECT DISTINCT strftime('%Y-%m', created_at) AS ym, customer_id
  FROM reviews
)
SELECT m.ym,
       COUNT(*) AS reviewers,
       SUM(CASE WHEN m.ym = f.first_ym THEN 1 ELSE 0 END) AS new_reviewers,
       SUM(CASE WHEN m.ym <> f.first_ym THEN 1 ELSE 0 END) AS repeat_reviewers
FROM monthly m
JOIN first_months f ON f.customer_id = m.customer_id
GROUP BY m.ym
ORDER BY m.ym;

-- ## Day 3: CTE 同士を比べる

-- [W06-D3-1] ★★★
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとの completed 売上と、全体に占める構成比（百分率、小数第1位まで）を求めよ。
-- 出力: category_name, sales, share
WITH category_sales AS (
  SELECT c.name AS category_name, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  JOIN categories c ON c.category_id = p.category_id
  WHERE o.status = 'completed'
  GROUP BY c.category_id, c.name
)
SELECT category_name, sales,
       ROUND(sales * 100.0 / (SELECT SUM(sales) FROM category_sales), 1) AS share
FROM category_sales;

-- [W06-D3-2] ★★★
-- 問: 商品ごとの completed 売上を出し、「同じカテゴリの商品の売上平均」を上回っている商品を取得せよ。カテゴリ平均は、売上が1円以上ある商品だけで計算し、整数に四捨五入して出すこと。
-- 出力: product_id, name, sales, category_avg
WITH product_sales AS (
  SELECT p.product_id, p.name, p.category_id, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
  GROUP BY p.product_id, p.name, p.category_id
),
category_avg AS (
  SELECT category_id, AVG(sales) AS avg_sales
  FROM product_sales
  GROUP BY category_id
)
SELECT ps.product_id, ps.name, ps.sales, ROUND(ca.avg_sales) AS category_avg
FROM product_sales ps
JOIN category_avg ca ON ca.category_id = ps.category_id
WHERE ps.sales > ca.avg_sales;

-- [W06-D3-3] ★★★ ordered
-- 問: 月次の completed 売上について、前月の売上と前月比の伸び率（(当月 − 前月) ÷ 前月 の百分率、小数第1位まで）を求めよ。ウィンドウ関数は使わず、月次売上の CTE を自己結合すること。最初の月は前月・伸び率とも NULL。月の昇順。
-- 出力: ym, sales, prev_sales, mom
-- ヒント: 前月は strftime('%Y-%m', ym || '-01', '-1 month') で求められる。
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY ym
)
SELECT cur.ym, cur.sales, prev.sales AS prev_sales,
       ROUND((cur.sales - prev.sales) * 100.0 / prev.sales, 1) AS mom
FROM monthly cur
LEFT JOIN monthly prev ON prev.ym = strftime('%Y-%m', cur.ym || '-01', '-1 month')
ORDER BY cur.ym;

-- ## Day 3 定着: CTE 同士を比べる

-- [W06-D3-R1] ★★★
-- 問: 顧客の都道府県ごとの completed 売上と、全体に占める構成比（百分率、小数第1位まで）を求めよ。
-- 出力: prefecture, sales, share
WITH pref_sales AS (
  SELECT c.prefecture, SUM(oi.quantity * oi.unit_price) AS sales
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY c.prefecture
)
SELECT prefecture, sales,
       ROUND(sales * 100.0 / (SELECT SUM(sales) FROM pref_sales), 1) AS share
FROM pref_sales;

-- [W06-D3-R2] ★★★
-- 問: completed の購入総額がある顧客について、購入総額が「同じ都道府県の購入者の購入総額の平均」を上回っている顧客を取得せよ。都道府県平均は整数に四捨五入して出すこと。
-- 出力: customer_id, prefecture, total, pref_avg
WITH customer_totals AS (
  SELECT c.customer_id, c.prefecture, SUM(oi.quantity * oi.unit_price) AS total
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY c.customer_id, c.prefecture
),
pref_avg AS (
  SELECT prefecture, AVG(total) AS avg_total
  FROM customer_totals
  GROUP BY prefecture
)
SELECT t.customer_id, t.prefecture, t.total, ROUND(a.avg_total) AS pref_avg
FROM customer_totals t
JOIN pref_avg a ON a.prefecture = t.prefecture
WHERE t.total > a.avg_total;

-- [W06-D3-R3] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）の注文件数（ステータスは問わない）と、前月の件数、前月との差（当月 − 前月）を求めよ。ウィンドウ関数は使わず、月次件数の CTE を自己結合すること。最初の月は前月・差とも NULL。月の昇順。
-- 出力: ym, cnt, prev_cnt, diff
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS cnt
  FROM orders
  GROUP BY ym
)
SELECT cur.ym, cur.cnt, prev.cnt AS prev_cnt, cur.cnt - prev.cnt AS diff
FROM monthly cur
LEFT JOIN monthly prev ON prev.ym = strftime('%Y-%m', cur.ym || '-01', '-1 month')
ORDER BY cur.ym;

-- ## Day 4: ロジックを分解する

-- [W06-D4-1] ★★★
-- 問: completed の注文を、クーポン利用の 'あり' / 'なし' に分け、それぞれの注文件数と平均注文金額（整数に四捨五入）を求めよ。
-- 出力: coupon_used, orders, avg_amount
WITH order_totals AS (
  SELECT o.order_id, o.coupon_code, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.coupon_code
)
SELECT CASE WHEN coupon_code IS NULL THEN 'なし' ELSE 'あり' END AS coupon_used,
       COUNT(*) AS orders,
       ROUND(AVG(amount)) AS avg_amount
FROM order_totals
GROUP BY coupon_used;

-- [W06-D4-2] ★★★
-- 問: completed の注文が2回以上ある顧客について、1回目から2回目の注文までの日数（julianday の差）を求め、該当顧客数とその平均日数（小数第1位まで）を出せ。ウィンドウ関数は使わないこと。
-- 出力: customers, avg_days
-- ヒント: 2回目の注文日時 = 「初回より後の注文」の中の最小値。
WITH first_orders AS (
  SELECT customer_id, MIN(ordered_at) AS first_at
  FROM orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
second_orders AS (
  SELECT o.customer_id, f.first_at, MIN(o.ordered_at) AS second_at
  FROM orders o
  JOIN first_orders f ON f.customer_id = o.customer_id AND o.ordered_at > f.first_at
  WHERE o.status = 'completed'
  GROUP BY o.customer_id, f.first_at
)
SELECT COUNT(*) AS customers,
       ROUND(AVG(julianday(second_at) - julianday(first_at)), 1) AS avg_days
FROM second_orders;

-- [W06-D4-3] ★★★ ordered
-- 問: 1注文に含まれる商品の種類数（明細行数）ごとに、注文件数と全注文に占める割合（百分率、小数第1位まで）を求めよ（ステータスは問わない）。種類数の昇順。
-- 出力: items, orders, share
WITH basket AS (
  SELECT order_id, COUNT(*) AS items
  FROM order_items
  GROUP BY order_id
)
SELECT items,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM basket), 1) AS share
FROM basket
GROUP BY items
ORDER BY items;

-- ## Day 4 定着: ロジックを分解する

-- [W06-D4-R1] ★★★
-- 問: completed の注文を、送料が 0 円の '無料' と、それ以外の '有料' に分け、それぞれの注文件数と平均注文金額（明細の合計。送料は含めない。整数に四捨五入）を求めよ。
-- 出力: shipping, orders, avg_amount
WITH order_totals AS (
  SELECT o.order_id, o.shipping_fee, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.shipping_fee
)
SELECT CASE WHEN shipping_fee = 0 THEN '無料' ELSE '有料' END AS shipping,
       COUNT(*) AS orders,
       ROUND(AVG(amount)) AS avg_amount
FROM order_totals
GROUP BY shipping;

-- [W06-D4-R2] ★★★
-- 問: レビューを2件以上書いた顧客について、1件目から2件目のレビューまでの日数（julianday の差）を求め、該当顧客数とその平均日数（小数第1位まで）を出せ。ウィンドウ関数は使わないこと。
-- 出力: customers, avg_days
WITH first_reviews AS (
  SELECT customer_id, MIN(created_at) AS first_at
  FROM reviews
  GROUP BY customer_id
),
second_reviews AS (
  SELECT r.customer_id, f.first_at, MIN(r.created_at) AS second_at
  FROM reviews r
  JOIN first_reviews f ON f.customer_id = r.customer_id AND r.created_at > f.first_at
  GROUP BY r.customer_id, f.first_at
)
SELECT COUNT(*) AS customers,
       ROUND(AVG(julianday(second_at) - julianday(first_at)), 1) AS avg_days
FROM second_reviews;

-- [W06-D4-R3] ★★★ ordered
-- 問: 1注文の合計数量（明細の quantity の合計）ごとに、注文件数と全注文に占める割合（百分率、小数第1位まで）を求めよ（ステータスは問わない）。合計数量の昇順。
-- 出力: total_qty, orders, share
WITH order_qty AS (
  SELECT order_id, SUM(quantity) AS total_qty
  FROM order_items
  GROUP BY order_id
)
SELECT total_qty,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_qty), 1) AS share
FROM order_qty
GROUP BY total_qty
ORDER BY total_qty;

-- ## Day 5: 中間テスト

-- [W06-D5-1] ★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、completed の注文件数と平均注文金額（整数に四捨五入）を求めよ。月の昇順。
-- 出力: ym, orders, aov
WITH order_totals AS (
  SELECT o.order_id, strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, ym
)
SELECT ym, COUNT(*) AS orders, ROUND(AVG(amount)) AS aov
FROM order_totals
GROUP BY ym
ORDER BY ym;

-- [W06-D5-2] ★★★
-- 問: 2025年の completed の注文について、注文回数が 5 回以上かつ購入総額が 100,000 円以上の顧客を取得せよ。
-- 出力: customer_id, name, orders, total
-- ヒント: orders と order_items を結合したまま COUNT(*) すると明細行数になる。注文回数は COUNT(DISTINCT order_id)。
SELECT c.customer_id, c.name,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity * oi.unit_price) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.order_id) >= 5
   AND SUM(oi.quantity * oi.unit_price) >= 100000;

-- [W06-D5-3] ★★★ ordered
-- 問: 商品ごとに「その商品を含む注文の数」と、そのうち cancelled の割合（百分率、小数第1位まで）を求め、注文数が 30 以上の商品の中でキャンセル率が高い上位5件を取得せよ。キャンセル率の高い順、同率なら product_id 順。
-- 出力: product_id, name, order_cnt, cancel_rate
WITH product_orders AS (
  SELECT oi.product_id,
         COUNT(*) AS order_cnt,
         SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  GROUP BY oi.product_id
)
SELECT p.product_id, p.name, po.order_cnt,
       ROUND(po.cancelled_cnt * 100.0 / po.order_cnt, 1) AS cancel_rate
FROM product_orders po
JOIN products p ON p.product_id = po.product_id
WHERE po.order_cnt >= 30
ORDER BY cancel_rate DESC, p.product_id
LIMIT 5;

-- ## Day 5 定着: 中間テスト

-- [W06-D5-R1] ★★ ordered
-- 問: 曜日（0=日曜 〜 6=土曜 の整数）ごとに、completed の注文件数と平均注文金額（整数に四捨五入）を求めよ。曜日の昇順。
-- 出力: dow, orders, aov
WITH order_totals AS (
  SELECT o.order_id,
         CAST(strftime('%w', o.ordered_at) AS INTEGER) AS dow,
         SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, dow
)
SELECT dow, COUNT(*) AS orders, ROUND(AVG(amount)) AS aov
FROM order_totals
GROUP BY dow
ORDER BY dow;

-- [W06-D5-R2] ★★★
-- 問: 2024年の completed の注文について、注文回数が 3 回以上かつ購入総額が 50,000 円以上の顧客を取得せよ。
-- 出力: customer_id, name, orders, total
SELECT c.customer_id, c.name,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity * oi.unit_price) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.ordered_at >= '2024-01-01' AND o.ordered_at < '2025-01-01'
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.order_id) >= 3
   AND SUM(oi.quantity * oi.unit_price) >= 50000;

-- [W06-D5-R3] ★★★ ordered
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとに「そのカテゴリの商品を含む注文の数」と、そのうち cancelled の割合（百分率、小数第1位まで）を求め、注文数が 100 以上のカテゴリの中でキャンセル率が高い上位3つを取得せよ。1つの注文に同じカテゴリの商品が複数あっても1と数える。キャンセル率の高い順、同率なら category_id 順。
-- 出力: category_id, name, order_cnt, cancel_rate
WITH category_orders AS (
  SELECT DISTINCT p.category_id, o.order_id, o.status
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
),
stats AS (
  SELECT category_id,
         COUNT(*) AS order_cnt,
         SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt
  FROM category_orders
  GROUP BY category_id
)
SELECT c.category_id, c.name, s.order_cnt,
       ROUND(s.cancelled_cnt * 100.0 / s.order_cnt, 1) AS cancel_rate
FROM stats s
JOIN categories c ON c.category_id = s.category_id
WHERE s.order_cnt >= 100
ORDER BY cancel_rate DESC, c.category_id
LIMIT 3;
