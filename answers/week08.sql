-- # Week 8: ウィンドウ関数 (2) 前後の行・累計・フレーム

-- ## Day 1: LAG / LEAD

-- [W08-D1-1] ★★ ordered
-- 問: 月次（'YYYY-MM'）の completed 売上について、前月の売上と前月比の伸び率（百分率、小数第1位まで）を LAG を使って求めよ（W06-D3-3 の別解）。月の昇順。
-- 出力: ym, sales, prev_sales, mom
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY ym
)
SELECT ym, sales,
       LAG(sales) OVER (ORDER BY ym) AS prev_sales,
       ROUND((sales - LAG(sales) OVER (ORDER BY ym)) * 100.0 / LAG(sales) OVER (ORDER BY ym), 1) AS mom
FROM monthly
ORDER BY ym;

-- [W08-D1-2] ★★★
-- 問: completed の注文について、同じ顧客の前回の注文からの経過日数（julianday の差）を求め、全体の平均（小数第1位まで）を出せ。各顧客の初回注文は前回がないので対象外。
-- 出力: avg_interval_days
WITH intervals AS (
  SELECT julianday(ordered_at)
         - julianday(LAG(ordered_at) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id)) AS days
  FROM orders
  WHERE status = 'completed'
)
SELECT ROUND(AVG(days), 1) AS avg_interval_days
FROM intervals
WHERE days IS NOT NULL;

-- [W08-D1-3] ★★★ ordered
-- 問: 2025年の各月について、completed 売上・前年同月の売上・前年同月比の伸び率（百分率、小数第1位まで）を求めよ。月の昇順。
-- 出力: ym, sales, last_year_sales, yoy
-- ヒント: 全24か月が欠けなく揃っているなら LAG(sales, 12) が使える。
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
SELECT ym, sales, last_year_sales,
       ROUND((sales - last_year_sales) * 100.0 / last_year_sales, 1) AS yoy
FROM with_last_year
WHERE ym >= '2025-01'
ORDER BY ym;

-- ## Day 1 定着: LAG / LEAD

-- [W08-D1-R1] ★★ ordered
-- 問: 2025年の各月（'YYYY-MM'）について、completed の注文件数・翌月の注文件数・翌月との増減（翌月 − 当月）を LEAD を使って求めよ。2025年12月の翌月はデータがないので NULL でよい。月の昇順。
-- 出力: ym, orders, next_orders, diff
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS orders
  FROM orders
  WHERE status = 'completed'
    AND ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01'
  GROUP BY ym
)
SELECT ym, orders,
       LEAD(orders) OVER (ORDER BY ym) AS next_orders,
       LEAD(orders) OVER (ORDER BY ym) - orders AS diff
FROM monthly
ORDER BY ym;

-- [W08-D1-R2] ★★★
-- 問: レビューについて、同じ顧客の前回のレビュー（投稿日時順、同時刻なら review_id 順）からの経過日数（julianday の差）を求め、全体の平均（小数第1位まで）を出せ。各顧客の最初のレビューは前回がないので対象外。
-- 出力: avg_interval_days
WITH intervals AS (
  SELECT julianday(created_at)
         - julianday(LAG(created_at) OVER (PARTITION BY customer_id ORDER BY created_at, review_id)) AS days
  FROM reviews
)
SELECT ROUND(AVG(days), 1) AS avg_interval_days
FROM intervals
WHERE days IS NOT NULL;

-- [W08-D1-R3] ★★★ ordered
-- 問: 2025年の各四半期（'2025-Q1' の形式）について、completed 売上・前年同四半期の売上・前年同四半期比の伸び率（百分率、小数第1位まで）を求めよ。四半期の昇順。
-- 出力: yq, sales, last_year_sales, yoy
-- ヒント: 四半期の番号は (CAST(strftime('%m', ordered_at) AS INTEGER) + 2) / 3。8四半期が欠けなく揃っているので LAG(sales, 4) が使える。2025年で先に絞ると前年の値が取れない。
WITH quarterly AS (
  SELECT strftime('%Y', o.ordered_at) || '-Q'
         || ((CAST(strftime('%m', o.ordered_at) AS INTEGER) + 2) / 3) AS yq,
         SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY yq
),
with_last_year AS (
  SELECT yq, sales, LAG(sales, 4) OVER (ORDER BY yq) AS last_year_sales
  FROM quarterly
)
SELECT yq, sales, last_year_sales,
       ROUND((sales - last_year_sales) * 100.0 / last_year_sales, 1) AS yoy
FROM with_last_year
WHERE yq >= '2025'
ORDER BY yq;

-- ## Day 2: 累計と移動平均

-- [W08-D2-1] ★★ ordered
-- 問: 2025年の月次 completed 売上と、年初からの累計を求めよ。月の昇順。
-- 出力: ym, sales, cumulative
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
    AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
  GROUP BY ym
)
SELECT ym, sales, SUM(sales) OVER (ORDER BY ym) AS cumulative
FROM monthly
ORDER BY ym;

-- [W08-D2-2] ★★★ ordered
-- 問: 2025年11月の各日について、completed の日次売上と、その日を含む直近7日間の移動平均（整数に四捨五入）を求めよ。10月末の日も平均の計算には含めること。日付の昇順。（この期間は売上のない日が存在しないので、行ベースのフレームで計算してよい。売上のない日がある場合の厳密版は W09-D3-2 で扱う）
-- 出力: day, sales, ma7
-- ヒント: ROWS BETWEEN 6 PRECEDING AND CURRENT ROW。先に11月で絞ると、月初の平均に10月分が入らなくなる。
WITH daily AS (
  SELECT date(o.ordered_at) AS day, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY day
),
with_ma AS (
  SELECT day, sales,
         ROUND(AVG(sales) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS ma7
  FROM daily
)
SELECT day, sales, ma7
FROM with_ma
WHERE day BETWEEN '2025-11-01' AND '2025-11-30'
ORDER BY day;

-- [W08-D2-3] ★★★
-- 問: 顧客ごとに completed の注文金額を時系列（注文日時順、同時刻なら order_id 順）で累計し、累計が初めて 100,000 円以上になった注文を取得せよ。
-- 出力: customer_id, order_id, ordered_at, cumulative
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.ordered_at, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id, o.ordered_at
),
running AS (
  SELECT *, SUM(amount) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS cumulative
  FROM order_totals
)
SELECT customer_id, order_id, ordered_at, cumulative
FROM running
WHERE cumulative >= 100000
  AND cumulative - amount < 100000;

-- ## Day 2 定着: 累計と移動平均

-- [W08-D2-R1] ★★ ordered
-- 問: 2024年の月次 completed 注文件数と、年初からの累計件数を求めよ。月の昇順。
-- 出力: ym, orders, cumulative
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS orders
  FROM orders
  WHERE status = 'completed'
    AND ordered_at >= '2024-01-01' AND ordered_at < '2025-01-01'
  GROUP BY ym
)
SELECT ym, orders, SUM(orders) OVER (ORDER BY ym) AS cumulative
FROM monthly
ORDER BY ym;

-- [W08-D2-R2] ★★★ ordered
-- 問: 2025年11月の各日について、サイト全体のページビュー数（access_logs の行数。ゲストも含む）と、その日を含む直近7日間の移動平均（小数第1位まで）を求めよ。10月末の日も平均の計算には含めること。日付の昇順。（アクセスログは期間中アクセスのない日が存在しないので、行ベースのフレームで計算してよい）
-- 出力: day, pv, ma7
-- ヒント: 先に11月で絞ってから移動平均を取ると、11月1日〜6日の平均に10月分が入らなくなる。
WITH daily AS (
  SELECT date(accessed_at) AS day, COUNT(*) AS pv
  FROM access_logs
  GROUP BY day
),
with_ma AS (
  SELECT day, pv,
         ROUND(AVG(pv) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS ma7
  FROM daily
)
SELECT day, pv, ma7
FROM with_ma
WHERE day BETWEEN '2025-11-01' AND '2025-11-30'
ORDER BY day;

-- [W08-D2-R3] ★★★
-- 問: 商品ごとに completed の注文での販売数量を時系列（注文日時順、同時刻なら order_id 順）で累計し、累計販売数量が初めて 100 個以上になった注文を取得せよ。
-- 出力: product_id, order_id, ordered_at, cumulative_qty
WITH running AS (
  SELECT oi.product_id, o.order_id, o.ordered_at, oi.quantity,
         SUM(oi.quantity) OVER (PARTITION BY oi.product_id ORDER BY o.ordered_at, o.order_id) AS cumulative_qty
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
)
SELECT product_id, order_id, ordered_at, cumulative_qty
FROM running
WHERE cumulative_qty >= 100
  AND cumulative_qty - quantity < 100;

-- ## Day 3: フレームと FIRST_VALUE / LAST_VALUE

-- [W08-D3-1] ★★★
-- 問: 全商品について、同じカテゴリで最も安い商品の名前（同額なら product_id の小さい方）を各行に付けよ。
-- 出力: product_id, name, price, cheapest_in_category
SELECT product_id, name, price,
       FIRST_VALUE(name) OVER (PARTITION BY category_id ORDER BY price, product_id) AS cheapest_in_category
FROM products;

-- [W08-D3-2] ★★★
-- 問: 部署に所属している社員について、同じ部署で最も年収が高い社員の名前（同額なら employee_id の大きい方）を、LAST_VALUE を使って各行に付けよ。
-- 出力: name, department_id, salary, top_earner
-- ヒント: ORDER BY を書いたときのデフォルトのフレームは「先頭〜現在行」。そのままだと LAST_VALUE は自分自身を返す。
-- 解説: ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING でパーティション全体をフレームにする。
SELECT name, department_id, salary,
       LAST_VALUE(name) OVER (
         PARTITION BY department_id
         ORDER BY salary, employee_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS top_earner
FROM employees
WHERE department_id IS NOT NULL;

-- [W08-D3-3] ★★★ ordered
-- 問: 全社員を年収の低い順（同額なら employee_id 順）に並べ、年収の累計を2通り求めよ。(1) running_range: `ORDER BY salary` のみを指定したデフォルトのフレームでの累計（同額の行は同じ値になる）。(2) running_rows: 並び順どおりに1行ずつ足していく累計。
-- 出力: name, salary, running_range, running_rows
-- 解説: デフォルトは RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW で、ORDER BY の値が同じ行（ピア）をまとめて含む。1行ずつ足したいなら ROWS を明示し、並び順を一意にする。
SELECT name, salary,
       SUM(salary) OVER (ORDER BY salary) AS running_range,
       SUM(salary) OVER (ORDER BY salary, employee_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_rows
FROM employees
ORDER BY salary, employee_id;

-- ## Day 3 定着: フレームと FIRST_VALUE / LAST_VALUE

-- [W08-D3-R1] ★★★
-- 問: 部署に所属している社員について、同じ部署で最も早く入社した社員の名前（入社日が同じなら employee_id の小さい方）を FIRST_VALUE を使って各行に付けよ。
-- 出力: name, department_id, hired_on, first_hired
SELECT name, department_id, hired_on,
       FIRST_VALUE(name) OVER (PARTITION BY department_id ORDER BY hired_on, employee_id) AS first_hired
FROM employees
WHERE department_id IS NOT NULL;

-- [W08-D3-R2] ★★★
-- 問: 全商品について、同じカテゴリ（商品が直接属するカテゴリ）で最も価格の高い商品の名前（同額なら product_id の大きい方）を、LAST_VALUE を使って各行に付けよ。
-- 出力: product_id, name, price, priciest_in_category
-- ヒント: ORDER BY を書いたときのデフォルトのフレームは「先頭〜現在行」。フレームを指定しないと LAST_VALUE は自分（と同額の行）までしか見ない。
SELECT product_id, name, price,
       LAST_VALUE(name) OVER (
         PARTITION BY category_id
         ORDER BY price, product_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS priciest_in_category
FROM products;

-- [W08-D3-R3] ★★★ ordered
-- 問: 全商品を価格の安い順（同額なら product_id 順）に並べ、「その行までの商品数」を2通り求めよ。(1) cnt_range: `ORDER BY price` のみを指定したデフォルトのフレームでの COUNT(*)（同額の商品は同じ値になる）。(2) cnt_rows: 並び順どおりに1行ずつ数えた COUNT(*)。
-- 出力: product_id, price, cnt_range, cnt_rows
-- 解説: cnt_range は「自分以下の価格の商品数」になる。デフォルトのフレームは RANGE で、同じ price の行（ピア）をまとめて含むため。
SELECT product_id, price,
       COUNT(*) OVER (ORDER BY price) AS cnt_range,
       COUNT(*) OVER (ORDER BY price, product_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cnt_rows
FROM products
ORDER BY price, product_id;

-- ## Day 4: NTILE と中央値

-- [W08-D4-1] ★★★ ordered
-- 問: デシル分析。completed の購入総額がある顧客を、総額の高い順（同額なら customer_id 順）に10等分し、グループ（1 が最上位）ごとの顧客数・売上合計・全体に占める売上構成比（百分率、小数第1位まで）を求めよ。グループ番号の昇順。
-- 出力: decile, customers, total_sales, share
WITH customer_totals AS (
  SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
),
tiled AS (
  SELECT *, NTILE(10) OVER (ORDER BY total DESC, customer_id) AS decile
  FROM customer_totals
)
SELECT decile,
       COUNT(*) AS customers,
       SUM(total) AS total_sales,
       ROUND(SUM(total) * 100.0 / SUM(SUM(total)) OVER (), 1) AS share
FROM tiled
GROUP BY decile
ORDER BY decile;

-- [W08-D4-2] ★★★
-- 問: 全社員を年収の高い順（同額なら employee_id 順）に4等分したとき、最上位グループに入る社員を取得せよ。
-- 出力: name, salary
WITH tiled AS (
  SELECT name, salary, NTILE(4) OVER (ORDER BY salary DESC, employee_id) AS quartile
  FROM employees
)
SELECT name, salary
FROM tiled
WHERE quartile = 1;

-- [W08-D4-3] ★★★
-- 問: 商品価格の中央値を求めよ（件数が偶数の場合は中央2件の平均）。
-- 出力: median_price
-- ヒント: 価格順の通し番号 rn と総件数 n を付け、rn が (n+1)/2 または (n+2)/2（整数除算）の行を平均する。
-- 解説: PostgreSQL なら PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) で一発。
WITH numbered AS (
  SELECT price,
         ROW_NUMBER() OVER (ORDER BY price) AS rn,
         COUNT(*) OVER () AS n
  FROM products
)
SELECT AVG(price) AS median_price
FROM numbered
WHERE rn IN ((n + 1) / 2, (n + 2) / 2);

-- ## Day 4 定着: NTILE と中央値

-- [W08-D4-R1] ★★★ ordered
-- 問: 全商品を価格の高い順（同額なら product_id 順）に5等分し、グループ（1 が最も高価格）ごとの商品数・最高価格・最低価格を求めよ。グループ番号の昇順。
-- 出力: grp, products, max_price, min_price
-- 解説: 77件を5等分すると割り切れないので、先頭のグループから1件ずつ多くなる（16, 16, 15, 15, 15）。
WITH tiled AS (
  SELECT price, NTILE(5) OVER (ORDER BY price DESC, product_id) AS grp
  FROM products
)
SELECT grp, COUNT(*) AS products, MAX(price) AS max_price, MIN(price) AS min_price
FROM tiled
GROUP BY grp
ORDER BY grp;

-- [W08-D4-R2] ★★★
-- 問: 部署に所属している社員を、部署ごとに年収の高い順（同額なら employee_id 順）で2等分したとき、上位グループに入る社員を取得せよ。
-- 出力: department_id, name, salary
-- 解説: 人数が奇数の部署では、上位グループの方が1人多くなる。
WITH tiled AS (
  SELECT department_id, name, salary,
         NTILE(2) OVER (PARTITION BY department_id ORDER BY salary DESC, employee_id) AS half
  FROM employees
  WHERE department_id IS NOT NULL
)
SELECT department_id, name, salary
FROM tiled
WHERE half = 1;

-- [W08-D4-R3] ★★★
-- 問: completed の注文1件あたりの金額（注文ごとの売上）の中央値を求めよ（件数が偶数の場合は中央2件の平均）。
-- 出力: median_amount
-- ヒント: まず注文ごとの金額を出し、金額順の通し番号 rn と総件数 n を付ける。
WITH order_totals AS (
  SELECT o.order_id, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id
),
numbered AS (
  SELECT amount,
         ROW_NUMBER() OVER (ORDER BY amount) AS rn,
         COUNT(*) OVER () AS n
  FROM order_totals
)
SELECT AVG(amount) AS median_amount
FROM numbered
WHERE rn IN ((n + 1) / 2, (n + 2) / 2);

-- ## Day 5: 総合演習

-- [W08-D5-1] ★★★
-- 問: 月次の completed 売上が「2か月連続で前月を上回った」月（＝当月 > 前月 かつ 前月 > 前々月）を取得せよ。
-- 出力: ym, sales
WITH monthly AS (
  SELECT strftime('%Y-%m', o.ordered_at) AS ym, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY ym
),
lagged AS (
  SELECT ym, sales,
         LAG(sales, 1) OVER (ORDER BY ym) AS prev1,
         LAG(sales, 2) OVER (ORDER BY ym) AS prev2
  FROM monthly
)
SELECT ym, sales
FROM lagged
WHERE sales > prev1 AND prev1 > prev2;

-- [W08-D5-2] ★★★ ordered
-- 問: ABC分析。completed 売上のある商品を売上の高い順（同額なら product_id 順）に並べ、売上の累積構成比（百分率）を求めよ。累積構成比が 70 以下なら 'A'、90 以下なら 'B'、それ以外は 'C' とランク付けすること。累積構成比は小数第1位まで表示するが、ランク判定は丸める前の値で行う。
-- 出力: product_id, sales, cum_share, abc
WITH product_sales AS (
  SELECT oi.product_id, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY oi.product_id
),
cumulative AS (
  SELECT product_id, sales,
         SUM(sales) OVER (ORDER BY sales DESC, product_id) * 100.0 / SUM(sales) OVER () AS cum_share
  FROM product_sales
)
SELECT product_id, sales,
       ROUND(cum_share, 1) AS cum_share,
       CASE WHEN cum_share <= 70 THEN 'A'
            WHEN cum_share <= 90 THEN 'B'
            ELSE 'C' END AS abc
FROM cumulative
ORDER BY sales DESC, product_id;

-- [W08-D5-3] ★★★
-- 問: completed の注文のうち各顧客の2回目以降の注文について、「同じ顧客の前回の注文より金額が大きかった」注文の割合（0〜1、小数第3位まで）を求めよ。
-- 出力: ratio
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.ordered_at, SUM(oi.quantity * oi.unit_price) AS amount
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id, o.ordered_at
),
lagged AS (
  SELECT amount,
         LAG(amount) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev_amount
  FROM order_totals
)
SELECT ROUND(AVG(CASE WHEN amount > prev_amount THEN 1.0 ELSE 0 END), 3) AS ratio
FROM lagged
WHERE prev_amount IS NOT NULL;

-- ## Day 5 定着: 総合演習

-- [W08-D5-R1] ★★★
-- 問: 月次の completed 注文件数が「2か月連続で前月を下回った」月（＝当月 < 前月 かつ 前月 < 前々月）を取得せよ。
-- 出力: ym, orders
WITH monthly AS (
  SELECT strftime('%Y-%m', ordered_at) AS ym, COUNT(*) AS orders
  FROM orders
  WHERE status = 'completed'
  GROUP BY ym
),
lagged AS (
  SELECT ym, orders,
         LAG(orders, 1) OVER (ORDER BY ym) AS prev1,
         LAG(orders, 2) OVER (ORDER BY ym) AS prev2
  FROM monthly
)
SELECT ym, orders
FROM lagged
WHERE orders < prev1 AND prev1 < prev2;

-- [W08-D5-R2] ★★★ ordered
-- 問: カテゴリ（商品が直接属するカテゴリ）ごとの completed 売上を売上の高い順（同額なら category_id 順）に並べ、売上の累積構成比（百分率）を求めよ。累積構成比が 50 以下なら 'A'、80 以下なら 'B'、それ以外は 'C' とランク付けすること。累積構成比は小数第1位まで表示するが、ランク判定は丸める前の値で行う。
-- 出力: category_id, sales, cum_share, abc
WITH category_sales AS (
  SELECT p.category_id, SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category_id
),
cumulative AS (
  SELECT category_id, sales,
         SUM(sales) OVER (ORDER BY sales DESC, category_id) * 100.0 / SUM(sales) OVER () AS cum_share
  FROM category_sales
)
SELECT category_id, sales,
       ROUND(cum_share, 1) AS cum_share,
       CASE WHEN cum_share <= 50 THEN 'A'
            WHEN cum_share <= 80 THEN 'B'
            ELSE 'C' END AS abc
FROM cumulative
ORDER BY sales DESC, category_id;

-- [W08-D5-R3] ★★★
-- 問: completed の注文のうち各顧客の2回目以降の注文について、「同じ顧客の前回の注文（注文日時順、同時刻なら order_id 順）と同じ支払方法だった」注文の割合（0〜1、小数第3位まで）を求めよ。
-- 出力: ratio
WITH lagged AS (
  SELECT payment_method,
         LAG(payment_method) OVER (PARTITION BY customer_id ORDER BY ordered_at, order_id) AS prev_method
  FROM orders
  WHERE status = 'completed'
)
SELECT ROUND(AVG(CASE WHEN payment_method = prev_method THEN 1.0 ELSE 0 END), 3) AS ratio
FROM lagged
WHERE prev_method IS NOT NULL;
