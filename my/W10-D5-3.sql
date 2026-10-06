-- W10-D5-3 ★★★   Week 10: データ更新（DML）とテーブル定義（DDL） / Day 5: トランザクションと総合演習
--
-- 【問題】
-- 価格改定の履歴テーブル price_history（product_id, old_price, new_price, changed_at）を作成し、カテゴリID 19（コーヒー豆）の全商品を 100 円値上げせよ。値上げと同時に、変更前後の価格を changed_at = '2026-01-01' で履歴に記録すること。履歴の記録と値上げは1つのトランザクションで行う。
--
-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）
--     SELECT p.product_id, p.price, h.old_price, h.new_price, h.changed_at FROM products p JOIN price_history h ON h.product_id = p.product_id ORDER BY p.product_id
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W10-D5-3

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
-- 先に UPDATE してしまうと変更前の価格が分からなくなる。順番に注意。
