# メッセージ一覧（消息一览）

| 項目 | 内容 |
|---|---|
| 文書名 | メッセージ一覧（消息一览）（自动生成） |
| 文書番号 | DSN-MTX-007 |
| 版数 | v1.0 |
| 作成日 | 2026-10-20 |
| 作成者 | Lead（生成工具 gen_matrix.py） |
| 状態 | ドラフト（自动生成・最終レビュー前） |
| 備考 | 全 1014 件。メッセージID/種別/本文/発生条件/対処/域/提取元 |

> 本文件由 `20-matrix/tools/gen_matrix.py` 从各域设计书中自动提取生成。修改设计书后重新运行即可更新。

| メッセージ ID | 種別 | 本文 | 発生条件 | 対処 | 域 | 提取元 |
|---|---|---|---|---|---|---|
| MSG-COM-001 | I | 保存しました。 | 登録・更新成功 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-002 | I | 删除しました。 | 論理削除成功 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-003 | I | 处理已完成。 | 一括処理・状態操作成功 | 件数を添える場合は本文後に「（n 件）」 | COM | 00-common/05-common-message-list.md |
| MSG-COM-004 | I | 导出任务已受理，完成后可在「导入导出中心」下载。 | 非同期エクスポート受付 | ジョブ ID を併記 | COM | 00-common/05-common-message-list.md |
| MSG-COM-005 | I | 审批流程已提交。 | 提出成功 | 現在承認者を通知 | COM | 00-common/05-common-message-list.md |
| MSG-COM-006 | I | 操作成功，但部分数据失败（成功 {0} 件，失败 {1} 件）。 | 一括処理の部分成功 | 失敗一覧を表示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-010 | C | 确定要删除吗？删除后不可恢复。 | 削除操作前 | OK/キャンセル | COM | 00-common/05-common-message-list.md |
| MSG-COM-011 | C | 有未保存的修改，确定要离开吗？ | 編集画面離脱時 | 破棄/編集継続 | COM | 00-common/05-common-message-list.md |
| MSG-COM-012 | C | 该操作不可撤销，是否继续？ | 取消・過帳等の不可逆操作前 | OK/キャンセル | COM | 00-common/05-common-message-list.md |
| MSG-COM-013 | C | 已选择 {0} 件数据，确定执行吗？ | 一括操作前 | 対象件数明示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-014 | C | 取消后相关库存和会计处理也将回退，是否继续？ | 伝票取消前 | 影響範囲明示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-020 | E | 登录已过期，请重新登录。 | トークン期限切れ・無効 | ログイン画面へ遷移（code=2001） | COM | 00-common/05-common-message-list.md |
| MSG-COM-021 | E | 企业代码、用户名或密码错误。 | ログイン失敗（企業コード不存在・無効・期限切れ、ユーザ不存在、パスワード不一致を区別しない） | 連続失敗でロック（MSG-COM-023）（code=2002） | COM | 00-common/05-common-message-list.md |
| MSG-COM-022 | E | 验证码错误或已过期，请重新输入。 | 検証コード不一致・期限切れ・使用済み | 検証コード再取得（code=2005） | COM | 00-common/05-common-message-list.md |
| MSG-COM-023 | E | 账号已被锁定，请于 {0} 分钟后重试或联系管理员。 | ログイン失敗回数超過 | ロック解除は管理者（code=2003） | COM | 00-common/05-common-message-list.md |
| MSG-COM-024 | E | 首次登录或密码已重置，请修改密码。 | 初回ログイン・リセット後 | パスワード変更画面へ強制遷移 | COM | 00-common/05-common-message-list.md |
| MSG-COM-025 | E | 密码已过期，请修改密码。 | パスワード有効期限切れ | パスワード変更画面へ強制遷移（code=2004） | COM | 00-common/05-common-message-list.md |
| MSG-COM-026 | E | 密码强度不符合要求（8〜20 位，且包含大写字母、小写字母、数字、符号中至少 3 类）。 | パスワード変更時 | 強度要件を表示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-027 | E | 原密码不正确。 | パスワード変更時 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-028 | E | 该账号已在其他终端登录，已被强制下线。 | 多重ログイン制限 | 再ログイン | COM | 00-common/05-common-message-list.md |
| MSG-COM-030 | E | 您没有执行该操作的权限，请联系管理员。 | 権限不足 | code=3001 | COM | 00-common/05-common-message-list.md |
| MSG-COM-031 | E | 您没有查看该数据的权限。 | データ範囲外 | code=3002 | COM | 00-common/05-common-message-list.md |
| MSG-COM-032 | E | 该数据已被删除或不存在，请刷新后重试。 | 対象不存在・論理削除済み | code=4001 | COM | 00-common/05-common-message-list.md |
| MSG-COM-033 | E | 数据已被其他用户更新，请重新获取最新信息后再操作。 | 楽観排他競合 | code=4003。最新情報再取得ボタン | COM | 00-common/05-common-message-list.md |
| MSG-COM-034 | E | 该记录当前状态不允许此操作。 | 状態不整合 | code=4002。現在状態を表示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-035 | E | 数据已被其他操作占用，请稍后重试。 | 行ロック・同時処理 | code=4005 | COM | 00-common/05-common-message-list.md |
| MSG-COM-040 | E | 请输入必填项「{0}」。 | 必須漏れ | 項目をハイライト | COM | 00-common/05-common-message-list.md |
| MSG-COM-041 | E | 「{0}」不能超过 {1} 个字符。 | 桁数超過 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-042 | E | 「{0}」的数值格式不正确。 | 数値形式エラー | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-043 | E | 「{0}」的日期格式不正确。 | 日付形式エラー | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-044 | E | 「{0}」必须大于 {1}。 | 値域エラー | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-045 | E | 「{0}」不能大于「{1}」。 | 相関チェック（数量・日付等） | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-046 | E | 开始日期不能晚于结束日期。 | 日付範囲矛盾 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-047 | E | 数量必须大于 0。 | 数量 0 以下 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-048 | E | 金额不能为负数。 | 金額負値 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-049 | E | 所选数据不存在或已失效，请重新选择。 | コード存在チェック | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-050 | E | 该数据已存在，请勿重复添加。 | 一意制約違反 | 既存データへリンク | COM | 00-common/05-common-message-list.md |
| MSG-COM-051 | E | 输入的金额与合计不一致，请确认。 | 合計相違 | 警告（W）の場合あり | COM | 00-common/05-common-message-list.md |
| MSG-COM-052 | E | 查询条件过于宽泛，请增加筛选条件（预计超过 {0} 件）。 | 件数超過 | 条件追加を促す | COM | 00-common/05-common-message-list.md |
| MSG-COM-060 | E | 文件大小超过限制（单文件最大 {0} MB）。 | サイズ超過 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-061 | E | 文件格式不支持，请上传 {0} 格式的文件。 | 拡張子不正 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-062 | E | 文件解析失败，请使用系统提供的模板。 | テンプレート不正 | テンプレート DL 導線 | COM | 00-common/05-common-message-list.md |
| MSG-COM-063 | E | 导入失败：第 {0} 行，{1}。 | 行単位エラー | エラー行一覧を表示・DL | COM | 00-common/05-common-message-list.md |
| MSG-COM-064 | W | 导入完成：成功 {0} 行，失败 {1} 行。 | 部分成功 | 失敗行は修正して再取込 | COM | 00-common/05-common-message-list.md |
| MSG-COM-065 | E | 导出数据量超过上限（{0} 件），请缩小范围或使用异步导出。 | 同期エクスポート上限超過 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-066 | E | 文件下载失败或文件已过期，请重新生成。 | ジョブ結果期限切れ・削除済み | 再実行 | COM | 00-common/05-common-message-list.md |
| MSG-COM-070 | W | 库存不足，当前可用数量：{0}。 | 在庫引当不足 | 続行可否は機能側で定義 | COM | 00-common/05-common-message-list.md |
| MSG-COM-071 | E | 会计期间已结账，不能新增或修改该期间的数据。 | 締切済期間 | 期間解除は管理者のみ | COM | 00-common/05-common-message-list.md |
| MSG-COM-072 | E | 该单据已存在后续业务处理，不能取消。 | 下流処理あり | 下流処理の取消を先に行う | COM | 00-common/05-common-message-list.md |
| MSG-COM-073 | E | 未找到匹配的审批流程，请联系管理员配置。 | WF 未設定 | 流程設定画面へ | COM | 00-common/05-common-message-list.md |
| MSG-COM-074 | W | 当前数据存在未处理事项，请确认后再继续。 | 未完了事項あり | 詳細を表示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-075 | E | 该业务单据已提交，请勿重复提交。 | 二重提出 | code=4005 | COM | 00-common/05-common-message-list.md |
| MSG-COM-080 | E | 服务器处理失败，请联系管理员（错误编号：{0}）。 | 500 エラー | trace_id を表示 | COM | 00-common/05-common-message-list.md |
| MSG-COM-081 | E | 网络连接失败，请检查网络后重试。 | 通信エラー | 再試行 | COM | 00-common/05-common-message-list.md |
| MSG-COM-082 | E | 请求过于频繁，请稍后重试。 | レート制限 | 429 | COM | 00-common/05-common-message-list.md |
| MSG-COM-083 | E | 系统维护中，预计 {0} 恢复。 | メンテナンス | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-084 | W | 当前功能正在处理中，请稍候。 | 処理中 | 二重起動防止 | COM | 00-common/05-common-message-list.md |
| MSG-COM-085 | E | 数据加载失败，请刷新页面重试。 | 取得失敗 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-086 | W | 当前页面数据已过期，请刷新后再操作。 | 画面滞留 | — | COM | 00-common/05-common-message-list.md |
| MSG-COM-087 | E | 「{0}」只能输入半角英数字。 | 半角英数チェック | — | COM | 00-common/05-common-message-list.md |
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
| MSG-INT-001 | E | 接口代码格式不正确（应为 IF-INT-三位数字）。 | 形式違反 | IF-INT-001 形式で入力 | INT | 09-integration/93-messages.md |
| MSG-INT-002 | E | 接口代码已存在，请勿重复登记。 | 一意違反 | 既存設定を編集 | INT | 09-integration/93-messages.md |
| MSG-INT-003 | E | 连接测试失败：{0}。请检查地址、证书与网络。 | テスト失敗 | 接続先・証明書・NW を確認 | INT | 09-integration/93-messages.md |
| MSG-INT-004 | E | 超时、重试或退避参数超出允许范围。 | 値域違反 | 1,000〜120,000ms、0〜10 回に修正 | INT | 09-integration/93-messages.md |
| MSG-INT-005 | E | 该接口当前状态不允许此操作。 | 状態不整合 | 現在状態を確認 | INT | 09-integration/93-messages.md |
| MSG-INT-006 | E | 连接测试未通过或已超过 24 小时，不能启用。 | 有効化条件不足 | 再テスト後に有効化 | INT | 09-integration/93-messages.md |
| MSG-INT-007 | E | 字段映射未定义或不完整。 | マッピング不備 | マッピングを追加 | INT | 09-integration/93-messages.md |
| MSG-INT-008 | E | 认证信息读取失败，请联系系统管理员。 | Secrets 参照失敗 | 情報部へ連絡 | INT | 09-integration/93-messages.md |
| MSG-INT-009 | W | 认证信息将在 {0} 天后到期，请及时更新。 | 期限 30/7 日前 | ローテーション実施 | INT | 09-integration/93-messages.md |
| MSG-INT-010 | W | 调用频率超过限制，已进入等待队列。 | レート超過 | 待機（自動再試行） | INT | 09-integration/93-messages.md |
| MSG-INT-011 | E | 接口已启用，无需重复操作。 | 二重有効化 | 状態確認 | INT | 09-integration/93-messages.md |
| MSG-INT-012 | E | 接口已停用，无需重复操作。 | 二重停止 | 状態確認 | INT | 09-integration/93-messages.md |
| MSG-INT-013 | E | 该接口正在被任务使用，不能删除。 | 使用中削除 | 停止後に無効化 | INT | 09-integration/93-messages.md |
| MSG-INT-014 | I | 接口配置已保存。 | 保存成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-015 | I | 连接测试成功（{0} ms）。 | テスト成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-016 | I | 认证信息已更新，旧凭证将在 24 小时后失效。 | ローテーション成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-017 | W | 旧凭证已失效，请确认新凭证运行正常。 | 切替完了 | 疎通確認 | INT | 09-integration/93-messages.md |
| MSG-INT-018 | E | 旧凭证仍在使用中，暂不能失效。 | 切替未完了 | 先に切替を完了 | INT | 09-integration/93-messages.md |
| MSG-INT-020 | E | 税局拒绝了开票请求（原因：{0}），请修正后重新发送。 | 税局拒否 | 内容修正→同一流水号で再送 | INT | 09-integration/93-messages.md |
| MSG-INT-021 | E | 开票信息不完整或通信失败，请检查购买方信息与网络后重试。 | 項目不備/通信失敗 | 項目確認・再送 | INT | 09-integration/93-messages.md |
| MSG-INT-022 | E | 金额与税额之和不等于价税合计。 | 金額不整合 | 金額修正 | INT | 09-integration/93-messages.md |
| MSG-INT-023 | E | 税率无效或税码不存在。 | 税率不正 | 税コード確認 | INT | 09-integration/93-messages.md |
| MSG-INT-024 | I | 数电票已开具，发票号码：{0}。 | 受理成功 | 交付確認へ | INT | 09-integration/93-messages.md |
| MSG-INT-025 | I | 发票已交付给购买方。 | 交付成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-026 | E | 该发票不能开具红字发票（未发行或已红冲）。 | 赤伝不可 | 元発票確認 | INT | 09-integration/93-messages.md |
| MSG-INT-027 | I | 红字发票已开具。 | 赤伝成功 | AR 調整へ | INT | 09-integration/93-messages.md |
| MSG-INT-028 | W | 该发票已开具，请勿重复开票。 | 同一流水号/源泉 | 既存発票を参照 | INT | 09-integration/93-messages.md |
| MSG-INT-029 | E | 发票交付失败：{0}，请检查购买方邮箱或下载链接。 | 交付失敗 | 交付先確認・再交付 | INT | 09-integration/93-messages.md |
| MSG-INT-030 | E | 发票查验不一致：发票号码 {0}，请核对金额、日期与销售方。 | 査験不一致 | 発票再確認 | INT | 09-integration/93-messages.md |
| MSG-INT-031 | W | 该发票风险等级为高，请谨慎确认用途。 | リスク高 | 財務責任者確認 | INT | 09-integration/93-messages.md |
| MSG-INT-032 | I | 发票查验一致。 | 査験成功 | 用途確認へ | INT | 09-integration/93-messages.md |
| MSG-INT-033 | E | 发票查验服务暂时不可用，请稍后重试。 | サービス停止 | 再実行 | INT | 09-integration/93-messages.md |
| MSG-INT-034 | E | 该发票已完成用途确认，不能重复确认。 | 二重確認 | 状態確認 | INT | 09-integration/93-messages.md |
| MSG-INT-035 | E | 该发票已作废或失效，不能用于抵扣。 | 無効発票 | 発票再取得 | INT | 09-integration/93-messages.md |
| MSG-INT-040 | E | 银行返回账户信息不符（{0}），请核对收款账户与联行号。 | 口座相違 | 口座マスタ修正（承認要） | INT | 09-integration/93-messages.md |
| MSG-INT-041 | E | 银行账户余额不足，无法完成付款。 | 残高不足 | 入金/口座変更 | INT | 09-integration/93-messages.md |
| MSG-INT-042 | E | 付款金额必须大于 0。 | 金額不正 | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-043 | E | 收款账号格式不正确（应为 8〜32 位数字）。 | 形式エラー | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-044 | E | 联行号格式不正确（应为 12 位数字）。 | 形式エラー | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-045 | E | 付款金额与已批准的付款申请金额不一致。 | 金額不一致 | 申請と照合 | INT | 09-integration/93-messages.md |
| MSG-INT-046 | W | 银行返回结果不明，系统将在稍后自动查询，请勿重复发送。 | 状態不明 | 照会待ち | INT | 09-integration/93-messages.md |
| MSG-INT-047 | I | 付款指令已发送，银行受理号：{0}。 | 送信成功 | 完了待ち | INT | 09-integration/93-messages.md |
| MSG-INT-048 | I | 付款已完成，回单号：{0}。 | 完了 | FIN へ連携 | INT | 09-integration/93-messages.md |
| MSG-INT-049 | E | 银行连接不可用，请检查网络或联系银行。 | 接続不可 | NW/銀行へ連絡 | INT | 09-integration/93-messages.md |
| MSG-INT-050 | E | 对账单文件格式不正确（第 {0} 行：{1}），已取消本次导入。 | 形式エラー | テンプレート確認 | INT | 09-integration/93-messages.md |
| MSG-INT-051 | E | 对账单明细行数与文件头件数不一致。 | 件数不一致 | ファイル再取得 | INT | 09-integration/93-messages.md |
| MSG-INT-052 | W | 该对账单文件已导入（批次 {0}），本次不重复导入。 | 重複 | 既存批次参照 | INT | 09-integration/93-messages.md |
| MSG-INT-053 | E | 对账单移交财务失败，请稍后重试。 | FIN 引渡失敗 | 再引渡 | INT | 09-integration/93-messages.md |
| MSG-INT-054 | E | 文件行数超过上限（{0} 行）。 | 行数超過 | 分割 | INT | 09-integration/93-messages.md |
| MSG-INT-055 | E | 第 {0} 行缺少必填项「{1}」。 | 必須漏れ | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-056 | E | 第 {0} 行的代码「{1}」不存在或已失效。 | コード不存在 | マスタ確認 | INT | 09-integration/93-messages.md |
| MSG-INT-057 | W | 导入完成：成功 {0} 行，失败 {1} 行。 | 部分成功 | エラー行修正 | INT | 09-integration/93-messages.md |
| MSG-INT-058 | I | 对账单导入完成，共 {0} 行，已移交财务。 | 取込成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-059 | E | 对账单没有明细行，请确认文件内容。 | 0 件 | ファイル確認 | INT | 09-integration/93-messages.md |
| MSG-INT-060 | E | 工单下发失败（{0}），系统将自动重试。 | 通信失敗/未承認 | 監視・再送 | INT | 09-integration/93-messages.md |
| MSG-INT-061 | E | 报工对应的工单不存在或状态不正确。 | 工单不存在 | 工单確認 | INT | 09-integration/93-messages.md |
| MSG-INT-062 | I | 检测到重复报工（{0}），已跳过。 | 重複 | — | INT | 09-integration/93-messages.md |
| MSG-INT-063 | E | 报工数量不满足投入 ≥ 良品 + 不良 + 报废。 | 数量不整合 | MES 側修正 | INT | 09-integration/93-messages.md |
| MSG-INT-064 | E | 工序或工作中心未在 MES 中登记。 | マスタ不整合 | マスタ登録 | INT | 09-integration/93-messages.md |
| MSG-INT-065 | E | BOM/工艺版本重复或适用日期冲突。 | 版数競合 | 承認者が調整 | INT | 09-integration/93-messages.md |
| MSG-INT-066 | E | PDA 终端未授权或已停用，请联系管理员。 | 端末不正 | 端末再登録 | INT | 09-integration/93-messages.md |
| MSG-INT-067 | E | 报工数量超过工单允许的超出率。 | 過剰報工 | 数量修正 | INT | 09-integration/93-messages.md |
| MSG-INT-068 | E | 报工日期无效或会计期间已关闭。 | 日付/期間 | 日付修正 | INT | 09-integration/93-messages.md |
| MSG-INT-069 | E | 工单版本不一致，请先重新下发。 | 版数不一致 | 再下发 | INT | 09-integration/93-messages.md |
| MSG-INT-070 | E | 已达最大重试次数，任务转为死信，请联系运维处理。 | 死信 | 手動再送/修正 | INT | 09-integration/93-messages.md |
| MSG-INT-071 | E | 离线补传序号缺失或重复，已暂挂该批次。 | 補伝不整合 | 端末再送 | INT | 09-integration/93-messages.md |
| MSG-INT-072 | E | 该任务当前状态不允许重试。 | 状態不整合 | 状態確認 | INT | 09-integration/93-messages.md |
| MSG-INT-073 | W | 单次最多重试 500 件，已切换为异步任务。 | 件数超過 | ジョブ確認 | INT | 09-integration/93-messages.md |
| MSG-INT-074 | W | 接口熔断中，暂不发送，将在 {0} 后重试。 | サーキット OPEN | 待機 | INT | 09-integration/93-messages.md |
| MSG-INT-075 | I | 重试完成：成功 {0} 件，失败 {1} 件。 | 再送完了 | 失敗分確認 | INT | 09-integration/93-messages.md |
| MSG-INT-076 | W | 工单 {0} 已下发但超过 24 小时未回传报工。 | 未回伝 | MES/現場確認 | INT | 09-integration/93-messages.md |
| MSG-INT-077 | I | 完工实绩已接收（工单 {0}）。 | 完工受信 | — | INT | 09-integration/93-messages.md |
| MSG-INT-078 | I | 领料实绩已接收（工单 {0}）。 | 領料受信 | — | INT | 09-integration/93-messages.md |
| MSG-INT-079 | I | PLM 数据导入完成：成功 {0} 行，失败 {1} 行，已进入审批。 | 取込完了 | 承認へ | INT | 09-integration/93-messages.md |
| MSG-INT-080 | E | 指定的权限范围无效。 | スコープ不正 | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-081 | E | IP 地址格式不正确。 | 形式エラー | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-082 | E | 签名验证失败或请求时间超时，请检查密钥与服务器时间。 | 署名/時刻 | 設定確認 | INT | 09-integration/93-messages.md |
| MSG-INT-083 | E | 请求重复（nonce 已使用），请重新生成。 | nonce 再利用 | 再生成 | INT | 09-integration/93-messages.md |
| MSG-INT-084 | E | 该 API 客户端已失效，请联系管理员。 | 失効クライアント | 再発行申請 | INT | 09-integration/93-messages.md |
| MSG-INT-085 | I | API 客户端已创建，请妥善保管密钥（仅显示一次）。 | 発行成功 | 保管 | INT | 09-integration/93-messages.md |
| MSG-INT-086 | I | 文件导入完成，共 {0} 行。 | 取込成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-087 | E | 文件导入失败，请下载错误报告后修正。 | 取込失敗 | エラー行修正 | INT | 09-integration/93-messages.md |
| MSG-INT-088 | W | 日次对账发现差异（{0} 件，金额 {1} 元），请确认。 | 対账差異 | 原因調査 | INT | 09-integration/93-messages.md |
| MSG-INT-089 | E | 对账数据获取失败，请稍后重试。 | 照会失敗 | 再実行 | INT | 09-integration/93-messages.md |
| MSG-INT-090 | E | 通知渠道未启用或配置不正确。 | チャネル無効 | 設定確認 | INT | 09-integration/93-messages.md |
| MSG-INT-091 | E | 通知接收地址无效。 | 宛先不正 | 修正 | INT | 09-integration/93-messages.md |
| MSG-INT-092 | W | 通知发送失败，系统将自动重试（第 {0} 次）。 | 送信失敗 | 監視 | INT | 09-integration/93-messages.md |
| MSG-INT-093 | I | 通知已发送。 | 送信成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-094 | I | 测试通知已发送，请确认接收。 | テスト成功 | — | INT | 09-integration/93-messages.md |
| MSG-INT-095 | I | 对账完成，无差异。 | 差異 0 | — | INT | 09-integration/93-messages.md |
| MSG-INV-001 | E | 库存不足，当前可用数量：{0} {1}。 | 出庫・沖销時の可用量不足 | 数量を調整するか、欠品として処理する | INV | 05-inventory/93-messages.md |
| MSG-INV-004 | E | 该物料未启用批次管理，不能指定批次。 | 非批次管理物料への批次指定 | 批次をクリアする | INV | 05-inventory/93-messages.md |
| MSG-INV-005 | E | 该物料启用批次管理，必须指定批次。 | 批次管理物料の批次未入力 | 批次を指定する | INV | 05-inventory/93-messages.md |
| MSG-INV-006 | E | 批次 {0} 不存在或已失效。 | 無効・不存在の批次 | 有効な批次を選択する | INV | 05-inventory/93-messages.md |
| MSG-INV-007 | E | 序列号数量必须与行数量一致（数量 {0}、序列号 {1} 件）。 | 数量と序列号数の不一致 | 序列号を追加・削除する | INV | 05-inventory/93-messages.md |
| MSG-INV-008 | E | 序列号 {0} 重复。 | 序列号の重複入力・重複スキャン | 重複を除外する | INV | 05-inventory/93-messages.md |
| MSG-INV-009 | E | 序列号 {0} 不属于批次 {1}，请确认序列号与批次的对应关系。 | 序列号と批次の不整合 | 序列号・批次を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-010 | E | 该物料启用序列号管理，必须录入序列号。 | 序列号未入力 | 序列号を入力する | INV | 05-inventory/93-messages.md |
| MSG-INV-011 | E | 库存状态不允许出库（当前状态：{0}）。 | 待検/凍結/不合格/報廃待ちからの出庫 | 在庫状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-012 | E | 该记录当前状态不允许此操作（当前状态：{0}）。 | 状態遷移不正（未承認の過账等） | 最新の状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-013 | E | 批次号 {0} 已存在。 | 批次番号の重複 | 別の批番を指定する | INV | 05-inventory/93-messages.md |
| MSG-INV-015 | E | 批次 {0} 已超过有效期（{1}），不能出库。 | 期限切れ批次の出庫 | 有効な批次を選択する | INV | 05-inventory/93-messages.md |
| MSG-INV-016 | W | 物料 {0} 未设置安全库存或提前期，无法生成补货建议。 | マスタ未設定 | MDM で安全在庫・LT を設定する | INV | 05-inventory/93-messages.md |
| MSG-INV-017 | E | 序列号 {0} 不存在或不属于该物料。 | 序列号の不存在・物料不一致 | 序列号を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-018 | E | 序列号 {0} 当前状态（{1}）不允许该操作。 | 序列号の状態不正 | 序列号の状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-020 | E | 库存事务已过账，不能修改或取消。 | 過账後の編集・取消 | 沖销して再登録する | INV | 05-inventory/93-messages.md |
| MSG-INV-021 | E | 该库存事务已冲销，不能重复冲销。 | 二重沖销 | 最新情報を再取得する | INV | 05-inventory/93-messages.md |
| MSG-INV-022 | E | 事务类型 {0} 不允许手工创建。 | 手動禁止の取引種別 | 来源伝票から処理する | INV | 05-inventory/93-messages.md |
| MSG-INV-023 | E | 未过账的库存事务不能冲销。 | txn_status ≠ 30 | 状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-024 | E | 该库存事务存在后续业务处理，不能冲销。 | 下流処理あり | 下流の取消を先に行う | INV | 05-inventory/93-messages.md |
| MSG-INV-025 | E | 事务日期 {0} 早于该物料最后交易日期 {1}，不允许追溯登记。 | 遡及取引（08 §6.1） | 正しい日付で再登録する | INV | 05-inventory/93-messages.md |
| MSG-INV-026 | E | 库存数据正在被其他操作占用，请稍后重试。 | ロックタイムアウト・デッドロック | しばらく待って再実行する | INV | 05-inventory/93-messages.md |
| MSG-INV-027 | E | 调拨数量超出可调拨量（可用 {0} {1}）。 | 出庫時の可用不足 | 数量または批次を変更する | INV | 05-inventory/93-messages.md |
| MSG-INV-028 | E | 受入数量超过在途数量（在途 {0} {1}）。 | 受入超過・二重受入 | 受入数量を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-029 | E | 调拨单当前状态不允许该操作（当前状态：{0}）。 | 調撥単の状態不正 | 状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-031 | E | 同仓移库的源库位与目标库位不能相同；跨仓调拨的源仓库与目标仓库不能相同。 | 倉庫・庫位の相関エラー | 倉庫・庫位を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-032 | E | 该仓库存在未完成的盘点单，不能重复创建盘点单或执行入出库。 | 未完了棚卸・全倉凍結中 | 棚卸の完了または取消を待つ | INV | 05-inventory/93-messages.md |
| MSG-INV-033 | E | 盘点差异尚未审批，不能执行库存调整。 | 承認前の調整実行 | 承認を待つ | INV | 05-inventory/93-messages.md |
| MSG-INV-035 | W | 盘点差异金额 {0} 元超过阈值 {1} 元，需要上级审批。 | 承認閾値超過（10,000 元） | 承認フローへ進む | INV | 05-inventory/93-messages.md |
| MSG-INV-036 | E | 盘点数据不完整或差异发生变化：{0}。请确认后重新提交。 | 実盤未入力・調整時差異変化 | 内容を確認し再提出する | INV | 05-inventory/93-messages.md |
| MSG-INV-037 | E | 成本调整导致库存金额为负，不能调整。 | 調整後金額 < 0 | 調整額・対象を見直す | INV | 05-inventory/93-messages.md |
| MSG-INV-038 | E | 该库存存在预留，不能冻结或转出，请先释放预留。 | 引当済在庫の凍結・転出 | 予約を解放してから実行する | INV | 05-inventory/93-messages.md |
| MSG-INV-039 | E | 无法计算平均单价（库存数量为 0），或重点物料存在盘点差异必须录入复盘数量。 | 数量 0 の出庫・復盤未入力 | 在庫・復盤を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-040 | W | 无法取得退料原价，已按当前平均单价处理。 | MIR 単価引継不能 | 原価担当に確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-041 | E | 原价核对不一致或无法执行：{0}。 | 月结・再計算の前提未充足 | 差異原因を調査する | INV | 05-inventory/93-messages.md |
| MSG-INV-042 | E | 库存期间 {0} 已关账，不能登记库存事务。 | 关账後の登録・修正 | 翌期間で処理する | INV | 05-inventory/93-messages.md |
| MSG-INV-043 | E | 上期未关账，不能关账本期 {0}。 | 前月が未关账 | 前月を先に关账する | INV | 05-inventory/93-messages.md |
| MSG-INV-044 | E | 会计期间已关账或已年结，不能重新打开。 | 期間再开不可 | 財務部に確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-045 | W | 该期间尚未关账，显示的是暂定数据。 | 未关账期間の帳票 | 月结後に再出力する | INV | 05-inventory/93-messages.md |
| MSG-INV-046 | W/E | 库龄/库存数据不一致：{0}。 | 集計差異・スナップショット未生成 | バッチ再実行・原因調査 | INV | 05-inventory/93-messages.md |
| MSG-INV-047 | E/W | 预留数量超过可用量（可用 {0} {1}），不足部分已作为缺货处理。 | 引当不足・予約外出庫 | 欠品対応・入荷後の自動引当を待つ | INV | 05-inventory/93-messages.md |
| MSG-INV-048 | E | 预留已释放或已消耗，不能重复操作。 | 予約解放の二重実行 | 最新情報を再取得する | INV | 05-inventory/93-messages.md |
| MSG-INV-050 | E | 条码无法识别或终端未登记，请重新扫描或联系管理员。 | バーコード不正・端末未登録 | 再スキャン・端末登録 | INV | 05-inventory/93-messages.md |
| MSG-INV-051 | E | 条码不属于当前作业仓库（条码仓库 {0}，作业仓库 {1}）。 | 誤倉庫のバーコード | 倉庫・バーコードを確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-052 | E | 扫描数量与单据数量不一致（应 {0}，实 {1}）。 | 数量不一致 | 数量を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-053 | E | 不允许负库存出库。 | allow_negative_stock=false での負在庫 | 数量を見直す | INV | 05-inventory/93-messages.md |
| MSG-INV-054 | W | 扫码重复，已忽略本次扫描。 | 同一セッション内の重複スキャン | そのまま続行可 | INV | 05-inventory/93-messages.md |
| MSG-INV-055 | E | 来源单据 {0} 不存在、未确认或已处理。 | 来源不整合・二重処理 | 来源伝票の状態を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-056 | E | 库存事务数量与来源单据数量不一致。 | 部分入出庫の残超過・数量不整合 | 数量を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-057 | E | 该仓库未启用库位管理，不能进行同仓移库或指定库位。 | 庫位未管理倉庫での移庫 | 跨倉調撥で対応する | INV | 05-inventory/93-messages.md |
| MSG-INV-058 | E | 库位 {0} 不属于仓库 {1}。 | 倉庫と庫位の不一致 | 倉庫・庫位を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-059 | E | 有效期的日期不合法（基准日 {0}、有效期 {1}）。 | 有効期限 < 基準日 | 日付を修正する | INV | 05-inventory/93-messages.md |
| MSG-INV-060 | E | 条码与单据的物料/批次不一致。 | 誤物料・誤批次 | 対象を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-061 | W | 成本差异金额为 0，无需调整。 | 差異 0 の成本調整 | 内容を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-062 | E | 盘点对象范围内没有库存数据。 | 対象範囲に残高 0 件 | 範囲を変更する | INV | 05-inventory/93-messages.md |
| MSG-INV-063 | E | 检验判定结果代码（resultCode={0}）无效，无法换算库存状态。 | E15 の resultCode 不正 | PRD の判定を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-064 | W | 检验判定对应的入库单据尚未过账，已保留待处理；24 小时内未处理将触发告警。 | E15 先着（inv_event_wait） | E14/E24 の未処理を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-065 | E | 完工入库的库存状态 {0} 不允许（检查必需品必须为 10 待检）。 | E24 の stockStatus 不正 | E24 の内容を確認する | INV | 05-inventory/93-messages.md |
| MSG-INV-066 | E | 该收货单已完成检验、已引当/出库或已核销，不能取消。 | E35 取消不可 | 返品処理（E16）で対応する | INV | 05-inventory/93-messages.md |
| MSG-INV-067 | W | 仓库 {0} 已停用，但仍存在库存余额 {1}，请安排移库或调整。 | E39 倉庫無効化と在庫残 | 在庫移管（TR）または調整を実施する | INV | 05-inventory/93-messages.md |
| MSG-MDM-006 | W | 類似した既存データが {0} 件あります。内容を確認してください。 | 重複チェックで類似度が閾値以上 | 既存データを確認し、重複なら使用停止・統合を検討 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-011 | E | 指定した物料分類は使用できません。末級の有効な分類を選択してください。 | 分類が末級・有効でない | 分類を選び直す | MDM | 02-mdm/93-messages.md |
| MSG-MDM-012 | E | 指定した会計科目が存在しないか、末級科目ではありません。 | FIN 科目照会失敗 | 財務に科目を確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-013 | E | 物料编码は 10 桁（分類 4 桁＋流水 6 桁）で、分類コードと一致する必要があります。 | コード形式不正 | 自動採番を使用 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-014 | E | 物料编码「{0}」は既に使用されています。 | コード重複 | 別コードを使用 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-015 | E | 購買・販売単位が基本単位と異なる場合、換算率は 0 より大きい値を入力してください。 | 換算率不正 | 換算率を修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-016 | E | 批次管理と序列号管理は同時に有効にできません。 | 相互排他違反 | いずれかを解除 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-017 | E | 安全在庫 ≦ 再訂貨点 ≦ 最大在庫 となるように入力してください。 | 在庫パラメータ相関不正 | 値を修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-018 | E | 倒冲は製造品かつ BOM 要の品目のみ設定できます。倒冲倉庫も必須です。 | 倒冲条件違反 | 条件を満たすか解除 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-019 | E | 検査段階を「免検」以外に設定した場合、検査基準の指定が必要です。 | 検査基準未設定 | 基準を選択 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-020 | I | 承認が完了し、物料を有効化しました。 | 最終承認 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-021 | W | 申請が差戻されました。内容を修正して再提出してください。 | 差戻し | 修正・再提出 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-022 | I | 申請が却下されました。理由：{0} | 却下 | 理由確認、再申請 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-023 | I | 物料「{0}」を有効化しました。関連業務に反映されます（最大 5 分）。 | 有効化 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-024 | I | 物料「{0}」を使用停止にしました。新規の業務利用はできません。 | 使用停止 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-025 | I | 物料「{0}」の使用を再開しました。 | 再開 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-026 | W | 客供品は購買・販売の対象外です。購買/販売停止の設定を推奨します。 | 客供品登録 | 停止設定を検討 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-027 | W | 製品系列が未入力です。製品（成品）には製品系列の設定を推奨します。 | 成品で系列空 | 入力を検討 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-028 | E | 承認者または承認経路が設定されていないため提出できません。管理者に連絡してください。 | 提出時に WF 経路なし | 管理者へ WF 設定を依頼 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-029 | E | 該当物料は使用中のため使用停止できません（参照：{0}）。参照を解消するか強制停止を申請してください。 | 参照中 | 参照解消 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-030 | E | 物料编码の流水が枯渇しました。分類の分割または採番規則の見直しが必要です。 | 流水 > 999,999 | 管理者へ | MDM | 02-mdm/93-messages.md |
| MSG-MDM-031 | E | 子分類または物料が存在するため、この分類は削除できません。使用停止を利用してください。 | 分類削除時 | 使用停止（status=0）に変更 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-040 | I | 承認が完了し、取引先を有効化しました。 | 最終承認 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-041 | I | 取引先「{0}」を有効化しました。 | 有効化 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-042 | I | 取引先「{0}」を使用停止にしました。新規の業務利用はできません。 | 使用停止 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-043 | I | 供应商「{0}」を合格供应商（AVL）に登録しました。 | 准入承認 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-050 | E | 取引先コード「{0}」は既に使用されています。 | コード重複 | 別コード | MDM | 02-mdm/93-messages.md |
| MSG-MDM-051 | E | 統一社会信用コードの形式が正しくないか、既に登録されています。 | 税号不正/重複 | 確認・修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-052 | E | 増値税専用発票の発行には、請求宛名・税号・住所電話・开户行及口座の入力が必要です。 | 発票情報欠落 | 4 要素を入力 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-053 | W | 連絡先が登録されていません。取引先の連絡先登録を推奨します。 | 連絡先 0 件 | 登録を検討 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-054 | E | 既定の収貨地址は 1 件のみ設定できます。 | 既定住所重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-055 | E | 銀行口座番号は 8〜32 桁の数字で入力してください。 | 口座形式不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-056 | E | 供应商の「合格」への変更は准入審査の承認によってのみ可能です。 | 准入状態の直接変更 | 准入申請を実施 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-057 | E | 有効な資格（営業執照等）が登録されていないため准入承認できません。 | 資格不足 | 資格を登録 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-058 | W | 資格「{0}」の有効期限が切れています。更新してください。 | 期限切れ | 更新 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-059 | E | 供給範囲は物料または物料分類のいずれかを指定してください。 | 供給範囲不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-060 | E | 联行号（CNAPS）は 12 桁の数字で入力してください。 | CNAPS 形式不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-061 | W | 口座名義が供应商名と一致しません。確認してください。 | 名義不一致 | 確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-062 | E | 該当取引先は未完了の取引があるため使用停止できません（参照：{0}）。 | 参照中 | 参照解消 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-063 | E | 与信限度額が設定されていません。信用管理画面で設定してください。 | 与信レコードなし | 与信設定 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-070 | I | 倉庫「{0}」を登録しました。 | 登録完了 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-071 | E | 倉庫コードは WH＋2 桁で入力してください。既に使用されている場合は別のコードを使用してください。 | 形式/重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-072 | E | 既定庫位は同一倉庫に属する有効な庫位を指定してください。 | 既定庫位不整合 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-073 | E | 庫区コードが不正か、同一倉庫内で重複しています。 | 庫区コード不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-074 | E | 庫位コードが重複しています（{0} 件）。重複一覧を確認してください。 | 一括生成重複 | 範囲修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-075 | E | 該当倉庫は在庫残高または未完了の入出庫指示があるため使用停止できません。 | 参照中 | 在庫処理を完了 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-076 | E | 在庫残高または予約がある庫位は削除できません。使用停止を利用してください。 | 庫位削除不可 | 使用停止 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-077 | W | 庫位の保管条件が倉庫と異なります。保管条件を確認してください。 | 保管条件不一致 | 確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-078 | E | 庫位ラベルの条码規則が設定されていません。条码規則を設定してください。 | 条码規則なし | 設定 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-079 | E | 一括生成件数は 1〜5,000 件の範囲で指定してください。 | 件数超過 | 範囲縮小 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-080 | E | ラベル印刷は 1 回 500 枚までです。分割して実行してください。 | 印刷超過 | 分割 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-090 | I | 登録しました。 | 単位・通貨・税码登録 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-091 | E | 通貨コードは ISO 4217 の 3 桁で指定し、記帳本位幣は 1 件のみ設定できます。 | 通貨不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-092 | I | 「{0}」を使用停止にしました。既存データの参照は可能です。 | 使用停止 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-093 | E | 単位コードは大文字英数字 1〜16 字で入力してください。 | 形式不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-094 | E | 同一換算グループの基本単位は 1 件のみ設定できます。 | 基本単位重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-095 | E | 換算元と換算先の単位グループが一致しないか、換算率が不正です。 | 換算不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-096 | E | 税码または基礎税率コードが不正です。コード一覧を確認してください。 | 税码/基礎碼不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-097 | E | 税码の有効期間が既存レコードと重複しています。期間を調整してください。 | 期間重複 | 調整 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-098 | E | 為替レートは 0 より大きい値を入力してください。 | レート不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-099 | W | 未来日の為替レートは、業務日が到来するまで使用されません。 | 未来日登録/使用 | 確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-100 | E | 税收分类编码が存在しないか有効期限切れです。 | 分類不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-110 | I | 価格表の承認が完了しました。 | 承認 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-111 | I | 価格表「{0}」を有効化しました。関連業務に反映されます。 | 有効化 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-112 | I | 価格表「{0}」を終了しました。 | 期間満了/停止 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-113 | E | 有効な販売価格が見つかりません。手動で価格を入力し、承認を取得してください。 | 取价失敗 | 手動価格 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-114 | E | 価格表コードは既に使用されています。 | 重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-115 | E | 適用範囲に応じて、客户・客户分類・物料を指定してください。 | スコープ相関不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-116 | E | 同一の適用範囲・有効期間で数量帯が重複しています（行 {0}）。 | 数量帯重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-117 | W | 標準価格から±5% を超える価格です。承認フローで審査されます。 | 価格乖離 | 承認へ | MDM | 02-mdm/93-messages.md |
| MSG-MDM-118 | E | 折扣率は 0〜100 の範囲で入力してください。 | 折扣不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-119 | E | 税込単価の設定と税码の税込/税抜設定が矛盾しています。 | 税整合不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-120 | E | 分割比率の合計は 100.00% にしてください。 | 分割不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-121 | E | 固定支払日を指定してください（1〜31）。 | 支払日不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-122 | E | 联行号（CNAPS）は 12 桁の数字で入力してください。 | CNAPS 形式不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-123 | W | 口座名義が取引先名と一致しません。確認してください。 | 名義不一致 | 確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-124 | E | 既定口座は取引先ごとに 1 件のみ設定できます。 | 既定重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-125 | E | 口座変更には変更理由と承認が必要です。 | 変更手続き不備 | WF へ | MDM | 02-mdm/93-messages.md |
| MSG-MDM-130 | E | 指定した銀行が存在しないか有効ではありません。 | 銀行不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-141 | E | 顧客の与信限度が設定されていません。与信設定後に受注してください。 | 与信レコードなし | 財務へ与信申請 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-142 | E | 与信限度額を超過しています（限度：{0}、占用予定：{1}）。受注できません。 | ブロック設定で超過 | 入金・限度見直し | MDM | 02-mdm/93-messages.md |
| MSG-MDM-143 | E | 顧客は与信凍結中です。財務部に解除を申請してください。 | 凍結中 | 財務へ解除申請 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-144 | W | 与信限度額を超過しています（警告）。経理・営業責任者に通知しました。 | 警告設定で超過 | 入金状況確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-145 | W | 単一受注上限を超過しています。承認フローで審査されます。 | 単一上限超過 | 承認へ | MDM | 02-mdm/93-messages.md |
| MSG-MDM-146 | I | 与信超過の承認申請を送信しました。承認まで出荷できません。 | 承認設定で超過 | 承認待ち | MDM | 02-mdm/93-messages.md |
| MSG-MDM-147 | E | 該当顧客の有効な与信レコードが既に存在します。変更は履歴保持のため新レコードで行います。 | 重複 | 変更画面を使用 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-148 | E | 超限許容率は 0〜100% の範囲で入力してください。 | 範囲外 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-150 | E | 有効な資格（営業執照等）が不足しているか、有効期限が 30 日未満です。准入承認できません。 | 資格不足 | 資格更新 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-151 | E | 評価点は 0〜100 の範囲で入力してください。 | 範囲外 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-152 | E | 確定済みの評価は変更できません。再評価を新規作成してください。 | 確定済変更 | 再評価 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-153 | W | D 級供應商です。暂停または改善要求（CAPA）の発行を検討してください。 | D 級 | 采购经理判断 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-154 | W | 品質・納期の実績データが不足しています。一部を手動評価で補完しました。 | データ不足 | データ確認 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-171 | E | 代替元と代替先には異なる物料を指定してください。 | 自己参照 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-172 | E | 代替関係に循環参照があります（{0}）。 | 循環 | 経路確認・修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-173 | E | 同一方向・同一有効期間の代替関係が既に登録されています。 | 重複 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-174 | E | 緊急代替の有効期間は 90 日以内に設定してください。 | 期間超過 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-176 | E | 条码規則が対象種別・内容パターンと整合していません。 | 規則不正 | 修正 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-177 | E | 同一内容の条码が既に存在します。再発行は既存条码を無効化して行ってください。 | 条码重複 | 無効化して再発行 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-178 | E | 有効期間が既存の換算率と重複しています。 | 換算率の登録・更新・再有効化で ex_mdm_uom_conversion_period 違反（DB 23P01）（蓝色大肥鱼 2026-10-21 決定） | 有効期間を調整 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-180 | I | 変更申請を承認しました。対象マスタへ反映します。 | 承認 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-181 | I | 変更内容を反映しました。関連業務に通知されます。 | 反映 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-182 | E | 申請後にデータが更新されています。最新情報を確認して再申請してください。 | base_version 不一致 | 再申請 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-183 | E | 申請者本人は承認できません。他の承認者に依頼してください。 | 自己承認 | 他者へ | MDM | 02-mdm/93-messages.md |
| MSG-MDM-190 | I | 品質問題を担当者に割り当てました。 | 割当 | — | MDM | 02-mdm/93-messages.md |
| MSG-MDM-191 | E | 一括维护の行数は 1〜10,000 行の範囲で指定してください。 | 行数超過 | 分割 | MDM | 02-mdm/93-messages.md |
| MSG-MDM-195 | W | データ権限が未設定のため全社データを表示しています。管理者に設定を依頼してください。 | 権限未設定 | 管理者へ | MDM | 02-mdm/93-messages.md |
| MSG-PRD-001 | E | 指定した品目は製造品ではありません。製造品または委外品を選択してください。 | 品目区分不一致 | 品目を変更 | PRD | 06-production/93-messages.md |
| MSG-PRD-002 | E | 承認前の受注からは工单を作成できません。 | 受注状態 < 25 | 受注承認後に再実行 | PRD | 06-production/93-messages.md |
| MSG-PRD-003 | E | 変更後の数量が既入庫数量を下回っています。 | 数量減が入庫実績未満 | 数量を確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-004 | W | 計画着手日が過去日です。このまま登録しますか？ | 過去日指定 | 確認 | PRD | 06-production/93-messages.md |
| MSG-PRD-005 | E | 起案者と承認者が同一のため承認できません。 | 自己承認（工单承認、超産承認） | 別の承認者へ | PRD | 06-production/93-messages.md |
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
| MSG-PRD-022 | E | BOM の単位と物料の基本単位が整合しません（換算不可）。 | 単位不整合（同一単位でも同一換算グループでもない、または有効な換算率が 0 件・複数件）。BOM 保存（CHK-PRD-001-09、BOM API 実装時に接続）、工单登録（BOM 展開行）、材料明細の保存（新規追加・単位／数量変更行）、承認提出（全行）、工单下达（全行）（CHK-PRD-002-10）で 422／60022 | BOM・単位換算マスタを修正 | PRD | 06-production/93-messages.md |
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
| MSG-PRD-101 | E | 超産承認が却下または取消のため入庫できません。 | 超産承認無効（却下・取消済での入庫。超産申請の状態不正操作（承認済 30・却下 40・取消 90 への承認等）、工单級申請で工单未下达・allowed_qty NULL も同コード、91 §3.14） | 再申請または数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-102 | E | 冲销数量が已完工数量を超えています。 | 冲销 qty > completed_qty | 数量修正 | PRD | 06-production/93-messages.md |
| MSG-PRD-103 | E | 超産申請数量が不正です。申請超産数量は 0 より大きく、受注行基本数量 × 超産上限率（{0}）以下、かつ基本単位の小数桁数（{1} 桁）以内で指定してください。 | request_qty ≤ 0 または NULL、上限（受注行基本数量 × prd.overproduction_max_rate、1 件単位・累計なし）超過、小数桁数 > 基本単位 decimal_places（いずれも 60103） | 申請超産数量を修正して再申請 | PRD | 06-production/93-messages.md |
| MSG-PRD-104 | E | 下达日不能早于今天。 | releaseDate が Asia/Shanghai 当日より前（60104） | 下达日を当日以降に修正 | PRD | 06-production/93-messages.md |
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
| MSG-RPT-001 | E | 没有查看该报表的权限。 | 権限なし | 管理者へ申請 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-002 | E | 指定的期间无效或尚未开始。 | 期間不正 | 期間選択 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-003 | W | 部分指标因数据未就绪显示为「-」。 | 欠測 | 抽出完了後に再表示 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-004 | I | 驾驶舱数据已更新。 | 表示更新 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-005 | W | 当前显示为暂定值，月次确定后将更新。 | 未確定 | 確定後に再表示 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-006 | E | 该看板布局不存在或已停用。 | レイアウト不正 | 既定レイアウトを使用 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-007 | I | 看板布局已保存。 | 保存成功 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-008 | E | 布局保存失败，请刷新后重试。 | 保存失敗 | 再実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-009 | W | 该指标的目标值未设定，无法显示达成率。 | 目標未設定 | 目標を設定 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-010 | E | KPI 代码格式不正确（应为 KPI-RPT-三位数字）。 | 形式違反 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-011 | E | KPI 计算公式不正确，请检查函数与字段引用。 | 算式不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-012 | E | 指定的维度或分类不在允许范围内。 | 次元/分類不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-013 | E | 数据来源表或字段不存在。 | 出所不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-014 | E | KPI 代码已存在。 | 重複 | 既存を編集 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-015 | W | 分母为 0，该比率指标无法计算。 | 分母 0 | データ確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-016 | I | KPI 定义已保存，等待审批。 | 保存成功 | 承認者へ | RPT | 10-analytics/93-messages.md |
| MSG-RPT-017 | I | KPI 定义已审批通过。 | 承認成功 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-018 | E | 该 KPI 已停用，不能修改。 | 廃止済み | 新規版を登録 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-019 | W | KPI 定义已变更，历史数据不会重新计算。 | 版数変更 | 必要に応じ再計算 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-020 | W | KPI 与业务域汇总存在差异（{0}%），请确认。 | 差異 | 原因調査 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-021 | E | 该期间 KPI 已确定，不能重新计算。 | 確定済み | 翌月調整 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-022 | W | 月次 KPI 尚未确定，当前为暂定值。 | 未確定 | 確定後に再出力 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-023 | I | 重新计算任务已受理，完成后可查看结果。 | 再計算受付 | ジョブ確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-024 | E | 重新计算已在进行中，请稍后。 | 二重起動 | 待機 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-025 | E | 重新计算期间超过上限（12 个月），请缩小范围。 | 期間超過 | 分割 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-030 | E | 分析数据抽取失败：{0}，请联系管理员。 | 抽出失敗 | ログ確認・再実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-031 | W | 部分业务数据尚未确定，当前分析结果为暂定值。 | 期間未確定 | 確定後に再表示 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-032 | W | 抽取数据量超过预期（{0} 行），请确认是否存在异常。 | 件数超過 | データ確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-033 | E | 指定的分析条件无效。 | 条件不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-034 | W | 明细超过 10,000 件，请使用导出功能。 | 明細超過 | 出力 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-035 | E | 分析结果导出失败：{0}。 | 出力失敗 | 再実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-036 | I | 导出任务已受理，完成后可在「导入导出中心」下载。 | 出力受付 | DL | RPT | 10-analytics/93-messages.md |
| MSG-RPT-037 | E | 导出文件已过期或不存在。 | ファイル期限切れ | 再出力 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-038 | E | 该分析画面暂不支持所选维度。 | 次元非対応 | 次元変更 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-039 | W | 当前数据为上次抽取结果，可能不是最新。 | 抽出遅延 | 再抽出 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-040 | E | 预警规则代码格式不正确（应为 WARN-RPT-三位数字）。 | 形式違反 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-041 | I | 该预警已存在，已更新为最新值。 | 重複 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-042 | E | 指定的 KPI 不存在或已停用。 | KPI 不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-043 | E | 阈值超出该指标的有效范围。 | 閾値不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-044 | E | 连续次数必须在 1〜12 之间。 | 値域違反 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-045 | E | 请至少选择一个通知渠道。 | チャネルなし | 選択 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-046 | W | 该指标的 KPI 尚未计算，本次跳过。 | KPI 未計算 | 翌日再評価 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-047 | W | 部分通知渠道不可用，已改由站内通知。 | チャネル障害 | 設定確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-048 | W | 升级通知的接收人不存在，已通知系统管理员。 | 宛先不在 | ロール確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-049 | I | 预警已解决。 | 解決 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-050 | E | 指定的报表不存在。 | 帳票不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-051 | E | 配信日与频率不匹配。 | 日付不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-052 | E | 请至少指定一个接收人。 | 宛先なし | 追加 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-053 | E | 配信时刻必须在 06:00〜20:00 之间。 | 時刻不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-054 | W | 该期间已配信，本次跳过。 | 二重配信 | 再配信を明示 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-055 | E | 报表生成失败：{0}，系统将重试。 | 生成失敗 | 監視 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-056 | W | 接收人展开后为 0 件，未执行配信。 | 宛先 0 | 設定確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-057 | E | 解决预警时必须填写原因与对策（10 字以上）。 | 理由不足 | 入力 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-058 | E | 该预警当前状态不允许此操作。 | 状態不整合 | 状態確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-059 | W | 该预警已连续 {0} 个月发生，请检视指标或业务流程。 | 連続発生 | 見直し | RPT | 10-analytics/93-messages.md |
| MSG-RPT-060 | I | 订阅已保存，下次配信时间为 {0}。 | 保存成功 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-061 | I | 已停止配信。 | 停止 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-062 | I | 已恢复配信，下次配信时间为 {0}。 | 再開 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-063 | E | 配信失败已达上限，订阅已暂停，请检查配置。 | 連続失敗 | 設定確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-070 | E | 系统繁忙，请稍后重试。 | 一時的負荷 | 再試行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-071 | E | 数据加载失败，请刷新页面重试。 | 取得失敗 | 再読込 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-072 | W | 当前页面数据已过期，请刷新后再操作。 | 画面滞留 | 再読込 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-073 | E | 该功能在当前版本中不可用。 | Phase 2 機能 | リリース待ち | RPT | 10-analytics/93-messages.md |
| MSG-RPT-074 | C | 该操作将重新生成分析数据，是否继续？ | 再計算前 | OK/キャンセル | RPT | 10-analytics/93-messages.md |
| MSG-RPT-075 | I | 分析结果已导出，请稍后下载。 | 出力成功 | DL | RPT | 10-analytics/93-messages.md |
| MSG-RPT-076 | E | 导出任务失败：{0}。 | 出力失敗 | 再実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-077 | W | 导出数据量较大，已转为后台处理。 | 件数超過 | ジョブ確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-078 | E | 导出格式不支持，请选择 Excel 或 PDF。 | 形式不正 | 修正 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-079 | E | 导出文件生成超时，请缩小范围后重试。 | タイムアウト | 範囲縮小 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-080 | W | 该导出文件将在 7 天后删除，请及时下载。 | 期限警告 | DL | RPT | 10-analytics/93-messages.md |
| MSG-RPT-081 | E | 抽取任务启动失败，可能存在正在运行的同类任务。 | 二重起動 | 待機 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-082 | W | 抽取数据存在 {0} 行错误，已跳过并记录。 | 行エラー | エラー確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-083 | E | 抽取源数据不存在或已被删除。 | 参照不能 | 業務域確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-084 | W | KPI 快照已过期，请重新计算。 | 古いデータ | 再計算 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-085 | W | 数据质量检查发现 {0} 项差异，请确认。 | 差異 | 原因調査 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-086 | I | 数据质量检查完成，无差异。 | 差異 0 | — | RPT | 10-analytics/93-messages.md |
| MSG-RPT-087 | E | 数据质量检查失败：{0}。 | 検査失敗 | 再実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-088 | W | 该期间的数据尚未抽取，无法生成月报。 | 未抽出 | 抽出実行 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-089 | E | 您没有查看该指标明细的权限。 | 項目権限なし | 管理者へ申請 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-090 | E | 该数据超出您的数据范围。 | 行レベル範囲外 | 範囲確認 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-091 | W | 本次导出包含敏感金额信息，请妥善保管。 | 機密出力 | 管理徹底 | RPT | 10-analytics/93-messages.md |
| MSG-RPT-092 | I | 操作已记录到审计日志。 | 重要操作 | — | RPT | 10-analytics/93-messages.md |
| MSG-SAL-001 | I | 销售订单已保存（{0}）。 |  | 詳細を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-002 | E | 该客户已停止交易或信用冻结，不能受理订单。 |  | 顧客マスタ・與信を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-004 | E | 受注日必须为当天至 3 个月前的日期。 |  | 日付を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-005 | E | 订单明细必须在 1 行以上、1,000 行以内。 |  | 行数を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-006 | E | 物料「{0}」已停止销售，不能添加到订单。 |  | 物料を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-007 | E | 数量必须大于 0，且不能低于最小销售数量 {0}。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-008 | E | 销售单位与基本单位不属于同一换算组，不能换算。 |  | 單位を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-009 | E | 单价必须大于等于 0，且最多 6 位小数。 |  | 單價を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-010 | E | 税码无效或税率超出范围。 |  | 稅碼を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-011 | W | 该客户订单号已存在，是否继续？ |  | 確認して続行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-012 | W | 未找到有效价格，已切换为手工单价，需提交价格审批。 |  | 單價入力・特價申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-013 | W | 折扣率 {0}% 超过 5%，提交时需要审批。 |  | 承認申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-014 | E | 明细交期不能晚于订单交期，且不能早于受注日。 |  | 納期を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-015 | E | 审批已驳回：{0}。 |  | 內容修正・再作成 | SAL | 03-sales/93-messages.md |
| MSG-SAL-016 | I | 已退回申请人修改。 |  | 修正・再提出 | SAL | 03-sales/93-messages.md |
| MSG-SAL-017 | I | 销售订单 {0} 已审批通过。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-018 | E | 不能审批自己创建的订单。 |  | 別の承認者へ | SAL | 03-sales/93-messages.md |
| MSG-SAL-019 | E | 订单明细为空或尚未完成与信判定，不能提交。 |  | 明細追加・判定 | SAL | 03-sales/93-messages.md |
| MSG-SAL-020 | W | 与信使用额超过信用额度，需提交超限审批。 |  | 超限承認申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-021 | E | 本次订单金额超过单笔限额 {0}，不能提交。 |  | 分割受注・超限承認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-022 | W | 与信额度不足。审批通过前不能发货。 |  | 承認完了を待つ | SAL | 03-sales/93-messages.md |
| MSG-SAL-023 | W | 单价偏离标准价格 {0}%，需提交价格审批。 |  | 特價申請・承認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-030 | W | 物料「{0}」可用量不足（可用 {1}，受注 {2}），将作为欠货处理。 |  | 納期回答・入荷待ち | SAL | 03-sales/93-messages.md |
| MSG-SAL-031 | W | 受注引当未完成，请确认库存引当执行状况。 |  | 再引當・INV 照會 | SAL | 03-sales/93-messages.md |
| MSG-SAL-032 | W | 引当不足：{0} 行（不足数量 {1}），已转为欠货。 |  | 納期再回答・バックオーダー管理 | SAL | 03-sales/93-messages.md |
| MSG-SAL-036 | E | 出荷数量超过引当数量／受注残数量。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-037 | W | 库存不足，当前可用数量：{0}。 |  | 入荷待ち・引當再確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-039 | E | 出荷确定数量与指示数量不一致，请确认拣货与出荷数量。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-041 | I | 订单已全部出荷并关闭。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-045 | I | 订单已取消。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-046 | E | 该订单已存在出荷实绩，不能取消；请使用销售退货处理。 |  | 返品処理へ | SAL | 03-sales/93-messages.md |
| MSG-SAL-047 | W | 已出荷部分不能取消，将仅取消剩余数量。 |  | 確認して続行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-048 | E | 当前状态不允许变更订单（僅承認済 25/30 可変更）。 |  | 狀態を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-049 | E | 变更理由不能为空。 |  | 理由を入力 | SAL | 03-sales/93-messages.md |
| MSG-SAL-050 | I | 已创建变更版本 v{0}，请编辑后提交。 |  | 変更ウィザードへ | SAL | 03-sales/93-messages.md |
| MSG-SAL-051 | I | 订单变更已确定（v{0}），引当数量将同步调整。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-052 | I | 变更已中止。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-053 | W | 变更后的引当数量将减少 {0}，已通知库存域释放引当。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-054 | E | 变更后数量不能小于已出荷数量 {0}。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-055 | W | 本次变更金额增加 {0}，超出与信余力，需要重新审批。 |  | 再承認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-056 | E | 变更后数量（基本单位）不能小于已完工数量或已出库数量 {0}。 |  | 數量を修正（≥ max(已完工, 已出库)） | SAL | 03-sales/93-messages.md |
| MSG-SAL-080 | E | 该客户尚未设置信用额度，不能提交订单。请先在主数据中维护信用额度。 |  | 主データ登録申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-081 | E | 无法获取应收账款余额，请稍后重试或联系财务。 |  | 再試行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-082 | E | 第一版 仅支持人民币（CNY）交易。 |  | 通貨を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-083 | I | 与信台帳照会・判定完成：{0}（10 正常/20 注意/30 超限審査中/40 超限承認済/90 凍結・閉鎖）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-084 | I | 与信台帳の投影を更新しました（{0}，金額 {1}）。台帳権威は FIN。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-085 | E | 当前客户与信已超限且未完成超限审批，不能发货。 |  | 超限承認を先に完了 | SAL | 03-sales/93-messages.md |
| MSG-SAL-086 | I | 特价申请已保存（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-087 | I | 特价申请已批准，有效期 {0} 〜 {1}。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-088 | I | 特价申请已到期失效（{0}）。 |  | 必要なら再申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-089 | I | 特价申请已取消。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-090 | E | 特价与促销折扣不能同时使用。 |  | いずれかを解除 | SAL | 03-sales/93-messages.md |
| MSG-SAL-091 | E | 特价必须大于 0，且不能超过标准价格的 150%。 |  | 單價を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-092 | E | 有效期间必须是 12 个月以内，且开始日不能晚于结束日。 |  | 期間を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-093 | E | 同一客户、同一物料在有效期间内已存在特价，请勿重复申请。 |  | 既存特價を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-094 | W | 特价低于标准成本，毛利率为负，需要总经理审批。 |  | 承認経路を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-095 | W | 特价已过期或尚未生效，已回退为标准价格。 |  | 標準價で続行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-096 | E | 未找到有效的汇率，请先维护汇率。 |  | 匯率を登録 | SAL | 03-sales/93-messages.md |
| MSG-SAL-100 | E | 该订单当前状态不能创建发货通知（需承认済且存在未出荷数量）。 |  | 受注を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-101 | E | 未找到有效的库存引当，不能确定出荷；如需例外出荷请提交主管审批。 |  | 引當依頼・例外承認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-102 | E | 仓库或物料不可出荷，请确认主数据状态。 |  | マスタを確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-103 | E | 指定批次不可用（状态：{0}），请重新选择批次。 |  | 批次を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-104 | E | 序列号不足或重复，请确认出荷数量与序列号。 |  | 序列號を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-105 | I | 发货通知已创建（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-106 | I | 拣货作业已开始（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-107 | I | 出荷已确定（部分），订单状态更新为 35。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-108 | I | 出荷已全部确定（{0}），订单状态更新为 40。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-109 | E | 该发货通知已确定出荷或已取消，不能取消。 |  | 返品処理へ | SAL | 03-sales/93-messages.md |
| MSG-SAL-110 | E | 出荷日必须在库存最终交易日之后且不超过 7 天。 |  | 日付を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-111 | E | 拣货数量与指示数量不一致，请完成拣货后再确定出荷。 |  | ピッキング完了 | SAL | 03-sales/93-messages.md |
| MSG-SAL-112 | E | 尚未确定出荷，不能输出送货单。 |  | 出荷確定を先に | SAL | 03-sales/93-messages.md |
| MSG-SAL-113 | W | 出荷已确定但库存出库尚未完成（E18 未受信），请稍后确认。 |  | 在庫照會・再処理 | SAL | 03-sales/93-messages.md |
| MSG-SAL-114 | W | 本次出荷数量低于指示数量，将按部分出荷处理。 |  | 確認して続行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-115 | E | 该序列号已被其他出荷使用，不能重复出荷。 |  | 序列號を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-120 | E | 未找到可退货的出荷记录，或该出荷已全部退货。 |  | 出荷番號を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-121 | W | 已超过退货期限（{0}），需要财务经理例外审批。 |  | 例外承認申請 | SAL | 03-sales/93-messages.md |
| MSG-SAL-122 | E | 退货数量不能超过可退货数量 {0}。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-123 | E | 尚未完成退货检验，不能执行库存退回。 |  | 検品を実施 | SAL | 03-sales/93-messages.md |
| MSG-SAL-124 | E | 未找到原发票，不能开具红字发票；请先确认发票信息。 |  | 発票を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-125 | I | 退货单已创建（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-126 | I | 退货单已审批通过，等待收货检验。 |  | 検品を実施 | SAL | 03-sales/93-messages.md |
| MSG-SAL-127 | I | 退货检验完成，已通知库存退回并生成红字应收。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-128 | I | 退货处理已完成（库存退回・红字计上）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-129 | E | 该退货单已进入检验/退回流程，不能取消。 |  | 修正伝票で対応 | SAL | 03-sales/93-messages.md |
| MSG-SAL-130 | I | 退货检验已开始。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-131 | I | 退货检验已确定：{0}。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-132 | E | 退货日必须在出荷日之后且不能晚于当天。 |  | 日付を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-133 | E | 受入数量与退货数量不一致，如需部分受入请先获得审批。 |  | 數量修正・承認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-134 | E | 检验结果为不合格/返修时必须填写不良内容。 |  | 內容を入力 | SAL | 03-sales/93-messages.md |
| MSG-SAL-135 | W | 该出荷明细已存在未完成的退货单，请确认是否重复。 |  | 既存返品を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-136 | E | 红字计上尚未完成，退货单保持「検品完了」状态，请稍后确认。 |  | 照會・再確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-140 | E | 没有可开票的出荷明细（需出荷确定且应收取入済）。 |  | 出荷・應收を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-141 | E | 客户开票信息不完整（抬头/税号/地址电话/银行），不能开具专用发票。 |  | MDM を補完 | SAL | 03-sales/93-messages.md |
| MSG-SAL-142 | E | 开票申请尚未审批通过，不能登记发票。 |  | 承認を先に完了 | SAL | 03-sales/93-messages.md |
| MSG-SAL-143 | E | 对账单期间必须是已结账的月份以前。 |  | 期間を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-144 | I | 开票申请已创建（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-145 | I | 开票申请已审批通过。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-146 | I | 开票申请已完成（与应收纽付け完毕）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-147 | I | 开票申请已取消。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-148 | I | 发票已登记（{0}），已通知财务域纽付け应收。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-149 | I | 发票已交付（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-150 | I | 发票与应收已完成纽付け。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-151 | I | 红字发票已登记（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-152 | I | 对账单已生成（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-153 | I | 对账单已发送（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-154 | I | 对账单已完成顾客确认。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-155 | E | 开票金额与应收金额存在差异，请填写差额理由并提交财务审批。 |  | 理由を入力 | SAL | 03-sales/93-messages.md |
| MSG-SAL-156 | E | 发票号码已存在，请确认是否重复登记。 |  | 番號を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-157 | E | 发票代码格式不正确（纸票为 10/12 位，数电票无代码）。 |  | 形式を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-158 | E | 发票金额与开票申请金额不一致。 |  | 金額を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-159 | E | 该应收明细已开票，不能重复开票。 |  | 既存發票を確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-160 | W | 对账单余额与财务应收余额不一致（差异 {0}），已记录差异原因。 |  | 差異原因を記錄 | SAL | 03-sales/93-messages.md |
| MSG-SAL-161 | E | 红字发票金额不能超过原发票可红冲金额。 |  | 金額を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-162 | W | 发票已登记，但应收纽付け尚未确认，请稍后确认。 |  | 照會・再確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-163 | E | 发票尚未交付，不能执行该操作。 |  | 交付を先に | SAL | 03-sales/93-messages.md |
| MSG-SAL-170 | E | 有效期不能为空，开始日不能晚于结束日，且最长 180 天。 |  | 期限を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-171 | E | 报价单尚未审批通过，不能发行。 |  | 承認を先に完了 | SAL | 03-sales/93-messages.md |
| MSG-SAL-172 | I | 询价单已创建（{0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-173 | I | 询价回答已登记。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-174 | I | 报价单已创建（{0}），请确认价格与有效期后发行。 |  | 內容確認・發行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-175 | I | 询价单已取消。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-176 | I | 报价单已保存（{0} 版 {1}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-177 | I | 报价单已发行，有效期至 {0}。 |  | 顧客へ提示 | SAL | 03-sales/93-messages.md |
| MSG-SAL-178 | I | 已创建新版本（版 {0}），旧版本保留。 |  | 新版を編集 | SAL | 03-sales/93-messages.md |
| MSG-SAL-179 | I | 已转为销售订单（{0}）。 |  | 受注內容確認 | SAL | 03-sales/93-messages.md |
| MSG-SAL-180 | I | 报价单已失效（超过有效期）。 |  | 必要なら新規見積 | SAL | 03-sales/93-messages.md |
| MSG-SAL-181 | I | 报价单已取消。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-182 | E | 报价单价必须大于等于 0 且最多 6 位小数；0 元需样品审批。 |  | 單價を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-183 | E | 转订单数量不能超过可转数量 {0}。 |  | 數量を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-184 | E | 报价单已过有效期，不能转为销售订单。请重新创建报价单。 |  | 新規見積を作成 | SAL | 03-sales/93-messages.md |
| MSG-SAL-185 | E | 已转订单的报价单不能取消。 |  | 受注側で処理 | SAL | 03-sales/93-messages.md |
| MSG-SAL-190 | I | 没有符合条件的数据。 |  | 條件を変更 | SAL | 03-sales/93-messages.md |
| MSG-SAL-191 | W | 部分明细缺少成本数据，毛利按「—」显示且不计入合计。 |  | 原價確定後に再実行 | SAL | 03-sales/93-messages.md |
| MSG-SAL-192 | E | 预测対象月必须在 3 个月前至当月的范围内。 |  | 対象月を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-193 | E | 出口销售信息格式不正确（Incoterms/货币/国家代码）。 |  | 形式を修正 | SAL | 03-sales/93-messages.md |
| MSG-SAL-194 | I | 已导出 {0} 件数据。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-195 | W | 数据量超过 10,000 件，已转为异步导出（任务号 {0}）。 |  | ジョブ完了を待つ | SAL | 03-sales/93-messages.md |
| MSG-SAL-196 | I | 预测已保存（版 {0}）。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-197 | I | 预测已确定，可用于生产计划。 |  | — | SAL | 03-sales/93-messages.md |
| MSG-SAL-198 | W | 齐套率低于目标值（{0}%），请确认欠品与延迟案件。 |  | 欠品・遅延を確認 | SAL | 03-sales/93-messages.md |
| MSG-SYS-001 | E | 该账号已停用或已离职，请联系管理员。 | status=0/account_status=3 | 管理者へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-002 | E | 内置账号不能执行此操作。 | builtin ユーザ | 別アカウント使用 | SYS | 01-system/93-messages.md |
| MSG-SYS-003 | E | 原密码不正确，请重新输入。连续 5 次错误将锁定账号 30 分钟。 | 改密の旧パスワード不一致 | 再入力 | SYS | 01-system/93-messages.md |
| MSG-SYS-004 | E | 两次输入的新密码不一致。 | 確認不一致 | 再入力 | SYS | 01-system/93-messages.md |
| MSG-SYS-005 | E | 新密码不能与原密码相同。 | 旧と同一 | 再入力 | SYS | 01-system/93-messages.md |
| MSG-SYS-006 | E | 新密码不能与最近 5 次使用过的密码相同。 | 履歴再利用 | 再入力 | SYS | 01-system/93-messages.md |
| MSG-SYS-007 | E | 密码修改失败，请稍后重试或联系管理员。 | 更新 0 件 | 再試行 | SYS | 01-system/93-messages.md |
| MSG-SYS-008 | W | 您的密码将在 {0} 天后过期，请及时修改。 | 期限 7 日前 | パスワード変更 | SYS | 01-system/93-messages.md |
| MSG-SYS-009 | I | 登录成功，欢迎使用 Stellar ERP。 | ログイン成功 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-010 | E | 请至少为用户指定一个角色。 | ロール 0 件 | ロール選択 | SYS | 01-system/93-messages.md |
| MSG-SYS-011 | E | 不能将自己的权限授予自己，请由其他管理员操作。 | 自己付与 | 他管理者へ依頼 | SYS | 01-system/93-messages.md |
| MSG-SYS-012 | W | 所选角色存在职责分离冲突（{0}）。如确需兼任，请填写理由。 | SoD 競合 | 理由入力 or 見直し | SYS | 01-system/93-messages.md |
| MSG-SYS-013 | E | 直属上级设置存在循环引用。 | 循環参照 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-014 | E | 不能对当前账号执行此操作。 | 自己停用/リセット | 他管理者へ依頼 | SYS | 01-system/93-messages.md |
| MSG-SYS-015 | E | 请至少选择一项权限。 | 権限 0 件 | 権限選択 | SYS | 01-system/93-messages.md |
| MSG-SYS-016 | E | 内置角色（{0}）的权限不可修改。 | 内置ロール | 新規ロール作成 | SYS | 01-system/93-messages.md |
| MSG-SYS-017 | E | 该角色已分配给 {0} 名用户，不能删除。可改为无效化。 | 付与中削除 | 無効化 | SYS | 01-system/93-messages.md |
| MSG-SYS-018 | E | 该角色正在审批流程中使用，不能删除或无效化。 | 承認ルート使用中 | 経路変更後 | SYS | 01-system/93-messages.md |
| MSG-SYS-019 | E | 该用户存在进行中的审批任务，请先指定代理人后再停用。 | 進行中タスク | 代理指定 | SYS | 01-system/93-messages.md |
| MSG-SYS-020 | I | 权限申请已{0}。 | 承認結果 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-021 | E | 按钮菜单必须挂在菜单节点下。 | メニュー階層違反 | 親変更 | SYS | 01-system/93-messages.md |
| MSG-SYS-022 | E | 路由路径「{0}」已被使用。 | パス重複 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-023 | E | 该菜单已分配给角色或包含子菜单，不能删除。可改为隐藏/停用。 | 使用中削除 | 無効化 | SYS | 01-system/93-messages.md |
| MSG-SYS-024 | E | 权限代码格式不正确，应形如 module:resource:action。 | 形式違反 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-030 | E | 部门代码「{0}」已存在，请使用其他代码。 | コード重複 | 別コード | SYS | 01-system/93-messages.md |
| MSG-SYS-031 | E | 该部门下存在用户或进行中的审批，不能停用。请先完成人员异动或审批。 | 参照あり無効化 | 異動後に再実行 | SYS | 01-system/93-messages.md |
| MSG-SYS-032 | E | 上级部门不能选择当前部门或其下级部门。 | 循環 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-033 | E | 部门层级不能超过 6 级。 | 階層超過 | 階層見直し | SYS | 01-system/93-messages.md |
| MSG-SYS-034 | E | 已存在默认工厂，请先取消其他工厂的默认设置。 | 默认重複 | 既存解除 | SYS | 01-system/93-messages.md |
| MSG-SYS-035 | E | 系统至少需要保留一家公司，不能删除。 | 最後の会社 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-036 | E | 该岗位已被用户使用，不能停用。 | 岗位使用中 | ユーザ異動 | SYS | 01-system/93-messages.md |
| MSG-SYS-040 | E | 系统内置字典/参数不能删除。 | 内置 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-041 | E | 该参数为只读参数，不能修改。 | 只読更新 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-042 | E | 字典项目代码「{0}」已存在。 | 項目重複 | 別コード | SYS | 01-system/93-messages.md |
| MSG-SYS-043 | E | 同一字典只能设置一个默认值。 | 默认重複 | 解除 | SYS | 01-system/93-messages.md |
| MSG-SYS-044 | E | 参数值不符合类型要求（{0}）。 | 型不一致 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-045 | E | 高危参数变更需要复核，且复核人不能与申请人相同。 | 承認不備 | 复核者選択 | SYS | 01-system/93-messages.md |
| MSG-SYS-046 | E | 参数值超出允许范围（{0}）。 | 値域外 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-047 | E | 该字典类型不存在或已停用。 | 字典無効 | 再選択 | SYS | 01-system/93-messages.md |
| MSG-SYS-048 | W | 字典缓存更新失败，已保留旧缓存，请稍后重试。 | キャッシュ更新失敗 | 再試行 | SYS | 01-system/93-messages.md |
| MSG-SYS-050 | E | 未找到有效的编号规则（{0}），请联系管理员。 | ルールなし | 管理者へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-051 | E | 日次重置的编号规则日期格式必须包含日（如 yyMMdd）。 | 形式不整合 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-052 | E | 编号生成超时，请稍后重试。 | ロックタイムアウト | 再試行 | SYS | 01-system/93-messages.md |
| MSG-SYS-053 | E | 前缀只能使用大写字母和数字（1〜10 位）。 | 形式違反 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-054 | E | 已启用规则的修改必须从未来日期生效。 | 過去日 | 未来日設定 | SYS | 01-system/93-messages.md |
| MSG-SYS-055 | E | 已存在采番记录，不能缩短流水位数。 | 桁数短縮 | 新ルール追加 | SYS | 01-system/93-messages.md |
| MSG-SYS-056 | E | 导入文件行数超过上限（10,000 行），请分割后导入。 | 行数超過 | 分割 | SYS | 01-system/93-messages.md |
| MSG-SYS-057 | E | 当前任务数已达上限（用户 3 个/系统 10 个），请稍后重试。 | 同時実行上限 | 待機 | SYS | 01-system/93-messages.md |
| MSG-SYS-058 | E | 编号流水位数不足（当前值 {0}），请调整规则或起始值。 | 桁溢れ | ルール見直し | SYS | 01-system/93-messages.md |
| MSG-SYS-059 | E | 任务执行失败：{0}。请检查数据后重新执行。 | ワーカー失敗 | 再実行 | SYS | 01-system/93-messages.md |
| MSG-SYS-060 | E | 审计日志查询期间不能超过 3 个月，请缩小范围。 | 期間超過 | 範囲縮小 | SYS | 01-system/93-messages.md |
| MSG-SYS-061 | E | 模板变量与占位符不匹配，请检查 {0}。 | 変数不整合 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-070 | E | 文件保存或读取失败，请稍后重试或联系管理员。 | ストレージ障害 | 再試行/管理者 | SYS | 01-system/93-messages.md |
| MSG-SYS-071 | E | 该单据附件已达上限（20 个/100MB）。 | 件数・容量超過 | 不要ファイル削除 | SYS | 01-system/93-messages.md |
| MSG-SYS-072 | E | 模板代码「{0}」已存在，请使用其他代码或新增版本。 | コード重複 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-073 | E | 模板内容超过长度上限（邮件 4000 字/短信 500 字）。 | 桁数超過 | 短縮 | SYS | 01-system/93-messages.md |
| MSG-SYS-074 | I | 测试邮件已发送，请查收。 | テスト送信 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-075 | E | 通知发送失败（渠道：{0}，接收者：{1}）。请检查通知配置。 | 送信失敗 | 設定確認/再送 | SYS | 01-system/93-messages.md |
| MSG-SYS-076 | I | 已全部标记为已读。 | 一括既読 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-077 | E | 该通知不存在或不属于当前用户。 | 他ユーザ通知 | 再取得 | SYS | 01-system/93-messages.md |
| MSG-SYS-080 | E | 打印模板不存在或生成失败，请联系管理员。 | テンプレートなし/PDF 失敗 | 管理者へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-081 | E | 模板格式错误：{0}。 | 構文エラー | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-082 | E | 同一报表只能指定一个默认模板。 | 既定重複 | 解除 | SYS | 01-system/93-messages.md |
| MSG-SYS-083 | E | Cron 表达式格式不正确。 | Cron 不正 | 修正 | SYS | 01-system/93-messages.md |
| MSG-SYS-084 | E | 请输入「EXECUTE」以确认执行。 | 確認不一致 | 再入力 | SYS | 01-system/93-messages.md |
| MSG-SYS-085 | E | 数据维护需要由其他管理员审批，且申请人不能自行审批。 | 承認不備 | 他管理者へ依頼 | SYS | 01-system/93-messages.md |
| MSG-SYS-086 | E | 系统已初始化，不能重复执行初始化。 | 初期化済み | — | SYS | 01-system/93-messages.md |
| MSG-SYS-087 | E | 执行前备份失败，已中止维护操作。 | バックアップ失敗 | ディスク確認 | SYS | 01-system/93-messages.md |
| MSG-SYS-088 | E | 缓存重建失败，已保留旧缓存，请重试或联系管理员。 | 再構築失敗 | 再実行 | SYS | 01-system/93-messages.md |
| MSG-SYS-089 | W | 定时任务执行失败，请联系管理员检查。 | ジョブ失敗 | 運用へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-090 | I | 定时任务已启动执行。 | 手動実行 | — | SYS | 01-system/93-messages.md |
| MSG-SYS-091 | E | 审计日志写入失败，操作已中止，请稍后重试或联系管理员。 | 重要操作の監査ログ INSERT 失敗 | 再試行/管理者へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-092 | W | 审计日志写入延迟，已转存本地待补录，请通知运维人员处理。 | ローカルファイル退避発生 | 運用担当へ連絡 | SYS | 01-system/93-messages.md |
| MSG-SYS-093 | E | 公司代码「{0}」或统一社会信用代码已存在，请使用其他代码。 | 公司登録時のコード重複（業務コード 10035、HTTP 422） | 別コード | SYS | 01-system/93-messages.md |
| MSG-SYS-094 | E | 岗位数据不存在或已失效，请重新选择。 | 岗位無効（ユーザ登録・更新時の岗位選択） | 再選択 | SYS | 01-system/93-messages.md |
| MSG-WF-001 | E | BPMN 文件格式错误，请检查文件后重试。 | パース失敗 | ファイル修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-002 | E | BPMN 文件中未找到用户任务节点，无法作为审批流程使用。 | userTask なし | モデル修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-003 | E | 未找到该业务类型的审批流程配置，请联系管理员。 | マッピングなし | 管理者へ連絡 | WF | 08-workflow/93-messages.md |
| MSG-WF-004 | E | 未找到匹配的审批规则（业务类型：{0}，金额：{1}）。 | マトリクス該当なし | 管理者へ連絡 | WF | 08-workflow/93-messages.md |
| MSG-WF-005 | E | 无法确定审批人（{0}），请检查角色/岗位/上级设置。 | 承認者 0 名 | 組織設定修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-006 | E | 该流程定义存在进行中的审批，不能删除。可改为“无效”。 | 進行中削除 | 無効化 | WF | 08-workflow/93-messages.md |
| MSG-WF-007 | E | 相同流程键与相同内容的 BPMN 已存在，请勿重复部署。 | 重複デプロイ | 確認 | WF | 08-workflow/93-messages.md |
| MSG-WF-008 | E | 同一流程键只能设置一个默认版本。 | 既定重複 | 解除 | WF | 08-workflow/93-messages.md |
| MSG-WF-010 | E | 请至少配置一个审批节点。 | 明細 0 行 | 追加 | WF | 08-workflow/93-messages.md |
| MSG-WF-011 | I | 审批已完成，业务单据状态已更新。 | 最終承認 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-012 | I | 已驳回该申请，申请人将收到通知。 | 驳回 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-013 | I | 已退回申请人修改，修改后可重新提交。 | 差戻し | — | WF | 08-workflow/93-messages.md |
| MSG-WF-014 | I | 催办通知已发送给当前审批人。 | 催办 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-015 | E | 该任务不属于当前用户，或已被处理。 | 他者タスク/処理済み | 再取得 | WF | 08-workflow/93-messages.md |
| MSG-WF-016 | E | 驳回或退回时必须填写理由。 | 理由なし | 入力 | WF | 08-workflow/93-messages.md |
| MSG-WF-017 | E | 加签对象无效（申请人、已存在审批人或已离职）。 | 加签不正 | 再選択 | WF | 08-workflow/93-messages.md |
| MSG-WF-018 | E | 转办对象无效或不能转办给自己。 | 转办不正 | 再選択 | WF | 08-workflow/93-messages.md |
| MSG-WF-019 | E | 催办过于频繁，请 1 小时后再试。 | レート制限 | 待機 | WF | 08-workflow/93-messages.md |
| MSG-WF-020 | I | 已撤回该申请，审批流程已终止。 | 撤回 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-021 | E | 已有审批通过的节点，不能撤回。 | 承認済ノードあり | 管理者へ相談 | WF | 08-workflow/93-messages.md |
| MSG-WF-022 | E | 审批处理失败，请刷新后重试。 | Flowable 例外 | 再試行 | WF | 08-workflow/93-messages.md |
| MSG-WF-030 | I | 该流程已被管理员终止。 | 強制終了 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-031 | E | 审批流程已挂起，暂不能处理。 | 挂起中の操作 | 管理者へ連絡 | WF | 08-workflow/93-messages.md |
| MSG-WF-032 | I | 流程已挂起，暂停审批任务生成。 | 挂起 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-033 | I | 流程已恢复，可继续审批。 | 再開 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-041 | E | 代理人无效（已停用、离职或与委任人相同）。 | 代理設定不正 | 再選択 | WF | 08-workflow/93-messages.md |
| MSG-WF-042 | E | 代理期间不正确（开始须早于结束，且不超过 90 天）。 | 期間不正 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-043 | E | 存在循环代理或期间重叠的代理设置。 | 循環・重複 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-044 | I | 代理设置已到期，已自动失效。 | 期限切れ | 再設定 | WF | 08-workflow/93-messages.md |
| MSG-WF-045 | E | 高权限角色的代理需要审批通过后才能生效。 | 未承認 | 承認待ち | WF | 08-workflow/93-messages.md |
| MSG-WF-046 | E | 自动审批设置不完整（需指定时间与金额上限）。 | 設定不備 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-047 | E | 财务相关流程不允许自动审批。 | 統制違反 | 無効化 | WF | 08-workflow/93-messages.md |
| MSG-WF-048 | E | 跳转目标节点不存在或不可用。 | 节点不正 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-049 | W | 超过自动审批金额上限，已跳过自动审批。 | 金額超過 | 手動承認 | WF | 08-workflow/93-messages.md |
| MSG-WF-050 | E | 跳转至最终审批节点需要第二名管理员确认。 | 二重承認未実施 | 再実行 | WF | 08-workflow/93-messages.md |
| MSG-WF-051 | E | 业务类型与映射不匹配或缺少默认映射。 | マッピング設定不備 | 設定修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-052 | E | 审批条件表达式格式错误（{0}）。 | 条件 JSON 不正 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-053 | W | 金额范围与既有规则（{0}）存在重叠，将按优先级执行。 | 金額重複 | 優先度確認 | WF | 08-workflow/93-messages.md |
| MSG-WF-061 | E | 字段「{0}」不存在于该业务类型的快照字段中。 | 項目不存在 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-062 | E | 财务金额等关键字段不能设置为“非隐藏”。 | 監査要件違反 | 参照のみに変更 | WF | 08-workflow/93-messages.md |
| MSG-WF-063 | E | 字段权限设置矛盾：必填字段不能设置为非隐藏。 | 矛盾設定 | 修正 | WF | 08-workflow/93-messages.md |
| MSG-WF-073 | E | 该业务单据已提交，请勿重复提交。 | 二重提出 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-080 | I | 您有新的审批任务：{0}（申请人：{1}，金额：{2}），请及时处理。 | タスク生成 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-081 | I | 您提交的{0}已审批通过。 | 最終承認 | — | WF | 08-workflow/93-messages.md |
| MSG-WF-082 | I | 您提交的{0}已被驳回。理由：{1}。 | 驳回 | 内容確認・再申請 | WF | 08-workflow/93-messages.md |
| MSG-WF-083 | I | 您提交的{0}已被退回修改。理由：{1}。 | 差戻し | 修正・再提出 | WF | 08-workflow/93-messages.md |
| MSG-WF-084 | W | 审批任务「{0}」已超过 {1} 小时未处理，请尽快处理。 | リマインダ | 承認処理 | WF | 08-workflow/93-messages.md |
| MSG-WF-085 | W | 审批任务「{0}」已升级至您处理，请及时审核。 | エスカレーション | 承認処理 | WF | 08-workflow/93-messages.md |
| MSG-WF-086 | I | 审批任务「{0}」已超过设定时限，系统已自动通过。 | 自動承認 | 内容確認 | WF | 08-workflow/93-messages.md |
| MSG-WF-087 | I | 申请人已催办：{0}，请尽快处理。 | 催办 | 承認処理 | WF | 08-workflow/93-messages.md |
| MSG-WF-088 | I | 您的代理设置已过期：{0}。 | 代理期限切れ | 再設定 | WF | 08-workflow/93-messages.md |

## 改訂履歴

| 版数 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v1.0 | 2026-10-20 | 自动生成 | gen_matrix.py |
