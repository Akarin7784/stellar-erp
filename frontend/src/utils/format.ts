import dayjs from 'dayjs'
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'

dayjs.extend(utc)
dayjs.extend(timezone)

/** 系统日时一律按 Asia/Shanghai 显示，与浏览器时区无关（00-common/01 §94、04 §22、03 §240）。 */
export const DISPLAY_TIME_ZONE = 'Asia/Shanghai'

/** ISO 字符串末尾带 Z 或 ±HH:mm / ±HHmm 偏移。 */
const HAS_OFFSET = /(?:[zZ]|[+-]\d{2}:?\d{2})$/

/**
 * 格式化日期时间（默认 `YYYY-MM-DD HH:mm:ss`），输出固定为 Asia/Shanghai。
 * - 带偏移的 ISO 字符串（后端 OffsetDateTime，03 §240：`2026-10-20T14:30:00+08:00`）、Date、时间戳：
 *   视为绝对时刻，换算到 Asia/Shanghai。
 * - 不带偏移的字符串（如 `2026-10-20 14:30:00`、业务日期 `2026-10-20`）：视为 Asia/Shanghai 的本地时间，
 *   不随浏览器时区平移（业务日期按原日期显示）。
 */
export function formatDateTime(
  value: string | number | Date,
  pattern = 'YYYY-MM-DD HH:mm:ss',
): string {
  const d =
    typeof value === 'string' && !HAS_OFFSET.test(value.trim())
      ? dayjs.tz(value, DISPLAY_TIME_ZONE)
      : dayjs(value).tz(DISPLAY_TIME_ZONE)
  return d.format(pattern)
}

/** 格式化金额，千分位 + 固定小数位。 */
export function formatAmount(value: number, digits = 2): string {
  return value.toLocaleString('zh-CN', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}
