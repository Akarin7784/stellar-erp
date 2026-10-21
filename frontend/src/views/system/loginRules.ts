/** SCR-SYS-001 客户端校验，与 AuthController.validate 一致：040（必填）→ 041（超长）→ 087（半角英数）。 */
/** 企业代码记忆（§4.4 No.0）：登录成功即保存，与 rememberMe 无关。 */
export const TENANT_CODE_STORAGE_KEY = 'stellar.login.tenantCode'

export type LoginField = 'tenantCode' | 'username' | 'password'

export const LOGIN_FIELDS: readonly LoginField[] = ['tenantCode', 'username', 'password']

export const LOGIN_LABELS: Record<LoginField, string> = {
  tenantCode: '企业代码',
  username: '账号',
  password: '密码',
}

/** 最大长度取自后端 AuthController.validate（tenantCode 32 / username 64 / password 64）。 */
export const LOGIN_MAX_LENGTH: Record<LoginField, number> = {
  tenantCode: 32,
  username: 64,
  password: 64,
}

const ALNUM = /^[A-Za-z0-9]+$/

export const msgRequired = (label: string) => `请输入必填项「${label}」。`
export const msgTooLong = (label: string, max: number) => `「${label}」不能超过 ${max} 个字符。`
export const msgHalfWidth = (label: string) => `「${label}」只能输入半角英数字。`

/** 返回该字段第一条违规文案；通过时返回 null。 */
export function validateLoginField(
  field: LoginField,
  value: string | null | undefined,
): string | null {
  const label = LOGIN_LABELS[field]
  if (value == null || value.trim() === '') return msgRequired(label)
  const max = LOGIN_MAX_LENGTH[field]
  if (value.length > max) return msgTooLong(label, max)
  if (field !== 'password' && !ALNUM.test(value)) return msgHalfWidth(label)
  return null
}

export function validateLoginForm(
  form: Record<LoginField, string>,
): Partial<Record<LoginField, string>> {
  const errors: Partial<Record<LoginField, string>> = {}
  for (const f of LOGIN_FIELDS) {
    const e = validateLoginField(f, form[f])
    if (e) errors[f] = e
  }
  return errors
}

/** 企业代码不区分大小写（BR-13），输入时转大写。 */
export function normalizeTenantCode(v: string): string {
  return v.toUpperCase()
}
