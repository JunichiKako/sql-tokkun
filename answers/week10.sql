-- # Week 10: データ更新（DML）とテーブル定義（DDL）

-- ## Day 1: INSERT

-- [W10-D1-1] ★
-- 問: 最上位カテゴリとして、category_id = 22・名前 '文房具' を追加せよ。
-- 確認: SELECT category_id, name, parent_id FROM categories WHERE category_id = 22
INSERT INTO categories (category_id, name, parent_id)
VALUES (22, '文房具', NULL);

-- [W10-D1-2] ★★
-- 問: テーブル vip_customers（customer_id: 整数・主キー、name: 文字列・NOT NULL、total: 整数・NOT NULL）を作成し、completed の購入総額が 300,000 円以上の顧客を INSERT ... SELECT で登録せよ。
-- 確認: SELECT customer_id, name, total FROM vip_customers ORDER BY customer_id
CREATE TABLE vip_customers (
  customer_id INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  total       INTEGER NOT NULL
);

INSERT INTO vip_customers (customer_id, name, total)
SELECT c.customer_id, c.name, SUM(oi.quantity * oi.unit_price)
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name
HAVING SUM(oi.quantity * oi.unit_price) >= 300000;

-- [W10-D1-3] ★★
-- 問: 1つの INSERT 文で、次の2商品を追加せよ。(901, 'ペーパーフィルター 100枚', カテゴリ 19, 価格 480, 原価 200, 発売日 2026-01-10) と (902, 'コーヒーミル 手挽き', カテゴリ 5, 価格 5480, 原価 2600, 発売日 2026-01-10)。is_discontinued は指定せず、デフォルト値に任せること。
-- 確認: SELECT product_id, name, category_id, price, cost, released_on, is_discontinued FROM products WHERE product_id >= 900 ORDER BY product_id
INSERT INTO products (product_id, name, category_id, price, cost, released_on)
VALUES (901, 'ペーパーフィルター 100枚', 19, 480, 200, '2026-01-10'),
       (902, 'コーヒーミル 手挽き', 5, 5480, 2600, '2026-01-10');

-- ## Day 1 定着: INSERT

-- [W10-D1-R1] ★
-- 問: 部署として、department_id = 7・名前 '品質保証部'・所在地 '大阪府' を追加せよ。
-- 確認: SELECT department_id, name, location FROM departments ORDER BY department_id
INSERT INTO departments (department_id, name, location)
VALUES (7, '品質保証部', '大阪府');

-- [W10-D1-R2] ★★
-- 問: テーブル inactive_customers（customer_id: 整数・主キー、name: 文字列・NOT NULL）を作成し、一度も注文したことがない顧客（ステータスは問わない）を INSERT ... SELECT で登録せよ。
-- 確認: SELECT customer_id, name FROM inactive_customers ORDER BY customer_id
CREATE TABLE inactive_customers (
  customer_id INTEGER PRIMARY KEY,
  name        TEXT NOT NULL
);

INSERT INTO inactive_customers (customer_id, name)
SELECT c.customer_id, c.name
FROM customers c
WHERE NOT EXISTS (
        SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
      );

-- [W10-D1-R3] ★★
-- 問: 1つの INSERT 文で、次の2人の社員を追加せよ。(41, '新井 翔', 部署 3, 上司 8, '一般社員', 年収 4,000,000, 入社日 2026-04-01) と (42, '上野 舞', 部署 5, 上司 11, '一般社員', 年収 3,800,000, 入社日 2026-04-01)。
-- 確認: SELECT employee_id, name, department_id, manager_id, job_title, salary, hired_on FROM employees WHERE employee_id > 40 ORDER BY employee_id
INSERT INTO employees (employee_id, name, department_id, manager_id, job_title, salary, hired_on)
VALUES (41, '新井 翔', 3, 8, '一般社員', 4000000, '2026-04-01'),
       (42, '上野 舞', 5, 11, '一般社員', 3800000, '2026-04-01');

-- ## Day 2: UPDATE

-- [W10-D2-1] ★
-- 問: 商品ID 5 の価格を 10% 値上げせよ（四捨五入して整数にする）。
-- 確認: SELECT product_id, price FROM products WHERE product_id = 5
-- 解説: UPDATE / DELETE は必ず WHERE を確認してから実行する。先に同じ WHERE で SELECT して対象行を見るのが安全。
UPDATE products
SET price = CAST(ROUND(price * 1.1) AS INTEGER)
WHERE product_id = 5;

-- [W10-D2-2] ★★
-- 問: 開発部（department_id = 3）の「一般社員」全員の年収を 5% 引き上げよ（四捨五入して整数にする）。
-- 確認: SELECT employee_id, salary FROM employees WHERE department_id = 3 ORDER BY employee_id
UPDATE employees
SET salary = CAST(ROUND(salary * 1.05) AS INTEGER)
WHERE department_id = 3
  AND job_title = '一般社員';

-- [W10-D2-3] ★★★
-- 問: 一度も注文されたことがない商品（ステータスは問わない）を、すべて販売終了（is_discontinued = 1）にせよ。
-- 確認: SELECT product_id FROM products WHERE is_discontinued = 1 ORDER BY product_id
UPDATE products
SET is_discontinued = 1
WHERE NOT EXISTS (
        SELECT 1
        FROM order_items oi
        WHERE oi.product_id = products.product_id
      );

-- ## Day 2 定着: UPDATE

-- [W10-D2-R1] ★
-- 問: 社員ID 12 の役職を '課長' に変更せよ。
-- 確認: SELECT employee_id, job_title FROM employees ORDER BY employee_id
-- 解説: 確認クエリは全社員を見ているので、WHERE を書き忘れて全員が課長になると不正解になる。
UPDATE employees
SET job_title = '課長'
WHERE employee_id = 12;

-- [W10-D2-R2] ★★
-- 問: カテゴリID 16（コミック）の全商品を 10% 値下げせよ（四捨五入して整数にする）。
-- 確認: SELECT product_id, price FROM products ORDER BY product_id
UPDATE products
SET price = CAST(ROUND(price * 0.9) AS INTEGER)
WHERE category_id = 16;

-- [W10-D2-R3] ★★★
-- 問: 2025年に completed の注文で一度も売れなかった商品を、すべて販売終了（is_discontinued = 1）にせよ。
-- 確認: SELECT product_id FROM products WHERE is_discontinued = 1 ORDER BY product_id
UPDATE products
SET is_discontinued = 1
WHERE NOT EXISTS (
        SELECT 1
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE oi.product_id = products.product_id
          AND o.status = 'completed'
          AND o.ordered_at >= '2025-01-01' AND o.ordered_at < '2026-01-01'
      );

-- ## Day 3: DELETE と UPSERT

-- [W10-D3-1] ★★
-- 問: コメントがなく（NULL）、評価が 3 のレビューを削除せよ。
-- 確認: SELECT COUNT(*), SUM(rating) FROM reviews
DELETE FROM reviews
WHERE comment IS NULL AND rating = 3;

-- [W10-D3-2] ★★★
-- 問: キャンセルされた注文（cancelled）に紐づく注文明細をすべて削除せよ。
-- 確認: SELECT COUNT(*), SUM(quantity) FROM order_items
DELETE FROM order_items
WHERE order_id IN (
        SELECT order_id
        FROM orders
        WHERE status = 'cancelled'
      );

-- [W10-D3-3] ★★★
-- 問: テーブル product_stock（product_id: 整数・主キー、stock: 整数・NOT NULL）を作成し、初期データとして (1, 10) と (2, 5) を登録せよ。続けて、入荷データ (2, 3) と (3, 7) を「すでに行があれば stock に加算、なければ新規登録」する1つの文で反映せよ。
-- 確認: SELECT product_id, stock FROM product_stock ORDER BY product_id
-- ヒント: INSERT ... ON CONFLICT (product_id) DO UPDATE SET ...。挿入しようとした値は excluded.列名 で参照できる。
-- 解説: SQLite と PostgreSQL は同じ構文。MySQL は INSERT ... ON DUPLICATE KEY UPDATE、標準 SQL は MERGE。
CREATE TABLE product_stock (
  product_id INTEGER PRIMARY KEY,
  stock      INTEGER NOT NULL
);

INSERT INTO product_stock (product_id, stock) VALUES (1, 10), (2, 5);

INSERT INTO product_stock (product_id, stock)
VALUES (2, 3), (3, 7)
ON CONFLICT (product_id) DO UPDATE SET stock = stock + excluded.stock;

-- ## Day 3 定着: DELETE と UPSERT

-- [W10-D3-R1] ★★
-- 問: ゲスト（customer_id が NULL）のアクセスログをすべて削除せよ。
-- 確認: SELECT COUNT(*), COUNT(customer_id) FROM access_logs
-- 解説: `customer_id = NULL` と書くと1件も消えない。NULL の判定は IS NULL。
DELETE FROM access_logs
WHERE customer_id IS NULL;

-- [W10-D3-R2] ★★★
-- 問: 販売終了した商品（is_discontinued = 1）に付いたレビューをすべて削除せよ。
-- 確認: SELECT COUNT(*), SUM(rating) FROM reviews
DELETE FROM reviews
WHERE product_id IN (
        SELECT product_id
        FROM products
        WHERE is_discontinued = 1
      );

-- [W10-D3-R3] ★★★
-- 問: テーブル daily_visits（day: 文字列・主キー、visits: 整数・NOT NULL）を作成し、初期データとして ('2025-12-01', 10) を登録せよ。続けて、('2025-12-01', 4) と ('2025-12-02', 6) を「すでに行があれば visits に加算、なければ新規登録」する1つの文で反映せよ。
-- 確認: SELECT day, visits FROM daily_visits ORDER BY day
CREATE TABLE daily_visits (
  day    TEXT PRIMARY KEY,
  visits INTEGER NOT NULL
);

INSERT INTO daily_visits (day, visits) VALUES ('2025-12-01', 10);

INSERT INTO daily_visits (day, visits)
VALUES ('2025-12-01', 4), ('2025-12-02', 6)
ON CONFLICT (day) DO UPDATE SET visits = visits + excluded.visits;

-- ## Day 4: テーブル定義・制約・ビュー

-- [W10-D4-1] ★★
-- 問: クーポンのマスタテーブル coupons を作成せよ。列は code（文字列・主キー）、discount_rate（整数・NOT NULL・1〜50 の範囲のみ許可する CHECK 制約）、valid_until（文字列・NULL 可）。作成後、('WELCOME10', 10, NULL)、('SUMMER25', 15, '2025-08-31')、('WINTER25', 15, '2025-12-31')、('VIP15', 15, NULL) を登録せよ。
-- 確認: SELECT code, discount_rate, valid_until FROM coupons ORDER BY code
-- 解説: 制約が効いているかは、discount_rate = 80 の行を INSERT してエラーになることで自分で確かめておくこと。
CREATE TABLE coupons (
  code          TEXT PRIMARY KEY,
  discount_rate INTEGER NOT NULL CHECK (discount_rate BETWEEN 1 AND 50),
  valid_until   TEXT
);

INSERT INTO coupons (code, discount_rate, valid_until)
VALUES ('WELCOME10', 10, NULL),
       ('SUMMER25', 15, '2025-08-31'),
       ('WINTER25', 15, '2025-12-31'),
       ('VIP15', 15, NULL);

-- [W10-D4-2] ★★
-- 問: 注文ごとの合計金額を見られるビュー v_order_totals を作成せよ。列は order_id, customer_id, ordered_at, status, total（明細の 数量 × 単価 の合計）。
-- 確認: SELECT order_id, customer_id, ordered_at, status, total FROM v_order_totals WHERE order_id <= 20 ORDER BY order_id
CREATE VIEW v_order_totals AS
SELECT o.order_id, o.customer_id, o.ordered_at, o.status,
       SUM(oi.quantity * oi.unit_price) AS total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.customer_id, o.ordered_at, o.status;

-- [W10-D4-3] ★★★
-- 問: customers テーブルに会員ランクの列 tier（文字列・NOT NULL・デフォルト 'regular'）を追加し、completed の購入総額が 200,000 円以上の顧客を 'gold'、50,000 円以上 200,000 円未満の顧客を 'silver' に更新せよ。
-- 確認: SELECT tier, COUNT(*) FROM customers GROUP BY tier ORDER BY tier
-- ヒント: 相関サブクエリで顧客ごとの購入総額を求め、CASE で振り分ける。GROUP BY のない集約は、対象行が0件でも必ず1行返す。
ALTER TABLE customers ADD COLUMN tier TEXT NOT NULL DEFAULT 'regular';

UPDATE customers
SET tier = (
  SELECT CASE WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) >= 200000 THEN 'gold'
              WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) >= 50000 THEN 'silver'
              ELSE 'regular' END
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.customer_id = customers.customer_id
    AND o.status = 'completed'
);

-- ## Day 4 定着: テーブル定義・制約・ビュー

-- [W10-D4-R1] ★★
-- 問: 店舗テーブル shops を作成せよ。列は shop_id（整数・主キー）、name（文字列・NOT NULL・重複不可）、prefecture（文字列・NOT NULL）、opened_on（文字列・NULL 可）。作成後、(1, '渋谷店', '東京都', '2024-04-01')、(2, '梅田店', '大阪府', '2024-10-01')、(3, '天神店', '福岡県', NULL) を登録せよ。
-- 確認: SELECT shop_id, name, prefecture, opened_on FROM shops ORDER BY shop_id
-- 解説: 重複不可は UNIQUE 制約。同じ name の行を INSERT してエラーになることを自分で確かめておくこと。
CREATE TABLE shops (
  shop_id    INTEGER PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,
  prefecture TEXT NOT NULL,
  opened_on  TEXT
);

INSERT INTO shops (shop_id, name, prefecture, opened_on)
VALUES (1, '渋谷店', '東京都', '2024-04-01'),
       (2, '梅田店', '大阪府', '2024-10-01'),
       (3, '天神店', '福岡県', NULL);

-- [W10-D4-R2] ★★
-- 問: 商品ごとの completed の販売実績を見られるビュー v_product_sales を作成せよ。列は product_id, name, qty（販売数量の合計）, sales（売上）。completed で一度も売れていない商品は含めなくてよい。
-- 確認: SELECT product_id, name, qty, sales FROM v_product_sales ORDER BY product_id
CREATE VIEW v_product_sales AS
SELECT p.product_id, p.name,
       SUM(oi.quantity) AS qty,
       SUM(oi.quantity * oi.unit_price) AS sales
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY p.product_id, p.name;

-- [W10-D4-R3] ★★★
-- 問: products テーブルに平均評価の列 rating_avg（実数・NULL 可）を追加し、各商品のレビューの平均評価（小数第2位まで）で更新せよ。レビューがない商品は NULL のままにすること。
-- 確認: SELECT product_id, rating_avg FROM products ORDER BY product_id
ALTER TABLE products ADD COLUMN rating_avg REAL;

UPDATE products
SET rating_avg = (
  SELECT ROUND(AVG(r.rating), 2)
  FROM reviews r
  WHERE r.product_id = products.product_id
);

-- ## Day 5: トランザクションと総合演習

-- [W10-D5-1] ★★
-- 問: 新しい注文を1件、トランザクションで登録せよ。注文: order_id 9001、顧客 1、日時 '2026-01-05 10:00:00'、ステータス 'pending'、支払方法 'credit_card'、クーポンなし、送料 0。明細: 商品 1 を 2 個、商品 2 を 1 個。単価は products テーブルの現在の price をそのまま使うこと（値を直書きしない）。
-- 確認: SELECT o.order_id, o.customer_id, o.status, oi.product_id, oi.quantity, oi.unit_price FROM orders o JOIN order_items oi ON oi.order_id = o.order_id WHERE o.order_id = 9001 ORDER BY oi.product_id
-- 解説: 注文と明細は「両方入るか、どちらも入らないか」でないと不整合になる。途中で失敗したら ROLLBACK する。
BEGIN;

INSERT INTO orders (order_id, customer_id, ordered_at, status, payment_method, coupon_code, shipping_fee)
VALUES (9001, 1, '2026-01-05 10:00:00', 'pending', 'credit_card', NULL, 0);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 9001, product_id, CASE product_id WHEN 1 THEN 2 ELSE 1 END, price
FROM products
WHERE product_id IN (1, 2);

COMMIT;

-- [W10-D5-2] ★★★
-- 問: 月次サマリテーブル monthly_sales（ym: 文字列・主キー、orders: 整数、sales: 整数）を作成し、completed の注文について月（'YYYY-MM'）ごとの注文件数と売上を登録せよ。
-- 確認: SELECT ym, orders, sales FROM monthly_sales ORDER BY ym
CREATE TABLE monthly_sales (
  ym     TEXT PRIMARY KEY,
  orders INTEGER NOT NULL,
  sales  INTEGER NOT NULL
);

INSERT INTO monthly_sales (ym, orders, sales)
SELECT strftime('%Y-%m', o.ordered_at) AS ym,
       COUNT(DISTINCT o.order_id),
       SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY ym;

-- [W10-D5-3] ★★★
-- 問: 価格改定の履歴テーブル price_history（product_id, old_price, new_price, changed_at）を作成し、カテゴリID 19（コーヒー豆）の全商品を 100 円値上げせよ。値上げと同時に、変更前後の価格を changed_at = '2026-01-01' で履歴に記録すること。履歴の記録と値上げは1つのトランザクションで行う。
-- 確認: SELECT p.product_id, p.price, h.old_price, h.new_price, h.changed_at FROM products p JOIN price_history h ON h.product_id = p.product_id ORDER BY p.product_id
-- ヒント: 先に UPDATE してしまうと変更前の価格が分からなくなる。順番に注意。
CREATE TABLE price_history (
  product_id INTEGER NOT NULL REFERENCES products(product_id),
  old_price  INTEGER NOT NULL,
  new_price  INTEGER NOT NULL,
  changed_at TEXT NOT NULL
);

BEGIN;

INSERT INTO price_history (product_id, old_price, new_price, changed_at)
SELECT product_id, price, price + 100, '2026-01-01'
FROM products
WHERE category_id = 19;

UPDATE products
SET price = price + 100
WHERE category_id = 19;

COMMIT;

-- ## Day 5 定着: トランザクションと総合演習

-- [W10-D5-R1] ★★
-- 問: 新規顧客の登録と初回注文を、1つのトランザクションで行え。顧客: customer_id 201、氏名 '新井 太郎'、メール 'arai201@example.com'、性別 'M'、生年月日 NULL、'東京都'、登録日時 '2026-01-02 09:00:00'、紹介者 1。注文: order_id 9002、日時 '2026-01-02 10:00:00'、ステータス 'pending'、支払方法 'e_money'、クーポン 'WELCOME10'、送料 550。明細: 商品 55 を 3 個。単価は products テーブルの現在の price を使うこと（値を直書きしない）。
-- 確認: SELECT c.customer_id, c.referrer_id, o.order_id, o.coupon_code, oi.product_id, oi.quantity, oi.unit_price FROM customers c JOIN orders o ON o.customer_id = c.customer_id JOIN order_items oi ON oi.order_id = o.order_id WHERE c.customer_id = 201
BEGIN;

INSERT INTO customers (customer_id, name, email, gender, birth_date, prefecture, registered_at, referrer_id)
VALUES (201, '新井 太郎', 'arai201@example.com', 'M', NULL, '東京都', '2026-01-02 09:00:00', 1);

INSERT INTO orders (order_id, customer_id, ordered_at, status, payment_method, coupon_code, shipping_fee)
VALUES (9002, 201, '2026-01-02 10:00:00', 'pending', 'e_money', 'WELCOME10', 550);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 9002, product_id, 3, price
FROM products
WHERE product_id = 55;

COMMIT;

-- [W10-D5-R2] ★★★
-- 問: 商品別サマリテーブル product_summary（product_id: 整数・主キー、orders: 整数、qty: 整数、sales: 整数）を作成し、completed の注文について商品ごとの「その商品を含む注文の数」「販売数量」「売上」を登録せよ（completed で売れた商品のみ）。
-- 確認: SELECT product_id, orders, qty, sales FROM product_summary ORDER BY product_id
CREATE TABLE product_summary (
  product_id INTEGER PRIMARY KEY,
  orders     INTEGER NOT NULL,
  qty        INTEGER NOT NULL,
  sales      INTEGER NOT NULL
);

INSERT INTO product_summary (product_id, orders, qty, sales)
SELECT oi.product_id,
       COUNT(DISTINCT oi.order_id),
       SUM(oi.quantity),
       SUM(oi.quantity * oi.unit_price)
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY oi.product_id;

-- [W10-D5-R3] ★★★
-- 問: 年収改定の履歴テーブル salary_history（employee_id, old_salary, new_salary, changed_at）を作成し、マーケティング部（department_id = 4）の全社員の年収を 200,000 円引き上げよ。引き上げと同時に、変更前後の年収を changed_at = '2026-04-01' で履歴に記録すること。履歴の記録と引き上げは1つのトランザクションで行う。
-- 確認: SELECT e.employee_id, e.salary, h.old_salary, h.new_salary, h.changed_at FROM employees e JOIN salary_history h ON h.employee_id = e.employee_id ORDER BY e.employee_id
CREATE TABLE salary_history (
  employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
  old_salary  INTEGER NOT NULL,
  new_salary  INTEGER NOT NULL,
  changed_at  TEXT NOT NULL
);

BEGIN;

INSERT INTO salary_history (employee_id, old_salary, new_salary, changed_at)
SELECT employee_id, salary, salary + 200000, '2026-04-01'
FROM employees
WHERE department_id = 4;

UPDATE employees
SET salary = salary + 200000
WHERE department_id = 4;

COMMIT;
