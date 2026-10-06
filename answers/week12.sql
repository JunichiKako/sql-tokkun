-- # Week 12: 実務分析の総仕上げ

-- ## Day 1: 売上分析

-- [W12-D1-1] ★★★ ordered
-- 問: 2025年の各月（'YYYY-MM'）について、completed 売上・前年同月比の伸び率（百分率、小数第1位まで）・2025年の年初からの累計売上を求めよ。月の昇順。
-- 出力: ym, sales, yoy, ytd
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY ym
),
with_last_year AS (
  SELECT ym, sales, LAG(sales, 12) OVER (ORDER BY ym) AS last_year_sales
  FROM monthly
)
SELECT ym, sales,
       ROUND((sales - last_year_sales) * 100.0 / last_year_sales, 1) AS yoy,
       SUM(sales) OVER (ORDER BY ym) AS ytd
FROM with_last_year
WHERE ym >= '2025-01'
ORDER BY ym;

-- [W12-D1-2] ★★★
-- 問: 顧客の都道府県ごとに、completed 売上が最も大きい最上位カテゴリ（家電・食品・ファッション・書籍のいずれか）とその売上を求めよ（同額ならカテゴリ名の昇順で先に来る方）。
-- 出力: prefecture, top_category, sales
WITH RECURSIVE tree(category_id, top_category) AS (
  SELECT category_id, name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, t.top_category
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
),
pref_sales AS (
  SELECT cu.prefecture, t.top_category, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN customers cu ON cu.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  JOIN tree t ON t.category_id = p.category_id
  WHERE o.status = 'completed'
  GROUP BY cu.prefecture, t.top_category
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY prefecture ORDER BY sales DESC, top_category) AS rn
  FROM pref_sales
)
SELECT prefecture, top_category, sales
FROM ranked
WHERE rn = 1;

-- [W12-D1-3] ★★★ ordered
-- 問: カテゴリID 19（コーヒー豆）の商品を含む注文（ステータスは問わない）で、一緒に買われることが多い「他のカテゴリ」（商品が直接属するカテゴリ）の上位3つを求めよ。数えるのは注文数（1つの注文に同じカテゴリの商品が複数あっても1と数える）。注文数の多い順、同数なら category_id 順。
-- 出力: category_name, orders
WITH coffee_orders AS (
  SELECT DISTINCT oi.order_id
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  WHERE p.category_id = 19
)
SELECT c.name AS category_name, COUNT(DISTINCT oi.order_id) AS orders
FROM coffee_orders co
JOIN order_items oi ON oi.order_id = co.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE p.category_id <> 19
GROUP BY c.category_id, c.name
ORDER BY orders DESC, c.category_id
LIMIT 3;

-- ## Day 1 定着: 売上分析

-- [W12-D1-R1] ★★★ ordered
-- 問: 2025年の各月（'YYYY-MM'）について、completed の注文件数・前年同月比の伸び率（百分率、小数第1位まで）・2025年の年初からの累計件数を求めよ。月の昇順。
-- 出力: ym, orders, yoy, ytd_orders
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS orders
  FROM orders
  WHERE status = 'completed'
  GROUP BY ym
),
with_last_year AS (
  SELECT ym, orders, LAG(orders, 12) OVER (ORDER BY ym) AS last_year_orders
  FROM monthly
)
SELECT ym, orders,
       ROUND((orders - last_year_orders) * 100.0 / last_year_orders, 1) AS yoy,
       SUM(orders) OVER (ORDER BY ym) AS ytd_orders
FROM with_last_year
WHERE ym >= '2025-01'
ORDER BY ym;

-- [W12-D1-R2] ★★★
-- 問: 顧客の年代（2026年1月1日時点の満年齢で '20代'・'30代' …。生年月日が NULL の顧客は除く）ごとに、completed 売上が最も大きい最上位カテゴリ（家電・食品・ファッション・書籍のいずれか）とその売上を求めよ（同額ならカテゴリ名の昇順で先に来る方）。
-- 出力: age_group, top_category, sales
WITH RECURSIVE tree(category_id, top_category) AS (
  SELECT category_id, name
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.category_id, t.top_category
  FROM categories c
  JOIN tree t ON t.category_id = c.parent_id
),
age_sales AS (
  SELECT ((20260101 - CAST(strftime('%Y%m%d', cu.birth_date) AS INTEGER)) / 10000 / 10 * 10) || '代' AS age_group,
         t.top_category,
         SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN customers cu ON cu.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  JOIN tree t ON t.category_id = p.category_id
  WHERE o.status = 'completed'
    AND cu.birth_date IS NOT NULL
  GROUP BY age_group, t.top_category
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY age_group ORDER BY sales DESC, top_category) AS rn
  FROM age_sales
)
SELECT age_group, top_category, sales
FROM ranked
WHERE rn = 1;

-- [W12-D1-R3] ★★★ ordered
-- 問: カテゴリID 20（日本茶）の商品を含む注文（ステータスは問わない）で、一緒に買われることが多い「日本茶以外の商品」の上位3つを求めよ。数えるのは注文数。注文数の多い順、同数なら product_id 順。
-- 出力: product_id, name, orders
WITH tea_orders AS (
  SELECT DISTINCT oi.order_id
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  WHERE p.category_id = 20
)
SELECT p.product_id, p.name, COUNT(DISTINCT oi.order_id) AS orders
FROM tea_orders t
JOIN order_items oi ON oi.order_id = t.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE p.category_id <> 20
GROUP BY p.product_id, p.name
ORDER BY orders DESC, p.product_id
LIMIT 3;

-- ## Day 2: 顧客分析

-- [W12-D2-1] ★★★ ordered
-- 問: RFM分析。completed の注文がある顧客について、基準日 2026-01-01 時点の R（最終購入日からの経過日数。日付単位）、F（注文回数）、M（購入総額）を求め、それぞれ NTILE(5) で 1〜5 のスコアを付けよ。R は経過日数が短いほど高スコア、F・M は大きいほど高スコア（つまり R は経過日数の降順、F・M は値の昇順に並べて NTILE を付ける。同値は customer_id の昇順）。3スコアの合計が 13 以上の顧客を、合計の高い順（同点なら customer_id 順）に取得せよ。
-- 出力: customer_id, recency, frequency, monetary, rfm_total
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.ordered_at, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id, o.ordered_at
),
rfm AS (
  SELECT customer_id,
         CAST(julianday('2026-01-01') - julianday(date(MAX(ordered_at))) AS INTEGER) AS recency,
         COUNT(*) AS frequency,
         SUM(amount) AS monetary
  FROM order_totals
  GROUP BY customer_id
),
scored AS (
  SELECT *,
         NTILE(5) OVER (ORDER BY recency DESC, customer_id) AS r,
         NTILE(5) OVER (ORDER BY frequency, customer_id) AS f,
         NTILE(5) OVER (ORDER BY monetary, customer_id) AS m
  FROM rfm
)
SELECT customer_id, recency, frequency, monetary, r + f + m AS rfm_total
FROM scored
WHERE r + f + m >= 13
ORDER BY rfm_total DESC, customer_id;

-- [W12-D2-2] ★★★ ordered
-- 問: 初回の completed 注文が 2025年1月〜6月だった顧客を、初回購入月（'YYYY-MM'）でコホートに分け、コホートごとの顧客数、初回購入から 90 日以内（julianday の差が 90 以下）に2回目の completed 注文をした顧客数、その割合（百分率、小数第1位まで）を求めよ。月の昇順。
-- 出力: cohort, customers, repeaters, repeat_rate
WITH numbered AS (
  SELECT customer_id, ordered_at,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS seq
  FROM orders
  WHERE status = 'completed'
),
first_second AS (
  SELECT a.customer_id, a.ordered_at AS first_at, b.ordered_at AS second_at
  FROM numbered a
  LEFT JOIN numbered b ON b.customer_id = a.customer_id AND b.seq = 2
  WHERE a.seq = 1
)
SELECT strftime('%Y-%m', first_at) AS cohort,
       COUNT(*) AS customers,
       SUM(CASE WHEN julianday(second_at) - julianday(first_at) <= 90 THEN 1 ELSE 0 END) AS repeaters,
       ROUND(SUM(CASE WHEN julianday(second_at) - julianday(first_at) <= 90 THEN 1 ELSE 0 END) * 100.0
             / COUNT(*), 1) AS repeat_rate
FROM first_second
WHERE first_at >= '2025-01-01' AND first_at < '2025-07-01'
GROUP BY cohort
ORDER BY cohort;

-- [W12-D2-3] ★★★ ordered
-- 問: コホート残存分析。初回の completed 注文が 2025年1月〜3月だった顧客について、初回購入月（cohort）と、初回購入月からの経過月数（month_offset。初回月を 0）ごとに、その月に completed の注文をした顧客数を求めよ。経過月数は 0〜5 まで。該当者がいない組み合わせは出さなくてよい。cohort, month_offset の昇順。
-- 出力: cohort, month_offset, buyers
-- ヒント: 月の差は (年 × 12 + 月) 同士の引き算で求められる。
WITH first_orders AS (
  SELECT customer_id, MIN(ordered_at) AS first_at
  FROM orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
activity AS (
  SELECT DISTINCT o.customer_id,
         strftime('%Y-%m', f.first_at) AS cohort,
         (CAST(strftime('%Y', o.ordered_at) AS INTEGER) * 12 + CAST(strftime('%m', o.ordered_at) AS INTEGER))
         - (CAST(strftime('%Y', f.first_at) AS INTEGER) * 12 + CAST(strftime('%m', f.first_at) AS INTEGER)) AS month_offset
  FROM orders o
  JOIN first_orders f ON f.customer_id = o.customer_id
  WHERE o.status = 'completed'
)
SELECT cohort, month_offset, COUNT(*) AS buyers
FROM activity
WHERE cohort BETWEEN '2025-01' AND '2025-03'
  AND month_offset BETWEEN 0 AND 5
GROUP BY cohort, month_offset
ORDER BY cohort, month_offset;

-- ## Day 2 定着: 顧客分析

-- [W12-D2-R1] ★★★ ordered
-- 問: 2025年の completed の注文だけで RFM 分析をせよ。対象は 2025年に completed の注文がある顧客。R（基準日 2026-01-01 から最終購入日までの経過日数。日付単位）、F（注文回数）、M（購入総額）を求め、それぞれ NTILE(4) で 1〜4 のスコアを付ける（R は経過日数の降順、F・M は値の昇順に並べて NTILE を付ける。同値は customer_id の昇順）。3スコアの合計が 11 以上の顧客を、合計の高い順（同点なら customer_id 順）に取得せよ。
-- 出力: customer_id, recency, frequency, monetary, rfm_total
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.ordered_at, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY o.order_id, o.customer_id, o.ordered_at
),
rfm AS (
  SELECT customer_id,
         CAST(julianday('2026-01-01') - julianday(date(MAX(ordered_at))) AS INTEGER) AS recency,
         COUNT(*) AS frequency,
         SUM(amount) AS monetary
  FROM order_totals
  GROUP BY customer_id
),
scored AS (
  SELECT *,
         NTILE(4) OVER (ORDER BY recency DESC, customer_id) AS r,
         NTILE(4) OVER (ORDER BY frequency, customer_id) AS f,
         NTILE(4) OVER (ORDER BY monetary, customer_id) AS m
  FROM rfm
)
SELECT customer_id, recency, frequency, monetary, r + f + m AS rfm_total
FROM scored
WHERE r + f + m >= 11
ORDER BY rfm_total DESC, customer_id;

-- [W12-D2-R2] ★★★ ordered
-- 問: 初回の completed 注文が 2024年だった顧客を、初回購入の四半期（'2024-Q1' 〜 '2024-Q4'）でコホートに分け、コホートごとの顧客数、初回購入から 180 日以内（julianday の差が 180 以下）に2回目の completed 注文をした顧客数、その割合（百分率、小数第1位まで）を求めよ。四半期の昇順。
-- 出力: cohort, customers, repeaters, repeat_rate
-- ヒント: 四半期の番号は (月 + 2) / 3（整数の割り算）で求められる。
WITH numbered AS (
  SELECT customer_id, ordered_at,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS seq
  FROM orders
  WHERE status = 'completed'
),
first_second AS (
  SELECT a.customer_id, a.ordered_at AS first_at, b.ordered_at AS second_at
  FROM numbered a
  LEFT JOIN numbered b ON b.customer_id = a.customer_id AND b.seq = 2
  WHERE a.seq = 1
)
SELECT strftime('%Y', first_at) || '-Q' || ((CAST(strftime('%m', first_at) AS INTEGER) + 2) / 3) AS cohort,
       COUNT(*) AS customers,
       SUM(CASE WHEN julianday(second_at) - julianday(first_at) <= 180 THEN 1 ELSE 0 END) AS repeaters,
       ROUND(SUM(CASE WHEN julianday(second_at) - julianday(first_at) <= 180 THEN 1 ELSE 0 END) * 100.0
             / COUNT(*), 1) AS repeat_rate
FROM first_second
WHERE first_at >= '2024-01-01' AND first_at < '2025-01-01'
GROUP BY cohort
ORDER BY cohort;

-- [W12-D2-R3] ★★★ ordered
-- 問: 会員登録月（cohort）が 2025年1月〜3月の顧客について、登録月からの経過月数（month_offset。登録月を 0）ごとに、その月に completed の注文をした顧客数を求めよ。経過月数は 0〜5 まで。該当者がいない組み合わせは出さなくてよい。cohort, month_offset の昇順。
-- 出力: cohort, month_offset, buyers
WITH activity AS (
  SELECT DISTINCT o.customer_id,
         strftime('%Y-%m', c.registered_at) AS cohort,
         (CAST(strftime('%Y', o.ordered_at) AS INTEGER) * 12 + CAST(strftime('%m', o.ordered_at) AS INTEGER))
         - (CAST(strftime('%Y', c.registered_at) AS INTEGER) * 12 + CAST(strftime('%m', c.registered_at) AS INTEGER)) AS month_offset
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.status = 'completed'
)
SELECT cohort, month_offset, COUNT(*) AS buyers
FROM activity
WHERE cohort BETWEEN '2025-01' AND '2025-03'
  AND month_offset BETWEEN 0 AND 5
GROUP BY cohort, month_offset
ORDER BY cohort, month_offset;

-- ## Day 3: 行動ログ分析

-- [W12-D3-1] ★★★
-- 問: ファネル分析。ログイン済み顧客のアクセスログを、W09-D4-2 と同じルール（直前のアクセスから 1800 秒以上空いたら新セッション）でセッションに区切り、総セッション数と、各ステップのページを1回以上見たセッションの数を1行で出せ。ステップは top（'/'）、list（'/products'）、detail（'/products/...' の商品詳細）、cart（'/cart'）、checkout（'/checkout'）、complete（'/complete'）。
-- 出力: sessions, top, list, detail, cart, checkout, complete
-- ヒント: 「新セッションの先頭フラグ」の累計を取ると、顧客内のセッション番号になる。
WITH lagged AS (
  SELECT customer_id, path, device, accessed_at, log_id,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
sessionized AS (
  SELECT customer_id, path,
         SUM(CASE WHEN prev_at IS NULL
                    OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
                  THEN 1 ELSE 0 END)
           OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS session_no
  FROM lagged
),
session_steps AS (
  SELECT customer_id, session_no,
         MAX(CASE WHEN path = '/' THEN 1 ELSE 0 END) AS top,
         MAX(CASE WHEN path = '/products' THEN 1 ELSE 0 END) AS list,
         MAX(CASE WHEN path LIKE '/products/%' THEN 1 ELSE 0 END) AS detail,
         MAX(CASE WHEN path = '/cart' THEN 1 ELSE 0 END) AS cart,
         MAX(CASE WHEN path = '/checkout' THEN 1 ELSE 0 END) AS checkout,
         MAX(CASE WHEN path = '/complete' THEN 1 ELSE 0 END) AS complete
  FROM sessionized
  GROUP BY customer_id, session_no
)
SELECT COUNT(*) AS sessions,
       SUM(top) AS top, SUM(list) AS list, SUM(detail) AS detail,
       SUM(cart) AS cart, SUM(checkout) AS checkout, SUM(complete) AS complete
FROM session_steps;

-- [W12-D3-2] ★★★
-- 問: 前問と同じセッション定義で、デバイスごとのセッション数、'/complete' に到達したセッション数、コンバージョン率（百分率、小数第1位まで）を求めよ。セッションのデバイスは、そのセッションの最初のアクセスのデバイスとする。
-- 出力: device, sessions, cv_sessions, cvr
WITH lagged AS (
  SELECT customer_id, path, device, accessed_at, log_id,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
sessionized AS (
  SELECT customer_id, path, device, accessed_at, log_id,
         SUM(CASE WHEN prev_at IS NULL
                    OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
                  THEN 1 ELSE 0 END)
           OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS session_no
  FROM lagged
),
with_first_device AS (
  SELECT customer_id, session_no, path,
         FIRST_VALUE(device) OVER (PARTITION BY customer_id, session_no ORDER BY accessed_at, log_id) AS session_device
  FROM sessionized
),
sessions AS (
  SELECT customer_id, session_no, session_device AS device,
         MAX(CASE WHEN path = '/complete' THEN 1 ELSE 0 END) AS converted
  FROM with_first_device
  GROUP BY customer_id, session_no, session_device
)
SELECT device,
       COUNT(*) AS sessions,
       SUM(converted) AS cv_sessions,
       ROUND(SUM(converted) * 100.0 / COUNT(*), 1) AS cvr
FROM sessions
GROUP BY device;

-- [W12-D3-3] ★★★ ordered
-- 問: アクセスログ（ゲストも含む）から商品詳細ページ（'/products/{product_id}'）の閲覧数が多い商品の上位5件を求め、同じ期間（2025年10月1日〜12月31日）の completed の販売数量（なければ 0）を並べよ。閲覧数の多い順、同数なら product_id 順。
-- 出力: product_id, name, views, qty
-- ヒント: '/products/' は10文字なので、substr(path, 11) が product_id の部分。
WITH views AS (
  SELECT CAST(substr(path, 11) AS INTEGER) AS product_id, COUNT(*) AS views
  FROM access_logs
  WHERE path LIKE '/products/%'
  GROUP BY product_id
),
sold AS (
  SELECT oi.product_id, SUM(oi.quantity) AS qty
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-10-01' AND o.ordered_at < '2026-01-01'
  GROUP BY oi.product_id
)
SELECT p.product_id, p.name, v.views, COALESCE(s.qty, 0) AS qty
FROM views v
JOIN products p ON p.product_id = v.product_id
LEFT JOIN sold s ON s.product_id = v.product_id
ORDER BY v.views DESC, p.product_id
LIMIT 5;

-- ## Day 3 定着: 行動ログ分析

-- [W12-D3-R1] ★★★
-- 問: ログイン済み顧客のアクセスログを W09-D4-2 と同じルール（直前のアクセスから 1800 秒以上空いたら新セッション）でセッションに区切り、デバイスごとに、セッション数・'/cart' を1回以上見たセッション数・'/complete' を1回以上見たセッション数を求めよ。セッションのデバイスは、そのセッションの最初のアクセスのデバイスとする。
-- 出力: device, sessions, cart_sessions, complete_sessions
WITH lagged AS (
  SELECT customer_id, path, device, accessed_at, log_id,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
sessionized AS (
  SELECT customer_id, path, device, accessed_at, log_id,
         SUM(CASE WHEN prev_at IS NULL
                    OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
                  THEN 1 ELSE 0 END)
           OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS session_no
  FROM lagged
),
with_first_device AS (
  SELECT customer_id, session_no, path,
         FIRST_VALUE(device) OVER (PARTITION BY customer_id, session_no ORDER BY accessed_at, log_id) AS session_device
  FROM sessionized
),
sessions AS (
  SELECT customer_id, session_no, session_device AS device,
         MAX(CASE WHEN path = '/cart' THEN 1 ELSE 0 END) AS cart,
         MAX(CASE WHEN path = '/complete' THEN 1 ELSE 0 END) AS complete
  FROM with_first_device
  GROUP BY customer_id, session_no, session_device
)
SELECT device,
       COUNT(*) AS sessions,
       SUM(cart) AS cart_sessions,
       SUM(complete) AS complete_sessions
FROM sessions
GROUP BY device;

-- [W12-D3-R2] ★★★ ordered
-- 問: 前問と同じセッション定義で、セッションの開始時刻の「時」（0〜23 の整数）ごとに、セッション数と '/complete' に到達したセッションの割合（百分率、小数第1位まで）を求めよ。セッションが1つもない時間帯は出さなくてよい。時の昇順。
-- 出力: hour, sessions, cvr
WITH lagged AS (
  SELECT customer_id, path, accessed_at, log_id,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
sessionized AS (
  SELECT customer_id, path, accessed_at,
         SUM(CASE WHEN prev_at IS NULL
                    OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
                  THEN 1 ELSE 0 END)
           OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS session_no
  FROM lagged
),
sessions AS (
  SELECT customer_id, session_no,
         CAST(strftime('%H', MIN(accessed_at)) AS INTEGER) AS hour,
         MAX(CASE WHEN path = '/complete' THEN 1 ELSE 0 END) AS converted
  FROM sessionized
  GROUP BY customer_id, session_no
)
SELECT hour,
       COUNT(*) AS sessions,
       ROUND(SUM(converted) * 100.0 / COUNT(*), 1) AS cvr
FROM sessions
GROUP BY hour
ORDER BY hour;

-- [W12-D3-R3] ★★★ ordered
-- 問: 前問と同じセッション定義で、「'/cart' まで進んだのに '/complete' に到達しなかったセッション」（カゴ落ち）の数が多い顧客の上位5人を求めよ。セッション数の多い順、同数なら customer_id 順。
-- 出力: customer_id, abandoned
WITH lagged AS (
  SELECT customer_id, path, accessed_at, log_id,
         LAG(accessed_at) OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS prev_at
  FROM access_logs
  WHERE customer_id IS NOT NULL
),
sessionized AS (
  SELECT customer_id, path,
         SUM(CASE WHEN prev_at IS NULL
                    OR strftime('%s', accessed_at) - strftime('%s', prev_at) >= 1800
                  THEN 1 ELSE 0 END)
           OVER (PARTITION BY customer_id ORDER BY accessed_at, log_id) AS session_no
  FROM lagged
),
sessions AS (
  SELECT customer_id, session_no,
         MAX(CASE WHEN path = '/cart' THEN 1 ELSE 0 END) AS cart,
         MAX(CASE WHEN path = '/complete' THEN 1 ELSE 0 END) AS complete
  FROM sessionized
  GROUP BY customer_id, session_no
)
SELECT customer_id, COUNT(*) AS abandoned
FROM sessions
WHERE cart = 1 AND complete = 0
GROUP BY customer_id
ORDER BY abandoned DESC, customer_id
LIMIT 5;

-- ## Day 4: 応用

-- [W12-D4-1] ★★★ ordered
-- 問: 2025年の各月（'YYYY-MM'）について、completed の注文金額の中央値を求めよ（件数が偶数なら中央2件の平均）。月の昇順。
-- 出力: ym, median_amount
WITH order_totals AS (
  SELECT o.order_id, strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY o.order_id, ym
),
numbered AS (
  SELECT ym, amount,
         ROW_NUMBER() OVER (PARTITION BY ym ORDER BY amount) AS rn,
         COUNT(*) OVER (PARTITION BY ym) AS n
  FROM order_totals
)
SELECT ym, AVG(amount) AS median_amount
FROM numbered
WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
GROUP BY ym
ORDER BY ym;

-- [W12-D4-2] ★★★
-- 問: 休眠顧客の抽出。completed の注文が 3 回以上あり、最後の completed 注文の日付が基準日 2026-01-01 から 180 日以上前の顧客を取得せよ（経過日数は日付単位で計算）。
-- 出力: customer_id, name, orders, last_order_date
SELECT c.customer_id, c.name,
       COUNT(*) AS orders,
       date(MAX(o.ordered_at)) AS last_order_date
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name
HAVING COUNT(*) >= 3
   AND julianday('2026-01-01') - julianday(date(MAX(o.ordered_at))) >= 180;

-- [W12-D4-3] ★★★
-- 問: 全顧客を「紹介で登録したか」（referrer_id の有無。'あり' / 'なし'）で分け、それぞれの顧客数、購入者率（completed の購入が1円以上ある顧客の割合。百分率、小数第1位まで）、平均LTV（completed 購入総額の平均。未購入の顧客も 0 円として分母に含める。整数に四捨五入）を求めよ。
-- 出力: referred, customers, buyer_rate, avg_ltv
WITH ltv AS (
  SELECT c.customer_id, c.referrer_id,
         COALESCE(SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * oi.unit_price END), 0) AS total
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  LEFT JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY c.customer_id, c.referrer_id
)
SELECT CASE WHEN referrer_id IS NULL THEN 'なし' ELSE 'あり' END AS referred,
       COUNT(*) AS customers,
       ROUND(SUM(CASE WHEN total > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS buyer_rate,
       ROUND(AVG(total)) AS avg_ltv
FROM ltv
GROUP BY referred;

-- ## Day 4 定着: 応用

-- [W12-D4-R1] ★★★ ordered
-- 問: 顧客の都道府県ごとに、completed の注文金額の中央値を求めよ（全期間。件数が偶数なら中央2件の平均）。completed の注文が 100 件以上ある都道府県だけを、都道府県名の昇順で出すこと。
-- 出力: prefecture, orders, median_amount
WITH order_totals AS (
  SELECT o.order_id, c.prefecture, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, c.prefecture
),
numbered AS (
  SELECT prefecture, amount,
         ROW_NUMBER() OVER (PARTITION BY prefecture ORDER BY amount) AS rn,
         COUNT(*) OVER (PARTITION BY prefecture) AS n
  FROM order_totals
)
SELECT prefecture, MAX(n) AS orders, AVG(amount) AS median_amount
FROM numbered
WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
  AND n >= 100
GROUP BY prefecture
ORDER BY prefecture;

-- [W12-D4-R2] ★★★
-- 問: 「1回買って、それきり」の顧客の抽出。最初の completed 注文が 2025年1月1日〜6月30日で、その後 completed の注文が1件もない顧客を取得せよ。
-- 出力: customer_id, name, first_order_date
SELECT c.customer_id, c.name, date(MIN(o.ordered_at)) AS first_order_date
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name
HAVING COUNT(*) = 1
   AND MIN(o.ordered_at) >= '2025-01-01' AND MIN(o.ordered_at) < '2025-07-01';

-- [W12-D4-R3] ★★★
-- 問: 全顧客を性別ラベル（'M'→'男性'、'F'→'女性'、NULL→'不明'）で分け、それぞれの顧客数、購入者率（completed の購入が1円以上ある顧客の割合。百分率、小数第1位まで）、平均LTV（completed 購入総額の平均。未購入の顧客も 0 円として分母に含める。整数に四捨五入）を求めよ。
-- 出力: gender_label, customers, buyer_rate, avg_ltv
WITH ltv AS (
  SELECT c.customer_id, c.gender,
         COALESCE(SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * oi.unit_price END), 0) AS total
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  LEFT JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY c.customer_id, c.gender
)
SELECT CASE gender WHEN 'M' THEN '男性' WHEN 'F' THEN '女性' ELSE '不明' END AS gender_label,
       COUNT(*) AS customers,
       ROUND(SUM(CASE WHEN total > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS buyer_rate,
       ROUND(AVG(total)) AS avg_ltv
FROM ltv
GROUP BY gender_label;

-- ## Day 5: 卒業試験

-- [W12-D5-1] ★★★ ordered
-- 問: 経営ダッシュボード用の月次KPIを、2025年の各月（'YYYY-MM'）について1つのクエリで出せ。orders: completed の注文件数。buyers: completed の注文をした顧客数。sales: completed 売上。aov: completed の平均注文金額（整数に四捨五入）。new_buyers: その月に初めて completed の注文をした顧客数。cancel_rate: その月の全注文（全ステータス）に占める cancelled の割合（百分率、小数第1位まで）。月の昇順。
-- 出力: ym, orders, buyers, sales, aov, new_buyers, cancel_rate
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.status,
         strftime('%Y-%m', o.ordered_at) AS ym,
         SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_id, o.customer_id, o.status, ym
),
first_months AS (
  SELECT customer_id, MIN(ym) AS first_ym
  FROM order_totals
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT t.ym,
       SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) AS orders,
       COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.customer_id END) AS buyers,
       SUM(CASE WHEN t.status = 'completed' THEN t.amount ELSE 0 END) AS sales,
       ROUND(AVG(CASE WHEN t.status = 'completed' THEN t.amount END)) AS aov,
       COUNT(DISTINCT CASE WHEN t.status = 'completed' AND f.first_ym = t.ym THEN t.customer_id END) AS new_buyers,
       ROUND(SUM(CASE WHEN t.status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate
FROM order_totals t
LEFT JOIN first_months f ON f.customer_id = t.customer_id
WHERE t.ym BETWEEN '2025-01' AND '2025-12'
GROUP BY t.ym
ORDER BY t.ym;

-- [W12-D5-2] ★★★ ordered
-- 問: 商品ポートフォリオ。completed の注文について、商品ごとの売上、粗利（数量 ×（購入時単価 − 現在の原価）の合計）、粗利率（粗利 ÷ 売上 の百分率、小数第1位まで）、平均評価（小数第2位まで。レビューがなければ NULL）を求め、粗利の大きい上位10商品を取得せよ。粗利の大きい順、同額なら product_id 順。
-- 出力: product_id, name, sales, gross_profit, margin_rate, avg_rating
WITH product_sales AS (
  SELECT oi.product_id,
         SUM(oi.quantity * oi.unit_price) AS sales,
         SUM(oi.quantity * (oi.unit_price - p.cost)) AS gross_profit
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
  GROUP BY oi.product_id
),
ratings AS (
  SELECT product_id, ROUND(AVG(rating), 2) AS avg_rating
  FROM reviews
  GROUP BY product_id
)
SELECT p.product_id, p.name, s.sales, s.gross_profit,
       ROUND(s.gross_profit * 100.0 / s.sales, 1) AS margin_rate,
       r.avg_rating
FROM product_sales s
JOIN products p ON p.product_id = s.product_id
LEFT JOIN ratings r ON r.product_id = s.product_id
ORDER BY s.gross_profit DESC, p.product_id
LIMIT 10;

-- [W12-D5-3] ★★★ ordered
-- 問: 離反の予兆がある顧客の抽出。completed の注文が 4 回以上ある顧客について、平均購入間隔（連続する注文同士の julianday の差の平均。小数第1位まで）と、最後の注文から基準日 2026-01-01 00:00:00 までの経過日数（julianday の差。小数点以下切り捨て）を求め、経過日数が平均購入間隔の 3 倍を超えている顧客を取得せよ。経過日数の長い順、同じなら customer_id 順。
-- 出力: customer_id, orders, avg_interval, days_since_last
WITH lagged AS (
  SELECT customer_id, ordered_at,
         LAG(ordered_at) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev_at
  FROM orders
  WHERE status = 'completed'
),
stats AS (
  SELECT customer_id,
         COUNT(*) AS orders,
         AVG(julianday(ordered_at) - julianday(prev_at)) AS avg_interval,
         julianday('2026-01-01') - julianday(MAX(ordered_at)) AS days_since_last
  FROM lagged
  GROUP BY customer_id
)
SELECT customer_id, orders,
       ROUND(avg_interval, 1) AS avg_interval,
       CAST(days_since_last AS INTEGER) AS days_since_last
FROM stats
WHERE orders >= 4
  AND days_since_last > avg_interval * 3
ORDER BY days_since_last DESC, customer_id;

-- ## Day 5 定着: 卒業試験

-- [W12-D5-R1] ★★★ ordered
-- 問: 2024年の四半期（'2024-Q1' 〜 '2024-Q4'）ごとのKPIを1つのクエリで出せ。orders: completed の注文件数。buyers: completed の注文をした顧客数。sales: completed 売上。aov: completed の平均注文金額（整数に四捨五入）。cancel_rate: その四半期の全注文（全ステータス）に占める cancelled の割合（百分率、小数第1位まで）。四半期の昇順。
-- 出力: quarter, orders, buyers, sales, aov, cancel_rate
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.status,
         strftime('%Y', o.ordered_at) || '-Q' || ((CAST(strftime('%m', o.ordered_at) AS INTEGER) + 2) / 3) AS quarter,
         SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.ordered_at >= '2024-01-01' AND o.ordered_at < '2025-01-01'
  GROUP BY o.order_id, o.customer_id, o.status, quarter
)
SELECT quarter,
       SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS orders,
       COUNT(DISTINCT CASE WHEN status = 'completed' THEN customer_id END) AS buyers,
       SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS sales,
       ROUND(AVG(CASE WHEN status = 'completed' THEN amount END)) AS aov,
       ROUND(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate
FROM order_totals
GROUP BY quarter
ORDER BY quarter;

-- [W12-D5-R2] ★★★ ordered
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとに、completed の売上、粗利（数量 ×（購入時単価 − 現在の原価）の合計）、粗利率（百分率、小数第1位まで）、そのカテゴリの商品に付いた全レビューの平均評価（小数第2位まで。レビューがなければ NULL）を求め、売上の大きい上位5カテゴリを取得せよ。売上の大きい順、同額なら category_id 順。
-- 出力: category_id, name, sales, gross_profit, margin_rate, avg_rating
-- ヒント: 売上とレビューは別々に集計してから結合する（同時に JOIN すると行が膨らむ）。
WITH category_sales AS (
  SELECT p.category_id,
         SUM(oi.quantity * oi.unit_price) AS sales,
         SUM(oi.quantity * (oi.unit_price - p.cost)) AS gross_profit
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category_id
),
category_ratings AS (
  SELECT p.category_id, ROUND(AVG(r.rating), 2) AS avg_rating
  FROM reviews r
  JOIN products p ON p.product_id = r.product_id
  GROUP BY p.category_id
)
SELECT c.category_id, c.name, s.sales, s.gross_profit,
       ROUND(s.gross_profit * 100.0 / s.sales, 1) AS margin_rate,
       r.avg_rating
FROM category_sales s
JOIN categories c ON c.category_id = s.category_id
LEFT JOIN category_ratings r ON r.category_id = s.category_id
ORDER BY s.sales DESC, c.category_id
LIMIT 5;

-- [W12-D5-R3] ★★★ ordered
-- 問: 優良顧客の離脱チェック。2024年に completed の注文が 5 回以上あったのに、2025年7月1日以降は completed の注文が1件もない顧客を取得せよ。最後の completed 注文日（日付）も出すこと。最後の注文日の古い順、同じなら customer_id 順。
-- 出力: customer_id, orders_2024, last_order_date
SELECT o.customer_id,
       SUM(CASE WHEN o.ordered_at >= '2024-01-01' AND o.ordered_at < '2025-01-01' THEN 1 ELSE 0 END) AS orders_2024,
       date(MAX(o.ordered_at)) AS last_order_date
FROM orders o
WHERE o.status = 'completed'
GROUP BY o.customer_id
HAVING SUM(CASE WHEN o.ordered_at >= '2024-01-01' AND o.ordered_at < '2025-01-01' THEN 1 ELSE 0 END) >= 5
   AND MAX(o.ordered_at) < '2025-07-01'
ORDER BY last_order_date, o.customer_id;
