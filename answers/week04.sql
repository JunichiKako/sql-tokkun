-- # Week 4: サブクエリと集合演算

-- ## Day 1: スカラサブクエリと IN

-- [W04-D1-1] ★
-- 問: 全商品の平均価格より高い商品を取得せよ。
-- 出力: product_id, name, price
SELECT product_id, name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- [W04-D1-2] ★★
-- 問: レビューが1件も付いていない商品を、サブクエリを使って取得せよ。
-- 出力: product_id, name
SELECT product_id, name
FROM products
WHERE product_id NOT IN (SELECT product_id FROM reviews);

-- [W04-D1-3] ★★
-- 問: 全商品について、価格と「全商品の平均価格との差」（小数第1位まで）を取得せよ。
-- 出力: name, price, diff_from_avg
SELECT name, price,
       ROUND(price - (SELECT AVG(price) FROM products), 1) AS diff_from_avg
FROM products;

-- ## Day 1 定着: スカラサブクエリと IN

-- [W04-D1-R1] ★
-- 問: 全社員（部署未配属の社員も含む）の平均年収より年収が高い社員を取得せよ。
-- 出力: employee_id, name, salary
SELECT employee_id, name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- [W04-D1-R2] ★★
-- 問: 社員が1人も所属していない部署を、サブクエリを使って取得せよ。
-- 出力: department_id, name
-- ヒント: employees.department_id には NULL（未配属）がある。
-- 解説: NOT IN のリストに NULL が1つでも混じると、条件が「不明」になって1行も返らない。サブクエリ側で IS NOT NULL を付けるか、NOT EXISTS を使う。
SELECT department_id, name
FROM departments
WHERE department_id NOT IN (
        SELECT department_id
        FROM employees
        WHERE department_id IS NOT NULL
      );

-- [W04-D1-R3] ★★
-- 問: 全社員について、年収と「全社員の最高年収に対する割合」（百分率、小数第1位まで）を取得せよ。
-- 出力: employee_id, name, salary, pct_of_max
-- 解説: salary も MAX(salary) も整数なので、そのまま割ると整数の割り算で 0 になる。100.0 を掛けて実数にしてから割る。
SELECT employee_id, name, salary,
       ROUND(salary * 100.0 / (SELECT MAX(salary) FROM employees), 1) AS pct_of_max
FROM employees;

-- ## Day 2: EXISTS と相関サブクエリ

-- [W04-D2-1] ★★
-- 問: 2024年12月31日までに登録した顧客のうち、2025年に completed の注文が1件もない顧客を取得せよ。
-- 出力: customer_id, name
-- ヒント: NOT EXISTS。
SELECT c.customer_id, c.name
FROM customers c
WHERE c.registered_at < '2025-01-01'
  AND NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = c.customer_id
          AND o.status = 'completed'
          AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
      );

-- [W04-D2-2] ★★★
-- 問: 各カテゴリ（商品が直接属するカテゴリ）の中で最も価格が高い商品を取得せよ。同額1位が複数あればすべて出すこと。
-- 出力: category_id, name, price
-- ヒント: 相関サブクエリで「同じカテゴリの最高価格」と比較する。
SELECT p.category_id, p.name, p.price
FROM products p
WHERE p.price = (
        SELECT MAX(p2.price)
        FROM products p2
        WHERE p2.category_id = p.category_id
      );

-- [W04-D2-3] ★★★
-- 問: 注文したことがある各顧客の「最新の注文」を取得せよ（ステータスは問わない）。
-- 出力: customer_id, order_id, ordered_at
SELECT o.customer_id, o.order_id, o.ordered_at
FROM orders o
WHERE o.ordered_at = (
        SELECT MAX(o2.ordered_at)
        FROM orders o2
        WHERE o2.customer_id = o.customer_id
      );

-- ## Day 2 定着: EXISTS と相関サブクエリ

-- [W04-D2-R1] ★★
-- 問: 部下が1人もいない社員（自分を manager_id に持つ社員がいない社員）を取得せよ。
-- 出力: employee_id, name
-- ヒント: NOT EXISTS。
-- 解説: employee_id NOT IN (SELECT manager_id FROM employees) と書くと、社長の manager_id が NULL なので1行も返らない。
SELECT e.employee_id, e.name
FROM employees e
WHERE NOT EXISTS (
        SELECT 1
        FROM employees e2
        WHERE e2.manager_id = e.employee_id
      );

-- [W04-D2-R2] ★★★
-- 問: 各部署の中で最も年収が低い社員を取得せよ。同額の最下位が複数いればすべて出すこと。部署未配属の社員は対象外。
-- 出力: department_id, name, salary
-- ヒント: 相関サブクエリで「同じ部署の最低年収」と比較する。
SELECT e.department_id, e.name, e.salary
FROM employees e
WHERE e.salary = (
        SELECT MIN(e2.salary)
        FROM employees e2
        WHERE e2.department_id = e.department_id
      );

-- [W04-D2-R3] ★★★
-- 問: レビューが付いている各商品について、「最新のレビュー」を取得せよ。
-- 出力: product_id, review_id, rating, created_at
SELECT r.product_id, r.review_id, r.rating, r.created_at
FROM reviews r
WHERE r.created_at = (
        SELECT MAX(r2.created_at)
        FROM reviews r2
        WHERE r2.product_id = r.product_id
      );

-- ## Day 3: 派生テーブル（FROM 句のサブクエリ）

-- [W04-D3-1] ★★
-- 問: completed の注文がある顧客について「顧客ごとの購入総額」を出し、その平均（顧客1人あたりの平均購入総額、整数に四捨五入）を求めよ。
-- 出力: avg_total
SELECT ROUND(AVG(total)) AS avg_total
FROM (
  SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
) AS t;

-- [W04-D3-2] ★★★
-- 問: 全商品について、completed の注文での販売数量の合計（売れていなければ 0）と、レビューの平均評価（小数第2位まで。レビューがなければ NULL）を取得せよ。
-- 出力: product_id, name, total_qty, avg_rating
-- ヒント: order_items と reviews を両方そのまま products に JOIN すると、行が掛け算で増えて数量が水増しされる。
-- 解説: 1対多の関係を2つ同時に JOIN すると行が膨らむ（ファンアウト）。それぞれ先に集計してから結合する。
SELECT p.product_id, p.name,
       COALESCE(s.total_qty, 0) AS total_qty,
       r.avg_rating
FROM products p
LEFT JOIN (
  SELECT oi.product_id, SUM(oi.quantity) AS total_qty
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status = 'completed'
  GROUP BY oi.product_id
) AS s ON s.product_id = p.product_id
LEFT JOIN (
  SELECT product_id, ROUND(AVG(rating), 2) AS avg_rating
  FROM reviews
  GROUP BY product_id
) AS r ON r.product_id = p.product_id;

-- [W04-D3-3] ★★★ ordered
-- 問: 月ごと（'YYYY-MM'）に、completed の注文の売上合計と、その月で最も金額の大きかった1注文の金額を求めよ。月の昇順。
-- 出力: ym, sales, max_order_total
-- ヒント: まず注文単位で合計を出し、それを月単位で集計する（2段階集計）。
SELECT ym, SUM(total) AS sales, MAX(total) AS max_order_total
FROM (
  SELECT o.order_id,
         strftime('%Y-%m', o.ordered_at) AS ym,
         SUM(oi.quantity * oi.unit_price) AS total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, ym
) AS t
GROUP BY ym
ORDER BY ym;

-- ## Day 3 定着: 派生テーブル（FROM 句のサブクエリ）

-- [W04-D3-R1] ★★
-- 問: 2025年の completed の注文について「注文1件ごとの金額」を出し、その平均（平均注文金額、整数に四捨五入）を求めよ。
-- 出力: avg_order_amount
-- 解説: orders と order_items を結合したまま AVG(quantity * unit_price) を取ると「明細1行あたり」の平均になってしまう。先に注文単位に集計してから平均する。
SELECT ROUND(AVG(amount)) AS avg_order_amount
FROM (
  SELECT o.order_id, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY o.order_id
) AS t;

-- [W04-D3-R2] ★★★
-- 問: 全顧客について、completed の注文回数（なければ 0）と、書いたレビューの件数（なければ 0）を取得せよ。
-- 出力: customer_id, name, order_cnt, review_cnt
-- ヒント: orders と reviews を両方そのまま customers に JOIN すると、注文数 × レビュー数 の行ができて件数が水増しされる。
SELECT c.customer_id, c.name,
       COALESCE(o.order_cnt, 0) AS order_cnt,
       COALESCE(r.review_cnt, 0) AS review_cnt
FROM customers c
LEFT JOIN (
  SELECT customer_id, COUNT(*) AS order_cnt
  FROM orders
  WHERE status = 'completed'
  GROUP BY customer_id
) AS o ON o.customer_id = c.customer_id
LEFT JOIN (
  SELECT customer_id, COUNT(*) AS review_cnt
  FROM reviews
  GROUP BY customer_id
) AS r ON r.customer_id = c.customer_id;

-- [W04-D3-R3] ★★★ ordered
-- 問: 支払方法ごとに、completed の注文の件数、売上合計、その支払方法で最も金額の大きかった1注文の金額を求めよ。売上合計の多い順。
-- 出力: payment_method, orders, sales, max_order_total
-- ヒント: まず注文単位で合計を出し、それを支払方法単位で集計する（2段階集計）。
SELECT payment_method, COUNT(*) AS orders, SUM(total) AS sales, MAX(total) AS max_order_total
FROM (
  SELECT o.order_id, o.payment_method,
         SUM(oi.quantity * oi.unit_price) AS total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.payment_method
) AS t
GROUP BY payment_method
ORDER BY sales DESC;

-- ## Day 4: 集合演算（UNION / INTERSECT / EXCEPT）

-- [W04-D4-1] ★★ ordered
-- 問: 顧客ID 1 の行動履歴を1つの時系列にまとめよ。会員登録を 'registered'、注文を 'ordered' というイベント種別で表し、日時の昇順に並べること。
-- 出力: event_type, event_at
-- 解説: UNION は重複排除のためにソート等が走る。重複があり得ない・消したくない場合は UNION ALL を使う。
SELECT 'registered' AS event_type, registered_at AS event_at
FROM customers
WHERE customer_id = 1
UNION ALL
SELECT 'ordered', ordered_at
FROM orders
WHERE customer_id = 1
ORDER BY event_at;

-- [W04-D4-2] ★★
-- 問: 2024年と2025年の両方で completed の注文がある顧客の ID を求めよ。
-- 出力: customer_id
SELECT customer_id FROM orders
WHERE status = 'completed' AND ordered_at >= '2024-01-01' AND ordered_at < '2025-01-01'
INTERSECT
SELECT customer_id FROM orders
WHERE status = 'completed' AND ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01';

-- [W04-D4-3] ★★
-- 問: 2025年の上半期（1〜6月）には completed の注文があるのに、下半期（7〜12月）には1件もない顧客の ID を求めよ。
-- 出力: customer_id
SELECT customer_id FROM orders
WHERE status = 'completed' AND ordered_at >= '2025-01-01' AND ordered_at < '2025-07-01'
EXCEPT
SELECT customer_id FROM orders
WHERE status = 'completed' AND ordered_at >= '2025-07-01' AND ordered_at < '2026-01-01';

-- ## Day 4 定着: 集合演算（UNION / INTERSECT / EXCEPT）

-- [W04-D4-R1] ★★ ordered
-- 問: 商品ID 2 の出来事を1つの時系列にまとめよ。発売を 'released'（日時は released_on）、レビュー投稿を 'reviewed'（日時は created_at）というイベント種別で表し、日時の昇順に並べること。
-- 出力: event_type, event_at
SELECT 'released' AS event_type, released_on AS event_at
FROM products
WHERE product_id = 2
UNION ALL
SELECT 'reviewed', created_at
FROM reviews
WHERE product_id = 2
ORDER BY event_at;

-- [W04-D4-R2] ★★
-- 問: レビューを書いたことがあり、かつアクセスログにログイン状態でのアクセス記録がある顧客の ID を求めよ。
-- 出力: customer_id
SELECT customer_id FROM reviews
INTERSECT
SELECT customer_id FROM access_logs;

-- [W04-D4-R3] ★★
-- 問: アクセスログにログイン状態でのアクセス記録がある顧客のうち、同じ期間（2025年10〜12月）に注文が1件もない（ステータスは問わない）顧客の ID を求めよ。
-- 出力: customer_id
-- ヒント: ゲストのアクセスは customer_id が NULL。
-- 解説: 集合演算は NULL も1つの値として扱う（orders 側に NULL はないので引かれない）。NULL を除かないと、結果に NULL の行が1行残ってしまう。
SELECT customer_id FROM access_logs
WHERE customer_id IS NOT NULL
EXCEPT
SELECT customer_id FROM orders
WHERE ordered_at >= '2025-10-01' AND ordered_at < '2026-01-01';

-- ## Day 5: 総合演習

-- [W04-D5-1] ★★★
-- 問: 商品ごとの平均評価が、全レビューの平均評価を上回っている商品を取得せよ。平均評価は小数第2位まで。
-- 出力: product_id, avg_rating
SELECT product_id, ROUND(AVG(rating), 2) AS avg_rating
FROM reviews
GROUP BY product_id
HAVING AVG(rating) > (SELECT AVG(rating) FROM reviews);

-- [W04-D5-2] ★★★
-- 問: 自分が所属する部署の平均年収よりも年収が高い社員を取得せよ（部署未配属の社員は対象外）。
-- 出力: name, department_id, salary
SELECT e.name, e.department_id, e.salary
FROM employees e
WHERE e.salary > (
        SELECT AVG(e2.salary)
        FROM employees e2
        WHERE e2.department_id = e.department_id
      );

-- [W04-D5-3] ★★★
-- 問: カテゴリID 8（コーヒー・お茶）に直接属する商品を「すべて」completed の注文で購入したことがある顧客の ID を求めよ。
-- 出力: customer_id
-- ヒント: 「買っていない対象商品が存在しない」顧客、と言い換える（NOT EXISTS の二重否定）。
-- 解説: 関係除算と呼ばれるパターン。「対象商品の種類数 = 購入した対象商品の種類数」を HAVING で比べる方法もある。
SELECT c.customer_id
FROM customers c
WHERE NOT EXISTS (
        SELECT 1
        FROM products p
        WHERE p.category_id = 8
          AND NOT EXISTS (
                SELECT 1
                FROM orders o
                JOIN order_items oi ON oi.order_id = o.order_id
                WHERE o.customer_id = c.customer_id
                  AND o.status = 'completed'
                  AND oi.product_id = p.product_id
              )
      );

-- ## Day 5 定着: 総合演習

-- [W04-D5-R1] ★★★
-- 問: 部署ごとの平均年収が、全社員（部署未配属の社員も含む）の平均年収を上回っている部署を取得せよ。平均年収は整数に四捨五入。
-- 出力: department_id, avg_salary
SELECT department_id, ROUND(AVG(salary)) AS avg_salary
FROM employees
WHERE department_id IS NOT NULL
GROUP BY department_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- [W04-D5-R2] ★★★
-- 問: 自分が直接属するカテゴリの商品の平均価格よりも、価格が高い商品を取得せよ。
-- 出力: product_id, name, category_id, price
SELECT p.product_id, p.name, p.category_id, p.price
FROM products p
WHERE p.price > (
        SELECT AVG(p2.price)
        FROM products p2
        WHERE p2.category_id = p.category_id
      );

-- [W04-D5-R3] ★★★
-- 問: 販売終了の商品（is_discontinued = 1）を「すべて」注文したことがある顧客の ID を求めよ（ステータスは問わない）。
-- 出力: customer_id
-- ヒント: 「注文していない販売終了商品が存在しない」顧客、と言い換える（NOT EXISTS の二重否定）。
SELECT c.customer_id
FROM customers c
WHERE NOT EXISTS (
        SELECT 1
        FROM products p
        WHERE p.is_discontinued = 1
          AND NOT EXISTS (
                SELECT 1
                FROM orders o
                JOIN order_items oi ON oi.order_id = o.order_id
                WHERE o.customer_id = c.customer_id
                  AND oi.product_id = p.product_id
              )
      );
