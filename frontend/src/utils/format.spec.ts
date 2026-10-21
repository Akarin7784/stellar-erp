import { describe, expect, it } from 'vitest'

import { formatAmount, formatDateTime } from './format'

describe('formatDateTime（固定 Asia/Shanghai，与运行时区无关）', () => {
  it.each(['2026-10-20T00:30:00Z', '2026-10-20T08:30:00+08:00', '2026-10-20T08:30:00+0800'])(
    '带偏移的 ISO：%s',
    (v) => {
      expect(formatDateTime(v)).toBe('2026-10-20 08:30:00')
    },
  )

  it('跨日：UTC 前一天 16:30 → 上海次日 00:30', () => {
    expect(formatDateTime('2026-10-19T16:30:00Z')).toBe('2026-10-20 00:30:00')
  })

  it('Date 对象与时间戳按绝对时刻换算', () => {
    const t = Date.UTC(2026, 9, 20, 0, 30, 0)
    expect(formatDateTime(new Date(t))).toBe('2026-10-20 08:30:00')
    expect(formatDateTime(t)).toBe('2026-10-20 08:30:00')
  })

  it('不带偏移的字符串视为上海本地时间，不平移', () => {
    expect(formatDateTime('2026-10-20 08:30:00')).toBe('2026-10-20 08:30:00')
    expect(formatDateTime('2026-10-20T08:30:00')).toBe('2026-10-20 08:30:00')
  })

  it('业务日期（无时区）保持原日期', () => {
    expect(formatDateTime('2026-10-20', 'YYYY-MM-DD')).toBe('2026-10-20')
  })

  it('支持自定义格式', () => {
    expect(formatDateTime('2026-10-19T16:30:00Z', 'YYYY/MM/DD HH:mm')).toBe('2026/10/20 00:30')
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
