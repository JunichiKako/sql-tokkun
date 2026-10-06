-- # Week 7: ウィンドウ関数 (1) 順位とパーティション

-- ## Day 1: ROW_NUMBER / RANK / DENSE_RANK

-- [W07-D1-1] ★★
-- 問: 全社員に年収の高い順で順位を付けよ。RANK（同順位の次は番号が飛ぶ）、DENSE_RANK（飛ばない）、ROW_NUMBER（同額なら employee_id の小さい方が先の通し番号）の3種類を並べること。
-- 出力: name, salary, rnk, dense_rnk, row_num
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk,
       ROW_NUMBER() OVER (ORDER BY salary DESC, employee_id) AS row_num
FROM employees;

-- [W07-D1-2] ★★
-- 問: 部署に所属している社員について、部署内での年収順位（RANK、高い順）を求めよ。
-- 出力: department_id, name, salary, rnk
SELECT department_id, name, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
FROM employees
WHERE department_id IS NOT NULL;

-- [W07-D1-3] ★★★
-- 問: 各部署で年収が上位2位以内（DENSE_RANK で 2 以下。同額は同順位）の社員を取得せよ。部署未配属の社員は除く。
-- 出力: department_id, name, salary
-- 解説: ウィンドウ関数の結果は WHERE で直接絞れない（WHERE の後に評価されるため）。CTE かサブクエリで一段包む。
WITH ranked AS (
  SELECT department_id, name, salary,
         DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
  FROM employees
  WHERE department_id IS NOT NULL
)
SELECT department_id, name, salary
FROM ranked
WHERE rnk <= 2;

-- ## Day 1 定着: ROW_NUMBER / RANK / DENSE_RANK

-- [W07-D1-R1] ★★
-- 問: 全商品に価格の安い順で順位を付けよ。RANK（同順位の次は番号が飛ぶ）、DENSE_RANK（飛ばない）、ROW_NUMBER（同額なら product_id の小さい方が先の通し番号）の3種類を並べること。
-- 出力: product_id, name, price, rnk, dense_rnk, row_num
SELECT product_id, name, price,
       RANK() OVER (ORDER BY price) AS rnk,
       DENSE_RANK() OVER (ORDER BY price) AS dense_rnk,
       ROW_NUMBER() OVER (ORDER BY price, product_id) AS row_num
FROM products;

-- [W07-D1-R2] ★★
-- 問: 全商品について、商品が直接属するカテゴリ内での価格順位（DENSE_RANK、高い順）を求めよ。
-- 出力: category_id, product_id, price, dense_rnk
SELECT category_id, product_id, price,
       DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS dense_rnk
FROM products;

-- [W07-D1-R3] ★★★
-- 問: 各カテゴリ（商品が直接属するカテゴリ）で、価格が安い方から2位以内（RANK で 2 以下。同額は同順位）の商品を取得せよ。
-- 出力: category_id, product_id, name, price
-- 解説: 1位が2つ並ぶと次は3位になるので、RANK では「2位」が存在しないカテゴリもある。DENSE_RANK なら3つ目の価格まで含まれる。どちらで絞るかで結果が変わる。
WITH ranked AS (
  SELECT category_id, product_id, name, price,
         RANK() OVER (PARTITION BY category_id ORDER BY price) AS rnk
  FROM products
)
SELECT category_id, product_id, name, price
FROM ranked
WHERE rnk <= 2;

-- ## Day 2: PARTITION BY と集約ウィンドウ

-- [W07-D2-1] ★★
-- 問: 部署に所属している社員について、年収・部署の平均年収（整数に四捨五入）・部署平均との差（整数に四捨五入）を求めよ。
-- 出力: name, department_id, salary, dept_avg, diff
-- 解説: GROUP BY と違い、ウィンドウ関数は行を潰さずに集計値を各行に付けられる。
SELECT name, department_id, salary,
       ROUND(AVG(salary) OVER (PARTITION BY department_id)) AS dept_avg,
       ROUND(salary - AVG(salary) OVER (PARTITION BY department_id)) AS diff
FROM employees
WHERE department_id IS NOT NULL;

-- [W07-D2-2] ★★
-- 問: 全商品について、同じカテゴリ内の最高価格に対する自分の価格の比率（百分率、小数第1位まで）を求めよ。
-- 出力: product_id, category_id, price, ratio_to_max
SELECT product_id, category_id, price,
       ROUND(price * 100.0 / MAX(price) OVER (PARTITION BY category_id), 1) AS ratio_to_max
FROM products;

-- [W07-D2-3] ★★★
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとの completed 売上と構成比（百分率、小数第1位まで）を、今度はウィンドウ関数で求めよ（W06-D3-1 の別解）。
-- 出力: category_name, sales, share
-- ヒント: SUM(SUM(...)) OVER () のように、集約結果に対してウィンドウ関数を掛けられる。
SELECT c.name AS category_name,
       SUM(oi.quantity * oi.unit_price) AS sales,
       ROUND(SUM(oi.quantity * oi.unit_price) * 100.0
             / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1) AS share
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.status = 'completed'
GROUP BY c.category_id, c.name;

-- ## Day 2 定着: PARTITION BY と集約ウィンドウ

-- [W07-D2-R1] ★★
-- 問: 全商品について、価格・同じカテゴリ（商品が直接属するカテゴリ）の商品数・カテゴリの平均価格（整数に四捨五入）を求めよ。
-- 出力: product_id, category_id, price, cat_cnt, cat_avg
SELECT product_id, category_id, price,
       COUNT(*) OVER (PARTITION BY category_id) AS cat_cnt,
       ROUND(AVG(price) OVER (PARTITION BY category_id)) AS cat_avg
FROM products;

-- [W07-D2-R2] ★★
-- 問: 部署に所属している社員について、所属部署の年収合計に占める自分の年収の割合（百分率、小数第1位まで）を求めよ。
-- 出力: name, department_id, salary, share
SELECT name, department_id, salary,
       ROUND(salary * 100.0 / SUM(salary) OVER (PARTITION BY department_id), 1) AS share
FROM employees
WHERE department_id IS NOT NULL;

-- [W07-D2-R3] ★★★
-- 問: 支払方法ごとの completed 売上と構成比（百分率、小数第1位まで）を、ウィンドウ関数を使って求めよ。
-- 出力: payment_method, sales, share
-- ヒント: GROUP BY で支払方法ごとに集計した結果に、SUM(...) OVER () で全体の合計を付ける。
SELECT o.payment_method,
       SUM(oi.quantity * oi.unit_price) AS sales,
       ROUND(SUM(oi.quantity * oi.unit_price) * 100.0
             / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1) AS share
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY o.payment_method;

-- ## Day 3: グループ内 Top N / 最新1件

-- [W07-D3-1] ★★★
-- 問: 注文したことがある各顧客の最新の注文を、ROW_NUMBER を使って取得せよ（ステータスは問わない。同時刻なら order_id の大きい方を最新とする）。
-- 出力: customer_id, order_id, ordered_at
WITH ranked AS (
  SELECT customer_id, order_id, ordered_at,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at DESC, order_id DESC) AS rn
  FROM orders
)
SELECT customer_id, order_id, ordered_at
FROM ranked
WHERE rn = 1;

-- [W07-D3-2] ★★★
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとに、completed 売上の上位3商品を取得せよ。順位は売上の高い順、同額なら product_id 順の通し番号とする。
-- 出力: category_id, product_id, name, sales, rn
WITH product_sales AS (
  SELECT p.category_id, p.product_id, p.name, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category_id, p.product_id, p.name
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY sales DESC, product_id) AS rn
  FROM product_sales
)
SELECT category_id, product_id, name, sales, rn
FROM ranked
WHERE rn <= 3;

-- [W07-D3-3] ★★★
-- 問: 都道府県ごとに、completed 購入総額が最も多い顧客を1人ずつ取得せよ（同額なら customer_id の小さい方）。
-- 出力: prefecture, customer_id, name, total
WITH customer_totals AS (
  SELECT c.prefecture, c.customer_id, c.name, SUM(oi.quantity * oi.unit_price) AS total
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY c.prefecture, c.customer_id, c.name
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY prefecture ORDER BY total DESC, customer_id) AS rn
  FROM customer_totals
)
SELECT prefecture, customer_id, name, total
FROM ranked
WHERE rn = 1;

-- ## Day 3 定着: グループ内 Top N / 最新1件

-- [W07-D3-R1] ★★★
-- 問: レビューが付いている各商品について、最新のレビューを ROW_NUMBER を使って取得せよ（同時刻なら review_id の大きい方を最新とする）。
-- 出力: product_id, review_id, rating, created_at
WITH ranked AS (
  SELECT product_id, review_id, rating, created_at,
         ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY created_at DESC, review_id DESC) AS rn
  FROM reviews
)
SELECT product_id, review_id, rating, created_at
FROM ranked
WHERE rn = 1;

-- [W07-D3-R2] ★★★
-- 問: 都道府県ごとに、completed の注文件数が多い顧客の上位3人を取得せよ。順位は件数の多い順、同数なら customer_id 順の通し番号とする。
-- 出力: prefecture, customer_id, order_cnt, rn
WITH customer_orders AS (
  SELECT c.prefecture, c.customer_id, COUNT(*) AS order_cnt
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  WHERE o.status = 'completed'
  GROUP BY c.prefecture, c.customer_id
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY prefecture ORDER BY order_cnt DESC, customer_id) AS rn
  FROM customer_orders
)
SELECT prefecture, customer_id, order_cnt, rn
FROM ranked
WHERE rn <= 3;

-- [W07-D3-R3] ★★★
-- 問: completed の注文で売れたことがある各商品について、その商品を最も多く買った顧客（completed の購入数量の合計が最大。同数なら customer_id の小さい方）を1人ずつ取得せよ。
-- 出力: product_id, customer_id, qty
WITH customer_qty AS (
  SELECT oi.product_id, o.customer_id, SUM(oi.quantity) AS qty
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY oi.product_id, o.customer_id
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY qty DESC, customer_id) AS rn
  FROM customer_qty
)
SELECT product_id, customer_id, qty
FROM ranked
WHERE rn = 1;

-- ## Day 4: 重複検出と「n 回目」

-- [W07-D4-1] ★★★
-- 問: 同じメールアドレス（大文字・小文字の違いは無視）で二重登録されている顧客のうち、customer_id が最小の1件を「正」として残す場合、削除候補となる側の顧客を取得せよ。
-- 出力: customer_id, email
WITH numbered AS (
  SELECT customer_id, email,
         ROW_NUMBER() OVER (PARTITION BY lower(email) ORDER BY customer_id) AS rn
  FROM customers
  WHERE email IS NOT NULL
)
SELECT customer_id, email
FROM numbered
WHERE rn > 1;

-- [W07-D4-2] ★★★
-- 問: 各顧客の「初回の注文」（ステータスは問わない。同時刻なら order_id の小さい方）で使われた支払方法を調べ、支払方法ごとの顧客数を求めよ。
-- 出力: payment_method, customers
WITH numbered AS (
  SELECT customer_id, payment_method,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS rn
  FROM orders
)
SELECT payment_method, COUNT(*) AS customers
FROM numbered
WHERE rn = 1
GROUP BY payment_method;

-- [W07-D4-3] ★★★ ordered
-- 問: completed の注文に、顧客ごとの通し番号（1回目、2回目…。注文日時順、同時刻なら order_id 順）を付け、1〜5回目それぞれについて注文件数と平均注文金額（整数に四捨五入）を求めよ。回数の昇順。
-- 出力: seq, orders, avg_amount
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.ordered_at, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id, o.ordered_at
),
numbered AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS seq
  FROM order_totals
)
SELECT seq, COUNT(*) AS orders, ROUND(AVG(amount)) AS avg_amount
FROM numbered
WHERE seq <= 5
GROUP BY seq
ORDER BY seq;

-- ## Day 4 定着: 重複検出と「n 回目」

-- [W07-D4-R1] ★★★
-- 問: 同姓同名（name が完全に一致）の顧客について、登録日時の早い順（同時刻なら customer_id 順）に通し番号を付けたとき、2人目以降にあたる顧客を取得せよ。
-- 出力: customer_id, name, registered_at
WITH numbered AS (
  SELECT customer_id, name, registered_at,
         ROW_NUMBER() OVER (PARTITION BY name ORDER BY registered_at, customer_id) AS rn
  FROM customers
)
SELECT customer_id, name, registered_at
FROM numbered
WHERE rn > 1;

-- [W07-D4-R2] ★★★
-- 問: 各顧客の「最後の注文」（ステータスは問わない。同時刻なら order_id の大きい方）のステータスを調べ、ステータスごとの顧客数を求めよ。
-- 出力: status, customers
WITH numbered AS (
  SELECT customer_id, status,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at DESC, order_id DESC) AS rn
  FROM orders
)
SELECT status, COUNT(*) AS customers
FROM numbered
WHERE rn = 1
GROUP BY status;

-- [W07-D4-R3] ★★★ ordered
-- 問: レビューに、顧客ごとの通し番号（1件目、2件目…。投稿日時順、同時刻なら review_id 順）を付け、1〜3件目それぞれについてレビュー件数と平均評価（小数第2位まで）を求めよ。件数目の昇順。
-- 出力: seq, reviews, avg_rating
WITH numbered AS (
  SELECT rating,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at, review_id) AS seq
  FROM reviews
)
SELECT seq, COUNT(*) AS reviews, ROUND(AVG(rating), 2) AS avg_rating
FROM numbered
WHERE seq <= 3
GROUP BY seq
ORDER BY seq;

-- ## Day 5: 総合演習

-- [W07-D5-1] ★★
-- 問: レビュー件数の多い商品ランキングで 5 位以内（RANK。同数は同順位）の商品を取得せよ。
-- 出力: product_id, review_cnt, rnk
WITH counts AS (
  SELECT product_id, COUNT(*) AS review_cnt,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM reviews
  GROUP BY product_id
)
SELECT product_id, review_cnt, rnk
FROM counts
WHERE rnk <= 5;

-- [W07-D5-2] ★★★ ordered
-- 問: 2025年の各月（'YYYY-MM'）について、completed 売上が最も大きかった商品を1つずつ取得せよ（同額なら product_id の小さい方）。月の昇順。
-- 出力: ym, product_id, name, sales
WITH monthly_product AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, p.product_id, p.name,
         SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY ym, p.product_id, p.name
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY ym ORDER BY sales DESC, product_id) AS rn
  FROM monthly_product
)
SELECT ym, product_id, name, sales
FROM ranked
WHERE rn = 1
ORDER BY ym;

-- [W07-D5-3] ★★★
-- 問: 部署ごとに、最も新しく入社した社員の名前と、最も古くから在籍している社員の名前を1行で取得せよ（入社日が同じなら employee_id の小さい方を優先。部署未配属は除く）。
-- 出力: department_id, newest_name, oldest_name
WITH numbered AS (
  SELECT department_id, name,
         ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY hired_on DESC, employee_id) AS newest,
         ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY hired_on, employee_id) AS oldest
  FROM employees
  WHERE department_id IS NOT NULL
)
SELECT department_id,
       MAX(CASE WHEN newest = 1 THEN name END) AS newest_name,
       MAX(CASE WHEN oldest = 1 THEN name END) AS oldest_name
FROM numbered
GROUP BY department_id;

-- ## Day 5 定着: 総合演習

-- [W07-D5-R1] ★★
-- 問: completed の注文で買った商品の種類数（異なる product_id の数）が多い顧客のランキングで 5 位以内（RANK。同数は同順位）の顧客を取得せよ。
-- 出力: customer_id, product_kinds, rnk
WITH counts AS (
  SELECT o.customer_id, COUNT(DISTINCT oi.product_id) AS product_kinds,
         RANK() OVER (ORDER BY COUNT(DISTINCT oi.product_id) DESC) AS rnk
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
)
SELECT customer_id, product_kinds, rnk
FROM counts
WHERE rnk <= 5;

-- [W07-D5-R2] ★★★ ordered
-- 問: 2024年の各月（'YYYY-MM'）について、completed 売上が最も大きかったカテゴリ（商品が直接属するカテゴリ）を1つずつ取得せよ（同額なら category_id の小さい方）。月の昇順。
-- 出力: ym, category_id, category_name, sales
WITH monthly_category AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, c.category_id, c.name AS category_name,
         SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  JOIN categories c ON c.category_id = p.category_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2024-01-01' AND o.ordered_at < '2025-01-01'
  GROUP BY ym, c.category_id, c.name
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY ym ORDER BY sales DESC, category_id) AS rn
  FROM monthly_category
)
SELECT ym, category_id, category_name, sales
FROM ranked
WHERE rn = 1
ORDER BY ym;

-- [W07-D5-R3] ★★★
-- 問: 商品のあるカテゴリ（商品が直接属するカテゴリ）ごとに、最も価格の高い商品の名前と最も価格の安い商品の名前を1行で取得せよ（どちらも同額なら product_id の小さい方を優先）。
-- 出力: category_id, most_expensive, cheapest
WITH numbered AS (
  SELECT category_id, name,
         ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC, product_id) AS by_high,
         ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price, product_id) AS by_low
  FROM products
)
SELECT category_id,
       MAX(CASE WHEN by_high = 1 THEN name END) AS most_expensive,
       MAX(CASE WHEN by_low = 1 THEN name END) AS cheapest
FROM numbered
GROUP BY category_id;
