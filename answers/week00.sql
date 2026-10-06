-- # Week 0: 答え方の練習（見本つき）

-- ## 練習: 採点の流れをつかむ

-- [W00-D1-1] ★ ordered
-- 問: 東京都に住む顧客を、customer_id の小さい順に取得せよ。
-- 出力: customer_id, name
SELECT customer_id, name
FROM customers
WHERE prefecture = '東京都'
ORDER BY customer_id;

-- [W00-D1-2] ★
-- 問: 支払方法ごとの注文件数を求めよ。
-- 出力: payment_method, cnt
SELECT payment_method, COUNT(*) AS cnt
FROM orders
GROUP BY payment_method;

-- [W00-D1-3] ★
-- 問: 商品ID 1 の価格を 5,000 円に変更せよ。
-- 確認: SELECT product_id, price FROM products WHERE product_id = 1
UPDATE products
SET price = 5000
WHERE product_id = 1;
