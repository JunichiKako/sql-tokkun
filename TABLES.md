# テーブル一覧

特訓用データベース `tokkun.db` の全テーブル。このファイルは `python3 setup/build_tables_md.py` で実データから生成している。

## 全体のつながり

```
customers ─< orders ─< order_items >─ products >─ categories（parent_id で親子）
    │                                     │
    ├─< reviews >──────────────────────────┘
    ├─< access_logs
    └─ referrer_id（紹介者。customers 同士）

departments ─< employees（manager_id で上司・部下）
```

`A ─< B` は「A の1行に対して B が複数行」（1対多）を表す。JOIN するときの対応は次のとおり。

| 結合するテーブル | 結合条件 |
|---|---|
| orders と customers | `orders.customer_id = customers.customer_id` |
| order_items と orders | `order_items.order_id = orders.order_id` |
| order_items と products | `order_items.product_id = products.product_id` |
| products と categories | `products.category_id = categories.category_id` |
| categories の親子 | `子.parent_id = 親.category_id` |
| reviews と products / customers | `reviews.product_id = products.product_id` / `reviews.customer_id = customers.customer_id` |
| access_logs と customers | `access_logs.customer_id = customers.customer_id` |
| customers と紹介者 | `顧客.referrer_id = 紹介者.customer_id` |
| employees と departments | `employees.department_id = departments.department_id` |
| employees と上司 | `部下.manager_id = 上司.employee_id` |

## 目次

- [customers](#customers) — 顧客（ECサイトの会員）（200 行）
- [categories](#categories) — 商品カテゴリ（親子関係で最大3階層）（21 行）
- [products](#products) — 商品（77 行）
- [orders](#orders) — 注文（1回の買い物で1行）（2,728 行）
- [order_items](#order_items) — 注文明細（1つの注文に含まれる商品ごとに1行）（5,648 行）
- [reviews](#reviews) — 商品レビュー（592 行）
- [access_logs](#access_logs) — サイトのアクセスログ（1ページ閲覧で1行。2025-10-01〜2025-12-31）（7,575 行）
- [departments](#departments) — 運営会社の部署（6 行）
- [employees](#employees) — 運営会社の社員（40 行）

## customers

顧客（ECサイトの会員）。200 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `customer_id` | INTEGER | 主キー。登録が早い順に 1〜200 |
| `name` | TEXT | 氏名。`'姓 名'` の形（半角スペース区切り） |
| `email` | TEXT | メールアドレス。**NULL あり**・大文字混じりあり・二重登録あり |
| `gender` | TEXT | `'M'` / `'F'`。**NULL あり**（不明） |
| `birth_date` | TEXT | 生年月日 `'YYYY-MM-DD'`。**NULL あり** |
| `prefecture` | TEXT | 都道府県 |
| `registered_at` | TEXT | 会員登録日時 `'YYYY-MM-DD HH:MM:SS'` |
| `referrer_id` | INTEGER | 紹介してくれた顧客の customer_id。**紹介なしは NULL** |

先頭 5 行:

| customer_id | name | email | gender | birth_date | prefecture | registered_at | referrer_id |
|---|---|---|---|---|---|---|---|
| 1 | 斎藤 智子 | saito1@example.com | F | 1995-06-23 | 東京都 | 2023-01-01 03:13:44 | NULL |
| 2 | 木村 葵 | kimura2@example.com | F | 1993-03-26 | 埼玉県 | 2023-01-01 21:51:49 | NULL |
| 3 | 岡田 明美 | okada3@example.com | F | 1982-01-29 | 千葉県 | 2023-01-07 04:32:47 | NULL |
| 4 | 岡田 楓 | okada4@mail.example.org | F | 1995-08-30 | 広島県 | 2023-01-07 08:18:15 | NULL |
| 5 | 山田 明美 | yamada5@example.com | F | 1968-01-22 | 東京都 | 2023-01-09 08:10:03 | NULL |

## categories

商品カテゴリ（親子関係で最大3階層）。21 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `category_id` | INTEGER | 主キー |
| `name` | TEXT | カテゴリ名 |
| `parent_id` | INTEGER | 親カテゴリの category_id。**最上位は NULL** |

全データ:

| category_id | name | parent_id |
|---|---|---|
| 1 | 家電 | NULL |
| 2 | 食品 | NULL |
| 3 | ファッション | NULL |
| 4 | 書籍 | NULL |
| 5 | キッチン家電 | 1 |
| 6 | オーディオ | 1 |
| 7 | PC周辺機器 | 1 |
| 8 | コーヒー・お茶 | 2 |
| 9 | お菓子 | 2 |
| 10 | 調味料 | 2 |
| 11 | メンズ | 3 |
| 12 | レディース | 3 |
| 13 | バッグ | 3 |
| 14 | 技術書 | 4 |
| 15 | ビジネス書 | 4 |
| 16 | コミック | 4 |
| 17 | キーボード | 7 |
| 18 | マウス | 7 |
| 19 | コーヒー豆 | 8 |
| 20 | 日本茶 | 8 |
| 21 | 雑誌 | 4 |

## products

商品。77 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `product_id` | INTEGER | 主キー |
| `name` | TEXT | 商品名 |
| `category_id` | INTEGER | 所属カテゴリ → categories |
| `price` | INTEGER | 現在の定価（円） |
| `cost` | INTEGER | 原価（円） |
| `released_on` | TEXT | 発売日 `'YYYY-MM-DD'` |
| `is_discontinued` | INTEGER | `1` = 販売終了、`0` = 販売中 |

先頭 5 行:

| product_id | name | category_id | price | cost | released_on | is_discontinued |
|---|---|---|---|---|---|---|
| 1 | 電気ケトル | 5 | 4980 | 3720 | 2023-11-28 | 0 |
| 2 | コーヒーメーカー | 5 | 12800 | 5180 | 2023-06-16 | 0 |
| 3 | オーブントースター | 5 | 7980 | 5390 | 2024-06-27 | 0 |
| 4 | ハンドブレンダー | 5 | 6480 | 3120 | 2022-02-02 | 1 |
| 5 | 炊飯器 5.5合 | 5 | 24800 | 18150 | 2022-11-15 | 0 |

## orders

注文（1回の買い物で1行）。2,728 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `order_id` | INTEGER | 主キー。注文日時の早い順 |
| `customer_id` | INTEGER | 注文した顧客 → customers |
| `ordered_at` | TEXT | 注文日時 `'YYYY-MM-DD HH:MM:SS'`（2024-01-01〜2025-12-31） |
| `status` | TEXT | 注文の状態（下の値一覧を参照） |
| `payment_method` | TEXT | 支払方法（下の値一覧を参照） |
| `coupon_code` | TEXT | 使ったクーポン。**未使用は NULL** |
| `shipping_fee` | INTEGER | 送料（円）。`0` か `550` |

`status` の値: `completed`（2,282 件）、`cancelled`（305 件）、`shipped`（76 件）、`pending`（65 件）

`payment_method` の値: `credit_card`（1,513 件）、`convenience_store`（402 件）、`bank_transfer`（307 件）、`e_money`（275 件）、`cod`（231 件）

`coupon_code` の値: `NULL`（2,348 件）、`VIP15`（163 件）、`WELCOME10`（102 件）、`SUMMER25`（82 件）、`WINTER25`（33 件）

先頭 5 行:

| order_id | customer_id | ordered_at | status | payment_method | coupon_code | shipping_fee |
|---|---|---|---|---|---|---|
| 1 | 53 | 2024-01-01 12:53:11 | completed | credit_card | WELCOME10 | 0 |
| 2 | 23 | 2024-01-01 20:55:12 | completed | credit_card | NULL | 0 |
| 3 | 40 | 2024-01-01 21:47:47 | cancelled | credit_card | WELCOME10 | 550 |
| 4 | 27 | 2024-01-02 16:13:21 | completed | credit_card | WELCOME10 | 550 |
| 5 | 3 | 2024-01-02 17:04:34 | shipped | bank_transfer | NULL | 550 |

## order_items

注文明細（1つの注文に含まれる商品ごとに1行）。5,648 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `order_item_id` | INTEGER | 主キー |
| `order_id` | INTEGER | どの注文の明細か → orders |
| `product_id` | INTEGER | 買った商品 → products |
| `quantity` | INTEGER | 数量 |
| `unit_price` | INTEGER | 購入時の単価（円）。セール時は products.price より安い |

先頭 5 行:

| order_item_id | order_id | product_id | quantity | unit_price |
|---|---|---|---|---|
| 1 | 1 | 62 | 1 | 5980 |
| 2 | 1 | 27 | 3 | 522 |
| 3 | 2 | 75 | 2 | 980 |
| 4 | 2 | 46 | 2 | 3520 |
| 5 | 3 | 56 | 1 | 550 |

## reviews

商品レビュー。592 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `review_id` | INTEGER | 主キー |
| `product_id` | INTEGER | 対象の商品 → products |
| `customer_id` | INTEGER | 書いた顧客 → customers |
| `rating` | INTEGER | 評価 1〜5 |
| `comment` | TEXT | コメント。**NULL あり**（評価だけのレビュー） |
| `created_at` | TEXT | 投稿日時 |

先頭 5 行:

| review_id | product_id | customer_id | rating | comment | created_at |
|---|---|---|---|---|---|
| 1 | 54 | 54 | 1 | すぐに壊れてしまいました。 | 2024-01-08 10:05:46 |
| 2 | 67 | 60 | 1 | NULL | 2024-01-11 23:10:05 |
| 3 | 49 | 16 | 5 | NULL | 2024-01-19 16:35:33 |
| 4 | 38 | 25 | 5 | 最高です！また買います。 | 2024-01-26 02:14:33 |
| 5 | 12 | 13 | 5 | もっと早く買えばよかった。 | 2024-01-26 16:18:35 |

## access_logs

サイトのアクセスログ（1ページ閲覧で1行。2025-10-01〜2025-12-31）。7,575 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `log_id` | INTEGER | 主キー。アクセス日時の早い順 |
| `customer_id` | INTEGER | アクセスした顧客 → customers。**未ログイン（ゲスト）は NULL** |
| `path` | TEXT | 見たページ。`/`（トップ）、`/products`（一覧）、`/products/{product_id}`（商品詳細）、`/cart`、`/checkout`、`/complete`（購入完了） |
| `device` | TEXT | `'mobile'` / `'pc'` / `'tablet'` |
| `accessed_at` | TEXT | アクセス日時 |

`device` の値: `mobile`（4,083 件）、`pc`（2,921 件）、`tablet`（571 件）

先頭 6 行:

| log_id | customer_id | path | device | accessed_at |
|---|---|---|---|---|
| 1 | NULL | / | mobile | 2025-10-01 07:17:12 |
| 2 | NULL | /products | mobile | 2025-10-01 07:17:22 |
| 3 | 194 | / | mobile | 2025-10-01 07:48:05 |
| 4 | 194 | /products | mobile | 2025-10-01 07:49:10 |
| 5 | NULL | / | mobile | 2025-10-01 07:59:28 |
| 6 | NULL | /products | mobile | 2025-10-01 08:00:57 |

## departments

運営会社の部署。6 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `department_id` | INTEGER | 主キー |
| `name` | TEXT | 部署名 |
| `location` | TEXT | 所在地（都道府県） |

全データ:

| department_id | name | location |
|---|---|---|
| 1 | 経営企画部 | 東京都 |
| 2 | 営業部 | 東京都 |
| 3 | 開発部 | 東京都 |
| 4 | マーケティング部 | 大阪府 |
| 5 | カスタマーサポート部 | 福岡県 |
| 6 | 新規事業室 | 東京都 |

## employees

運営会社の社員。40 行。

| 列名 | 型 | 説明 |
|---|---|---|
| `employee_id` | INTEGER | 主キー |
| `name` | TEXT | 氏名 |
| `department_id` | INTEGER | 所属部署 → departments。**未配属は NULL** |
| `manager_id` | INTEGER | 上司の employee_id。**社長は NULL** |
| `job_title` | TEXT | 役職 |
| `salary` | INTEGER | 年収（円） |
| `hired_on` | TEXT | 入社日 `'YYYY-MM-DD'` |

`job_title` の値: `一般社員`（27 件）、`課長`（6 件）、`部長`（4 件）、`契約社員`（2 件）、`代表取締役`（1 件）

先頭 8 行:

| employee_id | name | department_id | manager_id | job_title | salary | hired_on |
|---|---|---|---|---|---|---|
| 1 | 森 大和 | 1 | NULL | 代表取締役 | 15000000 | 2010-03-24 |
| 2 | 池田 健一 | 2 | 1 | 部長 | 10000000 | 2013-04-11 |
| 3 | 小林 学 | 3 | 1 | 部長 | 10500000 | 2012-10-10 |
| 4 | 小川 明美 | 4 | 1 | 部長 | 10000000 | 2011-01-28 |
| 5 | 佐々木 楓 | 5 | 1 | 部長 | 9500000 | 2012-08-08 |
| 6 | 阿部 大輔 | 2 | 2 | 課長 | 7000000 | 2012-03-06 |
| 7 | 高橋 美咲 | 2 | 2 | 課長 | 7200000 | 2015-10-13 |
| 8 | 松本 隆 | 3 | 3 | 課長 | 7200000 | 2018-12-27 |
