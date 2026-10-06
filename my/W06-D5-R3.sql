-- W06-D5-R3 ★★★   Week 6: CTE（WITH 句）と多段集計 / Day 5 定着: 中間テスト
--
-- 【問題】
-- カテゴリ（商品が直接属するカテゴリ）ごとに「そのカテゴリの商品を含む注文の数」と、そのうち cancelled の割合（百分率、小数第1位まで）を求め、注文数が 100 以上のカテゴリの中でキャンセル率が高い上位3つを取得せよ。1つの注文に同じカテゴリの商品が複数あっても1と数える。キャンセル率の高い順、同率なら category_id 順。
--
-- 【出力列】 category_id, name, order_cnt, cancel_rate
-- 【並び順】 採点対象（ORDER BY が必要）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W06-D5-R3

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
