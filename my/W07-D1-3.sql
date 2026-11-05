-- W07-D1-3 ★★★   Week 7: ウィンドウ関数 (1) 順位とパーティション / Day 1: ROW_NUMBER / RANK / DENSE_RANK
--
-- 【はじめて出てくる構文】 先に読んでから問題へ
--   ウィンドウ関数の結果での絞り込み … WHERE に直接は書けないので、CTE かサブクエリで包む
--       WITH ranked AS (
--         SELECT ..., DENSE_RANK() OVER (...) AS rnk FROM employees
--       )
--       SELECT ... FROM ranked WHERE rnk <= 2
--   ウィンドウ関数は WHERE より後に計算されるため、同じ SELECT の WHERE では使えない。
--
-- 【問題】
-- 各部署で年収が上位2位以内（DENSE_RANK で 2 以下。同額は同順位）の社員を取得せよ。部署未配属の社員は除く。
--
-- 【出力列】 department_id, name, salary
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W07-D1-3

-- ▼ ここに SQL を書く



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
