-- # Week 1 復習: SELECT の基礎（総復習）

-- ## 復習 Day 1: 並び替え・日時の範囲・割り算

-- [W01-X1-1] ★ ordered
-- 問: 発売日の新しい順（同じ日なら product_id 順）に、商品を5件取得せよ。
-- 出力: product_id, name, released_on
SELECT product_id, name, released_on
FROM products
ORDER BY released_on DESC, product_id
LIMIT 5;

-- [W01-X1-2] ★
-- 問: 2025年12月25日に行われた注文を取得せよ（ステータスは問わない）。
-- 出力: order_id, ordered_at
-- ヒント: ordered_at は時刻付き。「その日1日」は「その日以上、翌日未満」。
SELECT order_id, ordered_at
FROM orders
WHERE ordered_at >= '2025-12-25' AND ordered_at < '2025-12-26';

-- [W01-X1-3] ★★
-- 問: 全商品について、原価率（cost ÷ price の百分率、小数第1位まで）を求めよ。
-- 出力: product_id, name, cost_rate
SELECT product_id, name,
       ROUND(cost * 100.0 / price, 1) AS cost_rate
FROM products;

-- ## 復習 Day 2: LIKE・NULL の否定・CASE

-- [W01-X2-1] ★
-- 問: メールアドレスのドメインが example.jp の顧客を取得せよ（@ の後ろがちょうど example.jp のもの。大文字・小文字の違いは区別しない）。
-- 出力: customer_id, email
-- 解説: '%example.jp' だと、@ の前に example.jp を含むアドレスまで拾う可能性がある。@ まで含めて書くと「ドメインが」の意味に正確になる。SQLite の LIKE は英字の大文字・小文字を区別しないので、大文字のアドレスも拾える。
SELECT customer_id, email
FROM customers
WHERE email LIKE '%@example.jp';

-- [W01-X2-2] ★★
-- 問: 紹介者が顧客ID 1 ではない顧客の数を求めよ。誰にも紹介されていない（referrer_id が NULL の）顧客も当然含む。
-- 出力: cnt
SELECT COUNT(*) AS cnt
FROM customers
WHERE referrer_id <> 1 OR referrer_id IS NULL;

-- [W01-X2-3] ★★
-- 問: 全社員について、役職の英語表記を求めよ。'代表取締役'→'CEO'、'部長'→'Manager'、'課長'→'Leader'、それ以外→'Staff'。
-- 出力: employee_id, name, title_en
SELECT employee_id, name,
       CASE job_title
         WHEN '代表取締役' THEN 'CEO'
         WHEN '部長' THEN 'Manager'
         WHEN '課長' THEN 'Leader'
         ELSE 'Staff'
       END AS title_en
FROM employees;

-- ## 復習 Day 3: 複数条件・LIKE の OR・計算した値で分類

-- [W01-X3-1] ★★ ordered
-- 問: 2024年7月の注文のうち、送料が 550 円かかった注文を、注文日時の古い順（同時刻なら order_id 順）に取得せよ（ステータスは問わない）。
-- 出力: order_id, ordered_at, shipping_fee
SELECT order_id, ordered_at, shipping_fee
FROM orders
WHERE ordered_at >= '2024-07-01' AND ordered_at < '2024-08-01'
  AND shipping_fee = 550
ORDER BY ordered_at, order_id;

-- [W01-X3-2] ★★
-- 問: 商品名に「ニット」または「シャツ」を含む商品を取得せよ。
-- 出力: product_id, name
SELECT product_id, name
FROM products
WHERE name LIKE '%ニット%' OR name LIKE '%シャツ%';

-- [W01-X3-3] ★★
-- 問: 全注文明細について、金額（quantity × unit_price）と、金額の大きさの区分を求めよ。区分は 3,000円未満なら '小'、3,000円以上10,000円未満なら '中'、10,000円以上なら '大'。
-- 出力: order_item_id, amount, size
SELECT order_item_id,
       quantity * unit_price AS amount,
       CASE WHEN quantity * unit_price < 3000 THEN '小'
            WHEN quantity * unit_price < 10000 THEN '中'
            ELSE '大' END AS size
FROM order_items;

-- ## 復習 Day 4: NULL の判定・COALESCE・計算した値で絞り込む

-- [W01-X4-1] ★★ ordered
-- 問: 2025年に投稿された、評価が 5 でコメントのないレビューを、投稿日時の古い順（同時刻なら review_id 順）に10件取得せよ。
-- 出力: review_id, created_at
SELECT review_id, created_at
FROM reviews
WHERE rating = 5
  AND comment IS NULL
  AND created_at >= '2025-01-01' AND created_at < '2026-01-01'
ORDER BY created_at, review_id
LIMIT 10;

-- [W01-X4-2] ★★
-- 問: 性別が登録されていない（NULL の）顧客について、連絡先（メールアドレス。NULL なら '未登録'）を取得せよ。
-- 出力: customer_id, name, contact
SELECT customer_id, name,
       COALESCE(email, '未登録') AS contact
FROM customers
WHERE gender IS NULL;

-- [W01-X4-3] ★★★ ordered
-- 問: 粗利（price − cost）が 5,000 円以上、かつ粗利率（粗利 ÷ price の百分率）が 50 以上の商品を、粗利率の高い順（同率なら product_id 順）に取得せよ。粗利率は小数第1位まで表示するが、50 以上かどうかは丸める前の値で判定すること。
-- 出力: product_id, name, margin, margin_rate
-- ヒント: SELECT で付けた別名（AS）は、標準 SQL では WHERE で使えない。WHERE には計算式をもう一度書く。
SELECT product_id, name,
       price - cost AS margin,
       ROUND((price - cost) * 100.0 / price, 1) AS margin_rate
FROM products
WHERE price - cost >= 5000
  AND (price - cost) * 100.0 / price >= 50
ORDER BY margin_rate DESC, product_id;

-- ## 復習 Day 5: 条件の組み立て・日付の範囲・CASE と LIKE

-- [W01-X5-1] ★★
-- 問: 2025年1月〜6月の注文のうち、支払方法が credit_card 以外で、クーポンを使った注文の件数を求めよ（ステータスは問わない）。
-- 出力: cnt
SELECT COUNT(*) AS cnt
FROM orders
WHERE ordered_at >= '2025-01-01' AND ordered_at < '2025-07-01'
  AND payment_method <> 'credit_card'
  AND coupon_code IS NOT NULL;

-- [W01-X5-2] ★★ ordered
-- 問: 2023年に会員登録した顧客のうち、1990年代（1990年1月1日〜1999年12月31日）生まれの顧客を、登録日時の古い順に取得せよ。
-- 出力: customer_id, name, birth_date, registered_at
SELECT customer_id, name, birth_date, registered_at
FROM customers
WHERE registered_at >= '2023-01-01' AND registered_at < '2024-01-01'
  AND birth_date >= '1990-01-01' AND birth_date < '2000-01-01'
ORDER BY registered_at;

-- [W01-X5-3] ★★★
-- 問: 2025年12月31日のアクセスログ（ゲストも含む）について、ページの種類を求めよ。path が '/' なら 'トップ'、'/products' なら '一覧'、'/products/' で始まるもの（商品詳細）なら '商品詳細'、それ以外（'/cart'・'/checkout'・'/complete'）は '購入フロー'。
-- 出力: log_id, path, page_type
-- ヒント: CASE の WHEN にも LIKE が書ける。'/products' と '/products/...' の判定の順番に注意。
SELECT log_id, path,
       CASE WHEN path = '/' THEN 'トップ'
            WHEN path = '/products' THEN '一覧'
            WHEN path LIKE '/products/%' THEN '商品詳細'
            ELSE '購入フロー' END AS page_type
FROM access_logs
WHERE accessed_at >= '2025-12-31' AND accessed_at < '2026-01-01';

-- ## 復習 Day 6: 組み合わせ問題

-- [W01-X6-1] ★★★ ordered
-- 問: 社員の月給（年収 ÷ 12 を四捨五入した整数）が 50万円以上の社員を、月給の高い順（同額なら employee_id 順）に上位5人取得せよ。月給の判定も、四捨五入した整数で行うこと。
-- 出力: name, monthly
SELECT name,
       CAST(ROUND(salary / 12.0) AS INTEGER) AS monthly
FROM employees
WHERE ROUND(salary / 12.0) >= 500000
ORDER BY monthly DESC, employee_id
LIMIT 5;

-- [W01-X6-2] ★★★
-- 問: 評価が 4 以上のレビューのうち、コメントに「です」を含まないもの（コメントのないレビューも含む）の件数を求めよ。
-- 出力: cnt
-- ヒント: AND と OR を混ぜるときは括弧が必要。括弧がないと AND が先に結び付く。
-- 解説: `rating >= 4 AND comment NOT LIKE '%です%' OR comment IS NULL` と書くと、「(評価4以上 かつ です を含まない) または コメントなし」になり、評価の低いコメントなしレビューまで数えてしまう。
SELECT COUNT(*) AS cnt
FROM reviews
WHERE rating >= 4
  AND (comment NOT LIKE '%です%' OR comment IS NULL);

-- [W01-X6-3] ★★★ ordered
-- 問: 販売中の商品を発売日の新しい順（同じ日なら product_id 順）に並べ、8件ずつページ分けしたとき、3ページ目を取得せよ。
-- 出力: product_id, name, released_on
SELECT product_id, name, released_on
FROM products
WHERE is_discontinued = 0
ORDER BY released_on DESC, product_id
LIMIT 8 OFFSET 16;

-- ## 復習 Day 7: 総仕上げ

-- [W01-X7-1] ★★★
-- 問: 2025年12月24日の注文（ステータスは問わない）について、ステータスの日本語表記（'completed'→'完了'、'shipped'→'発送済'、'pending'→'保留'、'cancelled'→'キャンセル'）と、使ったクーポン（使っていなければ 'なし'）を求めよ。
-- 出力: order_id, status_label, coupon
SELECT order_id,
       CASE status
         WHEN 'completed' THEN '完了'
         WHEN 'shipped' THEN '発送済'
         WHEN 'pending' THEN '保留'
         ELSE 'キャンセル'
       END AS status_label,
       COALESCE(coupon_code, 'なし') AS coupon
FROM orders
WHERE ordered_at >= '2025-12-24' AND ordered_at < '2025-12-25';

-- [W01-X7-2] ★★★
-- 問: 東京都以外に住んでいて、メールアドレスが登録されていて、性別が女性ではない顧客（性別が NULL の顧客も含む）の数を求めよ。
-- 出力: cnt
SELECT COUNT(*) AS cnt
FROM customers
WHERE prefecture <> '東京都'
  AND email IS NOT NULL
  AND (gender <> 'F' OR gender IS NULL);

-- [W01-X7-3] ★★★ ordered
-- 問: 注文明細のうち、税込金額（quantity × unit_price の 1.1 倍を四捨五入した整数）が 30,000 円以上のものを、税込金額の高い順（同額なら order_item_id 順）に並べ、11〜20件目を取得せよ。
-- 出力: order_item_id, quantity, unit_price, amount_with_tax
SELECT order_item_id, quantity, unit_price,
       CAST(ROUND(quantity * unit_price * 1.1) AS INTEGER) AS amount_with_tax
FROM order_items
WHERE ROUND(quantity * unit_price * 1.1) >= 30000
ORDER BY amount_with_tax DESC, order_item_id
LIMIT 10 OFFSET 10;
