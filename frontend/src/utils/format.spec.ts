import { describe, expect, it } from 'vitest'

import { formatAmount, formatDateTime } from './format'

describe('formatDateTime', () => {
  // formatDateTime 按运行环境的本地时区输出，测试用本地时间分量构造输入，不依赖 TZ
  it('按默认格式输出', () => {
    expect(formatDateTime(new Date(2026, 9, 20, 8, 30, 0))).toBe('2026-10-20 08:30:00')
  })

  it('支持自定义格式', () => {
    expect(formatDateTime(new Date(2026, 9, 20, 8, 30, 0), 'YYYY/MM/DD')).toBe('2026/10/20')
  })

  it('ISO 字符串按本地时区换算', () => {
    const iso = '2026-10-20T08:30:00+08:00'
    const d = new Date(iso)
    const pad = (n: number) => String(n).padStart(2, '0')
    const expected = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
    expect(formatDateTime(iso)).toBe(expected)
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
