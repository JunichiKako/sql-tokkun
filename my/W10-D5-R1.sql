-- W10-D5-R1 ★★   Week 10: データ更新（DML）とテーブル定義（DDL） / Day 5 定着: トランザクションと総合演習
--
-- 【問題】
-- 新規顧客の登録と初回注文を、1つのトランザクションで行え。顧客: customer_id 201、氏名 '新井 太郎'、メール 'arai201@example.com'、性別 'M'、生年月日 NULL、'東京都'、登録日時 '2026-01-02 09:00:00'、紹介者 1。注文: order_id 9002、日時 '2026-01-02 10:00:00'、ステータス 'pending'、支払方法 'e_money'、クーポン 'WELCOME10'、送料 550。明細: 商品 55 を 3 個。単価は products テーブルの現在の price を使うこと（値を直書きしない）。
--
-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）
--     SELECT c.customer_id, c.referrer_id, o.order_id, o.coupon_code, oi.product_id, oi.quantity, oi.unit_price FROM customers c JOIN orders o ON o.customer_id = c.customer_id JOIN order_items oi ON oi.order_id = o.order_id WHERE c.customer_id = 201
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W10-D5-R1

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
