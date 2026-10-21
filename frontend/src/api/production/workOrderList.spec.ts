import { afterEach, describe, expect, it, vi } from 'vitest'

vi.mock('element-plus', () => ({
  ElMessage: { error: vi.fn(), warning: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

import http, { ApiError } from '../http'
import {
  buildListParams,
  listWorkOrders,
  shanghaiDate,
  toListErrorText,
  MSG_GENERIC_ERROR,
} from './workOrder'

describe('工单一览 API（06/91 §3.15）', () => {
  afterEach(() => vi.restoreAllMocks())

  it('buildListParams：去空值、status 逗号分隔、sort=key,dir、pageSize ≤ 200', () => {
    expect(
      buildListParams({
        workOrderNo: ' WO1 ',
        material: '',
        status: [10, 20, 25],
        factoryId: undefined,
        isHold: false,
        priorityNo: 3,
        sort: { key: 'plannedEndDate', dir: 'desc' },
        pageNum: 2,
        pageSize: 500,
      }),
    ).toEqual({
      workOrderNo: 'WO1',
      status: '10,20,25',
      isHold: false,
      priorityNo: 3,
      sort: 'plannedEndDate,desc',
      pageNum: 2,
      pageSize: 200,
    })
  })

  it('buildListParams：默认 pageNum=1 / pageSize=20，空 status 不传', () => {
    expect(buildListParams({ status: [] })).toEqual({ pageNum: 1, pageSize: 20 })
  })

  it('listWorkOrders：GET /production/work-orders，silent', async () => {
    const page = { list: [], total: 0, pageNum: 1, pageSize: 20, pages: 0 }
    const get = vi
      .spyOn(http, 'get')
      .mockResolvedValue({ data: { code: 0, message: 'ok', data: page, msgId: null } })
    await expect(listWorkOrders({ salesOrderNo: 'SO' })).resolves.toEqual(page)
    expect(get).toHaveBeenCalledWith('/production/work-orders', {
      params: { salesOrderNo: 'SO', pageNum: 1, pageSize: 20 },
      silent: true,
    })
  })

  it('shanghaiDate：按上海时区取日期', () => {
    const now = new Date('2026-10-21T17:00:00Z') // 上海 10-22 01:00
    expect(shanghaiDate(0, now)).toBe('2026-10-22')
    expect(shanghaiDate(90, now)).toBe('2027-01-20')
  })

  it('toListErrorText：1001 显示 [msgId] message；403 用拦截器文案；其他通用', () => {
    for (const [msgId, message] of [
      ['MSG-COM-049', '所选数据不存在或已失效，请重新选择。'],
      ['MSG-COM-089', '「priorityNo」必须在 1 到 9 之间。'],
      ['MSG-COM-043', '「plannedEndDateFrom」的日期格式不正确。'],
      ['MSG-COM-088', '「isHold」的格式不正确。'],
      ['MSG-COM-046', '开始日期不能晚于结束日期。'],
    ]) {
      const e = new ApiError('x', {
        status: 400,
        code: 1001,
        msgId,
        data: { code: 1001, message, msgId, data: { fieldErrors: [] } },
      })
      expect(toListErrorText(e)).toBe(`[${msgId}] ${message}`)
    }
    const f = new ApiError('无权限访问（数据范围外）', { status: 403, code: 3002 })
    expect(toListErrorText(f)).toBe('无权限访问（数据范围外）')
    expect(toListErrorText(new Error('x'))).toBe(MSG_GENERIC_ERROR)
  })
})
