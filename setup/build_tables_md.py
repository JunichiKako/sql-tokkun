#!/usr/bin/env python3
"""tokkun.db の中身から TABLES.md（テーブル一覧・列の説明・サンプル行）を生成する。

    python3 setup/build_tables_md.py
"""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (テーブル, 説明, サンプル行数, {列: 説明})
TABLES = [
    ("customers", "顧客（ECサイトの会員）", 5, {
        "customer_id": "主キー。登録が早い順に 1〜200",
        "name": "氏名。`'姓 名'` の形（半角スペース区切り）",
        "email": "メールアドレス。**NULL あり**・大文字混じりあり・二重登録あり",
        "gender": "`'M'` / `'F'`。**NULL あり**（不明）",
        "birth_date": "生年月日 `'YYYY-MM-DD'`。**NULL あり**",
        "prefecture": "都道府県",
        "registered_at": "会員登録日時 `'YYYY-MM-DD HH:MM:SS'`",
        "referrer_id": "紹介してくれた顧客の customer_id。**紹介なしは NULL**",
    }),
    ("categories", "商品カテゴリ（親子関係で最大3階層）", 21, {
        "category_id": "主キー",
        "name": "カテゴリ名",
        "parent_id": "親カテゴリの category_id。**最上位は NULL**",
    }),
    ("products", "商品", 5, {
        "product_id": "主キー",
        "name": "商品名",
        "category_id": "所属カテゴリ → categories",
        "price": "現在の定価（円）",
        "cost": "原価（円）",
        "released_on": "発売日 `'YYYY-MM-DD'`",
        "is_discontinued": "`1` = 販売終了、`0` = 販売中",
    }),
    ("orders", "注文（1回の買い物で1行）", 5, {
        "order_id": "主キー。注文日時の早い順",
        "customer_id": "注文した顧客 → customers",
        "ordered_at": "注文日時 `'YYYY-MM-DD HH:MM:SS'`（2024-01-01〜2025-12-31）",
        "status": "注文の状態（下の値一覧を参照）",
        "payment_method": "支払方法（下の値一覧を参照）",
        "coupon_code": "使ったクーポン。**未使用は NULL**",
        "shipping_fee": "送料（円）。`0` か `550`",
    }),
    ("order_items", "注文明細（1つの注文に含まれる商品ごとに1行）", 5, {
        "order_item_id": "主キー",
        "order_id": "どの注文の明細か → orders",
        "product_id": "買った商品 → products",
        "quantity": "数量",
        "unit_price": "購入時の単価（円）。セール時は products.price より安い",
    }),
    ("reviews", "商品レビュー", 5, {
        "review_id": "主キー",
        "product_id": "対象の商品 → products",
        "customer_id": "書いた顧客 → customers",
        "rating": "評価 1〜5",
        "comment": "コメント。**NULL あり**（評価だけのレビュー）",
        "created_at": "投稿日時",
    }),
    ("access_logs", "サイトのアクセスログ（1ページ閲覧で1行。2025-10-01〜2025-12-31）", 6, {
        "log_id": "主キー。アクセス日時の早い順",
        "customer_id": "アクセスした顧客 → customers。**未ログイン（ゲスト）は NULL**",
        "path": "見たページ。`/`（トップ）、`/products`（一覧）、`/products/{product_id}`（商品詳細）、`/cart`、`/checkout`、`/complete`（購入完了）",
        "device": "`'mobile'` / `'pc'` / `'tablet'`",
        "accessed_at": "アクセス日時",
    }),
    ("departments", "運営会社の部署", 6, {
        "department_id": "主キー",
        "name": "部署名",
        "location": "所在地（都道府県）",
    }),
    ("employees", "運営会社の社員", 8, {
        "employee_id": "主キー",
        "name": "氏名",
        "department_id": "所属部署 → departments。**未配属は NULL**",
        "manager_id": "上司の employee_id。**社長は NULL**",
        "job_title": "役職",
        "salary": "年収（円）",
        "hired_on": "入社日 `'YYYY-MM-DD'`",
    }),
]
# 取りうる値を一覧で見せたい列
ENUMS = {"orders": ["status", "payment_method", "coupon_code"], "access_logs": ["device"],
         "employees": ["job_title"]}

HEADER = """# テーブル一覧

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
"""


def cell(v):
    return "NULL" if v is None else str(v).replace("|", "\\|")


def md_table(cols, rows):
    out = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    out += ["| " + " | ".join(cell(v) for v in r) + " |" for r in rows]
    return out


def main():
    conn = sqlite3.connect(ROOT / "tokkun.db")
    out = [HEADER, "## 目次", ""]
    for name, desc, _, _ in TABLES:
        count = conn.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]
        out.append(f"- [{name}](#{name}) — {desc}（{count:,} 行）")
    for name, desc, n, col_desc in TABLES:
        count = conn.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]
        info = conn.execute(f"PRAGMA table_info({name})").fetchall()
        out += ["", f"## {name}", "", f"{desc}。{count:,} 行。", ""]
        out += md_table(["列名", "型", "説明"], [(f"`{c[1]}`", c[2], col_desc[c[1]]) for c in info])
        for col in ENUMS.get(name, []):
            vals = conn.execute(
                f"SELECT {col}, COUNT(*) FROM {name} GROUP BY {col} ORDER BY COUNT(*) DESC").fetchall()
            out += ["", f"`{col}` の値: " + "、".join(f"`{cell(v)}`（{c:,} 件）" for v, c in vals)]
        pk = info[0][1]
        cur = conn.execute(f"SELECT * FROM {name} ORDER BY {pk} LIMIT {n}")
        label = "全データ" if n >= count else f"先頭 {n} 行"
        out += ["", f"{label}:", ""] + md_table([d[0] for d in cur.description], cur.fetchall())
    (ROOT / "TABLES.md").write_text("\n".join(out) + "\n", encoding="utf-8")
    print("TABLES.md を書き出しました")


if __name__ == "__main__":
    main()
