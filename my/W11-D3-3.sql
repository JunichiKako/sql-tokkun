-- W11-D3-3 ★★★   Week 11: インデックス・実行計画・クエリの書き換え / Day 3: 遅い書き方を直す
--
-- 【問題】
-- 次のクエリは、2025年の日ごとの注文件数とその累計を自己結合で求めているため、日数の2乗に比例して遅くなる。ウィンドウ関数で書き直せ。日付の昇順。
-- WITH daily AS (
--   SELECT date(ordered_at) AS day, COUNT(*) AS cnt FROM orders
--   WHERE ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01' GROUP BY day
-- )
-- SELECT a.day, a.cnt, SUM(b.cnt) AS cumulative
-- FROM daily a JOIN daily b ON b.day <= a.day
-- GROUP BY a.day, a.cnt ORDER BY a.day;
--
-- 【出力列】 day, cnt, cumulative
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W11-D3-3

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
