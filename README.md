# SQL 特訓（120日・360問）

架空のECサイトのデータベースを相手に、SELECT の基礎から実務の分析クエリまでを一通り書けるようにする問題集。
SQLite だけで動くので、環境構築は不要。

**「新出の日」と「定着の日」の2日で1テーマ**を進める。

- 新出の日（`W01-D1-1`〜`3`）: 新しい書き方を学ぶ3問
- 定着の日（`W01-D1-R1`〜`R3`）: 同じテーマを、別のテーブル・題材でもう一度自力で書く3問

60テーマ × 2日 × 3問 = 360問。毎日やって約4か月。

## はじめかた

```sh
python3 setup/build_db.py      # tokkun.db を生成（すでにあれば作り直す）
sqlite3 tokkun.db              # 対話シェルで自由に触る（.tables / .schema / .headers on / .mode column が便利）
```

最初に読むもの:

- [TABLES.md](TABLES.md) — 全テーブルの列の説明とサンプルデータ
- [HOWTO.md](HOWTO.md) — 答え方の見本（解答ファイルの書き方と採点結果の読み方）

## 毎日の進め方

1. `my/<問題ID>.sql` を開く（例: `my/W01-D1-1.sql`）。問題文とテーブル早見表がコメントで入っている
2. 同じファイルの「▼ ここに SQL を書く」の下に解答を書く。隣に `TABLES.md` のプレビューを開いておくと列の説明やサンプルデータを見ながら書ける
3. 採点する。VS Code なら解答ファイルを開いたまま **`Cmd + Shift + B`** で、実行結果の表示と採点がまとめて行われる。ターミナルからは次のとおり

```sh
python3 tokkun.py W01-D1-1     # 1問を採点（不正解なら期待する結果との差を表示）
python3 tokkun.py W01          # Week 1 の解答済みの問題をまとめて採点
python3 tokkun.py              # 全体の進捗一覧
```

4. 解けても解けなくても `answers/weekNN.sql` の模範解答と「解説」を読む（別解や落とし穴が書いてある）

1日分は3問。進む順番はファイル名の順（`W01-D1-1〜3` → `W01-D1-R1〜R3` → `W01-D2-1〜3` → …）。
進捗一覧では3問ずつ区切って表示されるので、次にやる日がすぐ分かる。

ヒントがある問題は、解答ファイルの一番下（スクロールしないと見えない位置）に書いてある。
解答ファイルを消してしまったら `python3 tokkun.py --init` で作り直せる（残っているファイルは上書きしない）。

採点は結果セットの中身で判定する（列名は見ない。列の順番と数は「出力列」に合わせること）。
「並び順も採点対象」と書かれた問題だけ行の順番も見る。
採点は tokkun.db のコピーに対して行うので、Week 10 の UPDATE / DELETE を何度実行しても元のDBは壊れない。
「自己採点」の問題（Week 11 の実行計画系）は、`Cmd + Shift + B` で実行計画を表示させ、模範解答の解説と見比べる。

## カリキュラム

「Week」は日数ではなくテーマのまとまり。1つの Week は5テーマ × 2日 = 10日分。

| 目安 | ブロック | テーマ |
|---|---|---|
| 1か月目 | Week 1 | SELECT の基礎（WHERE / ORDER BY / LIMIT / NULL / LIKE / CASE） |
| | Week 2 | 集計（集約関数 / GROUP BY / HAVING / 条件付き集計） |
| | Week 3 | JOIN（INNER / LEFT / 自己結合 / 多テーブル） |
| 2か月目 | Week 4 | サブクエリ（スカラ / EXISTS / 相関 / 派生テーブル）と集合演算 |
| | Week 5 | 文字列・日付・NULL 処理・ピボット |
| | Week 6 | CTE と多段集計（+ 中間テスト） |
| 3か月目 | Week 7 | ウィンドウ関数 (1) 順位・PARTITION BY・グループ内 Top N |
| | Week 8 | ウィンドウ関数 (2) LAG / 累計 / 移動平均 / フレーム / NTILE / 中央値 |
| | Week 9 | 再帰 CTE・階層データ・欠損補完・連続区間・セッション化 |
| 4か月目 | Week 10 | INSERT / UPDATE / DELETE / UPSERT・DDL・制約・ビュー・トランザクション |
| | Week 11 | インデックス・実行計画・遅いクエリ／間違ったクエリの書き換え |
| | Week 12 | 実務分析（前年比 / RFM / コホート / ファネル / ABC / LTV）と卒業試験 |

難易度は ★（基本）〜 ★★★（考えさせる問題）。各 Week の Day 5 はその Week の総合演習。
後半（Week 7 以降）はほぼ ★★★ になるので、きつければ1日2問に減らし、残りを休日に回してよい。

## データベース

テーブル定義の全文は `setup/schema.sql`。データの期間は、注文が 2024-01-01〜2025-12-31、アクセスログが 2025-10-01〜2025-12-31。

| テーブル | 内容 | 行数 |
|---|---|---|
| `customers` | 顧客。`referrer_id` で紹介者（自己参照） | 200 |
| `categories` | 商品カテゴリ。`parent_id` で最大3階層 | 21 |
| `products` | 商品。`price` は現在の定価、`cost` は原価 | 77 |
| `orders` | 注文。`status` は completed / shipped / pending / cancelled | 2,728 |
| `order_items` | 注文明細。`unit_price` は購入時の単価 | 5,648 |
| `reviews` | 商品レビュー（rating 1〜5） | 592 |
| `access_logs` | サイトのアクセスログ。ゲストは `customer_id` が NULL | 7,575 |
| `departments` | 運営会社の部署 | 6 |
| `employees` | 社員。`manager_id` で上司（自己参照） | 40 |

```
customers ─< orders ─< order_items >─ products >─ categories（親子）
    │                                     │
    ├─< reviews >──────────────────────────┘
    └─< access_logs            departments ─< employees（上司・部下）
```

現実のデータらしく、わざと「汚れ」を入れてある。問題を解くときに思い出すこと。

- NULL がある列: `customers.email` / `gender` / `birth_date` / `referrer_id`、`orders.coupon_code`、`reviews.comment`、`employees.department_id` / `manager_id`、`access_logs.customer_id`
- 一度も注文していない顧客、一度も売れていない商品、商品のないカテゴリ、社員のいない部署がある
- メールアドレスに大文字混じり・二重登録がある
- 注文が1件もない日がある／極端に購入額の大きい顧客がいる

## 問題文の約束ごと

- **売上** = 注文明細の `quantity * unit_price` の合計。送料は含めない
- 「completed の〜」と書いてあれば `orders.status = 'completed'` の注文だけが対象。「ステータスは問わない」なら全注文
- 「現在」が必要な問題は、基準日 **2026-01-01** が問題文に明記されている（`date('now')` は使わない）
- 月は `'YYYY-MM'` 形式の文字列で出す

## SQLite と他のDBの違い

本番で使うことが多い PostgreSQL / MySQL との主な違い。模範解答の解説にも都度書いてある。

| やりたいこと | SQLite（この問題集） | PostgreSQL | MySQL |
|---|---|---|---|
| 年月を取り出す | `strftime('%Y-%m', d)` | `to_char(d, 'YYYY-MM')` | `DATE_FORMAT(d, '%Y-%m')` |
| 日付の加算 | `date(d, '+1 day')` | `d + INTERVAL '1 day'` | `d + INTERVAL 1 DAY` |
| 日数の差 | `julianday(a) - julianday(b)` | `a::date - b::date` | `DATEDIFF(a, b)` |
| 文字列の連結 | `a \|\| b` | `a \|\| b` | `CONCAT(a, b)` |
| 連番・日付の生成 | 再帰 CTE | `generate_series()` | 再帰 CTE |
| 実行計画 | `EXPLAIN QUERY PLAN` | `EXPLAIN (ANALYZE)` | `EXPLAIN` |

SQLite は型や GROUP BY の書き方に寛容で、他のDBではエラーになるSQLも通ってしまう。
模範解答は「SELECT に書いた非集約列はすべて GROUP BY に書く」など、できるだけ他のDBでも通る書き方にしてある（日付関数などの方言は除く）。

## ファイル構成

```
setup/schema.sql      テーブル定義
setup/build_db.py     データ生成（乱数シード固定。何度作っても同じデータ）
my/                   解答ファイル（問題文入り。ここに SQL を書く）
answers/weekNN.sql    問題の原本・模範解答・解説
tokkun.py             採点ツール
```

問題を追加したいときは `answers/weekNN.sql` に書き足して `python3 tokkun.py --init` で解答ファイルを作る。
`python3 tokkun.py --selftest` で模範解答がすべて実行できるか確認できる。
