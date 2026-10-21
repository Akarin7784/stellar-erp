import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'
import { createPinia, setActivePinia } from 'pinia'

const listWorkOrders = vi.fn()
vi.mock('@/api/production/workOrder', async (orig) => ({
  ...(await orig<typeof import('@/api/production/workOrder')>()),
  listWorkOrders: (...a: unknown[]) => listWorkOrders(...a),
}))
const listFactories = vi.fn()
vi.mock('@/api/mdm/lookup', () => ({
  listFactories: (...a: unknown[]) => listFactories(...a),
}))
vi.mock('@/api/system/dept', () => ({ listDeptOptions: vi.fn().mockResolvedValue([]) }))
const push = vi.fn()
vi.mock('vue-router', async (orig) => ({
  ...(await orig<typeof import('vue-router')>()),
  useRouter: () => ({ push }),
}))

import { ApiError } from '@/api/http'
import { shanghaiDate } from '@/api/production/workOrder'
import { useAuthStore } from '@/stores/auth'
import WorkOrderListView from './WorkOrderListView.vue'

const VIEW = 'production:work-order:view'
const CREATE = 'production:work-order:create'

const row = (id: string, extra = {}) => ({
  id,
  workOrderNo: `WO-${id}`,
  workOrderType: 10,
  materialId: '5',
  materialCode: 'M001',
  materialName: '螺栓',
  materialSpec: null,
  uomCode: 'PCS',
  orderQty: '10',
  completedQty: '0',
  reportedGoodQty: '0',
  progressRate: '0',
  plannedStartDate: '2026-10-22',
  plannedEndDate: '2026-10-30',
  orderStatus: 20,
  priorityNo: 5,
  sourceType: 20,
  isHold: false,
  factoryId: '1',
  factoryCode: 'F1',
  factoryName: '一厂',
  departmentId: null,
  departmentName: null,
  salesOrderId: null,
  salesOrderNo: null,
  customerId: null,
  customerName: null,
  version: 1,
  ...extra,
})
const page = (list: unknown[]) => ({ list, total: list.length, pageNum: 1, pageSize: 20, pages: 1 })

async function mountView(perms = [VIEW, CREATE]) {
  setActivePinia(createPinia())
  useAuthStore().me = {
    userInfo: { id: '1', username: 'u', nickname: null },
    companyId: '1',
    roles: [],
    permissions: perms,
    menus: [],
  }
  const w = mount(WorkOrderListView, { global: { plugins: [ElementPlus] } })
  await flushPromises()
  return w
}

describe('WorkOrderListView（SCR-PRD-008）', () => {
  beforeEach(() => {
    listWorkOrders.mockReset()
    push.mockReset()
    listFactories.mockReset().mockResolvedValue([])
  })

  it('挂载时按默认条件查询：状态 10〜35、计划完成日 当天〜+90 天、第 1 页 20 条', async () => {
    listWorkOrders.mockResolvedValue(page([]))
    await mountView()
    expect(listWorkOrders).toHaveBeenCalledTimes(1)
    const q = listWorkOrders.mock.calls[0]![0]
    expect(q.status).toEqual([10, 20, 25, 30, 35])
    expect(q.plannedEndDateFrom).toBe(shanghaiDate(0))
    expect(q.plannedEndDateTo).toBe(shanghaiDate(90))
    expect(q.pageNum).toBe(1)
    expect(q.pageSize).toBe(20)
    expect(q.sort).toBeUndefined()
    expect(q.factoryId).toBeUndefined()
    expect(q).not.toHaveProperty('customerId')
    expect(listFactories).toHaveBeenCalledWith({ silent: true })
  })

  const F = (id: string) => ({
    id,
    factoryCode: `F${id}`,
    factoryName: `工厂${id}`,
    plantType: null,
  })

  it('工厂恰好 1 个：默认选中并带入初次查询与重置', async () => {
    listFactories.mockResolvedValue([F('3')])
    listWorkOrders.mockResolvedValue(page([]))
    const w = await mountView()
    expect(listWorkOrders.mock.calls[0]![0].factoryId).toBe('3')
    await w.find('[data-test="reset"]').trigger('click')
    await flushPromises()
    expect(listWorkOrders.mock.lastCall![0].factoryId).toBe('3')
  })

  it('工厂多个：不指定默认工厂', async () => {
    listFactories.mockResolvedValue([F('1'), F('2')])
    listWorkOrders.mockResolvedValue(page([]))
    await mountView()
    expect(listWorkOrders.mock.calls[0]![0].factoryId).toBeUndefined()
  })

  it('工厂加载失败：下拉旁显示警告，一览照常查询', async () => {
    listFactories.mockRejectedValue(new Error('x'))
    listWorkOrders.mockResolvedValue(page([row('1')]))
    const w = await mountView()
    expect(w.find('[data-test="factory-load-warning"]').text()).toContain('工厂列表加载失败')
    expect(listWorkOrders).toHaveBeenCalledTimes(1)
    expect(listWorkOrders.mock.calls[0]![0].factoryId).toBeUndefined()
    expect(w.find('[data-test="table"]').text()).toContain('WO-1')
  })

  it('状态名用前端字典显示；销售订单号为空显示 MTS', async () => {
    listWorkOrders.mockResolvedValue(
      page([row('1'), row('2', { orderStatus: 30, salesOrderNo: 'SO-9' })]),
    )
    const w = await mountView()
    const t = w.find('[data-test="table"]').text()
    expect(t).toContain('待审批')
    expect(t).toContain('已下达')
    expect(t).toContain('MTS（库存生产）')
    expect(t).toContain('SO-9')
  })

  it('有 create 权限才显示「新建」，点击跳转登记画面', async () => {
    listWorkOrders.mockResolvedValue(page([]))
    let w = await mountView([VIEW])
    expect(w.find('[data-test="create"]').exists()).toBe(false)
    w = await mountView()
    await w.find('[data-test="create"]').trigger('click')
    expect(push).toHaveBeenCalledWith({ name: 'production-work-order-create' })
  })

  it('点击工单号跳转详细', async () => {
    listWorkOrders.mockResolvedValue(page([row('7')]))
    const w = await mountView()
    await w.find('[data-test="row-link"]').trigger('click')
    expect(push).toHaveBeenCalledWith({
      name: 'production-work-order-detail',
      params: { id: '7' },
    })
  })

  it('查询条件传给 API，重置回默认', async () => {
    listWorkOrders.mockResolvedValue(page([]))
    const w = await mountView()
    const el = w.find('[data-test="f-no"]')
    await (el.element.matches('input') ? el : el.find('input')).setValue('WO-1')
    await w.find('form').trigger('submit')
    await flushPromises()
    expect(listWorkOrders.mock.lastCall![0].workOrderNo).toBe('WO-1')
    await w.find('[data-test="reset"]').trigger('click')
    await flushPromises()
    expect(listWorkOrders.mock.lastCall![0].workOrderNo).toBe('')
    expect(listWorkOrders.mock.lastCall![0].status).toEqual([10, 20, 25, 30, 35])
  })

  it('排序：只接受 6 个允许键', async () => {
    listWorkOrders.mockResolvedValue(page([]))
    const w = await mountView()
    const vm = w.vm as unknown as {
      onSort: (a: { prop: string | null; order: string | null }) => void
    }
    vm.onSort({ prop: 'plannedEndDate', order: 'descending' })
    await flushPromises()
    expect(listWorkOrders.mock.lastCall![0].sort).toEqual({ key: 'plannedEndDate', dir: 'desc' })
    vm.onSort({ prop: 'materialCode', order: 'ascending' })
    await flushPromises()
    expect(listWorkOrders.mock.lastCall![0].sort).toBeUndefined()
  })

  it('400/1001 参数错误显示 [msgId] message', async () => {
    listWorkOrders.mockRejectedValue(
      new ApiError('x', {
        status: 400,
        code: 1001,
        msgId: 'MSG-COM-046',
        data: { code: 1001, message: '开始日期不能晚于结束日期。', msgId: 'MSG-COM-046' },
      }),
    )
    const w = await mountView()
    expect(w.find('[data-test="error"]').text()).toContain(
      '[MSG-COM-046] 开始日期不能晚于结束日期。',
    )
  })

  it('403/3002 显示拦截器生成的无权限文案', async () => {
    listWorkOrders.mockRejectedValue(
      new ApiError('无权限访问（数据范围外）', { status: 403, code: 3002 }),
    )
    const w = await mountView()
    expect(w.find('[data-test="error"]').text()).toContain('无权限访问（数据范围外）')
  })
})
