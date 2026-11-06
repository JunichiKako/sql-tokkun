-- W01-X5-3 ★★★   Week 1 復習: SELECT の基礎（総復習） / 復習 Day 5: 条件の組み立て・日付の範囲・CASE と LIKE
--
-- 【問題】
-- 2025年12月31日のアクセスログ（ゲストも含む）について、ページの種類を求めよ。path が '/' なら 'トップ'、'/products' なら '一覧'、'/products/' で始まるもの（商品詳細）なら '商品詳細'、それ以外（'/cart'・'/checkout'・'/complete'）は '購入フロー'。
--
-- 【出力列】 log_id, path, page_type
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W01-X5-3

-- ▼ ここに SQL を書く
SELECT log_id, path,
        CASE WHEN path = '/' THEN 'トップ'
        WHEN path = '/products' THEN '一覧'
        WHEN path LIKE '/products/%' THEN '商品詳細'
        ELSE '購入フロー'
        END AS page_type
FROM access_logs
WHERE accessed_at >= '2025-12-31'
  AND accessed_at <  '2026-01-01'





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
-- CASE の WHEN にも LIKE が書ける。'/products' と '/products/...' の判定の順番に注意。
