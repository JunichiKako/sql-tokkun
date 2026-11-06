-- W12-D3-1 ★★★   Week 12: 実務分析の総仕上げ / Day 3: 行動ログ分析
--
-- 【問題】
-- ファネル分析。ログイン済み顧客のアクセスログを、W09-D4-2 と同じルール（直前のアクセスから 1800 秒以上空いたら新セッション）でセッションに区切り、総セッション数と、各ステップのページを1回以上見たセッションの数を1行で出せ。ステップは top（'/'）、list（'/products'）、detail（'/products/...' の商品詳細）、cart（'/cart'）、checkout（'/checkout'）、complete（'/complete'）。
--
-- 【出力列】 sessions, top, list, detail, cart, checkout, complete
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W12-D3-1

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
-- 「新セッションの先頭フラグ」の累計を取ると、顧客内のセッション番号になる。
