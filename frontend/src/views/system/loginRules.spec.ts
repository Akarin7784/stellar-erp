import { describe, expect, it } from 'vitest'

import { normalizeTenantCode, validateLoginField, validateLoginForm } from './loginRules'

describe('loginRules', () => {
  it('040 必填（空白也算空）', () => {
    expect(validateLoginField('tenantCode', '')).toBe('请输入必填项「企业代码」。')
    expect(validateLoginField('username', '  ')).toBe('请输入必填项「账号」。')
    expect(validateLoginField('password', '')).toBe('请输入必填项「密码」。')
  })

  it('041 超长优先于 087', () => {
    expect(validateLoginField('tenantCode', 'A'.repeat(32))).toBeNull()
    expect(validateLoginField('tenantCode', '-'.repeat(33))).toBe(
      '「企业代码」不能超过 32 个字符。',
    )
    expect(validateLoginField('username', 'a'.repeat(65))).toBe('「账号」不能超过 64 个字符。')
    expect(validateLoginField('password', 'p'.repeat(65))).toBe('「密码」不能超过 64 个字符。')
  })

  it.each(['HD-JM', 'hd_jm', 'HD JM', 'ＨＤＪＭ', '华东'])(
    '087 企业代码/账号只能半角英数：%s',
    (v) => {
      expect(validateLoginField('tenantCode', v)).toBe('「企业代码」只能输入半角英数字。')
      expect(validateLoginField('username', v)).toBe('「账号」只能输入半角英数字。')
    },
  )

  it('密码不做半角英数校验', () => {
    expect(validateLoginField('password', 'p@ss 密码!')).toBeNull()
  })

  it('validateLoginForm 返回全部违规', () => {
    expect(validateLoginForm({ tenantCode: 'HDJM', username: 'E000123', password: 'x' })).toEqual(
      {},
    )
    expect(validateLoginForm({ tenantCode: '', username: 'a-b', password: '' })).toEqual({
      tenantCode: '请输入必填项「企业代码」。',
      username: '「账号」只能输入半角英数字。',
      password: '请输入必填项「密码」。',
    })
  })

  it('企业代码转大写', () => {
    expect(normalizeTenantCode('hdJm01')).toBe('HDJM01')
  })
})
