# 答え方の見本

練習用の Week 0 の3問（`my/W00-D1-1.sql` 〜 `my/W00-D1-3.sql`）は、解答済みの見本になっている。
まずこれをそのまま採点して、流れをつかむ。

```sh
python3 tokkun.py W00
```

```
✅ W00-D1-1: 正解！（57 行）
✅ W00-D1-2: 正解！（5 行）
✅ W00-D1-3: 正解！（1 行）
```

## VS Code で実行する

解答ファイル（`my/W01-D1-1.sql` など）を開いた状態で **`Cmd + Shift + B`** を押すと、下のターミナルに SQL の実行結果が表示され、続けて採点される。保存は自動で行われる。

```
■ W00-D1-2 の実行結果
  payment_method     cnt
  -----------------  ----
  bank_transfer      307
  cod                231
  convenience_store  402
  credit_card        1513
  e_money            275
  → 5 行

✅ W00-D1-2: 正解！（5 行）
```

- 書きかけの SQL の結果を見るだけの用途にも使える（不正解と出るだけで害はない）
- 実行は `tokkun.db` のコピーに対して行われるので、UPDATE や DELETE を何度流しても元のデータは変わらない
- このショートカットは、VS Code で `sql-tokkun` フォルダそのものを開いているときに効く（設定は `.vscode/tasks.json`）
- 進捗一覧は `Cmd + Shift + P` →「Tasks: Run Task」→「SQL: 進捗を見る」

## 1問を解く流れ

### 1. 問題を読む

解答ファイルを開くと、先頭に問題がコメントで書いてある。たとえばこういう形。

```sql
-- W00-D1-1 ★
--
-- 【問題】
-- 東京都に住む顧客を、customer_id の小さい順に取得せよ。
--
-- 【出力列】 customer_id, name
-- 【並び順】 採点対象（ORDER BY が必要）
-- 【採点】 python3 tokkun.py W00-D1-1
```

読み取ること:

| 書いてあること | 意味 |
|---|---|
| `W00-D1-1` | 問題ID。解答のファイル名と同じ |
| 【出力列】 | SELECT する列と、その**順番** |
| 【並び順】 | ORDER BY が必須。この表記がない問題は行の順番は自由 |
| 【ヒント】 | ある問題だけ。ファイルの一番下に書いてあるので、詰まったらスクロールして見る |

使うテーブルと列は [TABLES.md](TABLES.md) で調べる。この問題なら `customers` の `prefecture`。

### 2. 試しながら書く

いきなりファイルに書かず、`sqlite3` で実際に動かして結果を見ながら組み立てるとよい。

```sh
sqlite3 tokkun.db
```

```
sqlite> .headers on
sqlite> .mode column
sqlite> SELECT customer_id, name, prefecture FROM customers LIMIT 3;
customer_id  name    prefecture
-----------  ------  ----------
1            斎藤 智子   東京都
2            木村 葵    埼玉県
3            岡田 明美   千葉県
sqlite> .quit
```

### 3. 解答ファイルに保存する

`my/問題ID.sql` に SQL を書く。Week 1 以降は全問のファイルが最初から用意してあり、問題文とテーブル早見表がコメントで入っているので、「▼ ここに SQL を書く」の下に書くだけでよい（問題ファイルと行き来しなくて済む）。見本（`my/W00-D1-1.sql`）:

```sql
SELECT customer_id, name
FROM customers
WHERE prefecture = '東京都'
ORDER BY customer_id;
```

### 4. 採点する

```sh
python3 tokkun.py W00-D1-1
```

```
✅ W00-D1-1: 正解！（57 行）
```

### 5. 模範解答を読む

`answers/week00.sql` の同じ問題IDのところに、模範解答と（問題によっては）解説がある。正解しても読む。

## 不正解のときの読み方

### 結果の中身が違う

`WHERE prefecture = '東京'`（正しくは `'東京都'`）と書いた場合:

```
❌ W00-D1-1: 不正解
  期待する結果（57 行）
    customer_id | name
    1 | 斎藤 智子
    5 | 山田 明美
    11 | 木村 翔太
    ...
  あなたの結果（0 行）
    name | customer_id
```

行数（57 行と 0 行）と先頭の数行を見比べて原因を探す。ここでは 0 行なので WHERE の条件が怪しい、と分かる。
列の順番が `name | customer_id` と逆になっているのも間違い。

### 列が足りない・多い

```
❌ W00-D1-2: 不正解
  列数が違います（期待 2 列 / あなた 1 列）
```

「出力列」に書かれた列だけを、その順番で SELECT する。

### 並び順が違う

```
❌ W01-D1-2: 不正解
  行の中身は合っていますが、並び順が違います
```

ORDER BY の列や昇順・降順、同じ値のときの第2キー（問題文の「同額なら product_id 順」など）を確認する。

### SQL が間違っている

```
❌ W01-D2-1: SQLエラー: near "SELEC": syntax error
```

## 解答ファイルの書き方のルール

- ファイル名は `my/問題ID.sql`（例: `my/W03-D2-1.sql`）
- `--` で始まるコメントは自由に書いてよい。考えたことや別解をメモしておくと復習に使える
- 列名（`AS` の別名）は採点されない。ただし出力列の名前に合わせておくと読みやすい
- 数値は小数第2位までで比較される。`10` と `10.0` は同じ扱い
- 複数の文を書いた場合、**最後の SELECT の結果**が採点される

## 更新系の問題（Week 10）

INSERT / UPDATE / DELETE / CREATE TABLE などを書く問題は、【採点方法】として確認クエリが書いてある。

```sql
-- 【問題】
-- 商品ID 1 の価格を 5,000 円に変更せよ。
--
-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）
--     SELECT product_id, price FROM products WHERE product_id = 1
```

解答には更新の文だけを書けばよい（確認クエリは採点ツールが自動で実行する）。見本（`my/W00-D1-3.sql`）:

```sql
UPDATE products
SET price = 5000
WHERE product_id = 1;
```

複数の文が必要なら `;` で区切って上から順に書く。
採点は DB のコピーに対して行うので、何度実行しても `tokkun.db` は変わらない。

## 自己採点の問題（Week 11 の一部）

「自己採点」と書かれた問題は、実行計画を自分の目で確かめるのが目的なので自動採点しない。
`Cmd + Shift + B` で実行すれば `EXPLAIN QUERY PLAN` の結果が表示されるので、`answers/week11.sql` の解説と見比べる（インデックスを作る文と EXPLAIN の文を同じファイルに続けて書く）。対話的に試したい場合は DB のコピーを作る。

```sh
cp tokkun.db sandbox.db
sqlite3 sandbox.db
```

試した SQL を解答ファイルに書いておけば、進捗一覧では 📝 として数えられる。

## 進捗を見る

```sh
python3 tokkun.py
```

```
W00  ✅✅✅  （練習）
W01  ✅❌・・・・・・・・・・・・・
...
1 / 180 問クリア   (✅正解 ❌不正解 📝自己採点 ・未着手)
```
