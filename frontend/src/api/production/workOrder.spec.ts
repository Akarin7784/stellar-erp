import { afterEach, describe, expect, it, vi } from 'vitest'

vi.mock('element-plus', () => ({
  ElMessage: { error: vi.fn(), warning: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

import http, { ApiError } from '../http'
import {
  toReleaseErrorView,
  buildCreateRequest,
  createWorkOrder,
  formatRatePercent,
  MSG_GENERIC_ERROR,
  MSG_ID_BY_CODE,
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
    expect(v.message).toBe(`[${MSG_ID_BY_CODE[code] ?? code}] 业务拒否`)
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

describe('createWorkOrder 请求体', () => {
  afterEach(() => vi.restoreAllMocks())

  it('不带 companyId / overReceiptRate（由后端按登录公司和 sys_param 决定）', async () => {
    const post = vi
      .spyOn(http, 'post')
      .mockResolvedValue({ data: { code: 0, message: 'ok', data: { id: 1 } } })
    const form = {
      factoryId: '1',
      materialId: '2',
      warehouseId: '3',
      orderQty: '10',
      uomCode: 'PCE',
      plannedStartDate: '2026-11-12',
      plannedEndDate: '2026-11-17',
      // 即使画面状态里混入，也不得发送
      companyId: '9',
      overReceiptRate: '0.0500',
    } as unknown as WorkOrderCreateRequest
    await createWorkOrder(form)
    const body = post.mock.calls[0]![1] as Record<string, unknown>
    expect(post.mock.calls[0]![0]).toBe('/production/work-orders')
    expect(body).not.toHaveProperty('companyId')
    expect(body).not.toHaveProperty('overReceiptRate')
    expect(body).toMatchObject({ warehouseId: '3', factoryId: '1', materialId: '2' })
  })
})

describe('60104', () => {
  it('下达日过去日 → 业务消息 MSG-PRD-104', () => {
    expect(PRD_BUSINESS_CODES).toContain(60104)
    const v = toCreateErrorView(bizErr(60104, 'MSG-PRD-104', '下达日不能早于今天。'))
    expect(v).toEqual({ kind: 'business', message: '[MSG-PRD-104] 下达日不能早于今天。' })
  })
})

describe('60021 / 60022', () => {
  it('60021 → MSG-PRD-021 默认文案与 93:60 一致（后端无消息时）', () => {
    expect(PRD_BUSINESS_CODES).toContain(60021)
    const e = new ApiError('x', { status: 422, code: 60021, data: { code: 60021 } })
    expect(toCreateErrorView(e)).toEqual({
      kind: 'business',
      message: '[MSG-PRD-021] 有効な工艺路线がありません。工艺路线を登録してください。',
      field: undefined,
    })
  })

  it('60022 → MSG-PRD-022 默认文案与 93:61 一致', () => {
    expect(PRD_BUSINESS_CODES).toContain(60022)
    const e = new ApiError('x', { status: 422, code: 60022, data: { code: 60022 } })
    expect(toCreateErrorView(e).message).toBe(
      '[MSG-PRD-022] BOM の単位と物料の基本単位が整合しません（換算不可）。',
    )
  })

  it('60022 后端真实响应（GlobalExceptionHandler Result.fail(code, message, msgId)）', () => {
    // UomConverter.java:115-117 / WorkOrderMaterials.java:64-65 的实际 body 形状
    const e = bizErr(
      60022,
      'MSG-PRD-022',
      'BOM の単位と物料の基本単位が一致しません。（BOX → PCE）',
    )
    expect(toCreateErrorView(e)).toEqual({
      kind: 'business',
      message: '[MSG-PRD-022] BOM の単位と物料の基本単位が一致しません。（BOX → PCE）',
      field: undefined,
    })
  })

  it('后端带消息时优先用后端文本', () => {
    expect(toCreateErrorView(bizErr(60021, 'MSG-PRD-021', '工序明細 0 件')).message).toBe(
      '[MSG-PRD-021] 工序明細 0 件',
    )
  })
})

describe('toReleaseErrorView', () => {
  const e = (status: number, code: number, message: string, msgId?: string) =>
    new ApiError('fallback', {
      status,
      code,
      msgId,
      data: { code, message, data: null, msgId: msgId ?? null },
    })

  it('4003 → conflict（刷新提示）', () => {
    expect(toReleaseErrorView(e(409, 4003, 'x', 'MSG-COM-033'))).toMatchObject({
      kind: 'conflict',
      reload: true,
    })
  })
  it('4002（422）→ business，后端 message，需重读', () => {
    expect(toReleaseErrorView(e(422, 4002, '状态不允许', 'MSG-COM-034'))).toEqual({
      kind: 'business',
      message: '[MSG-COM-034] 状态不允许',
      reload: true,
    })
  })
  it('4002 缺 msgId/message 时用 MSG-COM-034 默认', () => {
    expect(toReleaseErrorView(e(422, 4002, '')).message).toBe(
      '[MSG-COM-034] 该记录当前状态不允许此操作。',
    )
  })
  it('60020 → business，缺 msgId 时补 MSG-PRD-020，不重读', () => {
    expect(toReleaseErrorView(e(422, 60020, '无 BOM'))).toEqual({
      kind: 'business',
      message: '[MSG-PRD-020] 无 BOM',
      reload: false,
    })
  })
  it('60020 缺 message 时用中文默认文案', () => {
    expect(toReleaseErrorView(e(422, 60020, '')).message).toBe(
      '[MSG-PRD-020] 没有有效的 BOM，请先登记并审批 BOM。',
    )
  })
  it('5000 / 非 ApiError → generic', () => {
    expect(toReleaseErrorView(e(500, 5000, 'x')).kind).toBe('generic')
    expect(toReleaseErrorView(new Error('x')).kind).toBe('generic')
  })
})
