-- W09-D4-2 ★★★   Week 9: 再帰 CTE・欠損の補完・連続区間 / Day 4: 連続区間（gaps and islands）とセッション化
--
-- 【問題】
-- ログイン済み顧客のアクセスログをセッションに区切れ。同じ顧客の直前のアクセスから 30 分（1800 秒）以上空いたら新しいセッションとする。総セッション数と、1セッションあたりの平均ページビュー数（小数第2位まで）を求めよ。
--
-- 【出力列】 sessions, avg_pv
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W09-D4-2

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
-- LAG で直前のアクセス時刻を取り、「セッションの先頭かどうか」のフラグを立てる。フラグの合計がセッション数。秒数の差は strftime('%s', ...) で計算できる。
