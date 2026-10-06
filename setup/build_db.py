#!/usr/bin/env python3
"""特訓用DB (tokkun.db) を生成する。

乱数シード固定なので、何度作り直しても同じデータになる。
    python3 setup/build_db.py
"""
import random
import sqlite3
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "tokkun.db"
rnd = random.Random(20261002)

SURNAMES = [
    ("佐藤", "sato"), ("鈴木", "suzuki"), ("高橋", "takahashi"), ("田中", "tanaka"),
    ("伊藤", "ito"), ("渡辺", "watanabe"), ("山本", "yamamoto"), ("中村", "nakamura"),
    ("小林", "kobayashi"), ("加藤", "kato"), ("吉田", "yoshida"), ("山田", "yamada"),
    ("佐々木", "sasaki"), ("山口", "yamaguchi"), ("松本", "matsumoto"), ("井上", "inoue"),
    ("木村", "kimura"), ("林", "hayashi"), ("斎藤", "saito"), ("清水", "shimizu"),
    ("山崎", "yamazaki"), ("森", "mori"), ("池田", "ikeda"), ("橋本", "hashimoto"),
    ("阿部", "abe"), ("石川", "ishikawa"), ("前田", "maeda"), ("藤田", "fujita"),
    ("小川", "ogawa"), ("岡田", "okada"),
]
MALE = ["太郎", "翔太", "健一", "大輔", "拓也", "直樹", "悠真", "蓮", "陽斗", "誠",
        "隆", "亮", "和也", "浩二", "修", "優斗", "颯", "大和", "健太", "学"]
FEMALE = ["花子", "美咲", "陽子", "さくら", "結衣", "葵", "由美", "恵", "真由美", "彩",
          "七海", "優奈", "千尋", "里奈", "明美", "凛", "楓", "直子", "智子", "莉子"]
PREFS = [("東京都", 25), ("神奈川県", 12), ("大阪府", 12), ("愛知県", 8), ("埼玉県", 7),
         ("千葉県", 7), ("福岡県", 6), ("北海道", 5), ("兵庫県", 5), ("京都府", 4),
         ("宮城県", 3), ("広島県", 3), ("沖縄県", 1)]
HOUR_W = [1, 1, .5, .3, .3, .5, 1, 2, 3, 4, 4, 5, 6, 5, 4, 4, 4, 5, 6, 8, 9, 9, 7, 4]

CATEGORIES = [
    (1, "家電", None), (2, "食品", None), (3, "ファッション", None), (4, "書籍", None),
    (5, "キッチン家電", 1), (6, "オーディオ", 1), (7, "PC周辺機器", 1),
    (8, "コーヒー・お茶", 2), (9, "お菓子", 2), (10, "調味料", 2),
    (11, "メンズ", 3), (12, "レディース", 3), (13, "バッグ", 3),
    (14, "技術書", 4), (15, "ビジネス書", 4), (16, "コミック", 4),
    (17, "キーボード", 7), (18, "マウス", 7),
    (19, "コーヒー豆", 8), (20, "日本茶", 8),
    (21, "雑誌", 4),  # 商品が1つもないカテゴリ
]
PRODUCTS = {
    5: [("電気ケトル", 4980), ("コーヒーメーカー", 12800), ("オーブントースター", 7980),
        ("ハンドブレンダー", 6480), ("炊飯器 5.5合", 24800), ("ホットプレート", 9800)],
    6: [("ワイヤレスイヤホン", 14800), ("Bluetoothスピーカー", 8980),
        ("ノイズキャンセリングヘッドホン", 32800), ("サウンドバー", 19800), ("有線イヤホン", 2980)],
    7: [("USB-Cハブ", 4480), ("Webカメラ", 5980), ("モニターアーム", 8800), ("ノートPCスタンド", 3480)],
    17: [("メカニカルキーボード 赤軸", 13800), ("静電容量無接点キーボード", 29800),
         ("薄型ワイヤレスキーボード", 5980)],
    18: [("ワイヤレスマウス", 2480), ("エルゴノミクスマウス", 7980),
         ("トラックボールマウス", 6980), ("ゲーミングマウス", 9800)],
    19: [("コーヒー豆 ブラジル 200g", 1280), ("コーヒー豆 エチオピア 200g", 1580),
         ("コーヒー豆 グアテマラ 200g", 1480), ("コーヒー豆 深煎りブレンド 500g", 2480),
         ("デカフェ コーヒー豆 200g", 1680), ("ドリップバッグコーヒー 30袋", 2180)],
    20: [("煎茶 100g", 1080), ("玉露 50g", 2980), ("ほうじ茶 ティーバッグ 50包", 980),
         ("抹茶 30g", 1880), ("玄米茶 200g", 780)],
    8: [("紅茶 アールグレイ 50包", 1380), ("ハーブティー アソート", 1180)],
    9: [("チョコレート アソート", 1980), ("バウムクーヘン", 1480), ("煎餅 詰め合わせ", 2480),
        ("クッキー缶", 3200), ("羊羹 3本セット", 2700), ("ドライフルーツミックス", 880)],
    10: [("丸大豆醤油 1L", 680), ("エクストラバージンオリーブオイル", 1880),
         ("だしパック 30袋", 1280), ("岩塩 ミル付き", 580), ("黒酢 720ml", 1480)],
    11: [("メンズ オックスフォードシャツ", 5980), ("メンズ チノパンツ", 6980),
         ("メンズ メリノウールニット", 9800), ("メンズ ダウンジャケット", 19800),
         ("メンズ 無地Tシャツ 2パック", 2980)],
    12: [("レディース リネンブラウス", 5480), ("レディース プリーツスカート", 6480),
         ("レディース カシミヤニット", 15800), ("レディース トレンチコート", 22800),
         ("レディース ワイドパンツ", 5980)],
    13: [("レザートートバッグ", 18800), ("ビジネスリュック", 12800), ("ショルダーバッグ", 7980),
         ("エコバッグ", 980), ("トラベルボストン", 14800)],
    14: [("SQL実践入門", 2860), ("データベース設計の教科書", 3080), ("Pythonデータ分析入門", 3520),
         ("実践Webアプリケーション開発", 3300), ("Linuxコマンド逆引き事典", 2640), ("アルゴリズム図鑑", 2620)],
    15: [("ロジカルシンキング入門", 1760), ("決算書の読み方", 1870), ("マーケティングの基本", 1980),
         ("1on1ミーティングの技術", 1650), ("交渉術の教科書", 1760)],
    16: [("冒険ファンタジー 第1巻", 550), ("冒険ファンタジー 第2巻", 550), ("学園ミステリー 第1巻", 594),
         ("料理人の物語 第1巻", 715), ("宇宙開拓記 第1巻", 660)],
}
NEVER_ORDERED = {"サウンドバー", "玉露 50g", "トラベルボストン", "宇宙開拓記 第1巻"}
DISCONTINUED = {"ハンドブレンダー", "有線イヤホン", "岩塩 ミル付き", "学園ミステリー 第1巻", "レディース ワイドパンツ"}
COMMENTS = {
    1: ["すぐに壊れてしまいました。", "写真と全然違う。", "期待はずれでした。"],
    2: ["値段の割にはいまひとつ。", "梱包が雑でした。", "思っていたより小さい。"],
    3: ["可もなく不可もなく。", "普通です。", "値段相応だと思います。"],
    4: ["なかなか良いです。", "使いやすい。リピートするかも。", "配送が早くて助かりました。"],
    5: ["最高です！また買います。", "期待以上でした。", "家族にも好評です。", "もっと早く買えばよかった。"],
}


def fmt(d):
    return d.strftime("%Y-%m-%d %H:%M:%S")


def rand_dt(start, end):
    return start + timedelta(seconds=rnd.randrange(int((end - start).total_seconds())))


def rand_time(d):
    hour = rnd.choices(range(24), HOUR_W)[0]
    return datetime(d.year, d.month, d.day, hour, rnd.randrange(60), rnd.randrange(60))


def rand_name():
    sur, roma = rnd.choice(SURNAMES)
    is_male = rnd.random() < 0.5
    return f"{sur} {rnd.choice(MALE if is_male else FEMALE)}", roma, is_male


def build_employees():
    depts = [(1, "経営企画部", "東京都"), (2, "営業部", "東京都"), (3, "開発部", "東京都"),
             (4, "マーケティング部", "大阪府"), (5, "カスタマーサポート部", "福岡県"),
             (6, "新規事業室", "東京都")]  # 新規事業室は所属0人
    emps = []

    def add(dept, manager, title, salary, hired_from, hired_to):
        hired = date(hired_from, 1, 1) + timedelta(days=rnd.randrange((hired_to - hired_from + 1) * 365))
        emps.append((len(emps) + 1, rand_name()[0], dept, manager, title, salary, hired.isoformat()))
        return len(emps)

    add(1, None, "代表取締役", 15_000_000, 2010, 2010)
    heads = {d: add(d, 1, "部長", rnd.randrange(90, 115, 5) * 100_000, 2011, 2015) for d in (2, 3, 4, 5)}
    chiefs = {1: [1]}
    for d, n in ((2, 2), (3, 2), (4, 1), (5, 1)):
        chiefs[d] = [add(d, heads[d], "課長", rnd.randrange(68, 86, 2) * 100_000, 2012, 2019) for _ in range(n)]
    for d, n in ((1, 3), (2, 7), (3, 9), (4, 4), (5, 4)):
        for _ in range(n):
            add(d, rnd.choice(chiefs[d]), "一般社員", rnd.randrange(36, 84, 2) * 100_000, 2013, 2025)
    add(None, heads[2], "契約社員", 3_200_000, 2025, 2025)
    add(None, heads[2], "契約社員", 3_400_000, 2025, 2025)
    return depts, emps


def build_customers():
    reg_times = sorted(rand_dt(datetime(2023, 1, 1), datetime(2025, 11, 1)) for _ in range(200))
    rows = []
    for i, reg in enumerate(reg_times, 1):
        name, roma, is_male = rand_name()
        gender = None if rnd.random() < 0.08 else ("M" if is_male else "F")
        birth = None if rnd.random() < 0.10 else (date(1960, 1, 1) + timedelta(days=rnd.randrange(46 * 365))).isoformat()
        domain = rnd.choices(["example.com", "example.jp", "mail.example.org", "example.net"], [50, 25, 15, 10])[0]
        email = None if rnd.random() < 0.06 else f"{roma}{i}@{domain}"
        if email and rnd.random() < 0.07:
            email = email.upper()
        pref = rnd.choices([p for p, _ in PREFS], [w for _, w in PREFS])[0]
        referrer = rnd.randint(1, i - 1) if i > 10 and rnd.random() < 0.25 else None
        rows.append([i, name, email, gender, birth, pref, fmt(reg), referrer])
    # 二重登録（同じメールアドレス。1件は大文字小文字だけ違う）
    for dup, (orig, upper) in zip((121, 158, 189), ((14, False), (33, True), (71, False))):
        src = rows[orig - 1][2] or f"dup{orig}@example.com"
        rows[orig - 1][2] = src.lower()
        rows[dup - 1][2] = src.upper() if upper else src.lower()
    return rows


def build_products():
    rows = []
    for cat_id in sorted(PRODUCTS):
        for name, price in PRODUCTS[cat_id]:
            cost = int(price * rnd.uniform(0.40, 0.75) / 10) * 10
            if rnd.random() < 0.8:
                released = date(2022, 1, 1) + timedelta(days=rnd.randrange(730))
            else:
                released = date(2024, 2, 1) + timedelta(days=rnd.randrange(600))
            rows.append((len(rows) + 1, name, cat_id, price, cost, released.isoformat(),
                         1 if name in DISCONTINUED else 0))
    return rows


def build_orders(customers, products):
    season = {1: .9, 2: .8, 3: 1, 4: 1, 5: 1, 6: 1.05, 7: 1.2, 8: 1.1, 9: .95, 10: 1, 11: 1.15, 12: 1.5}
    never = set(rnd.sample(range(21, 201), 18))  # 一度も注文しない顧客
    activity = {c[0]: rnd.paretovariate(1.5) for c in customers}
    registered = {c[0]: c[6] for c in customers}
    popularity = {p[0]: rnd.uniform(0.5, 1.5) * 20000 / (p[3] + 2000) for p in products}

    stamps = []
    for i in range(731):
        d = date(2024, 1, 1) + timedelta(days=i)
        mu = (2.4 + 2.2 * i / 730) * season[d.month]
        stamps += [rand_time(d) for _ in range(max(0, round(rnd.gauss(mu, mu ** 0.5))))]
    stamps.sort()

    orders, items, ordered_before = [], [], set()
    for ts in stamps:
        ts_s = fmt(ts)
        cands = [c for c in activity if c not in never and registered[c] < ts_s]
        cid = rnd.choices(cands, [activity[c] for c in cands])[0]
        avail = [p for p in products
                 if p[1] not in NEVER_ORDERED and p[5] <= ts_s[:10]
                 and not (p[6] and ts_s >= "2025-01-01")]
        chosen = {}
        for _ in range(rnd.choices([1, 2, 3, 4, 5], [40, 30, 17, 9, 4])[0]):
            p = rnd.choices(avail, [popularity[p[0]] for p in avail])[0]
            chosen[p[0]] = p
        order_id = len(orders) + 1
        subtotal = 0
        for p in chosen.values():
            qty = rnd.choices([1, 2, 3, 4, 5], [60, 22, 10, 5, 3])[0]
            unit = int(p[3] * 0.9) if rnd.random() < 0.15 else p[3]
            subtotal += qty * unit
            items.append((len(items) + 1, order_id, p[0], qty, unit))
        if ts >= datetime(2025, 12, 25):
            status = rnd.choices(["pending", "shipped", "completed", "cancelled"], [40, 35, 20, 5])[0]
        else:
            status = rnd.choices(["completed", "cancelled", "shipped", "pending"], [86, 10, 2, 2])[0]
        if cid not in ordered_before:
            coupon = "WELCOME10" if rnd.random() < 0.5 else None
        elif rnd.random() < 0.12:
            coupon = {6: "SUMMER25", 7: "SUMMER25", 8: "SUMMER25", 12: "WINTER25"}.get(ts.month, "VIP15")
        else:
            coupon = None
        ordered_before.add(cid)
        payment = rnd.choices(["credit_card", "e_money", "convenience_store", "bank_transfer", "cod"],
                              [55, 10, 15, 12, 8])[0]
        orders.append((order_id, cid, ts_s, status, payment, coupon, 0 if subtotal >= 5000 else 550))
    return orders, items


def build_reviews(orders, items):
    by_order = {o[0]: o for o in orders}
    seen, rows = set(), []
    for _, order_id, product_id, _, _ in items:
        o = by_order[order_id]
        if o[3] != "completed" or (product_id, o[1]) in seen or rnd.random() > 0.14:
            continue
        seen.add((product_id, o[1]))
        rating = rnd.choices([1, 2, 3, 4, 5], [5, 8, 17, 35, 35])[0]
        comment = None if rnd.random() < 0.3 else rnd.choice(COMMENTS[rating])
        created = datetime.strptime(o[2], "%Y-%m-%d %H:%M:%S") + timedelta(
            days=rnd.randint(3, 30), seconds=rnd.randrange(86400))
        rows.append((product_id, o[1], rating, comment, fmt(created)))
    rows.sort(key=lambda r: r[4])
    return [(i, *r) for i, r in enumerate(rows, 1)]


def build_access_logs(customers, products):
    visit_w = {c[0]: rnd.paretovariate(1.2) for c in customers}
    registered = {c[0]: c[6] for c in customers}
    product_ids = [p[0] for p in products]
    rows = []
    for i in range(92):
        d = date(2025, 10, 1) + timedelta(days=i)
        for _ in range(rnd.randint(18, 32)):
            t = rand_time(d)
            cid = None
            if rnd.random() >= 0.3:
                cands = [c for c in visit_w if registered[c] < fmt(t)]
                cid = rnd.choices(cands, [visit_w[c] for c in cands])[0]
            device = rnd.choices(["mobile", "pc", "tablet"], [55, 38, 7])[0]
            paths = ["/"]
            if rnd.random() < 0.8:
                paths.append("/products")
                if rnd.random() < 0.7:
                    paths += [f"/products/{rnd.choice(product_ids)}" for _ in range(rnd.randint(1, 3))]
                    if rnd.random() < 0.35:
                        paths.append("/cart")
                        if rnd.random() < 0.55:
                            paths.append("/checkout")
                            if rnd.random() < 0.75:
                                paths.append("/complete")
            for path in paths:
                rows.append((cid, path, device, fmt(t)))
                t += timedelta(seconds=rnd.randint(5, 300))
    rows.sort(key=lambda r: r[3])
    return [(i, *r) for i, r in enumerate(rows, 1)]


def main():
    depts, emps = build_employees()
    customers = build_customers()
    products = build_products()
    orders, items = build_orders(customers, products)
    reviews = build_reviews(orders, items)
    logs = build_access_logs(customers, products)

    DB.unlink(missing_ok=True)
    conn = sqlite3.connect(DB)
    conn.executescript((ROOT / "setup" / "schema.sql").read_text(encoding="utf-8"))
    for table, rows in (("departments", depts), ("employees", emps), ("customers", customers),
                        ("categories", CATEGORIES), ("products", products), ("orders", orders),
                        ("order_items", items), ("reviews", reviews), ("access_logs", logs)):
        marks = ",".join("?" * len(rows[0]))
        conn.executemany(f"INSERT INTO {table} VALUES ({marks})", rows)
        print(f"{table:12s} {len(rows):>6,d} 行")
    conn.commit()
    conn.close()
    print(f"→ {DB} を作成しました")


if __name__ == "__main__":
    main()
