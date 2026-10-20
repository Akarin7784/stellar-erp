import { describe, expect, it } from 'vitest'

import { formatAmount, formatDateTime } from './format'

describe('formatDateTime', () => {
  it('按默认格式输出', () => {
    expect(formatDateTime('2026-10-20T08:30:00+08:00')).toBe('2026-10-20 08:30:00')
  })

  it('支持自定义格式', () => {
    expect(formatDateTime('2026-10-20T08:30:00+08:00', 'YYYY/MM/DD')).toBe('2026/10/20')
  })
})

describe('formatAmount', () => {
  it('千分位与两位小数', () => {
    expect(formatAmount(1234567.8)).toBe('1,234,567.80')
  })

  it('支持自定义小数位', () => {
    expect(formatAmount(1234.5678, 3)).toBe('1,234.568')
  })
})
