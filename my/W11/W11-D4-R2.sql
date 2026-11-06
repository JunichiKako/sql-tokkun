-- W11-D4-R2 ★★★   Week 11: インデックス・実行計画・クエリの書き換え / Day 4 定着: よくある落とし穴
--
-- 【問題】
-- 全商品の「注文明細の行数」と「レビュー数」を出すつもりの次のクエリは、数字が実際より大きくなる。正しい結果を返すクエリに直せ（どちらも 0 件の商品は 0 と出す）。
-- SELECT p.product_id, COUNT(oi.order_item_id) AS item_cnt, COUNT(r.review_id) AS review_cnt
-- FROM products p
-- LEFT JOIN order_items oi ON oi.product_id = p.product_id
-- LEFT JOIN reviews r ON r.product_id = p.product_id
-- GROUP BY p.product_id;
--
-- 【出力列】 product_id, item_cnt, review_cnt
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W11-D4-R2

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
