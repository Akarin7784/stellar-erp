/** 数量 > 0、4 桁精度（CHK-PRD-002-02 / MSG-COM-047）。 */
export function validateOrderQty(v: unknown): Error | undefined {
  const s = String(v ?? '').trim()
  if (!/^\d{1,14}(\.\d{1,4})?$/.test(s) || Number(s) <= 0) {
    return new Error('数量必须大于 0（小数最多 4 位）。')
  }
  return undefined
}

/** 着手日 ≦ 完成日（CHK-PRD-002-04 / MSG-COM-045）。 */
export function validateDateRange(start: unknown, end: unknown): Error | undefined {
  if (typeof start === 'string' && typeof end === 'string' && start && end && start > end) {
    return new Error('「计划开工日」不能大于「计划完成日」。')
  }
  return undefined
}
