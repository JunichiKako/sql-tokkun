-- W12-D5-2 ★★★   Week 12: 実務分析の総仕上げ / Day 5: 卒業試験
--
-- 【問題】
-- 商品ポートフォリオ。completed の注文について、商品ごとの売上、粗利（数量 ×（購入時単価 − 現在の原価）の合計）、粗利率（粗利 ÷ 売上 の百分率、小数第1位まで）、平均評価（小数第2位まで。レビューがなければ NULL）を求め、粗利の大きい上位10商品を取得せよ。粗利の大きい順、同額なら product_id 順。
--
-- 【出力列】 product_id, name, sales, gross_profit, margin_rate, avg_rating
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W12-D5-2

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
