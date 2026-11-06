-- W03-D4-R3 ★★★   Week 3: JOIN / Day 4 定着: 多テーブル結合と集計
--
-- 【問題】
-- 同じ顧客がどちらもレビューしている商品のペアを数え、人数の多い上位5ペアを求めよ。ペアは product_id の小さい方を a、大きい方を b とし、人数の多い順、同数なら a, b の昇順に並べること。
--
-- 【出力列】 product_a, product_b, cnt
-- 【並び順】 採点対象（ORDER BY が必要）
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W03-D4-R3

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
-- reviews を customer_id で自己結合。`a.product_id < b.product_id` で (A,B) と (B,A) の二重カウントを防ぐ。
