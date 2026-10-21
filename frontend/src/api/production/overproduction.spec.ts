import { afterEach, describe, expect, it, vi } from 'vitest'

import http, { ApiError, MSG_CONFLICT } from '../http'
import {
  approveOverproductionApproval,
  createOverproductionApproval,
  fieldErrorsOf,
  listOverproductionApprovals,
  searchSalesOrderLines,
  updateOverproductionApproval,
  rejectOverproductionApproval,
  toOpaErrorView,
} from './overproduction'

const ok = (data: unknown) => ({ data: { code: 0, message: 'ok', data, msgId: null } })

describe('overproduction API 请求', () => {
  afterEach(() => vi.restoreAllMocks())

  it('一览：去掉空条件，带 pageNum/pageSize，silent', async () => {
    const get = vi.spyOn(http, 'get').mockResolvedValue(ok({ list: [], total: 0 }))
    await listOverproductionApprovals({
      approvalStatus: 20,
      salesOrderLineId: '',
      pageNum: 2,
      pageSize: 20,
    })
    expect(get).toHaveBeenCalledWith('/production/overproduction-approvals', {
      params: { approvalStatus: 20, pageNum: 2, pageSize: 20 },
      silent: true,
    })
  })

  it('新建：requestQty 为增量，空 workOrderId/remark 不传', async () => {
    const post = vi.spyOn(http, 'post').mockResolvedValue(ok({ id: '1' }))
    await createOverproductionApproval({
      salesOrderLineId: ' 9 ',
      workOrderId: '',
      requestQty: '5.5',
      remark: '',
    })
    expect(post).toHaveBeenCalledWith(
      '/production/overproduction-approvals',
      { salesOrderLineId: '9', requestQty: '5.5' },
      { silent: true },
    )
  })

  it('草稿修正：PUT /{id}，带 version；空工单/备注传 null', async () => {
    const put = vi.spyOn(http, 'put').mockResolvedValue(ok({}))
    await updateOverproductionApproval('7', {
      version: 3,
      workOrderId: ' ',
      requestQty: ' 8 ',
      remark: '',
    })
    expect(put).toHaveBeenCalledWith(
      '/production/overproduction-approvals/7',
      { version: 3, workOrderId: null, requestQty: '8', remark: null },
      { silent: true },
    )
  })

  it('销售订单行选择器：条件 trim、pageSize 不超过 200', async () => {
    const get = vi.spyOn(http, 'get').mockResolvedValue(ok({ list: [], total: 0 }))
    await searchSalesOrderLines({ salesOrderNo: ' SO1 ', material: '', pageNum: 2, pageSize: 500 })
    expect(get).toHaveBeenCalledWith('/production/overproduction-approvals/sales-order-lines', {
      params: { salesOrderNo: 'SO1', pageNum: 2, pageSize: 200 },
      silent: true,
    })
  })

  it('fieldErrorsOf：仅 1001 取 data.fieldErrors', () => {
    const fe = [{ field: 'remark', message: 'm' }]
    expect(
      fieldErrorsOf(
        new ApiError('x', { status: 400, code: 1001, data: { data: { fieldErrors: fe } } }),
      ),
    ).toEqual(fe)
    expect(fieldErrorsOf(new ApiError('x', { status: 422, code: 60101 }))).toEqual([])
  })

  it('批准 / 驳回 body', async () => {
    const post = vi.spyOn(http, 'post').mockResolvedValue(ok({}))
    await approveOverproductionApproval('7', 3)
    expect(post).toHaveBeenLastCalledWith(
      '/production/overproduction-approvals/7/approve',
      { version: 3 },
      { silent: true },
    )
    await rejectOverproductionApproval('7', 3, ' 数量过多 ')
    expect(post).toHaveBeenLastCalledWith(
      '/production/overproduction-approvals/7/reject',
      { version: 3, rejectReason: '数量过多' },
      { silent: true },
    )
  })
})

describe('toOpaErrorView', () => {
  const e = (status: number, code: number, message: string, msgId?: string) =>
    new ApiError('fallback', {
      status,
      code,
      msgId,
      data: { code, message, data: null, msgId: msgId ?? null },
    })

  it('4003（409）→ 刷新提示并重读', () => {
    expect(toOpaErrorView(e(409, 4003, 'x'))).toEqual({
      kind: 'conflict',
      message: MSG_CONFLICT,
      reload: true,
    })
  })
  it.each([
    [60005, 'MSG-PRD-005'],
    [60056, 'MSG-PRD-056'],
    [60101, 'MSG-PRD-101'],
    [60103, 'MSG-PRD-103'],
  ])('%i（422）→ [msgId] 后端 message，缺 msgId 时补', (code, id) => {
    expect(toOpaErrorView(e(422, code, '后端文案'))).toEqual({
      kind: 'business',
      message: `[${id}] 后端文案`,
      reload: false,
    })
  })
  it('4002（422）→ business，需重读', () => {
    expect(toOpaErrorView(e(422, 4002, '状态不允许', 'MSG-COM-034'))).toEqual({
      kind: 'business',
      message: '[MSG-COM-034] 状态不允许',
      reload: true,
    })
    expect(toOpaErrorView(e(422, 4002, '状态不允许')).message).toBe('[MSG-COM-034] 状态不允许')
  })
  it('1001（HTTP 400）显示后端 msgId', () => {
    expect(toOpaErrorView(e(400, 1001, '受注行必须指定。', 'MSG-COM-040')).message).toBe(
      '[MSG-COM-040] 受注行必须指定。',
    )
  })
  it('5000 / 非 ApiError → generic', () => {
    expect(toOpaErrorView(e(500, 5000, 'x')).kind).toBe('generic')
    expect(toOpaErrorView(new Error('x')).kind).toBe('generic')
  })
})
