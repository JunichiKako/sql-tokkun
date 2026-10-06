-- # Week 3: JOIN

-- ## Day 1: INNER JOIN

-- [W03-D1-1] ★
-- 問: 全商品について、商品名と所属カテゴリ名を取得せよ。
-- 出力: product_id, product_name, category_name
SELECT p.product_id, p.name AS product_name, c.name AS category_name
FROM products p
JOIN categories c ON c.category_id = p.category_id;

-- [W03-D1-2] ★★
-- 問: 注文ID 100 の明細について、商品名・数量・単価・小計（数量 × 単価）を取得せよ。
-- 出力: name, quantity, unit_price, subtotal
SELECT p.name, oi.quantity, oi.unit_price, oi.quantity * oi.unit_price AS subtotal
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
WHERE oi.order_id = 100;

-- [W03-D1-3] ★★
-- 問: 2025年12月の completed の注文それぞれについて、顧客名と注文合計金額（明細の数量 × 単価 の合計）を取得せよ。
-- 出力: order_id, customer_name, total
SELECT o.order_id, c.name AS customer_name, SUM(oi.quantity * oi.unit_price) AS total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.ordered_at >= '2025-12-01' AND o.ordered_at < '2026-01-01'
GROUP BY o.order_id, c.name;

-- ## Day 1 定着: INNER JOIN

-- [W03-D1-R1] ★
-- 問: 部署に配属されている社員について、社員名と所属部署名を取得せよ。
-- 出力: employee_id, employee_name, department_name
SELECT e.employee_id, e.name AS employee_name, d.name AS department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id;

-- [W03-D1-R2] ★★
-- 問: 顧客ID 10 が書いたレビューについて、商品名・評価・コメント・投稿日時を取得せよ。
-- 出力: name, rating, comment, created_at
SELECT p.name, r.rating, r.comment, r.created_at
FROM reviews r
JOIN products p ON p.product_id = r.product_id
WHERE r.customer_id = 10;

-- [W03-D1-R3] ★★
-- 問: 2025年11月に東京都の顧客が行った completed の注文それぞれについて、顧客名と購入点数（明細の数量の合計）を取得せよ。
-- 出力: order_id, customer_name, total_qty
SELECT o.order_id, c.name AS customer_name, SUM(oi.quantity) AS total_qty
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND c.prefecture = '東京都'
  AND o.ordered_at >= '2025-11-01' AND o.ordered_at < '2025-12-01'
GROUP BY o.order_id, c.name;

-- ## Day 2: LEFT JOIN

-- [W03-D2-1] ★★
-- 問: 全顧客について注文回数（ステータスは問わない）を求めよ。一度も注文していない顧客は 0 と表示すること。
-- 出力: customer_id, name, order_cnt
-- ヒント: COUNT(*) だと注文0件の顧客も 1 になってしまう。
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_cnt
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;

-- [W03-D2-2] ★★
-- 問: 一度も注文されたことがない商品を取得せよ（ステータスは問わない）。
-- 出力: product_id, name
-- ヒント: LEFT JOIN して、相手側が NULL の行だけ残す（アンチジョイン）。
SELECT p.product_id, p.name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;

-- [W03-D2-3] ★★★
-- 問: 全顧客について、2025年の completed の注文回数を求めよ。該当する注文がない顧客も 0 として出すこと（結果は顧客数と同じ 200 行になる）。
-- 出力: customer_id, order_cnt
-- ヒント: 注文側の条件を WHERE に書くと、LEFT JOIN が実質 INNER JOIN になってしまう。
-- 解説: 外部結合で「相手側」の絞り込み条件は ON 句に書く。WHERE に書くと NULL 行（注文なしの顧客）が落ちる。
SELECT c.customer_id, COUNT(o.order_id) AS order_cnt
FROM customers c
LEFT JOIN orders o
       ON o.customer_id = c.customer_id
      AND o.status = 'completed'
      AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
GROUP BY c.customer_id;

-- ## Day 2 定着: LEFT JOIN

-- [W03-D2-R1] ★★
-- 問: 全商品についてレビュー件数を求めよ。レビューが1件もない商品は 0 と表示すること。
-- 出力: product_id, name, review_cnt
-- ヒント: 数えるのは reviews 側の列。
SELECT p.product_id, p.name, COUNT(r.review_id) AS review_cnt
FROM products p
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name;

-- [W03-D2-R2] ★★
-- 問: 一度も注文したことがない顧客を取得せよ（ステータスは問わない）。
-- 出力: customer_id, name
-- ヒント: LEFT JOIN して、相手側が NULL の行だけ残す（アンチジョイン）。
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- [W03-D2-R3] ★★★
-- 問: 全顧客について、2025年12月のアクセス件数（access_logs の行数）を求めよ。12月にアクセスしていない顧客も 0 として出すこと（結果は顧客数と同じ 200 行になる）。
-- 出力: customer_id, access_cnt
-- ヒント: アクセス日時の条件をどこに書くかで結果の行数が変わる。
-- 解説: 外部結合の相手側（access_logs）の条件を WHERE に書くと、12月にアクセスのない顧客の行（相手側が NULL）が落ちて INNER JOIN と同じになる。ON 句に書く。
SELECT c.customer_id, COUNT(a.log_id) AS access_cnt
FROM customers c
LEFT JOIN access_logs a
       ON a.customer_id = c.customer_id
      AND a.accessed_at >= '2025-12-01' AND a.accessed_at < '2026-01-01'
GROUP BY c.customer_id;

-- ## Day 3: 自己結合

-- [W03-D3-1] ★★
-- 問: 全社員について、本人の名前と上司の名前を取得せよ。上司がいない社員は上司名を NULL で出すこと。
-- 出力: employee_name, manager_name
SELECT e.name AS employee_name, m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.manager_id;

-- [W03-D3-2] ★★
-- 問: 上司よりも年収が高い社員を取得せよ。
-- 出力: employee_name, salary, manager_name, manager_salary
SELECT e.name AS employee_name, e.salary, m.name AS manager_name, m.salary AS manager_salary
FROM employees e
JOIN employees m ON m.employee_id = e.manager_id
WHERE e.salary > m.salary;

-- [W03-D3-3] ★★★
-- 問: 紹介者（referrer）と紹介された顧客が同じ都道府県に住んでいるペアを取得せよ。
-- 出力: referrer_name, customer_name, prefecture
SELECT r.name AS referrer_name, c.name AS customer_name, c.prefecture
FROM customers c
JOIN customers r ON r.customer_id = c.referrer_id
WHERE r.prefecture = c.prefecture;

-- ## Day 3 定着: 自己結合

-- [W03-D3-R1] ★★
-- 問: 全顧客について、本人の名前と紹介者の名前を取得せよ。紹介者がいない顧客は紹介者名を NULL で出すこと。
-- 出力: customer_name, referrer_name
SELECT c.name AS customer_name, r.name AS referrer_name
FROM customers c
LEFT JOIN customers r ON r.customer_id = c.referrer_id;

-- [W03-D3-R2] ★★
-- 問: 上司よりも入社日が早い社員を取得せよ。
-- 出力: employee_name, hired_on, manager_name, manager_hired_on
SELECT e.name AS employee_name, e.hired_on, m.name AS manager_name, m.hired_on AS manager_hired_on
FROM employees e
JOIN employees m ON m.employee_id = e.manager_id
WHERE e.hired_on < m.hired_on;

-- [W03-D3-R3] ★★★
-- 問: 上司と所属部署が異なる社員について、本人・本人の部署ID・上司・上司の部署ID を取得せよ。部署未配属（NULL）の社員は対象外とする。
-- 出力: employee_name, department_id, manager_name, manager_department_id
SELECT e.name AS employee_name, e.department_id, m.name AS manager_name, m.department_id AS manager_department_id
FROM employees e
JOIN employees m ON m.employee_id = e.manager_id
WHERE e.department_id <> m.department_id;

-- ## Day 4: 多テーブル結合と集計

-- [W03-D4-1] ★★ ordered
-- 問: カテゴリごとの売上（completed の注文の 数量 × 単価 の合計）を、売上の高い順に求めよ。商品が直接属しているカテゴリで集計すればよい。
-- 出力: category_name, sales
SELECT c.name AS category_name, SUM(oi.quantity * oi.unit_price) AS sales
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.status = 'completed'
GROUP BY c.category_id, c.name
ORDER BY sales DESC;

-- [W03-D4-2] ★★★
-- 問: 顧客の都道府県ごとに、completed の注文の売上合計と、購入した顧客の人数（同じ人は1人と数える）を求めよ。
-- 出力: prefecture, sales, buyers
SELECT c.prefecture,
       SUM(oi.quantity * oi.unit_price) AS sales,
       COUNT(DISTINCT c.customer_id) AS buyers
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY c.prefecture;

-- [W03-D4-3] ★★★ ordered
-- 問: 同じ注文の中で一緒に買われた商品のペアを数え、回数の多い上位5ペアを求めよ（ステータスは問わない）。ペアは product_id の小さい方を a、大きい方を b とし、回数の多い順、同数なら a, b の昇順に並べること。
-- 出力: product_a, product_b, cnt
-- ヒント: order_items を自己結合。`a.product_id < b.product_id` で (A,B) と (B,A) の二重カウントを防ぐ。
SELECT a.product_id AS product_a, b.product_id AS product_b, COUNT(*) AS cnt
FROM order_items a
JOIN order_items b
  ON b.order_id = a.order_id
 AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY cnt DESC, product_a, product_b
LIMIT 5;

-- ## Day 4 定着: 多テーブル結合と集計

-- [W03-D4-R1] ★★ ordered
-- 問: 商品ごとの売上（completed の注文の 数量 × 単価 の合計）を求め、売上の高い順（同額なら product_id 順）に上位5件を取得せよ。
-- 出力: product_name, sales
SELECT p.name AS product_name, SUM(oi.quantity * oi.unit_price) AS sales
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY p.product_id, p.name
ORDER BY sales DESC, p.product_id
LIMIT 5;

-- [W03-D4-R2] ★★★
-- 問: カテゴリごとに、completed の注文での販売数量の合計と、購入した顧客の人数（同じ人は1人と数える）を求めよ。商品が直接属しているカテゴリで集計すればよい。
-- 出力: category_name, total_qty, buyers
SELECT c.name AS category_name,
       SUM(oi.quantity) AS total_qty,
       COUNT(DISTINCT o.customer_id) AS buyers
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE o.status = 'completed'
GROUP BY c.category_id, c.name;

-- [W03-D4-R3] ★★★ ordered
-- 問: 同じ顧客がどちらもレビューしている商品のペアを数え、人数の多い上位5ペアを求めよ。ペアは product_id の小さい方を a、大きい方を b とし、人数の多い順、同数なら a, b の昇順に並べること。
-- 出力: product_a, product_b, cnt
-- ヒント: reviews を customer_id で自己結合。`a.product_id < b.product_id` で (A,B) と (B,A) の二重カウントを防ぐ。
SELECT a.product_id AS product_a, b.product_id AS product_b, COUNT(*) AS cnt
FROM reviews a
JOIN reviews b
  ON b.customer_id = a.customer_id
 AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY cnt DESC, product_a, product_b
LIMIT 5;

-- ## Day 5: 総合演習

-- [W03-D5-1] ★★
-- 問: 全部署について、部署名と所属社員数を求めよ。社員が1人もいない部署も 0 として出すこと。
-- 出力: department_name, cnt
SELECT d.name AS department_name, COUNT(e.employee_id) AS cnt
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id
GROUP BY d.department_id, d.name;

-- [W03-D5-2] ★★★
-- 問: completed の注文で購入された「顧客 × 商品」の組み合わせのうち、その顧客がその商品のレビューをまだ書いていない組み合わせは何組あるか。
-- 出力: cnt
-- ヒント: 同じ顧客が同じ商品を複数回買っていても1組と数える。DISTINCT した結果をサブクエリにして数える。
SELECT COUNT(*) AS cnt
FROM (
  SELECT DISTINCT o.customer_id, oi.product_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  LEFT JOIN reviews r
         ON r.customer_id = o.customer_id
        AND r.product_id = oi.product_id
  WHERE o.status = 'completed'
    AND r.review_id IS NULL
) AS unreviewed;

-- [W03-D5-3] ★★★
-- 問: 「上司の上司」がいる社員について、本人・上司・上司の上司の名前を取得せよ。
-- 出力: employee_name, manager_name, grand_manager_name
SELECT e.name AS employee_name, m.name AS manager_name, g.name AS grand_manager_name
FROM employees e
JOIN employees m ON m.employee_id = e.manager_id
JOIN employees g ON g.employee_id = m.manager_id;

-- ## Day 5 定着: 総合演習

-- [W03-D5-R1] ★★
-- 問: 全カテゴリについて、カテゴリ名と、そのカテゴリに直接属している商品の数を求めよ。商品が1つもないカテゴリも 0 として出すこと。
-- 出力: category_name, cnt
SELECT c.name AS category_name, COUNT(p.product_id) AS cnt
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.name;

-- [W03-D5-R2] ★★★
-- 問: completed の注文をしたことがある顧客のうち、レビューを1件も書いていない顧客は何人いるか。
-- 出力: cnt
-- ヒント: 同じ顧客の注文が何件あっても1人と数える。
SELECT COUNT(DISTINCT o.customer_id) AS cnt
FROM orders o
LEFT JOIN reviews r ON r.customer_id = o.customer_id
WHERE o.status = 'completed'
  AND r.review_id IS NULL;

-- [W03-D5-R3] ★★★
-- 問: 所属カテゴリに「親の親」カテゴリがある商品について、商品名・カテゴリ名・親カテゴリ名・親の親カテゴリ名を取得せよ。
-- 出力: product_name, category_name, parent_name, grand_parent_name
SELECT p.name AS product_name, c.name AS category_name, pc.name AS parent_name, gc.name AS grand_parent_name
FROM products p
JOIN categories c ON c.category_id = p.category_id
JOIN categories pc ON pc.category_id = c.parent_id
JOIN categories gc ON gc.category_id = pc.parent_id;
