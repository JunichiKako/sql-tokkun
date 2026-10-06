-- W10-D3-R3 ★★★   Week 10: データ更新（DML）とテーブル定義（DDL） / Day 3 定着: DELETE と UPSERT
--
-- 【問題】
-- テーブル daily_visits（day: 文字列・主キー、visits: 整数・NOT NULL）を作成し、初期データとして ('2025-12-01', 10) を登録せよ。続けて、('2025-12-01', 4) と ('2025-12-02', 6) を「すでに行があれば visits に加算、なければ新規登録」する1つの文で反映せよ。
--
-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）
--     SELECT day, visits FROM daily_visits ORDER BY day
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W10-D3-R3

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
