-- W10-D1-R3 ★★   Week 10: データ更新（DML）とテーブル定義（DDL） / Day 1 定着: INSERT
--
-- 【問題】
-- 1つの INSERT 文で、次の2人の社員を追加せよ。(41, '新井 翔', 部署 3, 上司 8, '一般社員', 年収 4,000,000, 入社日 2026-04-01) と (42, '上野 舞', 部署 5, 上司 11, '一般社員', 年収 3,800,000, 入社日 2026-04-01)。
--
-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）
--     SELECT employee_id, name, department_id, manager_id, job_title, salary, hired_on FROM employees WHERE employee_id > 40 ORDER BY employee_id
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W10-D1-R3

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
