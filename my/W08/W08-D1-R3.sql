-- W08-D1-R3 ★★★   Week 8: ウィンドウ関数 (2) 前後の行・累計・フレーム / Day 1 定着: LAG / LEAD
--
-- 【問題】
-- 2025年の各四半期（'2025-Q1' の形式）について、completed 売上・前年同四半期の売上・前年同四半期比の伸び率（百分率、小数第1位まで）を求めよ。四半期の昇順。
--
-- 【出力列】 yq, sales, last_year_sales, yoy
-- 【並び順】 採点対象（ORDER BY が必要）
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W08-D1-R3

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












-- ─── ヒント ───
-- 四半期の番号は (CAST(strftime('%m', ordered_at) AS INTEGER) + 2) / 3。8四半期が欠けなく揃っているので LAG(sales, 4) が使える。2025年で先に絞ると前年の値が取れない。
