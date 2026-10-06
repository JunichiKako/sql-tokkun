-- W01-D1-3 ★★   Week 1: SELECT の基礎 / Day 1: 列の選択・並び替え・件数制限
--
-- 【問題】
-- 商品ごとに粗利（price - cost）と粗利率（粗利 ÷ price の百分率、小数第1位まで）を計算し、粗利率の高い順（同率なら product_id 順）に上位5件を取得せよ。
--
-- 【出力列】 name, price, cost, margin, margin_rate
-- 【並び順】 採点対象（ORDER BY が必要）
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W01-D1-3

-- ▼ ここに SQL を書く
SELECT name, price, cost,
       price - cost AS margin,
       ROUND((price - cost) * 100.0 / price, 1 ) AS margin_rate
FROM products
ORDER BY margin_rate DESC,product_id
LIMIT 5



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
-- 整数同士の割り算は切り捨てられる。`* 100.0` のように実数を混ぜる。
