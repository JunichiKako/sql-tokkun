-- 特訓用DBのスキーマ（架空のECサイト + 運営会社の社員情報）
-- 日時はすべて TEXT（'YYYY-MM-DD HH:MM:SS' または 'YYYY-MM-DD'）で持つ。
-- インデックスは主キー以外わざと張っていない（Week 11 で自分で張る）。

CREATE TABLE departments (
  department_id INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,
  location      TEXT NOT NULL            -- 都道府県
);

CREATE TABLE employees (
  employee_id   INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,
  department_id INTEGER REFERENCES departments(department_id),  -- 未配属は NULL
  manager_id    INTEGER REFERENCES employees(employee_id),      -- 上司。社長は NULL
  job_title     TEXT NOT NULL,
  salary        INTEGER NOT NULL,        -- 年収（円）
  hired_on      TEXT NOT NULL            -- 入社日
);

CREATE TABLE customers (
  customer_id   INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,           -- '姓 名'（半角スペース区切り）
  email         TEXT,                    -- NULL あり / 大文字混じりあり / 重複あり
  gender        TEXT,                    -- 'M' / 'F' / NULL
  birth_date    TEXT,                    -- NULL あり
  prefecture    TEXT NOT NULL,
  registered_at TEXT NOT NULL,
  referrer_id   INTEGER REFERENCES customers(customer_id)       -- 紹介してくれた顧客
);

CREATE TABLE categories (
  category_id   INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,
  parent_id     INTEGER REFERENCES categories(category_id)      -- 最上位は NULL（最大3階層）
);

CREATE TABLE products (
  product_id      INTEGER PRIMARY KEY,
  name            TEXT NOT NULL,
  category_id     INTEGER NOT NULL REFERENCES categories(category_id),
  price           INTEGER NOT NULL,      -- 現在の定価
  cost            INTEGER NOT NULL,      -- 原価
  released_on     TEXT NOT NULL,
  is_discontinued INTEGER NOT NULL DEFAULT 0   -- 1 = 販売終了
);

CREATE TABLE orders (
  order_id       INTEGER PRIMARY KEY,
  customer_id    INTEGER NOT NULL REFERENCES customers(customer_id),
  ordered_at     TEXT NOT NULL,
  status         TEXT NOT NULL,          -- 'completed' / 'shipped' / 'pending' / 'cancelled'
  payment_method TEXT NOT NULL,          -- 'credit_card' / 'e_money' / 'convenience_store' / 'bank_transfer' / 'cod'
  coupon_code    TEXT,                   -- 未使用は NULL
  shipping_fee   INTEGER NOT NULL
);

CREATE TABLE order_items (
  order_item_id INTEGER PRIMARY KEY,
  order_id      INTEGER NOT NULL REFERENCES orders(order_id),
  product_id    INTEGER NOT NULL REFERENCES products(product_id),
  quantity      INTEGER NOT NULL,
  unit_price    INTEGER NOT NULL         -- 購入時の単価（セールで定価と異なることがある）
);

CREATE TABLE reviews (
  review_id   INTEGER PRIMARY KEY,
  product_id  INTEGER NOT NULL REFERENCES products(product_id),
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  rating      INTEGER NOT NULL,          -- 1〜5
  comment     TEXT,                      -- NULL あり
  created_at  TEXT NOT NULL
);

CREATE TABLE access_logs (
  log_id      INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(customer_id),        -- 未ログイン（ゲスト）は NULL
  path        TEXT NOT NULL,             -- '/', '/products', '/products/{product_id}', '/cart', '/checkout', '/complete'
  device      TEXT NOT NULL,             -- 'pc' / 'mobile' / 'tablet'
  accessed_at TEXT NOT NULL
);
