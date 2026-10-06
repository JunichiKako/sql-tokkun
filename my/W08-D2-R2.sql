-- W08-D2-R2 ★★★   Week 8: ウィンドウ関数 (2) 前後の行・累計・フレーム / Day 2 定着: 累計と移動平均
--
-- 【問題】
-- 2025年11月の各日について、サイト全体のページビュー数（access_logs の行数。ゲストも含む）と、その日を含む直近7日間の移動平均（小数第1位まで）を求めよ。10月末の日も平均の計算には含めること。日付の昇順。（アクセスログは期間中アクセスのない日が存在しないので、行ベースのフレームで計算してよい）
--
-- 【出力列】 day, pv, ma7
-- 【並び順】 採点対象（ORDER BY が必要）
-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）
--     ターミナルから実行する場合: python3 tokkun.py --run W08-D2-R2

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
-- 先に11月で絞ってから移動平均を取ると、11月1日〜6日の平均に10月分が入らなくなる。
