-- 見本: W00-D1-2「支払方法ごとの注文件数を求めよ。出力列: payment_method, cnt」
--
-- ・列名（別名）は採点されないが、出力列の名前に合わせて AS を付けておくと読みやすい
-- ・「並び順も採点対象」と書かれていない問題は、ORDER BY がなくても、あっても正解になる
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     ターミナルから実行する場合: python3 tokkun.py --run W00-D1-2

SELECT payment_method, COUNT(*) AS cnt
FROM orders
GROUP BY payment_method;
