-- # Week 1: SELECT の基礎

-- ## Day 1: 列の選択・並び替え・件数制限

-- [W01-D1-1] ★ ordered
-- 問: 商品を価格の高い順（同額なら product_id の小さい順）に並べ、上位10件を取得せよ。
-- 出力: name, price
SELECT name, price
FROM products
ORDER BY price DESC, product_id
LIMIT 10;

-- [W01-D1-2] ★ ordered
-- 問: 顧客が住んでいる都道府県を、重複なしで昇順に一覧せよ。
-- 出力: prefecture
SELECT DISTINCT prefecture
FROM customers
ORDER BY prefecture;

-- [W01-D1-3] ★★ ordered
-- 問: 商品ごとに粗利（price - cost）と粗利率（粗利 ÷ price の百分率、小数第1位まで）を計算し、粗利率の高い順（同率なら product_id 順）に上位5件を取得せよ。
-- 出力: name, price, cost, margin, margin_rate
-- ヒント: 整数同士の割り算は切り捨てられる。`* 100.0` のように実数を混ぜる。
SELECT name, price, cost,
       price - cost AS margin,
       ROUND((price - cost) * 100.0 / price, 1) AS margin_rate
FROM products
ORDER BY margin_rate DESC, product_id
LIMIT 5;

-- ## Day 1 定着: 列の選択・並び替え・件数制限

-- [W01-D1-R1] ★ ordered
-- 問: 社員を年収の高い順（同額なら employee_id の小さい順）に並べ、上位5件を取得せよ。
-- 出力: name, salary
SELECT name, salary
FROM employees
ORDER BY salary DESC, employee_id
LIMIT 5;

-- [W01-D1-R2] ★ ordered
-- 問: 注文で使われている支払方法を、重複なしで昇順に一覧せよ。
-- 出力: payment_method
SELECT DISTINCT payment_method
FROM orders
ORDER BY payment_method;

-- [W01-D1-R3] ★★ ordered
-- 問: 社員ごとに月額給与（salary ÷ 12、小数第1位まで）を計算し、月額の低い順（同額なら employee_id 順）に5件取得せよ。
-- 出力: name, salary, monthly_salary
-- ヒント: salary も 12 も整数なので、そのまま割ると小数点以下が切り捨てられる。
SELECT name, salary,
       ROUND(salary / 12.0, 1) AS monthly_salary
FROM employees
ORDER BY monthly_salary, employee_id
LIMIT 5;

-- ## Day 2: WHERE（比較・AND/OR・IN・BETWEEN）

-- [W01-D2-1] ★
-- 問: 価格が 3,000円以上 10,000円以下で、販売終了していない商品を取得せよ。
-- 出力: product_id, name, price
SELECT product_id, name, price
FROM products
WHERE price BETWEEN 3000 AND 10000
  AND is_discontinued = 0;

-- [W01-D2-2] ★
-- 問: 東京都・神奈川県・千葉県・埼玉県のいずれかに住む顧客を取得せよ。
-- 出力: customer_id, name, prefecture
SELECT customer_id, name, prefecture
FROM customers
WHERE prefecture IN ('東京都', '神奈川県', '千葉県', '埼玉県');

-- [W01-D2-3] ★★
-- 問: 2025年に行われた注文のうち、キャンセルされておらず、支払方法が credit_card か e_money で、送料が 0 円のものを取得せよ。
-- 出力: order_id, ordered_at, payment_method
-- ヒント: 日時の範囲は「以上・未満」で書くのが安全（BETWEEN だと 12/31 の日中が漏れやすい）。
-- 解説: AND は OR より優先される。OR を使うなら必ず括弧で囲む。ここでは IN が簡潔。
SELECT order_id, ordered_at, payment_method
FROM orders
WHERE ordered_at >= '2025-01-01' AND ordered_at < '2026-01-01'
  AND status <> 'cancelled'
  AND payment_method IN ('credit_card', 'e_money')
  AND shipping_fee = 0;

-- ## Day 2 定着: WHERE（比較・AND/OR・IN・BETWEEN）

-- [W01-D2-R1] ★
-- 問: 役職が「一般社員」で、年収が 500万円以上 700万円以下の社員を取得せよ。
-- 出力: employee_id, name, salary
SELECT employee_id, name, salary
FROM employees
WHERE job_title = '一般社員'
  AND salary BETWEEN 5000000 AND 7000000;

-- [W01-D2-R2] ★
-- 問: カテゴリID が 17・18・19 のいずれかに属する商品を取得せよ。
-- 出力: product_id, name, category_id
SELECT product_id, name, category_id
FROM products
WHERE category_id IN (17, 18, 19);

-- [W01-D2-R3] ★★
-- 問: 2025年11月に行われた注文のうち、キャンセルされておらず、支払方法が cod か bank_transfer で、送料が 550 円のものを取得せよ。
-- 出力: order_id, ordered_at, payment_method
-- ヒント: 11月30日の夜の注文も漏らさないよう、日時の範囲は「以上・未満」で書く。
-- 解説: `payment_method = 'cod' OR payment_method = 'bank_transfer' AND ...` と括弧なしで書くと、AND が先に結び付いて cod の注文が条件なしで全部通ってしまう。
SELECT order_id, ordered_at, payment_method
FROM orders
WHERE ordered_at >= '2025-11-01' AND ordered_at < '2025-12-01'
  AND status <> 'cancelled'
  AND payment_method IN ('cod', 'bank_transfer')
  AND shipping_fee = 550;

-- ## Day 3: NULL と LIKE

-- [W01-D3-1] ★
-- 問: メールアドレスが登録されていない（NULL の）顧客を取得せよ。
-- 出力: customer_id, name
-- 解説: `email = NULL` は常に不明（UNKNOWN）になり1件も返らない。必ず IS NULL を使う。
SELECT customer_id, name
FROM customers
WHERE email IS NULL;

-- [W01-D3-2] ★
-- 問: 商品名に「コーヒー」を含む商品を取得せよ。
-- 出力: product_id, name
SELECT product_id, name
FROM products
WHERE name LIKE '%コーヒー%';

-- [W01-D3-3] ★★
-- 問: クーポン WELCOME10 を「使っていない」注文の件数を求めよ。クーポン自体を使っていない注文も当然含む。
-- 出力: cnt
-- ヒント: `coupon_code <> 'WELCOME10'` だけだと NULL の行が落ちる。
-- 解説: NULL との比較結果は UNKNOWN で、WHERE は TRUE の行しか通さない。NULL を含む列の否定条件は要注意。
SELECT COUNT(*) AS cnt
FROM orders
WHERE coupon_code IS NULL OR coupon_code <> 'WELCOME10';

-- ## Day 3 定着: NULL と LIKE

-- [W01-D3-R1] ★
-- 問: 部署に配属されていない（department_id が NULL の）社員を取得せよ。
-- 出力: employee_id, name
SELECT employee_id, name
FROM employees
WHERE department_id IS NULL;

-- [W01-D3-R2] ★
-- 問: 姓が「佐々木」の顧客を取得せよ。name は「姓 名」の形（半角スペース区切り）で入っている。
-- 出力: customer_id, name
SELECT customer_id, name
FROM customers
WHERE name LIKE '佐々木 %';

-- [W01-D3-R3] ★★
-- 問: コメントに「壊れ」を含まないレビューの件数を求めよ。コメントのない（NULL の）レビューも当然含む。
-- 出力: cnt
-- ヒント: `comment NOT LIKE '%壊れ%'` だけだと NULL の行が落ちる。
-- 解説: NULL に対する LIKE / NOT LIKE はどちらも UNKNOWN になり、WHERE を通らない。
SELECT COUNT(*) AS cnt
FROM reviews
WHERE comment IS NULL OR comment NOT LIKE '%壊れ%';

-- ## Day 4: 式・関数・CASE 入門

-- [W01-D4-1] ★
-- 問: 全商品の税込価格（price の 1.1 倍を四捨五入した整数）を求めよ。
-- 出力: name, price_with_tax
SELECT name, CAST(ROUND(price * 1.1) AS INTEGER) AS price_with_tax
FROM products;

-- [W01-D4-2] ★★
-- 問: 全商品を価格帯に分類せよ。1,000円未満は '低'、1,000円以上5,000円未満は '中'、5,000円以上は '高'。
-- 出力: product_id, name, price_band
SELECT product_id, name,
       CASE WHEN price < 1000 THEN '低'
            WHEN price < 5000 THEN '中'
            ELSE '高' END AS price_band
FROM products;

-- [W01-D4-3] ★★
-- 問: 全顧客について、メールアドレス（NULL なら '未登録'）と、性別ラベル（'M'→'男性'、'F'→'女性'、NULL→'不明'）を取得せよ。
-- 出力: name, email, gender_label
-- ヒント: COALESCE と CASE。
SELECT name,
       COALESCE(email, '未登録') AS email,
       CASE gender WHEN 'M' THEN '男性' WHEN 'F' THEN '女性' ELSE '不明' END AS gender_label
FROM customers;

-- ## Day 4 定着: 式・関数・CASE 入門

-- [W01-D4-R1] ★
-- 問: 全注文明細について、税込金額（quantity × unit_price の 1.1 倍を四捨五入した整数）を求めよ。
-- 出力: order_item_id, amount_with_tax
SELECT order_item_id,
       CAST(ROUND(quantity * unit_price * 1.1) AS INTEGER) AS amount_with_tax
FROM order_items;

-- [W01-D4-R2] ★★
-- 問: 全社員を年収帯に分類せよ。500万円未満は 'C'、500万円以上800万円未満は 'B'、800万円以上は 'A'。
-- 出力: employee_id, name, salary_band
SELECT employee_id, name,
       CASE WHEN salary < 5000000 THEN 'C'
            WHEN salary < 8000000 THEN 'B'
            ELSE 'A' END AS salary_band
FROM employees;

-- [W01-D4-R3] ★★
-- 問: 全レビューについて、コメント（NULL なら '（コメントなし）'）と、評価ラベル（5→'最高'、4→'良い'、3→'普通'、それ以外→'不満'）を取得せよ。
-- 出力: review_id, comment, rating_label
-- ヒント: COALESCE と CASE。
SELECT review_id,
       COALESCE(comment, '（コメントなし）') AS comment,
       CASE rating WHEN 5 THEN '最高' WHEN 4 THEN '良い' WHEN 3 THEN '普通' ELSE '不満' END AS rating_label
FROM reviews;

-- ## Day 5: 総合演習

-- [W01-D5-1] ★ ordered
-- 問: 2020年1月1日以降に入社し、年収が 600万円以上の社員を、年収の高い順（同額なら employee_id 順）に取得せよ。
-- 出力: name, salary, hired_on
SELECT name, salary, hired_on
FROM employees
WHERE hired_on >= '2020-01-01' AND salary >= 6000000
ORDER BY salary DESC, employee_id;

-- [W01-D5-2] ★★ ordered
-- 問: コメント付きで評価が 2 以下のレビューを、新しい順（同時刻なら review_id の大きい順）に5件取得せよ。
-- 出力: review_id, rating, comment, created_at
SELECT review_id, rating, comment, created_at
FROM reviews
WHERE comment IS NOT NULL AND rating <= 2
ORDER BY created_at DESC, review_id DESC
LIMIT 5;

-- [W01-D5-3] ★★★ ordered
-- 問: 商品一覧を価格の安い順（同額なら product_id 順）に10件ずつページ分けしたとき、3ページ目（21〜30件目）を取得せよ。
-- 出力: product_id, name, price
-- ヒント: LIMIT と OFFSET。
SELECT product_id, name, price
FROM products
ORDER BY price, product_id
LIMIT 10 OFFSET 20;

-- ## Day 5 定着: 総合演習

-- [W01-D5-R1] ★ ordered
-- 問: 販売中で価格が 2,000円未満の商品を、価格の高い順（同額なら product_id 順）に取得せよ。
-- 出力: name, price
SELECT name, price
FROM products
WHERE is_discontinued = 0 AND price < 2000
ORDER BY price DESC, product_id;

-- [W01-D5-R2] ★★ ordered
-- 問: ログインした顧客（customer_id が NULL でない）が PC から購入完了ページ（path が '/complete'）にアクセスしたログを、新しい順（同時刻なら log_id の大きい順）に5件取得せよ。
-- 出力: log_id, customer_id, accessed_at
SELECT log_id, customer_id, accessed_at
FROM access_logs
WHERE customer_id IS NOT NULL
  AND device = 'pc'
  AND path = '/complete'
ORDER BY accessed_at DESC, log_id DESC
LIMIT 5;

-- [W01-D5-R3] ★★★ ordered
-- 問: 生年月日が登録されている顧客を、生年月日の古い順（年齢の高い順。同日なら customer_id 順）に20件ずつページ分けしたとき、2ページ目（21〜40件目）を取得せよ。
-- 出力: customer_id, name, birth_date
-- ヒント: 生年月日が NULL の顧客を先に除いてからページ分けする。
-- 解説: SQLite では昇順に並べると NULL が先頭に来るので、除き忘れると NULL の顧客がページを埋めてしまう（PostgreSQL では逆に末尾）。
SELECT customer_id, name, birth_date
FROM customers
WHERE birth_date IS NOT NULL
ORDER BY birth_date, customer_id
LIMIT 20 OFFSET 20;
