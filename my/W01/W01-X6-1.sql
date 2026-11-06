-- W01-X6-1 ★★★   Week 1 復習: SELECT の基礎（総復習） / 復習 Day 6: 組み合わせ問題
--
-- 【問題】
-- 社員の月給（年収 ÷ 12 を四捨五入した整数）が 50万円以上の社員を、月給の高い順（同額なら employee_id 順）に上位5人取得せよ。月給の判定も、四捨五入した整数で行うこと。
--
-- 【出力列】 name, monthly
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W01-X6-1

-- ▼ ここに SQL を書く
SELECT name, CAST(ROUND(salary / 12.0)AS INTEGER) AS monthly
FROM employees
WHERE ROUND(salary / 12.0) >= 500000
ORDER BY monthly DESC, employee_id
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
