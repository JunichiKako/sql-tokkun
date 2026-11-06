-- W01-D4-R2 ★★   Week 1: SELECT の基礎 / Day 4 定着: 式・関数・CASE 入門
--
-- 【問題】
-- 全社員を年収帯に分類せよ。500万円未満は 'C'、500万円以上800万円未満は 'B'、800万円以上は 'A'。
--
-- 【出力列】 employee_id, name, salary_band
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W01-D4-R2

-- ▼ ここに SQL を書く
SELECT employee_id,name,
       CASE WHEN salary < 5000000 THEN 'C'
       WHEN salary < 8000000 THEN 'B'
       ELSE 'A'
       END AS salary_band
FROM employees



-- ─── テーブル早見表 ───
-- 読み方: テーブル名(列名, 列名, ...)。このDBにある全テーブルと全列を並べてある
--
-- departments(department_id, name, location)
-- employees(employee_id, name, department_id, manager_id, job_title, salary, hired_on)
-- customers(customer_id, name, email, gender, birth_date, prefecture, registered_at, referrer_id)
-- categories(category_id, name, parent_id)
-- products(product_id, name, category_id, price, cost, released_on, is_discontinued)
-- orders(order_id, customer_id, ordered_at, status, payment_method, coupon_code, shipping_fee)
-- order_items(order_item_id, order_id, product_id, quantity, unit_price)
-- reviews(review_id, product_id, customer_id, rating, comment, created_at)
-- access_logs(log_id, customer_id, path, device, accessed_at)
--
-- 列の意味や実際のデータを見たいときは TABLES.md を開く:
--     Cmd + P →「TABLES」と入力して Enter → Cmd + K のあと V（プレビューを横に並べて表示）
