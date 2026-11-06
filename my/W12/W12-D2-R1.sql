-- W12-D2-R1 ★★★   Week 12: 実務分析の総仕上げ / Day 2 定着: 顧客分析
--
-- 【問題】
-- 2025年の completed の注文だけで RFM 分析をせよ。対象は 2025年に completed の注文がある顧客。R（基準日 2026-01-01 から最終購入日までの経過日数。日付単位）、F（注文回数）、M（購入総額）を求め、それぞれ NTILE(4) で 1〜4 のスコアを付ける（R は経過日数の降順、F・M は値の昇順に並べて NTILE を付ける。同値は customer_id の昇順）。3スコアの合計が 11 以上の顧客を、合計の高い順（同点なら customer_id 順）に取得せよ。
--
-- 【出力列】 customer_id, recency, frequency, monetary, rfm_total
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W12-D2-R1

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
