-- pgTAP：COMMENT 中文化（sys/V202610211419）。按版本回放全部迁移后，表／列／约束／函数的最终 COMMENT 不得含日文：
-- 假名、简体中文不用的日文/繁体汉字，以及仅由简体可写汉字组成的日文用词（品目、受注、却下、仕入先、追記専用 等）。失败时列出对象。
BEGIN;
SELECT plan(1);

SELECT is((SELECT string_agg(obj, ', ' ORDER BY obj) FROM (
  SELECT format('%s.%s', c.relname, a.attname) AS obj, d.description AS txt
    FROM pg_description d JOIN pg_class c ON c.oid = d.objoid AND d.classoid = 'pg_class'::regclass
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = d.objsubid WHERE d.objsubid > 0
  UNION ALL
  SELECT c.relname::text, d.description FROM pg_description d JOIN pg_class c ON c.oid = d.objoid AND d.classoid = 'pg_class'::regclass WHERE d.objsubid = 0
  UNION ALL
  SELECT format('%s ON %s', k.conname, c.relname), d.description FROM pg_description d
    JOIN pg_constraint k ON k.oid = d.objoid AND d.classoid = 'pg_constraint'::regclass JOIN pg_class c ON c.oid = k.conrelid
  UNION ALL
  SELECT p.oid::regprocedure::text, d.description FROM pg_description d JOIN pg_proc p ON p.oid = d.objoid AND d.classoid = 'pg_proc'::regclass
) x WHERE txt ~ '[ぁ-ゟ゠-ヿ]|[並仮伝価係倉個値側備働償優冪処別則効動務単収員問囲図報場増変奨実対専導層帰帳庫廃張強従応態慮払抜拡捗捨採換損撥敗時暦暫書査棄検業構標権機歴気決済測満準無現環産異発監盤確礎種範築約納純紙細終組結給総編縦績織義職補製複規視覧親観計記設許証試話該認説読調請識譜議負財貨責買費賃賦質購跡転軸込連週進遅運過適還銀録門開間関階際電響項順須領頭頼題額類顧験齢]|品目|受注|却下|引当|過入荷|出荷|仕入|追記|専用|発注|納期|入荷|得意先|部品|起票|採番|予定|完了|着手|受入|残業|作業|予約|削除|契約|満了|付与|連動|配列|移管|正味|残高|申請|既定|会社|顧客|型番|品番|伝票|担当|行番号|工数|版数|送信|受信|出力|参照先|返品|画面|本体|取消理由|見積|仕訳|棚卸'),
  NULL, '全部 COMMENT 不含日文（假名／日文汉字／日文用词）');

SELECT * FROM finish();
ROLLBACK;
