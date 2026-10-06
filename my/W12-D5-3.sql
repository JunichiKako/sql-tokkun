-- W12-D5-3 ★★★   Week 12: 実務分析の総仕上げ / Day 5: 卒業試験
--
-- 【問題】
-- 離反の予兆がある顧客の抽出。completed の注文が 4 回以上ある顧客について、平均購入間隔（連続する注文同士の julianday の差の平均。小数第1位まで）と、最後の注文から基準日 2026-01-01 00:00:00 までの経過日数（julianday の差。小数点以下切り捨て）を求め、経過日数が平均購入間隔の 3 倍を超えている顧客を取得せよ。経過日数の長い順、同じなら customer_id 順。
--
-- 【出力列】 customer_id, orders, avg_interval, days_since_last
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W12-D5-3

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
