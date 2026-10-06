-- W01-D2-3 ★★   Week 1: SELECT の基礎 / Day 2: WHERE（比較・AND/OR・IN・BETWEEN）
--
-- 【問題】
-- 2025年に行われた注文のうち、キャンセルされておらず、支払方法が credit_card か e_money で、送料が 0 円のものを取得せよ。
--
-- 【出力列】 order_id, ordered_at, payment_method
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W01-D2-3

-- ▼ ここに SQL を書く
SELECT order_id, ordered_at, payment_method
FROM orders
WHERE ordered_at >= '2025-01-01' 
      AND ordered_at < '2026-01-01'
      AND status <> 'cancelled'
      AND payment_method IN ('credit_card', 'e_money')
      AND shipping_fee = 0





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
-- 日時の範囲は「以上・未満」で書くのが安全（BETWEEN だと 12/31 の日中が漏れやすい）。
