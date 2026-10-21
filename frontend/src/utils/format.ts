import dayjs from 'dayjs'

/** 格式化日期时间，默认 `YYYY-MM-DD HH:mm:ss`。 */
export function formatDateTime(value: string | number | Date, pattern = 'YYYY-MM-DD HH:mm:ss'): string {
  return dayjs(value).format(pattern)
}

/** 格式化金额，千分位 + 固定小数位。 */
export function formatAmount(value: number, digits = 2): string {
  return value.toLocaleString('zh-CN', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}
