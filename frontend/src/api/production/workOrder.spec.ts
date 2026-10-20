import { describe, expect, it, vi } from 'vitest'

vi.mock('element-plus', () => ({
  ElMessage: { error: vi.fn(), warning: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

import { ApiError } from '../http'
import {
  buildCreateRequest,
  formatRatePercent,
  MSG_GENERIC_ERROR,
  PRD_BUSINESS_CODES,
  toCreateErrorView,
  type WorkOrderCreateRequest,
} from './workOrder'
import { validateDateRange, validateOrderQty } from '../../views/production/workOrderRules'

function bizErr(code: number, msgId: string | undefined, message: string, status = 422) {
  return new ApiError(`[${msgId ?? code}] ${message}`, {
    status,
    code,
    msgId,
    data: { code, message, msgId, data: null },
  })
}

describe('toCreateErrorView', () => {
  it('60001 → 品目字段错误，带 MSG-PRD-001', () => {
    const v = toCreateErrorView(bizErr(60001, 'MSG-PRD-001', '指定品目不是制造品'))
    expect(v).toEqual({
      kind: 'business',
      field: 'materialId',
      message: '[MSG-PRD-001] 指定品目不是制造品',
    })
  })

  it('60056 → 受注明細字段', () => {
    expect(toCreateErrorView(bizErr(60056, 'MSG-PRD-056', 'x')).field).toBe('salesOrderLineId')
  })

  it.each(PRD_BUSINESS_CODES.filter((c) => c !== 60001 && c !== 60056))('%i → 业务消息', (code) => {
    const v = toCreateErrorView(bizErr(code, undefined, '业务拒否'))
    expect(v.kind).toBe('business')
    expect(v.field).toBeUndefined()
    expect(v.message).toBe(`[${code}] 业务拒否`)
  })

  it('5000 → 通用错误，不显示后端文本', () => {
    const v = toCreateErrorView(bizErr(5000, undefined, 'sys_param missing', 500))
    expect(v).toEqual({ kind: 'generic', message: MSG_GENERIC_ERROR })
  })

  it('1001 → 显示校验消息', () => {
    const v = toCreateErrorView(bizErr(1001, 'MSG-COM-047', '数量必须大于 0。', 400))
    expect(v).toEqual({ kind: 'validation', message: '数量必须大于 0。' })
  })

  it('非 ApiError → 通用错误', () => {
    expect(toCreateErrorView(new Error('boom')).kind).toBe('generic')
  })
})

describe('formatRatePercent', () => {
  it('比率显示为百分比', () => {
    expect(formatRatePercent('0.0500')).toBe('5.00%')
    expect(formatRatePercent(0)).toBe('0.00%')
    expect(formatRatePercent('0.1234')).toBe('12.34%')
  })
  it('null/非法 → —', () => {
    expect(formatRatePercent(null)).toBe('—')
    expect(formatRatePercent(undefined)).toBe('—')
    expect(formatRatePercent('abc')).toBe('—')
  })
})

describe('buildCreateRequest', () => {
  it('去掉空的可选字段，保留 false', () => {
    const req: WorkOrderCreateRequest = {
      workOrderType: 10,
      factoryId: '1',
      materialId: ' 2 ',
      orderQty: '120.0000',
      uomCode: 'PCE',
      plannedStartDate: '2026-11-12',
      plannedEndDate: '2026-11-17',
      priorityNo: 5,
      warehouseId: '',
      salesOrderLineId: null,
      isBackflush: false,
      remark: '',
    }
    expect(buildCreateRequest(req)).toEqual({
      workOrderType: 10,
      factoryId: '1',
      materialId: '2',
      orderQty: '120.0000',
      uomCode: 'PCE',
      plannedStartDate: '2026-11-12',
      plannedEndDate: '2026-11-17',
      priorityNo: 5,
      isBackflush: false,
    })
    expect(buildCreateRequest(req)).not.toHaveProperty('orderStatus')
  })
})

describe('workOrderRules', () => {
  it('数量 > 0、4 桁精度', () => {
    expect(validateOrderQty('120.0000')).toBeUndefined()
    expect(validateOrderQty('0')).toBeInstanceOf(Error)
    expect(validateOrderQty('-1')).toBeInstanceOf(Error)
    expect(validateOrderQty('1.12345')).toBeInstanceOf(Error)
  })
  it('着手日 ≦ 完成日', () => {
    expect(validateDateRange('2026-11-12', '2026-11-17')).toBeUndefined()
    expect(validateDateRange('2026-11-12', '2026-11-12')).toBeUndefined()
    expect(validateDateRange('2026-11-18', '2026-11-17')).toBeInstanceOf(Error)
  })
})
