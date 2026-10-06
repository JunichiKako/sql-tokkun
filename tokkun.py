#!/usr/bin/env python3
"""SQL特訓の採点ツール。

    python3 tokkun.py                 進捗一覧
    python3 tokkun.py W01-D1-1        my/W01-D1-1.sql を採点
    python3 tokkun.py W01             Week 1 のうち解答済みのものをまとめて採点
    python3 tokkun.py --run W01-D1-1  実行結果を表示してから採点（VS Code の Cmd+Shift+B はこれを呼ぶ）
    python3 tokkun.py --init          問題文入りの解答ファイルを my/ に作る（既存のファイルは上書きしない）
    python3 tokkun.py --selftest      模範解答がすべて実行できるか確認（--selftest W05 のように絞り込み可）

採点は tokkun.db のコピー（メモリ上）で行うので、UPDATE や DELETE を書いても元のDBは変わらない。
"""
import re
import sqlite3
import sys
import time
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = ROOT / "tokkun.db"
ANSWERS = ROOT / "answers"
MY = ROOT / "my"

MARK = re.compile(r"^-- \[(W\d{2}-D\d-R?\d)\]\s*(.*)$")  # R 付きは定着の日の問題
FIELD = re.compile(r"^-- (問|出力|ヒント|確認|解説): ?(.*)$")
CONT = re.compile(r"^-- \| ?(.*)$")
FIELDS = {"問": "question", "出力": "output", "ヒント": "hint", "確認": "verify", "解説": "note"}


def parse(path):
    """answers/weekNN.sql を問題のリストにする。"""
    problems, week, day, cur, last = [], "", "", None, None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("-- # "):
            week, cur = line[5:], None
            continue
        if line.startswith("-- ## "):
            day, cur = line[6:], None
            continue
        m = MARK.match(line)
        if m:
            flags = m.group(2).split()
            cur = {"id": m.group(1), "week": week, "day": day, "flags": set(flags),
                   "stars": next((f for f in flags if f.startswith("★")), ""),
                   "question": "", "output": "", "hint": "", "verify": "", "note": "",
                   "sql": [], "in_sql": False}
            problems.append(cur)
            continue
        if cur is None:
            continue
        if not cur["in_sql"]:
            f = FIELD.match(line)
            if f:
                last = FIELDS[f.group(1)]
                cur[last] = f.group(2)
                continue
            c = CONT.match(line)
            if c and last:
                cur[last] += "\n" + c.group(1)
                continue
            if not line.strip():
                continue
            cur["in_sql"] = True
        cur["sql"].append(line)
    for p in problems:
        p["sql"] = "\n".join(p["sql"]).strip()
    return problems


def load_all():
    problems = []
    for path in sorted(ANSWERS.glob("week*.sql")):
        problems += parse(path)
    return problems


def fresh_db():
    if not DB.exists():
        sys.exit("tokkun.db がありません。先に `python3 setup/build_db.py` を実行してください。")
    src = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    mem = sqlite3.connect(":memory:", isolation_level=None)
    src.backup(mem)
    src.close()
    return mem


def run(conn, sql):
    """SQL（複数文可）を順に実行し、最後に結果セットを返した文の (列名, 行) を返す。"""
    result, buf = None, ""
    for line in sql.splitlines(keepends=True) + ["\n;"]:
        buf += line
        if not sqlite3.complete_statement(buf):
            continue
        stmt, buf = buf.strip(), ""
        if not re.sub(r"--[^\n]*", "", stmt).strip(" ;\n\t"):
            continue
        cur = conn.execute(stmt)
        if cur.description is not None:
            result = ([d[0] for d in cur.description], cur.fetchall())
    return result


def evaluate(problem, sql):
    conn = fresh_db()
    try:
        result = run(conn, sql)
        if problem["verify"]:
            result = run(conn, problem["verify"])
        return result
    finally:
        conn.close()


def normalize(rows, ordered):
    def norm(v):
        return round(float(v), 2) if isinstance(v, (int, float)) else v

    rows = [tuple(norm(v) for v in r) for r in rows]
    if not ordered:
        rows.sort(key=lambda r: [("", "") if v is None else (type(v).__name__, str(v)) for v in r])
    return rows


def show(title, cols, rows, limit=8):
    print(f"  {title}（{len(rows)} 行）")
    print("    " + " | ".join(cols))
    for r in rows[:limit]:
        print("    " + " | ".join("NULL" if v is None else str(v) for v in r))
    if len(rows) > limit:
        print("    ...")


def answered(problem):
    """解答ファイルに（コメント以外の）SQL が書かれているか。"""
    path = MY / f"{problem['id']}.sql"
    if not path.exists():
        return False
    return bool(re.sub(r"--[^\n]*", "", path.read_text(encoding="utf-8")).strip(" ;\n\t"))


def init(problems):
    """問題文をコメントで埋め込んだ解答ファイルを my/ に作る（既存のファイルは上書きしない）。"""
    conn = fresh_db()
    tables = [r[0] for r in conn.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY rowid")]
    sheet = []
    for t in tables:
        cols = ", ".join(r[1] for r in conn.execute(f"PRAGMA table_info({t})"))
        sheet.append(f"-- {t}({cols})")
    conn.close()
    MY.mkdir(exist_ok=True)
    created = 0
    for p in problems:
        path = MY / f"{p['id']}.sql"
        if path.exists():
            continue
        question = [ln for ln in p["question"].split("\n") if not ln.startswith("```")]
        out = [f"-- {p['id']} {p['stars']}   {p['week']} / {p['day']}", "--", "-- 【問題】"]
        out += [f"-- {ln}" for ln in question]
        out.append("--")
        if p["output"]:
            out.append(f"-- 【出力列】 {p['output']}")
        if "ordered" in p["flags"]:
            out.append("-- 【並び順】 採点対象（ORDER BY が必要）")
        if p["verify"]:
            out += ["-- 【採点方法】 あなたの SQL を実行したあと、次のクエリの結果を比べる（自分で書く必要はない）",
                    f"--     {p['verify']}"]
        if p["hint"]:
            out.append("-- 【ヒント】 このファイルの一番下にあり（詰まったら見る）")
        if out[-1] != "--":
            out.append("--")
        out.append("-- 【試し方】 このファイルを開いたまま Cmd + Shift + B")
        if "nocheck" in p["flags"]:
            out += ["--     → 下のターミナルに実行結果（実行計画）が出る。この問題は自動採点なし",
                    f"--     → answers/week{p['id'][1:3]}.sql の模範解答・解説と見比べて自己採点する"]
        else:
            out.append("--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される")
        out += ["--     書きかけでも何度でも実行してよい（DB のコピーで動くので、元のデータは変わらない）",
                f"--     ターミナルから実行する場合: python3 tokkun.py --run {p['id']}"]
        out += ["", "-- ▼ ここに SQL を書く", "", "", "",
                "-- ─── テーブル早見表 ───",
                "-- 読み方: テーブル名(列名, 列名, ...)。このDBにある全テーブルと全列を並べてある",
                "--"] + sheet + [
                "--",
                "-- 列の意味や実際のデータを見たいときは TABLES.md を開く:",
                "--     Cmd + P →「TABLES」と入力して Enter → Cmd + K のあと V（プレビューを横に並べて表示）"]
        if p["hint"]:
            out += [""] * 12 + ["-- ─── ヒント ───"] + [f"-- {ln}" for ln in p["hint"].split("\n")]
        path.write_text("\n".join(out) + "\n", encoding="utf-8")
        created += 1
    print(f"{created} 個の解答ファイルを my/ に作りました（既存の {len(problems) - created} 個はそのまま）")


def check(problem, verbose=True):
    """戻り値: True=正解 / False=不正解 / None=未着手または自己採点"""
    path = MY / f"{problem['id']}.sql"
    if not answered(problem):
        if verbose:
            print(f"{problem['id']}: まだ解答が書かれていません → {path.relative_to(ROOT)} に書いてください")
        return None
    if "nocheck" in problem["flags"]:
        if verbose:
            print(f"{problem['id']}: 自己採点の問題です。answers/ の模範解答と解説を読んで確認してください")
        return None
    expected = evaluate(problem, problem["sql"])
    try:
        actual = evaluate(problem, path.read_text(encoding="utf-8"))
    except sqlite3.Error as e:
        if verbose:
            print(f"❌ {problem['id']}: SQLエラー: {e}")
        return False
    if actual is None:
        if verbose:
            print(f"❌ {problem['id']}: 結果を返す SELECT がありません")
        return False
    ordered = "ordered" in problem["flags"]
    exp_rows, act_rows = normalize(expected[1], ordered), normalize(actual[1], ordered)
    if exp_rows == act_rows:
        if verbose:
            print(f"✅ {problem['id']}: 正解！（{len(exp_rows)} 行）")
        return True
    if verbose:
        print(f"❌ {problem['id']}: 不正解")
        if len(expected[0]) != len(actual[0]):
            print(f"  列数が違います（期待 {len(expected[0])} 列 / あなた {len(actual[0])} 列）")
        elif sorted(map(repr, exp_rows)) == sorted(map(repr, act_rows)):
            print("  行の中身は合っていますが、並び順が違います")
        show("期待する結果", expected[0], expected[1])
        show("あなたの結果", actual[0], actual[1])
    return False


def width(s):
    """全角文字を2桁として数えた表示幅。"""
    return sum(2 if unicodedata.east_asian_width(c) in "FWA" else 1 for c in s)


def print_table(cols, rows, limit=30):
    cells = [[("NULL" if v is None else str(v)) for v in r] for r in rows[:limit]]
    widths = [max(width(x) for x in col) for col in zip(cols, *cells)]
    for line in [cols, ["-" * w for w in widths]] + cells:
        print("  " + "  ".join(x + " " * (w - width(x)) for x, w in zip(line, widths)).rstrip())
    more = f"（先頭 {limit} 行を表示）" if len(rows) > limit else ""
    print(f"  → {len(rows)} 行{more}")


def run_file(problems, name):
    """VS Code のタスク用。解答ファイルを実行して結果を表示し、続けて採点する。"""
    problem = next((p for p in problems if p["id"] == name.upper()), None)
    if problem is None:
        sys.exit(f"「{name}」は問題のファイルではありません。my/ の中の解答ファイル（例: W01-D1-1.sql）を開いた状態で実行してください。")
    if not answered(problem):
        sys.exit(f"{problem['id']}: まだ SQL が書かれていません。「▼ ここに SQL を書く」の下に書いてから実行してください。")
    sql = (MY / f"{problem['id']}.sql").read_text(encoding="utf-8")
    conn = fresh_db()
    try:
        result = run(conn, sql)
        if problem["verify"]:
            print(f"確認クエリ: {problem['verify']}")
            result = run(conn, problem["verify"])
    except sqlite3.Error as e:
        sys.exit(f"❌ {problem['id']}: SQLエラー: {e}")
    finally:
        conn.close()
    print(f"■ {problem['id']} の実行結果")
    if result is None:
        print("  （結果を返す SELECT がありません）")
    else:
        print_table(*result)
    print()
    check(problem)


def progress(problems):
    total = done = 0
    for week in sorted({p["id"][:3] for p in problems}):
        marks, group = "", None
        counted = week != "W00"  # W00 は答え方の練習なので問題数に数えない
        for p in (p for p in problems if p["id"].startswith(week)):
            g = p["id"][:6] + ("R" if "-R" in p["id"] else "")  # 新出 / 定着 の1日分ごとに区切る
            if group is not None and g != group:
                marks += " "
            group = g
            total += counted
            if not answered(p):
                marks += "・"
            elif "nocheck" in p["flags"]:
                marks += "📝"
                done += counted
            elif check(p, verbose=False):
                marks += "✅"
                done += counted
            else:
                marks += "❌"
        print(f"{week}  {marks}" + ("" if counted else "  （練習）"))
    print(f"\n{done} / {total} 問クリア   (✅正解 ❌不正解 📝自己採点 ・未着手。3問ずつが1日分)")


def selftest(problems):
    bad = 0
    for p in problems:
        try:
            started = time.time()
            res = evaluate(p, p["sql"])
            slow = time.time() - started > 3
            rows = None if res is None else len(res[1])
            warn = "" if rows or "nocheck" in p["flags"] else "  ← 結果が空"
            warn += "  ← 遅い" if slow else ""
            first = "" if not rows else "  " + " | ".join(str(v) for v in res[1][0])[:70]
            print(f"{p['id']}  {str(rows):>5} 行{warn}{first}")
            bad += bool(warn)
        except sqlite3.Error as e:
            bad += 1
            print(f"{p['id']}  エラー: {e}")
    print(f"\n{len(problems)} 問中 {bad} 問に問題あり")
    return bad


def main():
    problems = load_all()
    args = sys.argv[1:]
    if not args:
        progress(problems)
    elif args[0] == "--init":
        init(problems)
    elif args[0] == "--run" and len(args) == 2:
        run_file(problems, args[1])
    elif args[0] == "--selftest":
        targets = [p for p in problems if p["id"].startswith(tuple(a.upper() for a in args[1:]))] if args[1:] else problems
        sys.exit(1 if selftest(targets) else 0)
    else:
        key = args[0].upper()
        targets = [p for p in problems if p["id"] == key] or \
                  [p for p in problems if p["id"].startswith(key + "-") and answered(p)]
        if not targets:
            sys.exit(f"{key} に該当する問題（または解答ファイル）がありません")
        for p in targets:
            check(p)


if __name__ == "__main__":
    main()
