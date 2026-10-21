# メッセージ一覧（消息一览）

| 項目 | 内容 |
|---|---|
| 文書名 | メッセージ一覧（消息一览）（自动生成） |
| 文書番号 | DSN-MTX-007 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 910 件。メッセージID/種別/本文/発生条件/対処/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 | 域 | 提取元 |
|---|---|---|---|---|---|---|
| MSG-FIN-001 | E | 借方合计与贷方合计不一致（差额 {0}），无法保存。 | 借贷不平衡 | 差額行を修正（F-FIN-003/005/006） | FIN | 07-finance/93-messages.md |
| MSG-FIN-002 | E | 科目代码格式不正确（应为 4 位一级科目，明细以点号分隔，如 6602.12）。 | コード形式不正 | 形式修正（F-FIN-001） | FIN | 07-finance/93-messages.md |
| MSG-FIN-003 | E | 期初余额借贷不平衡（借方 {0} / 贷方 {1}，差额 {2}）。 | 期初试算不平衡 | 差额修正後に確定（F-FIN-002） | FIN | 07-finance/93-messages.md |
| MSG-FIN-004 | E | 科目代码「{0}」已存在。 | コード重複 | 別コードを採番（F-FIN-001） | FIN | 07-finance/93-messages.md |
| MSG-FIN-005 | E | 科目「{0}」已有余额或未记账凭证，不能停用或改变余额方向。 | 使用中科目変更 | 先に処理/振替（F-FIN-001） | FIN | 07-finance/93-messages.md |
| MSG-FIN-006 | E | 科目「{0}」已被使用，不能删除。请使用「停用」。 | 削除時使用中 | 停用に切替（F-FIN-001） | FIN | 07-finance/93-messages.md |
| MSG-FIN-007 | E | 科目层级不正确：父科目必须为非末级科目且层级不超过 4 级。 | 階層不正 | 親科目修正（F-FIN-001） | FIN | 07-finance/93-messages.md |
| MSG-FIN-008 | W | 统制科目「{0}」余额与子台账不一致（账面 {1} / 子台账 {2}），请确认。 | 統制科目照合差 | 原因確認・調整（F-FIN-002/035） | FIN | 07-finance/93-messages.md |
| MSG-FIN-009 | E | 该科目未绑定辅助核算维度「{0}」，不能录入该维度。 | 未綁定维度入力 | 科目設定確認（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-010 | E | 该科目余额方向与期初录入方向相反，请确认。 | 残高方向不一致 | 方向修正（F-FIN-002） | FIN | 07-finance/93-messages.md |
| MSG-FIN-011 | E | 制单人与审核人不能为同一人（职务分离要求）。 | SoD 違反（审核） | 別の审核者を指定（F-FIN-005） | FIN | 07-finance/93-messages.md |
| MSG-FIN-012 | E | 记账人与制单人/审核人不能为同一人（参数：记账分离=有效）。 | SoD 違反（記帳） | 別の記帳者を指定（F-FIN-006） | FIN | 07-finance/93-messages.md |
| MSG-FIN-013 | E | 当前凭证状态不允许该操作。 | 状態不整合 | 状態確認（共通 MSG-COM-034 優先可） | FIN | 07-finance/93-messages.md |
| MSG-FIN-014 | E | 科目「{0}」不是末级科目或已停用，不能使用。 | 科目不正 | 末级有効科目選択（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-015 | E | 科目「{0}」不存在或已停用。 | 科目不存在 | 科目再選択（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-016 | E | 摘要不能为空，且不能仅包含符号。 | 摘要不正 | 摘要入力（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-017 | E | 同一行不能同时录入借方和贷方金额，且金额不能为 0。 | 行金額不正 | 借/贷いずれか入力（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-018 | E | 凭证至少需要 2 行分录。 | 行数不足 | 行追加（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-019 | E | 红字冲销只能针对已记账且未冲销的凭证。 | 冲销条件不成立 | 原凭证確認（F-FIN-008） | FIN | 07-finance/93-messages.md |
| MSG-FIN-020 | E | 反记账只能在当前开放期间执行。 | 期間条件不成立 | 期間状態確認（F-FIN-007） | FIN | 07-finance/93-messages.md |
| MSG-FIN-021 | E | 反记账必须填写理由（1～500 字）。 | 理由なし | 理由入力（F-FIN-007） | FIN | 07-finance/93-messages.md |
| MSG-FIN-022 | E | 该分录已被后续业务引用，不能修改。 | 被引用 | 赤伝訂正（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-023 | E | 凭证模板无效或已停用。 | テンプレート無効 | テンプレート確認（F-FIN-004） | FIN | 07-finance/93-messages.md |
| MSG-FIN-024 | E | 辅助核算档案「{0}」已停用或不存在。 | 補助档案不正 | 有効な档案選択（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-025 | E | 凭证日期超出允许范围（所属期间 {0}）。 | 日付範囲外 | 日付修正（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-026 | E | 数量核算科目必须录入数量与单价，且数量×单价应等于金额。 | 数量核算不正 | 数量・単価修正（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-027 | E | 现金/银行存款科目必须选择现金流量项目。 | CF 項目なし | CF 項目選択（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-028 | E | 附件张数不能超过 {0} 张，或附件大小超过限制。 | 添付上限超過 | 添付削減（F-FIN-009） | FIN | 07-finance/93-messages.md |
| MSG-FIN-029 | E | 凭证字号已超过 9999 号，请调整期间或联系管理员。 | 採番枯渇 | 管理者連絡（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-030 | E | 所属会计期间未开放，不能录入凭证。 | 期間 FUTURE | 期間開帳待ち（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-031 | E | 试算平衡校验失败（借方 {0} / 贷方 {1}，差额 {2}）。 | 試算不平衡 | 原因調査（F-FIN-011） | FIN | 07-finance/93-messages.md |
| MSG-FIN-032 | E | 该凭证尚未记账，不能冲销。 | 冲销条件不成立 | 記帳後に冲销（F-FIN-008） | FIN | 07-finance/93-messages.md |
| MSG-FIN-033 | E | 该凭证已被冲销，不能重复冲销。 | 重複冲销 | 既存冲销凭证確認（F-FIN-008） | FIN | 07-finance/93-messages.md |
| MSG-FIN-034 | E | 凭证字与科目/日期不一致（收/付/转规则或期间不一致）。 | 凭证字制約/期間不一致 | 凭证字または科目修正（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-035 | E | 已审核的凭证不能直接修改，请先取消审核。 | 状態不整合 | 取消审核（F-FIN-005） | FIN | 07-finance/93-messages.md |
| MSG-FIN-036 | E | 已记账的凭证不能修改或删除，请使用红字冲销。 | 状態不整合 | 赤伝（F-FIN-008） | FIN | 07-finance/93-messages.md |
| MSG-FIN-037 | I | 凭证已审核。 | 审核成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-038 | I | 凭证已记账。 | 記帳成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-039 | E | 该凭证已作废，不能进行操作。 | 作废済 | 状態確認（F-FIN-003） | FIN | 07-finance/93-messages.md |
| MSG-FIN-040 | E | 该应付单已存在有效凭证，不能重复确认。 | 二重確認 | 既存凭证確認（F-FIN-012） | FIN | 07-finance/93-messages.md |
| MSG-FIN-041 | E | 暂估应付单尚未冲回，不能直接结转。 | 冲回漏れ | 冲回後に処理（F-FIN-014） | FIN | 07-finance/93-messages.md |
| MSG-FIN-042 | E | 发票号码「{0}」已登记，不能重复登记。 | 发票重複 | 既存发票照会（F-FIN-013/026） | FIN | 07-finance/93-messages.md |
| MSG-FIN-043 | E | 三单差异超过容差（差异 {0} / 容差 {1}），必须填写差异理由并审批。 | 容差超 | 理由入力・承認（F-FIN-013） | FIN | 07-finance/93-messages.md |
| MSG-FIN-044 | E | 发票数量超过收货数量（收货 {0} / 发票 {1}），超额部分不能确认应付。 | 数量差異 | 数量修正/保留（F-FIN-013） | FIN | 07-finance/93-messages.md |
| MSG-FIN-045 | E | 发票金额校验失败：税抜额 {0} + 税额 {1} ≠ 价税合计 {2}。 | 金額不整合 | 票面確認（F-FIN-013） | FIN | 07-finance/93-messages.md |
| MSG-FIN-046 | E | 所选税码不是进项税码（tax_type=11），不能用于采购发票。 | 税码不正 | 進項税码選択（F-FIN-013/026） | FIN | 07-finance/93-messages.md |
| MSG-FIN-047 | E | 该发票已认证，不能修改关键字段。 | 認証済変更 | 赤伝・再登録（F-FIN-026） | FIN | 07-finance/93-messages.md |
| MSG-FIN-048 | E | 供应商付款条件未設定，无法计算到期日。 | 付款条件なし | MDM 設定（F-FIN-012） | FIN | 07-finance/93-messages.md |
| MSG-FIN-049 | E | 当前付款申请状态不允许该操作。 | 状態不整合 | 状態確認（F-FIN-015） | FIN | 07-finance/93-messages.md |
| MSG-FIN-050 | I | 应付单已确认。 | 確認成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-051 | E | 该应付单已有核销记录，不能直接作废。请先反核销。 | 作废条件不成立 | 反核销後に作废（F-FIN-012） | FIN | 07-finance/93-messages.md |
| MSG-FIN-052 | I | 核销完成（核销金额 {0}，剩余 {1}）。 | 核销成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-053 | E | 反核销失败：该期间已结账或付款已作废。 | 反核销条件不成立 | 期間・状態確認（F-FIN-017） | FIN | 07-finance/93-messages.md |
| MSG-FIN-054 | E | 申请金额超过可付上限（可付 {0} / 申请 {1}）。 | 申請超過 | 金額修正（F-FIN-015） | FIN | 07-finance/93-messages.md |
| MSG-FIN-055 | E | 付款金额超过申请剩余可付金额（可付 {0} / 付款 {1}）。 | 付款超過 | 金額修正（F-FIN-016） | FIN | 07-finance/93-messages.md |
| MSG-FIN-056 | E | 核销金额超过未核销余额（余额 {0} / 核销 {1}）。 | 核销超過 | 金額修正（F-FIN-017） | FIN | 07-finance/93-messages.md |
| MSG-FIN-057 | E | 反核销只能在开放期间执行，且需付款/应付未结账。 | 条件不成立 | 期間確認（F-FIN-017） | FIN | 07-finance/93-messages.md |
| MSG-FIN-058 | E | 银行付款指令发送失败：{0}。请稍后重试或联系银行。 | 銀企連携失敗 | 再実行/銀行確認（F-FIN-016） | FIN | 07-finance/93-messages.md |
| MSG-FIN-059 | W | 付款后银行账户预计余额为负（余额 {0}），请确认。 | 残高不足 | 口座・金額確認（F-FIN-016） | FIN | 07-finance/93-messages.md |
| MSG-FIN-060 | E | 该应收单已存在有效凭证，不能重复确认。 | 二重確認 | 既存凭证確認（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-061 | E | 应收金额与出荷明細合计不一致（出荷 {0} / 明细 {1}）。 | E10 不整合 | SAL 確認・保留（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-062 | E | 出荷事件的金额与明细合计不一致，已转入待处理。 | E10 不整合 | 出荷データ修正（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-063 | E | 税率不正确（应为 0～100 的有效税率）。 | 税率不正 | 税码確認（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-064 | E | 银行流水号「{0}」已存在，不能重复登记。 | 流水重複 | 既存收款照会（F-FIN-020） | FIN | 07-finance/93-messages.md |
| MSG-FIN-065 | E | 核销金额超过应收未收余额（可核销 {0} / 本次 {1}）。 | 核销超過 | 金額修正（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-066 | E | 核销合计超过收款未核销金额（可核销 {0} / 本次 {1}）。 | 核销超過 | 金額修正（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-067 | E | 反核销失败：期间已结账或收款已作废。 | 条件不成立 | 期間・状態確認（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-068 | E | 开票金额超过应收金额（应收 {0} / 累计开票 {1} / 本次 {2}）。 | 開票超過 | SAL 確認（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-069 | E | 该收款单已有核销记录，不能直接作废，请先反核销。 | 作废条件不成立 | 反核销後作废（F-FIN-020） | FIN | 07-finance/93-messages.md |
| MSG-FIN-070 | I | 收款已确认，核销完成（未核销 {0} 转为预收）。 | 確認成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-071 | W | 该客户应收余额已超过信用额度（额度 {0} / 使用 {1}），请销售确认。 | 与信超過 | SAL 連絡（F-FIN-022） | FIN | 07-finance/93-messages.md |
| MSG-FIN-072 | E | 预收账款与应收单的客户不一致，不能核销。 | 取引先不一致 | 取引先確認（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-073 | E | 收款方式与银行账户不匹配（银行转账必须选择账户）。 | 口座不備 | 口座選択（F-FIN-020） | FIN | 07-finance/93-messages.md |
| MSG-FIN-074 | W | 客户对账单存在未核对差异 {0}，请与客户确认。 | 対账差異 | 差異調査（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-075 | E | 该客户坏账准备已计提，不能重复计提。 | P2 二重計提 | 既存計提確認（F-FIN-022） | FIN | 07-finance/93-messages.md |
| MSG-FIN-076 | E | 应收票据管理尚未启用，请使用银行收款。 | 未実装機能 | 実装順 P2 対応（F-FIN-020） | FIN | 07-finance/93-messages.md |
| MSG-FIN-077 | E | 该客户信用状态为冻结，不能登记新的应收。 | 与信凍結 | SAL/財務確認（F-FIN-019） | FIN | 07-finance/93-messages.md |
| MSG-FIN-078 | E | 收款日期不能早于应收单的业务日期。 | 日付不整合 | 日付修正（F-FIN-020） | FIN | 07-finance/93-messages.md |
| MSG-FIN-079 | E | 核销对象已结清，不能再次核销。 | 結清済 | 対象再選択（F-FIN-021） | FIN | 07-finance/93-messages.md |
| MSG-FIN-080 | E | 现金日记账金额无效（借贷方向与金额不一致）。 | 金額不整合 | 修正（F-FIN-023） | FIN | 07-finance/93-messages.md |
| MSG-FIN-081 | E | 现金盘点差异必须填写原因（差异 {0}）。 | 盤点差理由なし | 原因入力（F-FIN-023） | FIN | 07-finance/93-messages.md |
| MSG-FIN-082 | E | 该银行账户的 {0} 期间对账单已导入，不能重复导入。 | 重複取込 | 既存批次確認（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-083 | E | 银行账户未设置或已停用，请联系管理员。 | 口座不備 | 口座設定（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-084 | E | 余额调节表不平衡（调节后企业 {0} / 调节后银行 {1}，差额 {2}）。 | 調節表不一致 | 未達事項確認（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-085 | W | 申报辅助表与总账应交税费发生额存在差异 {0}，请确认。 | 照合差 | 差異理由記録（F-FIN-027） | FIN | 07-finance/93-messages.md |
| MSG-FIN-086 | E | 该期间的申报辅助表已确认，不能重新生成；如需修正请先取消确认。 | 確認済再生成 | 取消確認（F-FIN-027） | FIN | 07-finance/93-messages.md |
| MSG-FIN-087 | W | 当期应纳税额小于 0（留抵），附加税费计税依据按 0 计算。 | 留抵 | 情報表示（F-FIN-028） | FIN | 07-finance/93-messages.md |
| MSG-FIN-088 | W | 当期利润总额小于 0（亏损），所得税计提金额按 0 处理。 | 亏损 | 情報表示（F-FIN-028） | FIN | 07-finance/93-messages.md |
| MSG-FIN-089 | E | 该期间同一税种已计提，不能重复计提。 | 計提重複 | 既存計提赤伝訂正（F-FIN-028） | FIN | 07-finance/93-messages.md |
| MSG-FIN-090 | I | 银行对账完成：自动匹配 {0} 件，未达 {1} 件。 | 対账完了 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-091 | I | 增值税申报辅助表已生成（应纳税额 {0}，留抵 {1}）。 | 生成完了 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-092 | E | 对账单列映射不完整，缺少必需列：{0}。 | 列マッピング不足 | マッピング修正（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-093 | E | 对账单文件解析失败，请使用银行提供的标准格式。 | ファイル不正 | ファイル確認（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-094 | W | 银行账户余额不足（余额 {0} / 付款 {1}），请确认资金。 | 残高不足 | 入金/口座変更（F-FIN-016） | FIN | 07-finance/93-messages.md |
| MSG-FIN-095 | E | 进项发票勾选状态更新失败：{0}。 | 認証 IF 失敗 | 再実行（F-FIN-026） | FIN | 07-finance/93-messages.md |
| MSG-FIN-096 | W | 附加税计税依据为 0，本期不计提附加税费。 | 応納税額 0 | 情報表示（F-FIN-028） | FIN | 07-finance/93-messages.md |
| MSG-FIN-097 | I | 资金日报正在生成，请稍后刷新。 | 非同期処理中 | 再表示（F-FIN-025） | FIN | 07-finance/93-messages.md |
| MSG-FIN-098 | E | 该账户期间尚未导入对账单，不能进行对账。 | 対账单なし | 取込（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-099 | E | 余额调节表尚未复核，不能结账。 | 未復核 | 復核依頼（F-FIN-024） | FIN | 07-finance/93-messages.md |
| MSG-FIN-100 | E | 自动凭证模板代码「{0}」已存在。 | 重複 | 別コード（F-FIN-029） | FIN | 07-finance/93-messages.md |
| MSG-FIN-101 | I | 自动凭证已生成（{0} 张）。 | 生成成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-102 | E | 自动凭证生成失败：借贷不平衡或金额计算异常（事件 {0}）。 | 計算失敗 | テンプレート/payload 確認（F-FIN-030） | FIN | 07-finance/93-messages.md |
| MSG-FIN-103 | E | 自动凭证处理连续失败 10 次，已转入死信队列。 | DEAD_LETTER | ログ確認・手動再処理（F-FIN-030） | FIN | 07-finance/93-messages.md |
| MSG-FIN-104 | E | 未找到适用于事件「{0}」的自动凭证模板，请检查模板配置。 | テンプレート無 | テンプレート登録（F-FIN-029） | FIN | 07-finance/93-messages.md |
| MSG-FIN-105 | E | 模板「{0}」的借贷合计不一致（借 {1} / 贷 {2}）。 | テンプレート検証 | 行修正（F-FIN-029） | FIN | 07-finance/93-messages.md |
| MSG-FIN-106 | E | 税种「{0}」没有对应的科目映射，请检查科目表。 | 税種マップ無 | 科目マッピング（F-FIN-029） | FIN | 07-finance/93-messages.md |
| MSG-FIN-107 | E | 金额表达式计算异常（模板 {0}，行 {1}）：{2}。 | DSL 評価失敗 | 式修正（F-FIN-029） | FIN | 07-finance/93-messages.md |
| MSG-FIN-108 | E | 事件「{0}」的目标期间已结账，已暂停处理。 | 期間 CLOSED | 期間確認・翌期処理（F-FIN-030） | FIN | 07-finance/93-messages.md |
| MSG-FIN-109 | I | 该事件已处理，已跳过（幂等）。 | 重複イベント | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-110 | I | 制造费用分配完成：分配率 {0}，生成凭证 {1}。 | 分配成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-111 | I | 成本计算完成：完工产品 {0} 件，在制品 {1} 件。 | 計算成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-112 | W | 以下成本对象存在异常（负库存/无报工/无BOM）：{0}，未参与计算。 | 異常対象 | マスタ・実績修正後に再実行（F-FIN-031） | FIN | 07-finance/93-messages.md |
| MSG-FIN-113 | E | 生产成本科目余额与在制品合计不一致（科目 {0} / WIP {1}），不能确认成本。 | 照合差 | 原因調査（F-FIN-033） | FIN | 07-finance/93-messages.md |
| MSG-FIN-114 | E | 制造费用科目期末仍有余额 {0}，分配未完成。 | 分配漏れ | 分配再実行（F-FIN-032） | FIN | 07-finance/93-messages.md |
| MSG-FIN-115 | E | 该期间成本已确认，如需重算请先由财务总监取消确认。 | 再計算 | 取消→再計算（F-FIN-031） | FIN | 07-finance/93-messages.md |
| MSG-FIN-116 | E | 在库月结（E20）未完成，不能执行成本计算。 | 前提未成立 | 在庫月結を先に実行（F-FIN-031） | FIN | 07-finance/93-messages.md |
| MSG-FIN-117 | W | 未设定标准成本，本期不进行成本差异分析。 | 標準原価なし | 標準原価設定（第一版） | FIN | 07-finance/93-messages.md |
| MSG-FIN-118 | E | 成本计算结果为空，请检查成本对象与归集数据。 | 結果 0 件 | 対象確認（F-FIN-031） | FIN | 07-finance/93-messages.md |
| MSG-FIN-119 | E | 制造费用分配基准合计为 0，无法计算分配率。 | 基準 0 | 基準データ確認（F-FIN-032） | FIN | 07-finance/93-messages.md |
| MSG-FIN-120 | E | 该期间存在未记账凭证（{0} 张），不能结账。 | 未記帳あり | 审核・記帳完了（F-FIN-035） | FIN | 07-finance/93-messages.md |
| MSG-FIN-121 | I | 会计期间 {0} 已开账。 | 開帳成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-122 | E | 月结检查未通过（{0} 项 NG），不能结账；如需强制结账请由财务总监批准。 | チェック NG | NG 解消（F-FIN-035） | FIN | 07-finance/93-messages.md |
| MSG-FIN-123 | I | 会计期间 {0} 已结账，下一期间 {1} 已开账。 | 月結成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-124 | W | 期间 {0} 已重新开启，所有后续报表需重新生成。 | 再開 | 理由記録・再計算（F-FIN-035） | FIN | 07-finance/93-messages.md |
| MSG-FIN-125 | E | 年结失败：12 月未结账或年结检查未通过（{0}）。 | 年結条件不成立 | 12 月月結・検査（F-FIN-037） | FIN | 07-finance/93-messages.md |
| MSG-FIN-126 | E | 损益结转后损益类科目仍有余额（{0}），请检查结转范围。 | 転記検証 | 科目範囲確認（F-FIN-036） | FIN | 07-finance/93-messages.md |
| MSG-FIN-127 | E | 该期间已执行损益结转，不能重复执行。 | 二重転記 | 期間再開後に再実行（F-FIN-036） | FIN | 07-finance/93-messages.md |
| MSG-FIN-128 | E | 资产负债表不平衡（资产 {0} / 负债和所有者权益 {1}，差额 {2}），请检查科目余额。 | BS 不一致 | 原因調査（F-FIN-038） | FIN | 07-finance/93-messages.md |
| MSG-FIN-129 | E | 该期间尚未结账，法定报表只能预览，不能正式输出。 | 未 CLOSED | 月結完了（F-FIN-038） | FIN | 07-finance/93-messages.md |
| MSG-FIN-130 | E | 科目余额表借贷合计不一致（借 {0} / 贷 {1}），请检查余额数据。 | 試算不平衡 | 原因調査（F-FIN-039） | FIN | 07-finance/93-messages.md |
| MSG-FIN-131 | W | 该期间已重新开启，报表快照已失效，请重新生成。 | 再開後の快照 | 再生成（F-FIN-038） | FIN | 07-finance/93-messages.md |
| MSG-FIN-132 | W | 现金流量表与现金科目余额变动不一致（差异 {0}），请检查现金流量项目标记。 | CF 不一致 | CF 項目確認（F-FIN-038） | FIN | 07-finance/93-messages.md |
| MSG-FIN-133 | I | 年结完成：本年利润 {0} 转入未分配利润，下一会计年度已开账。 | 年結成功 | — | FIN | 07-finance/93-messages.md |
| MSG-FIN-134 | E | 标准成本发布失败：适用开始期间 {0} 不晚于当前有效版本的开始期间 {1}，或该期间成本已结账。 | 発行期間不正 | 開始期間を有効版より後かつ未結帳期間に変更（F-FIN-047） | FIN | 07-finance/93-messages.md |
| MSG-FIN-135 | E | 标准成本版本「{0}」不是草稿状态，不能编辑或发布。 | 状態不正（発行関数を経ずに直接変更する場合も含む） | 新版本を登録（F-FIN-047） | FIN | 07-finance/93-messages.md |
| MSG-FIN-136 | E | 物料「{0}」的标准成本版本「{1}」已存在。 | 版本重複 | 別版本コード（F-FIN-047） | FIN | 07-finance/93-messages.md |
| MSG-INT-001 | E | 接口代码格式不正确（应为 IF-INT-三位数字）。 | 形式違反 | 修正 | INT | 09-integration/01-integration-config.md |
| MSG-INT-002 | E | 接口代码已存在，请勿重复登记。 | 一意違反 | 既存を編集 | INT | 09-integration/01-integration-config.md |
| MSG-INT-003 | E | 连接测试失败：{0}。请检查地址、证书与网络。 | テスト失敗 | 設定・NW 確認 | INT | 09-integration/01-integration-config.md |
| MSG-INT-004 | E | 超时、重试或退避参数超出允许范围。 | 値域違反 | 修正 | INT | 09-integration/01-integration-config.md |
| MSG-INT-005 | E | 该接口当前状态不允许此操作。 | 状態不整合 | 状態確認 | INT | 09-integration/01-integration-config.md |
| MSG-INT-006 | E | 连接测试未通过或已超过 24 小时，不能启用。 | 有効化条件不足 | 再テスト | INT | 09-integration/01-integration-config.md |
| MSG-INT-007 | E | 字段映射未定义或不完整。 | マッピング不備 | 定義追加 | INT | 09-integration/01-integration-config.md |
| MSG-INT-008 | E | 认证信息读取失败，请联系系统管理员。 | Secrets 参照失敗 | 情報部へ連絡 | INT | 09-integration/01-integration-config.md |
| MSG-INT-009 | W | 认证信息将在 {0} 天后到期，请及时更新。 | 期限警告 | ローテーション | INT | 09-integration/01-integration-config.md |
| MSG-INT-010 | W | 调用频率超过限制，已进入等待队列。 | レート超過 | 待機 | INT | 09-integration/01-integration-config.md |
| MSG-INT-020 | E | 税局拒绝了开票请求（原因：{0}），请修正后重新发送。 | 税局拒否 | 内容修正→同一流水号で再送 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-021 | E | 开票信息不完整或通信失败，请检查购买方信息与网络后重试。 | 項目不備/通信失敗 | 項目確認・再送 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-022 | E | 金额与税额之和不等于价税合计。 | 金額不整合 | 金額修正 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-023 | E | 税率无效或税码不存在。 | 税率不正 | 税コード確認 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-024 | I | 数电票已开具，发票号码：{0}。 | 受理成功 | 交付確認へ | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-025 | I | 发票已交付给购买方。 | 交付成功 | — | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-026 | E | 该发票不能开具红字发票（未发行或已红冲）。 | 赤伝不可 | 元発票確認 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-027 | I | 红字发票已开具。 | 赤伝成功 | AR 調整へ | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-030 | E | 发票查验不一致：发票号码 {0}，请核对金额、日期与销售方。 | 査験不一致 | 発票再確認 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-031 | W | 该发票风险等级为高，请谨慎确认用途。 | リスク高 | 財務責任者確認 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-040 | E | 银行返回账户信息不符（{0}），请核对收款账户与联行号。 | 口座相違 | 口座マスタ修正（承認要） | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-041 | E | 银行账户余额不足，无法完成付款。 | 残高不足 | 入金/口座変更 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-042 | E | 付款金额必须大于 0。 | 金額不正 | 修正 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-043 | E | 收款账号格式不正确（应为 8〜32 位数字）。 | 形式エラー | 修正 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-044 | E | 联行号格式不正确（应为 12 位数字）。 | 形式エラー | 修正 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-045 | E | 付款金额与已批准的付款申请金额不一致。 | 金額不一致 | 申請と照合 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-046 | W | 银行返回结果不明，系统将在稍后自动查询，请勿重复发送。 | 状態不明 | 照会待ち | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-050 | E | 对账单文件格式不正确（第 {0} 行：{1}），已取消本次导入。 | 形式エラー | テンプレート確認 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-051 | E | 对账单明细行数与文件头件数不一致。 | 件数不一致 | ファイル再取得 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-052 | W | 该对账单文件已导入（批次 {0}），本次不重复导入。 | 重複 | 既存批次参照 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-053 | E | 对账单移交财务失败，请稍后重试。 | FIN 引渡失敗 | 再引渡 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-054 | E | 文件行数超过上限（{0} 行）。 | 行数超過 | 分割 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-055 | E | 第 {0} 行缺少必填项「{1}」。 | 必須漏れ | 修正 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-056 | E | 第 {0} 行的代码「{1}」不存在或已失效。 | コード不存在 | マスタ確認 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-057 | W | 导入完成：成功 {0} 行，失败 {1} 行。 | 部分成功 | エラー行修正 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-060 | E | 与外部系统的通信失败（{0}），系统将按计划重试。 | 通信失敗 | 監視・再送 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-061 | E | 报工对应的工单不存在或状态不正确。 | 工单不存在 | 工单確認 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-062 | I | 检测到重复报文，已忽略（外部单号：{0}）。 | 重複受信 | なし | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-063 | E | 报工数量不满足投入 ≥ 良品 + 不良 + 报废。 | 数量不整合 | MES 側修正 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-064 | E | 工序或工作中心未在 MES 中登记。 | マスタ不整合 | マスタ登録 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-065 | E | BOM/工艺版本重复或适用日期冲突。 | 版数競合 | 承認者が調整 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-066 | E | PDA 终端未授权或已停用，请联系管理员。 | 端末不正 | 端末再登録 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-067 | E | 报工数量超过工单允许的超出率。 | 過剰報工 | 数量修正 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-068 | E | 报工日期无效或会计期间已关闭。 | 日付/期間 | 日付修正 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-069 | E | 工单版本不一致，请先重新下发。 | 版数不一致 | 再下发 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-070 | E | 已达最大重试次数，任务转为死信，请联系运维处理。 | 死信 | 手動再送/修正 | INT | 09-integration/02-tax-bank-interface.md |
| MSG-INT-071 | E | 离线补传序号缺失或重复，已暂挂该批次。 | 補伝不整合 | 端末再送 | INT | 09-integration/03-mes-wms-plm.md |
| MSG-INT-072 | E | 该任务当前状态不允许重试。 | 状態不整合 | 状態確認 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-073 | W | 单次最多重试 500 件，已切换为异步任务。 | 件数超過 | ジョブ確認 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-074 | W | 接口熔断中，暂不发送，将在 {0} 后重试。 | サーキット OPEN | 待機 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-075 | I | 重试完成：成功 {0} 件，失败 {1} 件。 | 再送完了 | 失敗分確認 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-080 | E | 指定的权限范围无效。 | scope 不正 | 修正 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-081 | E | IP 地址格式不正确。 | 形式エラー | 修正 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-082 | E | 签名验证失败或请求时间超时，请检查密钥与服务器时间。 | 署名/時刻 | 設定確認 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-083 | E | 请求重复（nonce 已使用），请重新生成。 | nonce 再利用 | 再生成 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-088 | W | 日次对账发现差异（{0} 件，金额 {1} 元），请确认。 | 対账差異 | 原因調査 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-089 | E | 对账数据获取失败，请稍后重试。 | 照会失敗 | 再実行 | INT | 09-integration/05-sync-monitor.md |
| MSG-INT-090 | E | 通知渠道未启用或配置不正确。 | チャネル無効 | 設定確認 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-091 | E | 通知接收地址无效。 | 宛先不正 | 修正 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-092 | W | 通知发送失败，系统将自动重试（第 {0} 次）。 | 送信失敗 | 監視 | INT | 09-integration/04-openapi-file-notify.md |
| MSG-INT-095 | I | 对账完成，无差异。 | 差異 0 | — | INT | 09-integration/05-sync-monitor.md |
| MSG-COM-002 | I | 删除しました。 | — | — | INV | 05-inventory/07-reports.md |
| MSG-COM-006 | I | 操作成功，但部分数据失败（成功 {0} 件，失败 {1} 件）。 | 一括処理の部分成功 | 失敗一覧を確認 | INV | 05-inventory/02-inbound-outbound.md |
| MSG-COM-012 | C | 该操作不可撤销，是否继续？ | 過账・沖销前確認 | OK/キャンセル | INV | 05-inventory/02-inbound-outbound.md |
| MSG-INV-001 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-004 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-005 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-006 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-007 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-008 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-009 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-010 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-011 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-012 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-013 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-015 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-016 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-017 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-018 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-020 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-021 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-022 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-023 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-024 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-025 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-026 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-027 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-028 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-029 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-031 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-032 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-033 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-035 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-036 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-037 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-038 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-039 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-040 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-041 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-042 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-043 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-044 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-045 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-046 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-047 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-048 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-050 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-051 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-052 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-053 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-054 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-055 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-056 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-057 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-058 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-059 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-060 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-061 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-062 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-063 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-064 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-065 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-066 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-INV-067 |  |  |  |  | INV | 05-inventory/93-messages.md |
| MSG-COM-048 | 範囲 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-011 | コード存在 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-012 | コード存在 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-013 | E | 物料編碼は 10 桁（分類 4 桁＋流水 6 桁）で、分類コードと一致する必要があります。 | コード形式不正 | 自動採番を使用 | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-014 | 一意 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-015 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-016 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-017 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-018 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-019 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-020 | I | 承認が完了し、物料を有効化しました。 | 最終承認 | — | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-021 | W | 申請が差戻されました。内容を修正して再提出してください。 | 差戻し | 修正・再提出 | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-022 | E | 申請が却下されました。理由：{0} | 却下 | 理由確認、再申請 | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-023 | I | 物料「{0}」を有効化しました。関連業務に反映されます（最大 5 分）。 | 有効化 | — | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-024 | I | 物料「{0}」を使用停止にしました。新規の業務利用はできません。 | 使用停止 | — | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-025 | I | 物料「{0}」の使用を再開しました。 | 再開 | — | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-026 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-027 | 相関 |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-028 | 業務チェック |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-029 |  |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-030 |  |  |  |  | MDM | 02-mdm/01-material-master.md |
| MSG-MDM-040 | I | 承認が完了し、取引先を有効化しました。 | 最終承認 | — | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-041 | I | 取引先「{0}」を有効化しました。 | 有効化 | — | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-042 | I | 取引先「{0}」を使用停止にしました。新規の業務利用はできません。 | 使用停止 | — | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-043 | I | 供应商「{0}」を合格供应商（AVL）に登録しました。 | 准入承認 | — | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-050 | 形式/一意 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-051 | 形式/一意 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-052 | 相関 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-053 | 必須（条件） |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-054 | 相関 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-055 | 形式 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-056 | 業務 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-057 | 必須 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-058 | 範囲 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-059 | 相関 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-060 | 形式 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-061 | 相関 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-062 | 業務 |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-063 |  |  |  |  | MDM | 02-mdm/02-business-partner.md |
| MSG-MDM-070 | I | 倉庫「{0}」を登録しました。 | 登録完了 | — | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-071 | 形式/一意 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-072 | 相関 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-073 | 形式/一意 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-074 | 形式/一意 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-075 | 業務 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-076 | 業務 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-077 | 相関 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-078 | E | 庫位ラベルの条码規則が設定されていません。条码規則を設定してください。 | 条码規則なし | 設定 | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-079 | 上限 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-080 | 上限 |  |  |  | MDM | 02-mdm/03-warehouse-location.md |
| MSG-MDM-090 | I | 登録しました。 | 単位・通貨・税碼登録 | — | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-091 | 形式/一意 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-092 | I | 「{0}」を使用停止にしました。既存データの参照は可能です。 | 使用停止 | — | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-093 | 形式/一意 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-094 | 一意 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-095 | 範囲/相関 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-096 | 一意 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-097 | 相関 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-098 | 範囲/一意 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-099 | 範囲 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-100 | コード存在 |  |  |  | MDM | 02-mdm/04-uom-currency-tax.md |
| MSG-MDM-110 | I | 価格表の承認が完了しました。 | 承認 | — | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-111 | I | 価格表「{0}」を有効化しました。関連業務に反映されます。 | 有効化 | — | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-112 | I | 価格表「{0}」を終了しました。 | 期間満了/停止 | — | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-113 |  |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-114 | 形式/一意 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-115 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-116 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-117 | 業務 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-118 | 範囲 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-119 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-120 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-121 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-122 | 形式 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-123 | 相関 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-124 | 一意 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-125 | 権限 |  |  |  | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-130 | E | 指定した銀行が存在しないか有効ではありません。 | 銀行不正 | 修正 | MDM | 02-mdm/05-price-settlement.md |
| MSG-MDM-141 | 業務 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-142 |  |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-143 |  |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-144 |  |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-145 |  |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-146 | I | 与信超過の承認申請を送信しました。承認まで出荷できません。 | 承認設定で超過 | 承認待ち | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-147 | 一意 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-148 | 範囲 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-150 | 業務 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-151 | 範囲 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-152 | 業務 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-153 | 業務 |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-154 |  |  |  |  | MDM | 02-mdm/06-credit-supplier-eval.md |
| MSG-MDM-171 | 相関 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-172 | 業務 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-173 | 一意 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-174 | 範囲 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-176 | 相関 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-177 | 一意 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-180 | I | 変更申請を承認しました。対象マスタへ反映します。 | 承認 | — | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-181 | I | 変更内容を反映しました。関連業務に通知されます。 | 反映 | — | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-182 | 相関 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-183 | 権限 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-190 | I | 品質問題を担当者に割り当てました。 | 割当 | — | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-191 | 上限 |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-MDM-195 |  |  |  |  | MDM | 02-mdm/07-substitute-barcode-governance.md |
| MSG-PRD-001 | E | 指定した品目は製造品ではありません。製造品または委外品を選択してください。 | 品目区分不一致 | 品目を変更 | PRD | 06-production/93-messages.md |
| MSG-PRD-002 | E | 承認前の受注からは工单を作成できません。 | 受注状態 < 25 | 受注承認後に再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-003 | E | 変更後の数量が既入庫数量を下回っています。 | 数量減が入庫実績未満 | 数量を確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-004 | W | 計画着手日が過去日です。このまま登録しますか？ | 過去日指定 | 確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-005 | E | 起案者と承認者が同一のため承認できません。 | 自己承認 | 別の承認者へ | PRD | 06-production/93-messages.md |
| MSG-PRD-006 | E | 使用中のため削除できません。使用停止を検討してください。 | マスタ参照中 | 使用停止 | PRD | 06-production/93-messages.md |
| MSG-PRD-007 | E | 工单で参照済みの BOM 明細は削除できません。BOM を廃止してください。 | 参照済み明細削除 | 版数更新で廃止 | PRD | 06-production/93-messages.md |
| MSG-PRD-008 | E | BOM の変更には承認が必要です。承認申請してください。 | 未承認の変更確定 | 承認申請 | PRD | 06-production/93-messages.md |
| MSG-PRD-009 | I | 保存しました。 | 登録・更新成功 | — | PRD | 06-production/93-messages.md |
| MSG-PRD-010 | E | BOM に循環参照があります。親子関係を確認してください。 | 自己参照・間接循環 | BOM 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-011 | E | 同一品目・同一期間に有効な BOM が既に存在します。有効期間を確認してください。 | 期間重複 | 期間修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-012 | E | 承認済以降の BOM は直接編集できません。新版本を登録してください。 | 承認済編集 | 新版本登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-013 | E | 损耗率は 0 以上 0.95 未満で入力してください。 | 範囲外 | 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-014 | E | 工作中心が工場と一致しないか、無効です。 | 工作中心不整合 | 再選択 | PRD | 06-production/93-messages.md |
| MSG-PRD-015 | E | 工序 SEQ が重複しています。 | SEQ 重複 | 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-016 | W | BOM の有効期間が切れています。新版を登録してください。 | 有効期間外参照 | 新版登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-017 | E | 基準数量は 0 より大きい値を入力してください。 | 基準数量 ≤ 0 | 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-018 | E | 子品目の単位が基本単位と換算できません。 | 単位換算不可 | 単位修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-019 | W | 標準原価が未設定です。成本卷算を実行してください。 | 標準単価なし | 卷算実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-020 | E | 有効な BOM がありません。BOM を登録・承認してください。 | BOM なし。工单登録・草稿保存・承認提出では警告（warnings[]、処理続行）、下达で材料明細 0 行時はエラー（422／60020）（蓝色大肥鱼 2026-10-21 PR #37 決定） | BOM 登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-021 | E | 有効な工艺路线がありません。工艺路线を登録してください。 | 工艺なし。品目選択・保存では警告（warnings[]、処理続行）、承認で工序明細 0 行時はエラー（422／60021）（蓝色大肥鱼 2026-10-21 決定） | 工艺登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-022 | E | BOM の単位と物料の基本単位が整合しません（換算不可）。 | 単位不整合（同一単位でも同一換算グループでもない、または換算率なし）。BOM 保存（CHK-PRD-001-09、BOM API 実装時に接続）、工单下达時の BOM 展開・既存材料明細、材料明細の手動追加・編集（CHK-PRD-002-10）で 422／60022 | BOM・単位換算マスタを修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-023 | E | MRP の対象品目がありません。計画パラメータを確認してください。 | 対象 0 件 | パラメータ確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-024 | W | 在庫データに不整合があります。在庫を確認してください。 | マイナス在庫等 | 在庫確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-025 | E | 実行日は過去 30 日以内の日付を指定してください。 | 実行日範囲外 | 日付修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-026 | E | 発注数量が最小起订量・発注倍数を満たしていません。 | ロット規則違反 | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-027 | E | この計画订单は既に転送済み、または取消済みです。 | 二重転送 | 最新状態確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-028 | E | 計画订单の転送に失敗しました。再実行してください。 | 転送失敗 | 再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-029 | E | 他の MRP が実行中です。完了後に再実行してください。 | 二重実行 | 完了待ち | PRD | 06-production/93-messages.md |
| MSG-PRD-030 | E | 工单の材料明細にない物料、または領料数量が上限を超えています。 | 材料不一致/超領 | 材料・数量確認（超領は承認） | PRD | 06-production/93-messages.md |
| MSG-PRD-031 | E | 領料の確定に失敗しました。在庫の引当状況を確認してください。 | E22/INV 連携失敗 | 再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-032 | E | 投入数量と良品・不良・报废の合計が一致しません。 | 数量不整合 | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-033 | E | 在庫出庫済のため取消できません。先に在庫の逆出庫を行ってください。 | 取消不可 | 赤伝処理 | PRD | 06-production/93-messages.md |
| MSG-PRD-034 | E | 退料数量が領料数量を超えています。 | 過剰退料 | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-035 | W | 倒冲対象の在庫が不足しています。不足分は手動で領料してください。 | 倒冲不足 | 手動領料 | PRD | 06-production/93-messages.md |
| MSG-PRD-036 | E | 確定後 24 時間を超えた報工は取消できません。赤伝で処理してください。 | 取消期限超過 | 赤伝 | PRD | 06-production/93-messages.md |
| MSG-PRD-037 | E | 指定した批次の在庫がありません。批次を再選択してください。 | 批次なし | 再選択 | PRD | 06-production/93-messages.md |
| MSG-PRD-038 | E | 指定した物料は当該 BOM の替代料ではありません。 | 替代不許可 | 替代料確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-039 | E | 不良明細の数量合計が不良数量と一致しません。 | 明細不一致 | 明細修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-040 | E | 完工数量が許容上限（allowed_qty）を超えています。 | completed_qty 累計 > allowed_qty（MTS、または超産承認後も超過） | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-041 | E | 工数の合計が作業者別工数の合計と一致しません。 | 工数不一致 | 工数修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-042 | E | 报废を登録するには NCR を起票してください。 | 报废時 NCR なし | NCR 起票 | PRD | 06-production/93-messages.md |
| MSG-PRD-043 | E | 同一工单・工程・日付・シフトの報工が既に存在します。重複登録できません。 | 重複報工 | 既存報工を確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-044 | E | 下达に失敗しました。時間をおいて再実行してください。 | E21 発行失敗 | 再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-045 | W | 一部材料の引当が不足しています。不足分は補充手配が必要です。 | 引当不足 | 補充請購 | PRD | 06-production/93-messages.md |
| MSG-PRD-046 | E | 実績のある工单は取消できません。先に領料・報工・入庫を取消してください。 | 実績あり取消 | 実績取消 | PRD | 06-production/93-messages.md |
| MSG-PRD-047 | E | 保留中の工单は下达・報工・入庫できません。 | 保留中 | 保留解除 | PRD | 06-production/93-messages.md |
| MSG-PRD-048 | E | 拆分明細の数量合計が元工单数量と一致しません。 | 拆分合計不一致 | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-049 | E | 合并条件（品目・工場・BOM/工艺・納期）が一致しない工单は合并できません。 | 合并条件不一致 | 対象見直し | PRD | 06-production/93-messages.md |
| MSG-PRD-050 | W | 工作中心の能力を超過しています。日程調整を検討してください。 | 負荷率 > 1.0 | 日程調整・外注 | PRD | 06-production/93-messages.md |
| MSG-PRD-051 | E | 子工单の作成に失敗しました。処理をロールバックしました。 | 多阶作成失敗 | 再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-052 | W | 計画订单の必要日が過去のため即時発注として扱います。 | 着手日 < 実行日 | 即時発注 | PRD | 06-production/93-messages.md |
| MSG-PRD-053 | E | MPS の期間が重複しています。 | MPS 重複 | 期間修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-054 | E | 受注数量が予測数量を超えています。需要の二重計上を確認してください。 | 予測消費設定の不整合 | 設定確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-055 | W | 選択した工单の一部は状態が異なるため処理できません。 | 一括処理の状態混在 | 対象確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-056 | E | 工单品目与销售订单行品目不一致。 | 工单 material_id ≠ 受注行 material_id（G2-18） | 品目を受注行に合わせる | PRD | 06-production/93-messages.md |
| MSG-PRD-060 | E | 検査未合格の工序は次工程へ進めません。 | IPQC 未合格 | 検査完了・特采承認 | PRD | 06-production/93-messages.md |
| MSG-PRD-061 | W | 適用可能な検査標準がありません。手動で検査項目を入力してください。 | 標準未設定 | 標準登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-062 | E | 完成品検査（FQC）が合格していないため入庫できません。 | FQC 未合格 | 検査完了/特采 | PRD | 06-production/93-messages.md |
| MSG-PRD-063 | E | 指定した検査標準は有効期間外または未承認です。 | 標準期間外 | 標準確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-064 | E | この判定には質量主管の承認が必要です。 | 特采・报废の無承認 | 承認申請 | PRD | 06-production/93-messages.md |
| MSG-PRD-065 | E | 処置数量の合計が不合格数量と一致しません。 | 処置数量不一致 | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-066 | E | 判定確定後の検査単は取消できません（管理者のみ取消可）。 | 権限なし取消 | 管理者へ依頼 | PRD | 06-production/93-messages.md |
| MSG-PRD-067 | E | 実測値と判定が整合していません。再確認してください。 | 判定不整合 | 値・判定修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-068 | E | 未完了の処置があるため NCR を完了できません。 | 処置未完了 | 処置完了 | PRD | 06-production/93-messages.md |
| MSG-PRD-069 | E | 返品が起票されていません。購買の返品処理を先に実行してください。 | 返品未起票 | PUR で返品起票 | PRD | 06-production/93-messages.md |
| MSG-PRD-070 | W | 該当する追溯データがありません。 | 追溯 0 件 | キー確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-071 | E | 検査の判定が未完了のため入庫できません。 | 検査未判定 | 判定完了 | PRD | 06-production/93-messages.md |
| MSG-PRD-072 | W | 検査単の起票時に標準が見つからず、手動項目で作成しました。 | 起票時の標準なし | 標準登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-073 | E | 同一項目の判定が未入力です。 | 項目未判定 | 判定入力 | PRD | 06-production/93-messages.md |
| MSG-PRD-074 | E | NCR の承認が完了していないため処置を実行できません。 | NCR 未承認 | 承認待ち | PRD | 06-production/93-messages.md |
| MSG-PRD-075 | E | 結案条件を満たしていません。{0} | 結案条件未達 | 条件を解消 | PRD | 06-production/93-messages.md |
| MSG-PRD-076 | E | 未領材料・未退料が残っているため結案できません。 | 未領/未退料あり | 退料・調整 | PRD | 06-production/93-messages.md |
| MSG-PRD-077 | E | 原価が確定していないため結案できません。月結後に再実行してください。 | 原価未確定 | 月結後再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-078 | E | 工单に未完了の変更申請があります。 | 変更申請中 | 変更完了待ち | PRD | 06-production/93-messages.md |
| MSG-PRD-079 | W | 工单の計画完成日を超過しています。 | 遅延 | 納期再回答 | PRD | 06-production/93-messages.md |
| MSG-PRD-080 | E | 受入数量が委外注文の残数量を超えています。 | 超過受入 | 数量確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-081 | W | 加工単価が 0 です。購買価格を確認してください。 | 単価未設定 | 単価登録 | PRD | 06-production/93-messages.md |
| MSG-PRD-082 | E | 実績のある委外訂单は取消できません。先に発料・受入を取消してください。 | 実績あり取消 | 実績取消 | PRD | 06-production/93-messages.md |
| MSG-PRD-083 | E | 来料検査（IQC）が合格していないため入庫できません。 | IQC 未合格 | 検査完了/特采 | PRD | 06-production/93-messages.md |
| MSG-PRD-084 | E | 加工費結算の対象受入が不正です。受入確定・未結算を確認してください。 | 結算対象不正/連携失敗 | 対象確認・再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-085 | E | 扣款額が加工費を超えているか、扣款理由が未入力です。 | 扣款不正 | 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-086 | E | 支給材料の在庫が不足しています。発料できません。 | 在庫不足 | 補充手配 | PRD | 06-production/93-messages.md |
| MSG-PRD-087 | E | 委外先の支給材料残と一致しません。数量を確認してください。 | 委外先在庫差異 | 原因調査 | PRD | 06-production/93-messages.md |
| MSG-PRD-088 | W | 委外訂单の納期を超過しています。 | 委外遅延 | 督促・納期変更 | PRD | 06-production/93-messages.md |
| MSG-PRD-089 | E | 発料数量が支給材料の標準量を超えています。 | 過剰発料 | 数量確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-090 | E | 設備の状態が不正です。状態を確認してください。 | 設備状態不整合 | 状態修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-091 | E | 帳票の出力に失敗しました。条件を確認して再実行してください。 | 帳票生成失敗 | 再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-092 | E | 集計対象データがありません。 | 集計 0 件 | 条件変更 | PRD | 06-production/93-messages.md |
| MSG-PRD-093 | E | 選択した条件ではデータ量が多すぎます。条件を絞ってください。 | 件数超過 | 条件追加 | PRD | 06-production/93-messages.md |
| MSG-PRD-094 | E | パラメータ値が範囲外です。 | 設定値不正 | 修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-095 | E | 既に処理中です。完了後に再実行してください。 | 二重起動 | 完了待ち | PRD | 06-production/93-messages.md |
| MSG-PRD-096 | W | 一部のデータは権限がないため表示されません。 | 項目権限 | 管理者へ依頼 | PRD | 06-production/93-messages.md |
| MSG-PRD-097 | E | 過去日の報工は登録できません（当日以前 7 日以内のみ）。 | 報工日範囲外 | 日付修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-098 | E | 工序の順序が前工程の完了と整合していません。 | 前工程未完了 | 前工程完了 | PRD | 06-production/93-messages.md |
| MSG-PRD-099 | E | システムエラーが発生しました。管理者に連絡してください（エラー番号：{0}）。 | 500 エラー | trace_id を連絡 | PRD | 06-production/93-messages.md |
| MSG-PRD-100 | E | 超産承認が必要です。許容完工数量を超える入庫は承認後のみ可能です。 | 超産未承認 | 超産承認申請 | PRD | 06-production/93-messages.md |
| MSG-PRD-101 | E | 超産承認が却下または取消のため入庫できません。 | 超産承認無効 | 再申請または数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-102 | E | 冲销数量が已完工数量を超えています。 | 冲销 qty > completed_qty | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-103 | E | 超産申請数量が不正です。申請超産数量は 0 より大きい値を指定してください。 | request_qty ≤ 0 または NULL（60103） | 申請超産数量を修正して再申請 | PRD | 06-production/93-messages.md |
| MSG-PRD-104 | E | 下达日不能早于今天。 | releaseDate が Asia/Shanghai 当日より前（60104） | 下达日を当日以降に修正 | PRD | 06-production/93-messages.md |
| MSG-COM-032 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-033 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-034 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-035 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-045 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-047 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-049 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-051 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-071 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-072 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-073 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-COM-081 |  |  |  |  | PUR | 04-purchase/01-requisition.md |
| MSG-COM-082 |  |  |  |  | PUR | 04-purchase/91-api-design.md |
| MSG-COM-084 |  |  |  |  | PUR | 04-purchase/93-messages.md |
| MSG-PUR-001 | E | 希望交期不能早于今天。 | 希望交期 < サーバ当日 | 正しい日付を入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-002 | E | 所选物料不存在、已停用或不可采购，请重新选择。 | 物料無効/非采购品 | 物料を選び直す | PUR | 04-purchase/93-messages.md |
| MSG-PUR-003 | E | 所选供应商未通过准入或不在供货范围内，不能转单。 | 供应商未承認/範囲外 | 承認済供应商を選択、または MDM で准入 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-004 | W | 该部门/物料在近 {0} 天内已有未转单的请购（{1}），是否继续？ | 重複请购 | 「继续」で理由入力、または既存单へ統合 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-005 | W | 部门采购预算不足：本单税込金额 {0} 超过剩余预算 {1}，需上级承认。 | 预算残高不足 | 承認へ進む（警告のみ、保存可） | PUR | 04-purchase/93-messages.md |
| MSG-PUR-016 | I | 请购单已提交审批，当前审批人：{0}。 | 提出成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-017 | E | 当前状态不允许撤回（已有审批人处理）。 | 撤回不可 | 承認者に差戻しを依頼 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-018 | E | 请购单已被却下，请修正后重新提交。 | 却下後の操作 | 修正→再提出 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-019 | I | 请购单已取消。 | 取消成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-020 | I | 请购单已恢复为草稿，可修改后重新提交。 | 却下/差戻し後 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-021 | E | 转单数量超过请购剩余可转单数量（剩余 {0}）。 | 転単数量超過 | 数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-022 | E | 该请购单未批准或已全部转单，不能转单。 | 状態不整合 | 状態確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-023 | I | 已生成采购订单 {0}（{1} 张），请购单状态已更新。 | 転単成功 | PO へ遷移して確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-024 | I | 请购单已关闭，剩余未转单数量不再处理。 | 手動关闭 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-025 | E | 转单数量戻し处理异常：请购剩余数量不足（数据不一致），请联系管理员。 | 戻し異常 | データ調査 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-026 | W | 转单数量低于供应商最小起订量 {0}，已按 MOQ 调整。 | MOQ 未満 | 数量確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-030 | W | 已邀请供应商不足 2 家，请补充供应商或填写单一来源理由。 | 供应商 < 2 | 供应商追加 or 理由入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-031 | E | 报价截止日期必须晚于询价发出日期。 | 截止 ≤ 发出 | 日時修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-032 | W | 报价 {0} 的有效期（{1}）早于希望交期，不能中选。 | 有效期不足 | 该报价中选不可 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-033 | E | 该供应商未在邀请名单内，不能登记报价。 | 名单外供应商 | 邀请名单を確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-034 | E | 中选结果与比价规则不一致，请填写中选理由或修正选择。 | 规则不一致 | 理由入力 or 修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-035 | E | 中选价与目安単価差异超过 10%，请填写价格差异理由。 | 目安比 > 10% | 理由入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-036 | E | 存在未确定供应商的询价行，不能完成中选。 | 中选不完全 | 未選択行を選択 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-037 | E | 报价数量超过询价数量，请确认（按可供应数量中选）。 | 报价数量 > 询价 | 数量確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-038 | E | 询价对象不存在或状态不允许询价。 | 状态不整合 | 请购状態確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-039 | I | 询价已发出，邀请 {0} 家供应商。 | 发出成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-040 | E | 报价已截止，不能再登记或修改报价。 | 截止後操作 | 采购经理に延期依頼 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-041 | E | 未找到有效汇率（{0}→CNY），不能计算比价。 | 為替未設定 | 為替マスタ整備 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-042 | I | 比价计算完成：{0} 行、{1} 家供应商、{2} 件报价。 | 計算完了 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-043 | I | 询价单已取消。 | 取消成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-044 | E | 同一物料行只能中选 1 家供应商（数量分拆は実装順 P2）。 | 複数中选 | 1 社に修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-045 | E | 中选数量无效：必须大于 0 且不超过可供应数量 {0}。 | 数量不正 | 数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-046 | I | 中选已确定，共 {0} 行、金额（税込）{1}。 | 中选成功 | PO 生成へ | PUR | 04-purchase/93-messages.md |
| MSG-PUR-047 | I | 该询价单已生成采购订单（{0}），不重复生成。 | 再生成 | 既存 PO 参照 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-048 | W | 订单单价与有效采购价格（{0} {1}）不一致，价差 {2}%，请确认。 | 取价差異 > 0.5% | 単価確認 or 理由入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-049 | W | 未找到有效采购价格，已取最近成交价 {0}（{1}）或请手工定价。 | 取价不能 | 単価入力・理由 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-050 | W | 订单数量低于最小起订量 {0}，建议按 MOQ 调整或填写理由。 | MOQ 不足 | 数量調整 or 理由 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-051 | E | 订单数量不能低于已入荷数量 {0}。 | 变更で入荷済割れ | 数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-052 | E | 已入荷数量不能取消，错误处理请使用采购退货（E16）。 | 入荷済行の取消 | 返品処理へ | PUR | 04-purchase/93-messages.md |
| MSG-PUR-053 | W | 约定交期早于供应商标准提前期（{0} 天），可能无法按期交货。 | 交期 < LT | 交期調整 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-054 | I | 采购订单已提交审批，当前审批人：{0}。 | 提出成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-055 | E | 当前状态不允许撤回（已有审批人处理）。 | 撤回不可 | 承認者へ差戻し依頼 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-056 | E | 采购订单已被却下。 | 却下状態 | 修正→再提出 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-057 | I | 采购订单 {0} 已发送（方式：{1}）。 | 送信成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-058 | I | 采购订单 {0} 已关闭，未入荷残 {1} 不再处理。 | 关闭成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-059 | I | 变更申请已提交（版本 {0}），请在审批完成前不要重复变更。 | 变更提交 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-060 | I | 变更已批准，订单版本更新为 v{0}。 | 変更改承認 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-061 | I | 变更被却下，订单已恢复为变更前内容。 | 変更改却下 | 内容確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-062 | I | 采购订单已取消（取消数量 {0}）。 | 取消成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-063 | E | 该订单存在未完成的变更审批，不能重复变更或编辑。 | pending_change=true | 承認完了後に再操作 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-064 | E | 约定交期不能早于订单日。 | 交期 < 订单日 | 交期修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-065 | E | 订单日超出允许范围（当日 − 7 日 ～ 当日 + 365 日）。 | 日付範囲外 | 日付修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-066 | E | 手工定价时必须填写定价理由。 | 手工定价理由なし | 理由入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-067 | W | 降价/涨价幅度超过 10%（前次 {0} → 本次 {1}），请确认。 | 价格異常 | 確認・理由 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-068 | E | 收货数量超过可收上限（{0}），不能收货。 | 容差超過 | 数量修正 or 采购经理例外承認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-069 | W | 超收：累计收货 {0} 超过订单数量 {1}，超收 {2}（容差内），已记录。 | 容差内超收 | 理由追記・承認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-070 | E | 超收必须填写超收理由并经采购经理承认。 | 超收理由なし | 理由入力・承認依頼 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-071 | E | 该订单行已全部收货，不能再收货。 | 残量 0 | PO 状態確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-072 | W | 早于约定交期 {0} 天到货，请确认仓库接收与保管能力。 | 早入荷 | 倉庫確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-073 | E | 批次管理物料必须输入批次号。 | 批次号なし | 批次入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-074 | W | 收货数量与检验数量合计不一致（入荷 {0}、合格 {1}、特采 {2}、不合格 {3}），请确认。 | 数量不整合 | 検査結果・数量確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-075 | E | 收货单已入库或已匹配发票，不能取消；错误处理请使用采购退货。 | E35 条件不成立 | 返品処理へ | PUR | 04-purchase/93-messages.md |
| MSG-PUR-076 | I | 收货单 {0} 已确认入荷，待检在庫已登记（E14）。 | 入荷確定 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-077 | I | 收货单 {0} 已取消，待检在庫・暂估・IQC 已冲回（E35）。 | 取消成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-078 | W | IQC 判定为不合格，请执行退货、全数選別或特采处理。 | 不合格 | 処置選択 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-079 | E | 该收货单的 IQC 尚未完成，不能进行入库/退货以外的操作。 | 検査未完了 | 判定待ち | PUR | 04-purchase/93-messages.md |
| MSG-PUR-080 | E | 采购订单不存在、状态不允许收货或已无未入荷残。 | PO 状態不整合 | PO 確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-081 | E | 未找到该物料的检验标准，IQC 无法起票，请联系质量部。 | 検査標準なし | 質量部へ連絡 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-082 | I | 收货单 {0} 已全量入库，订单行完成。 | 入库完了 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-083 | E | 入荷日超出允许范围（≤ 当日 + 1 日）。 | 日付不正 | 日付修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-084 | I | 收货单已保存（{0}），请确认后执行入荷确定。 | 保存成功 | 確定へ | PUR | 04-purchase/93-messages.md |
| MSG-PUR-085 | I | 收货单已取消（登録ミス）。 | 未確定取消 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-086 | W | 入库数量与检验合格数量不一致（入库 {0}、合格 {1}、特采 {2}、退货 {3}），请联系库存管理员。 | E18 不整合 | INV へ連絡 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-087 | E | 退货数量超过可退货数量（最多 {0}）。 | 可退数量超過 | 数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-088 | I | 退货出库已确认（E16），已通知库存与财务。 | 出庫確定 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-089 | E | 库存不足，当前可用数量：{0}，不能出库。 | 在庫不足 | 在庫確認・数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-090 | I | 退货単已作成（{0}），请提交审批。 | 作成成功 | 提出へ | PUR | 04-purchase/93-messages.md |
| MSG-PUR-091 | I | 退货単已提交审批（采购经理→财务经理）。 | 提出成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-092 | E | 退货単已被差戻し/却下，请修正后重新提交。 | 差戻/却下 | 修正→再提出 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-093 | I | 貸項通知処理が完了しました（出庫なし）。 | 貸項完了 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-094 | I | 退货単 {0} 已完成（红字发票 {1} 已关联）。 | 完了成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-095 | I | 退货単已取消。 | 取消成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-096 | E | 已开票的退货必须选择原发票。 | 原发票未選択 | 原发票選択 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-097 | E | 已开票的退货必须登记红字发票后才能完成。 | 红字未登録 | 红字发票登録 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-098 | E | 退货已出库，不能取消；如需返送请使用新收货单。 | 出庫後取消 | 新規 GR | PUR | 04-purchase/93-messages.md |
| MSG-PUR-099 | W | 换货补货数量（{0}）与退货数量（{1}）不一致，请确认。 | 補貨数量不一致 | 数量確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-100 | E | 该发票号码已登记（发票代码 {0} / 号码 {1}），不能重复登记。 | 一意制約違反 | 既存发票を確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-101 | E | 发票合计金额与明细合计不一致（差额 {0}）。 | 合計不一致 | 明細修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-102 | E | 未找到可匹配的采购订单/收货单，请手工指定或确认入荷。 | PO/GR 未発見 | 手動紐付 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-103 | W | 匹配存在差异：单价差异 {0}（{1}%）、数量差异 {2}、税额差异 {3}。 | 差異あり | 内容確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-104 | W | 差异在容差范围内，已自动通过（差异金额 {0}）。 | 容差内自動通過 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-105 | E | 差异超出容差，必须输入差异理由并提交承认。 | 超容差理由なし | 理由入力・承認提出 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-106 | E | 发票请求数量超过可请求数量（累计已请求 {0}，可请求 {1}），超出部分保留。 | 数量超限 | 入荷待ち・数量修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-107 | I | 发票 {0} 匹配完成，已通知财务计上应付（E17）。 | 計上成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-108 | E | 该发票已计上应付，不能修改/取消；请使用红字发票处理。 | 計上済操作 | 赤伝処理 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-109 | E | 红字发票必须指定原发票且金额为负数。 | 红字不備 | 原发票・金額修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-110 | W | 暂估台账与财务暂估残高不一致（差 {0}），请与财务核对。 | 台账差異 | FIN と照合 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-111 | E | 发票销方税号与供应商主数据不一致（发票 {0} / 主数据 {1}），不能登记。 | 税号不一致 | 供应商 or 发票確認 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-112 | I | 采购发票已保存（{0}），请执行三单匹配。 | 登録成功 | 匹配実行 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-113 | E | 付款申请金额超过应付未付余额（未付 {0}）。 | 金額超過 | 金額修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-114 | E | 财务系统付款申请创建失败（{0}），请稍后重试或联系财务。 | FIN API 失敗 | 再試行・FIN 連絡 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-115 | E | 预付款申请金额超过订单允许比例（可申请 {0}）。 | 預付比例超過 | 金額修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-116 | I | 已提交付款申请（PA 号 {0}），审批与付款由财务执行。 | PA 起票成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-117 | W | 该供应商当前绩效等级为 {0}，是否继续发注？ | 等級 D の PO 登録 | 発注判断・理由記録 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-118 | W | 该计划订单已转换（{0}），不能重复转换。 | 変換済 | 既存請購参照 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-119 | E | 催货日不能晚于今天。 | 未来日 | 日付修正 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-120 | W | 供应商承诺交期晚于希望交期 {0} 天，已记录延迟。 | 交期遅延 | PO 变更・代替調達検討 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-121 | E | 一次最多转换 100 件计划订单，请分批执行。 | 上限超過 | 分割実行 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-122 | E | 手动调整绩效评分时必须填写调整理由。 | 調整理由なし | 理由入力 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-123 | W | 该订单未设定约定交期，按订单日 + 提前期计算。 | 交期未設定 | 交期登録 | PUR | 04-purchase/93-messages.md |
| MSG-PUR-124 | W | 采购报表尚未完成当日集計（最終更新：{0}），显示前一日数据。 | 集計未更新 | 再集計待ち | PUR | 04-purchase/93-messages.md |
| MSG-PUR-125 | I | 催货记录已保存。 | 保存成功 | — | PUR | 04-purchase/93-messages.md |
| MSG-PUR-126 | E | 采购业务处理失败，请联系管理员（错误编号：{0}）。 | 分類不能な業務エラー（40099） | trace_id を添えて管理者へ連絡 | PUR | 04-purchase/93-messages.md |
| MSG-RPT-001 | E | 没有查看该报表的权限。 | 権限なし | 管理者へ申请 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-002 | E | 指定的期间无效或尚未开始。 | 期間不正 | 期間選択 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-003 | W | 部分指标因数据未就绪显示为「-」。 | 欠測 | 抽出完了後に再表示 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-010 | E | KPI 代码格式不正确（应为 KPI-RPT-三位数字）。 | 形式違反 | 修正 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-011 | E | KPI 计算公式不正确，请检查函数与字段引用。 | 構文エラー | 修正 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-012 | E | 指定的维度不在允许范围内。 | 次元不正 | 修正 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-013 | E | 数据来源表或字段不存在。 | 出所不正 | 修正 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-014 | E | KPI 代码已存在。 | 重複 | 既存を編集 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-015 | W | 分母为 0，该比率指标无法计算。 | 分母 0 | データ確認 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-020 | W | KPI 与业务域汇总存在差异（{0}%），请确认。 | 差異 | 原因調査 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-021 | E | 该期间 KPI 已确定，不能重新计算。 | 確定済み | 翌月調整 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-022 | W | 月次 KPI 尚未确定，当前为暂定值。 | 未確定 | 確定後に再出力 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-023 | I | 重新计算任务已受理。 | 再計算受付 | ジョブ確認 | RPT | 10-analytics/01-dashboard.md |
| MSG-RPT-030 | E | 分析数据抽取失败：{0}，请联系管理员。 | 抽出失敗 | ログ確認・再実行 | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-031 | W | 部分业务数据尚未确定，当前分析结果为暂定值。 | 期間未確定 | 確定後に再表示 | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-032 | W | 抽取数据量超过预期（{0} 行），请确认是否存在异常。 | 件数超過 | データ確認 | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-033 | E | 指定的分析条件无效。 | 条件不正 | 修正 | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-034 | W | 明细超过 10,000 件，请使用导出功能。 | 件数超過 | 出力 | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-035 | I | 分析数据已更新。 | 抽出完了 | — | RPT | 10-analytics/02-domain-analysis.md |
| MSG-RPT-040 | E | 预警规则代码格式不正确（应为 WARN-RPT-三位数字）。 | 形式違反 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-041 | I | 该预警已存在，已更新为最新值。 | 重複 | — | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-042 | E | 指定的 KPI 不存在或已停用。 | KPI 不正 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-043 | E | 阈值超出该指标的有效范围。 | 閾値不正 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-044 | E | 连续次数必须在 1〜12 之间。 | 値域違反 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-045 | E | 请至少选择一个通知渠道。 | チャネルなし | 選択 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-046 | W | 该指标的 KPI 尚未计算，本次跳过。 | KPI 未計算 | 翌日再評価 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-047 | W | 部分通知渠道不可用，已改由站内通知。 | チャネル障害 | 設定確認 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-048 | W | 升级通知的接收人不存在，已通知系统管理员。 | 宛先不在 | ロール確認 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-049 | I | 预警已解决。 | 解決 | — | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-050 | E | 指定的报表不存在。 | 帳票不正 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-051 | E | 配信日与频率不匹配。 | 日付不正 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-052 | E | 请至少指定一个接收人。 | 宛先なし | 追加 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-053 | E | 配信时刻必须在 06:00〜20:00 之间。 | 時刻不正 | 修正 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-054 | W | 该期间已配信，本次跳过。 | 二重配信 | 再配信を明示 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-055 | E | 报表生成失败：{0}，系统将重试。 | 生成失敗 | 監視 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-RPT-056 | W | 接收人展开后为 0 件，未执行配信。 | 宛先 0 | 設定確認 | RPT | 10-analytics/03-warning-subscription.md |
| MSG-COM-043 | 必須/範囲 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-COM-075 |  |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-001 | I | 销售订单已保存（{0}）。 |  | 詳細へ遷移 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-002 |  |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-004 | 範圍 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-005 | 範圍 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-006 | 必須/コード存在 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-007 | 必須/範圍 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-008 | コード存在 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-009 | 必須/範圍 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-010 | 必須/コード存在 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-011 | 重複 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-012 |  |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-013 | 範圍 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-014 | 必須/相関 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-015 | E | 审批已驳回：{0}。 |  | 內容修正・再作成 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-016 | I | 已退回申请人修改。 |  | 修正・再提出 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-017 | I | 销售订单 {0} 已审批通过。 |  | — | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-018 | 職務分掌 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-019 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-020 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-021 | E | 本次订单金额超过单笔限额 {0}，不能提交。 |  | 分割受注・超限承認 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-022 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-023 | 業務 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-030 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-031 |  |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-032 | W | 引当不足：{0} 行（不足数量 {1}），已转为欠货。 |  | 納期再回答・バックオーダー管理 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-036 | E | 出荷数量超过引当数量／受注残数量。 |  | 數量修正 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-037 |  |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-041 | I | 订单已全部出荷并关闭。 |  | — | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-045 | I | 订单已取消。 |  | — | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-046 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-047 | W | 已出荷部分不能取消，将仅取消剩余数量。 |  | 確認して續行 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-048 | 業務 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-049 | 必須 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-050 | I | 已创建变更版本 v{0}，请编辑后提交。 |  | 變更ウィザードへ | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-051 | I | 订单变更已确定（v{0}），引当数量将同步调整。 |  | — | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-052 | I | 变更已中止。 |  | — | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-053 | 相関 |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-054 |  |  |  |  | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-055 | W | 本次变更金额增加 {0}，超出与信余力，需要重新审批。 |  | 再承認 | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-056 | E | 变更后数量（基本单位）不能小于已完工数量或已出库数量 {0}。 |  | 數量修正（≥ max(已完工, 已出库)） | SAL | 03-sales/02-sales-order.md |
| MSG-SAL-080 | 業務 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-081 |  |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-082 | 業務 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-083 | I | 与信台帳照会・判定完成：{0}（10 正常/20 注意/30 超限審査中/40 超限承認済/90 凍結・閉鎖）。 |  | — | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-084 | I | 与信台帳の投影を更新しました（{0}，金額 {1}）。台帳権威は FIN。 |  | — | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-085 | 業務 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-086 | I | 特价申请已保存（{0}）。 |  | — | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-087 | I | 特价申请已批准，有效期 {0} 〜 {1}。 |  | — | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-088 | I | 特价申请已到期失效（{0}）。 |  | 必要なら再申請 | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-089 | I | 特价申请已取消。 |  | — | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-090 | E | 特价与促销折扣不能同时使用。 |  | いずれかを解除 | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-091 | 必須/範圍 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-092 | 相関 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-093 | 一意 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-094 | 警告 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-095 | 業務 |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-096 |  |  |  |  | SAL | 03-sales/06-credit-pricing.md |
| MSG-SAL-100 | 必須/業務 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-101 | 業務 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-102 | E | 仓库或物料不可出荷，请确认主数据状态。 |  | マスタ確認 | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-103 | 必須/コード存在 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-104 | 必須/一意 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-105 | I | 发货通知已创建（{0}）。 |  | — | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-106 | I | 拣货作业已开始（{0}）。 |  | — | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-107 | I | 出荷已确定（部分），订单状态更新为 35。 |  | — | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-108 | I | 出荷已全部确定（{0}），订单状态更新为 40。 |  | — | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-109 | 業務 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-110 | 必須/範圍 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-111 | 相関 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-112 | 業務 |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-113 |  |  |  |  | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-114 | W | 本次出荷数量低于指示数量，将按部分出荷处理。 |  | 確認して續行 | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-115 | E | 该序列号已被其他出荷使用，不能重复出荷。 |  | 序列號変更 | SAL | 03-sales/03-delivery-picking.md |
| MSG-SAL-120 | 必須/業務 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-121 | 業務 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-122 | 必須/範圍 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-123 |  |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-124 | 業務 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-125 | I | 退货单已创建（{0}）。 |  | — | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-126 | I | 退货单已审批通过，等待收货检验。 |  | 検品実施 | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-127 | I | 退货检验完成，已通知库存退回并生成红字应收。 |  | — | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-128 | I | 退货处理已完成（库存退回・红字计上）。 |  | — | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-129 | 業務 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-130 | I | 退货检验已开始。 |  | — | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-131 | I | 退货检验已确定：{0}。 |  | — | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-132 | 必須/相関 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-133 | 相関 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-134 | 必須 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-135 | 一意 |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-136 |  |  |  |  | SAL | 03-sales/04-sales-return.md |
| MSG-SAL-140 | 必須 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-141 | 必須/形式 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-142 | 業務 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-143 | 必須 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-144 | I | 开票申请已创建（{0}）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-145 | I | 开票申请已审批通过。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-146 | I | 开票申请已完成（与应收纽付け完毕）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-147 | I | 开票申请已取消。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-148 | I | 发票已登记（{0}），已通知财务域纽付け应收。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-149 | I | 发票已交付（{0}）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-150 | I | 发票与应收已完成纽付け。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-151 | I | 红字发票已登记（{0}）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-152 | I | 对账单已生成（{0}）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-153 | I | 对账单已发送（{0}）。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-154 | I | 对账单已完成顾客确认。 |  | — | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-155 | 相関 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-156 | 必須/一意 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-157 | 形式 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-158 | 相関 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-159 | 一意 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-160 | 業務 |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-161 |  |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-162 |  |  |  |  | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-163 | E | 发票尚未交付，不能执行该操作。 |  | 交付を先に | SAL | 03-sales/05-invoice-receivable.md |
| MSG-SAL-170 | 必須/相関 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-171 | 業務 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-172 | I | 询价单已创建（{0}）。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-173 | I | 询价回答已登记。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-174 | 相関 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-175 | I | 询价单已取消。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-176 | I | 报价单已保存（{0} 版 {1}）。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-177 | I | 报价单已发行，有效期至 {0}。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-178 | I | 已创建新版本（版 {0}），旧版本保留。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-179 | I | 已转为销售订单（{0}）。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-180 | I | 报价单已失效（超过有效期）。 |  | 新規見積作成 | SAL | 03-sales/01-quotation.md |
| MSG-SAL-181 | I | 报价单已取消。 |  | — | SAL | 03-sales/01-quotation.md |
| MSG-SAL-182 | 必須/範囲 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-183 | 範囲 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-184 | 業務 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-185 | 業務 |  |  |  | SAL | 03-sales/01-quotation.md |
| MSG-SAL-190 |  |  |  |  | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-191 |  |  |  |  | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-192 | 必須/範囲 |  |  |  | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-193 | 形式 |  |  |  | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-194 | I | 已导出 {0} 件数据。 |  | — | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-195 | W | 数据量超过 10,000 件，已转为异步导出（任务号 {0}）。 |  | ジョブ完了を待つ | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-196 | I | 预测已保存（版 {0}）。 |  | — | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-197 | I | 预测已确定，可用于生产计划。 |  | — | SAL | 03-sales/07-tracking-reports.md |
| MSG-SAL-198 | W | 齐套率低于目标值（{0}%），请确认欠品与延迟案件。 |  | 欠品・遅延確認 | SAL | 03-sales/07-tracking-reports.md |
| MSG-COM-001 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-003 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-004 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-005 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-010 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-020 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-021 | 認証 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-022 | 必須（条件付） |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-023 |  |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-024 | E | 首次登录或密码已重置，请修改密码。 | password_reset_required=true | 強制改密 | SYS | 01-system/01-auth-login.md |
| MSG-COM-025 | E | 密码已过期，请修改密码。 | 期限切れ | 強制改密 | SYS | 01-system/01-auth-login.md |
| MSG-COM-026 | 強度 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-027 | E | 原密码不正确。 | 旧パスワード不一致 | 再入力 | SYS | 01-system/01-auth-login.md |
| MSG-COM-028 | E | 该账号已在其他终端登录，已被强制下线。 | 多重ログイン制限 | 再ログイン | SYS | 01-system/01-auth-login.md |
| MSG-COM-030 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-031 | 所有者 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-COM-040 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-041 | 桁数 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-042 | 形式 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-COM-044 | 値域 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-COM-046 | 相関 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-COM-050 | 一意 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-COM-052 | 上限 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-COM-060 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-061 | 形式 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-COM-062 | 形式 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-COM-063 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-COM-065 | 上限 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-COM-066 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-COM-070 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-080 |  |  |  |  | SYS | 01-system/93-messages.md |
| MSG-COM-083 |  |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-001 |  |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-002 | E | 内置账号不能执行此操作。 | builtin ユーザ | 別アカウント使用 | SYS | 01-system/01-auth-login.md |
| MSG-SYS-003 | 一致 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-004 | 相関 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-005 | 相関 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-006 | 履歴 |  |  |  | SYS | 01-system/01-auth-login.md |
| MSG-SYS-007 | E | 密码修改失败，请稍后重试或联系管理员。 | 更新 0 件 | 再試行 | SYS | 01-system/01-auth-login.md |
| MSG-SYS-010 | 必須 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-011 | E | 不能将自己的权限授予自己，请由其他管理员操作。 | 自己付与 | 他管理者へ依頼 | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-012 | SoD |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-013 | 循環 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-014 | 自己以外 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-015 | 必須 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-016 | 制約 |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-017 | E | 该角色已分配给 {0} 名用户，不能删除。可改为无效化。 | 付与中削除 | 無効化 | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-018 | E | 该角色正在审批流程中使用，不能删除或无效化。 | 承認ルート使用中 | 経路変更後に再実行 | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-019 |  |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-020 |  |  |  |  | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-021 | E | 岗位数据不存在或已失效，请重新选择。 | 岗位無効 | 再選択 | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-022 | E | 该用户为内置管理员，不能停用或删除。 | builtin | — | SYS | 01-system/02-user-role-permission.md |
| MSG-SYS-023 |  |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-024 | 形式 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-030 | 一意 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-031 | 参照 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-032 | 循環 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-033 | 階層 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-034 | 一意 |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-035 |  |  |  |  | SYS | 01-system/03-org-position.md |
| MSG-SYS-036 | E | 该岗位已被用户使用，不能停用。 | 岗位使用中 | ユーザ異動 | SYS | 01-system/03-org-position.md |
| MSG-SYS-040 | 制約 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-041 | 制約 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-042 | 一意 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-043 | 一意 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-044 | 型 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-045 | 承認 |  |  |  | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-046 | E | 参数值超出允许范围（{0}）。 | 値域外 | 修正 | SYS | 01-system/04-menu-dict-param.md |
| MSG-SYS-050 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-051 | 相関 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-052 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-053 | 形式 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-054 | 相関 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-055 | 制約 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-056 | 行数 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-057 | 上限 |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-058 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-059 |  |  |  |  | SYS | 01-system/06-import-export-numbering.md |
| MSG-SYS-060 | E | 审计日志查询期间不能超过 3 个月，请缩小范围。 | 期間超過 | 範囲縮小 | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-061 | 整合 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-070 |  |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-071 | 上限 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-072 | 形式・一意 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-073 | 桁数 |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-074 | I | 测试邮件已发送，请查收。 | テスト送信 | — | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-075 |  |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-076 | I | 已全部标记为已读。 | 一括既読 | — | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-077 | E | 该通知不存在或不属于当前用户。 | 他ユーザ通知 | 再取得 | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-080 | 存在 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-081 | 構文 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-082 | 一意 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-083 | 形式 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-084 | 一致 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-085 | 別人 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-086 | 状態 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-087 | 必須 |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-088 |  |  |  |  | SYS | 01-system/07-scheduled-job-print-monitor.md |
| MSG-SYS-091 |  |  |  |  | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-SYS-092 | W | 审计日志写入延迟，已转存本地待补录，请通知运维人员处理。 | ローカルファイル退避発生 | 運用担当へ連絡 | SYS | 01-system/05-audit-attachment-notify.md |
| MSG-WF-001 | 形式・サイズ |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-002 | 構造 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-003 | 存在 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-004 | 存在 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-005 |  |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-006 |  |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-007 | 一意 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-008 | 一意 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-010 | 必須 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-011 | I | 审批已完成，业务单据状态已更新。 | 最終承認 | — | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-012 | I | 已驳回该申请，申请人将收到通知。 | 驳回 | — | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-013 | I | 已退回申请人修改，修改后可重新提交。 | 差戻し | — | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-014 | I | 催办通知已发送给当前审批人。 | 催办 | — | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-015 | 権限 |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-016 | 必須（条件付） |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-017 | 存在・重複 |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-018 | 存在 |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-019 | 制約 |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-020 | I | 已撤回该申请，审批流程已终止。 | 撤回 | — | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-021 | 状態 |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-022 |  |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-030 |  |  |  |  | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-031 | I | 审批流程已挂起，暂不能处理。 | 掛起中 | 管理者へ連絡 | WF | 08-workflow/02-approval-runtime.md |
| MSG-WF-032 | I | 流程已挂起，暂停审批任务生成。 | 挂起 | — | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-033 | I | 流程已恢复，可继续审批。 | 再開 | — | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-041 | 存在・別人 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-042 | 相関 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-043 | 一意性 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-044 |  |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-045 | 承認 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-046 | 条件 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-047 | 制約 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-048 | 存在 |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-049 |  |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-050 |  |  |  |  | WF | 08-workflow/03-approval-admin.md |
| MSG-WF-051 | 存在・一意 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-052 | 演算子 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-053 | 一意性 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-061 | 存在 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-062 | 制約 |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-063 |  |  |  |  | WF | 08-workflow/01-process-model.md |
| MSG-WF-073 | E | 该业务单据已提交，请勿重复提交。 | 二重提出 | — | WF | 08-workflow/02-approval-runtime.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
