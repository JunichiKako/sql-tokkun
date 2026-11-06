-- 見本: W00-D1-1「東京都に住む顧客を、customer_id の小さい順に取得せよ。出力列: customer_id, name」
--
-- ・ファイル名は「問題ID.sql」
-- ・「出力列」に書かれた列を、その順番どおりに SELECT する（余計な列を足さない）
-- ・「並び順も採点対象」の問題は ORDER BY を必ず書く
-- ・こういうコメント（-- で始まる行）は自由に書いてよい
--
-- 【試し方】 このファイルを開いたまま Cmd + Shift + B
--     → 下のターミナルに実行結果が出て、続けて ✅正解 / ❌不正解 が表示される
--     ターミナルから実行する場合: python3 tokkun.py --run W00-D1-1

SELECT customer_id, name
FROM customers
WHERE prefecture = '東京都'
ORDER BY customer_id;
