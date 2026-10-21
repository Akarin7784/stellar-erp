import { afterEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'

const getWorkOrder = vi.fn()
const releaseWorkOrder = vi.fn()
vi.mock('@/api/production/workOrder', async (orig) => ({
  ...(await orig<typeof import('@/api/production/workOrder')>()),
  getWorkOrder: (...a: unknown[]) => getWorkOrder(...a),
  releaseWorkOrder: (...a: unknown[]) => releaseWorkOrder(...a),
}))

const confirm = vi.fn()
const success = vi.fn()
vi.mock('element-plus', async (orig) => {
  const m = await orig<typeof import('element-plus')>()
  return {
    ...m,
    ElMessageBox: { ...m.ElMessageBox, confirm: (...a: unknown[]) => confirm(...a) },
    ElMessage: Object.assign((...a: unknown[]) => m.ElMessage(...(a as [never])), m.ElMessage, {
      success: (...a: unknown[]) => success(...a),
    }),
  }
})

import { createPinia, setActivePinia } from 'pinia'

import { ApiError, MSG_CONFLICT } from '@/api/http'
import { useAuthStore } from '@/stores/auth'

import WorkOrderDetailView from './WorkOrderDetailView.vue'

const DETAIL = {
  id: '42',
  workOrderNo: 'WO-1',
  orderStatus: 10,
  statusName: null,
  materialCode: 'M-001',
  materialName: '轴',
  uomCode: 'PCE',
  orderQty: '10.0000',
}

const RELEASE = 'production:work-order:release'
const mountView = async (perms: string[] = ['production:work-order:view', RELEASE]) => {
  setActivePinia(createPinia())
  useAuthStore().me = {
    userInfo: { id: '1', username: 'u', nickname: null },
    companyId: '1',
    roles: [],
    permissions: perms,
    menus: [],
  }
  const w = mount(WorkOrderDetailView, {
    props: { id: '42' },
    global: { plugins: [ElementPlus] },
  })
  await flushPromises()
  return w
}

describe('WorkOrderDetailView warnings', () => {
  afterEach(() => window.history.replaceState(null, ''))

  it('建单 warnings 只显示一次（再次进入不重复）', async () => {
    getWorkOrder.mockResolvedValue(DETAIL)
    window.history.replaceState(
      { warnings: [{ code: 60020, msgId: 'MSG-PRD-020', message: '无有效 BOM' }] },
      '',
    )
    const w1 = await mountView()
    const alerts = w1.findAll('[data-test="warning"]')
    expect(alerts).toHaveLength(1)
    expect(alerts[0]!.text()).toContain('[MSG-PRD-020] 无有效 BOM')
    w1.unmount()

    const w2 = await mountView()
    expect(w2.findAll('[data-test="warning"]')).toHaveLength(0)
  })

  it('没有 warnings 时不显示', async () => {
    getWorkOrder.mockResolvedValue(DETAIL)
    const w = await mountView()
    expect(w.findAll('[data-test="warning"]')).toHaveLength(0)
  })
})

describe('WorkOrderDetailView 下达', () => {
  const APPROVED = { ...DETAIL, orderStatus: 25, version: 3 }
  const RELEASED = { ...DETAIL, orderStatus: 30, version: 4 }
  const bizErr = (status: number, code: number, message: string, msgId: string | null) =>
    new ApiError('x', {
      status,
      code,
      msgId: msgId ?? undefined,
      data: { code, message, data: null, msgId },
    })

  afterEach(() => {
    vi.clearAllMocks()
    window.history.replaceState(null, '')
  })

  it('状态 25 才显示下达按钮', async () => {
    getWorkOrder.mockResolvedValue(DETAIL)
    expect((await mountView()).find('[data-test="release"]').exists()).toBe(false)
    getWorkOrder.mockResolvedValue(APPROVED)
    expect((await mountView()).find('[data-test="release"]').exists()).toBe(true)
  })

  it('无 production:work-order:release 权限时不显示下达按钮', async () => {
    getWorkOrder.mockResolvedValue(APPROVED)
    const w = await mountView(['production:work-order:view'])
    expect(w.find('[data-test="release"]').exists()).toBe(false)
    const w2 = await mountView()
    expect(w2.find('[data-test="release"]').exists()).toBe(true)
  })

  it('取消确认时不调用 API', async () => {
    getWorkOrder.mockResolvedValue(APPROVED)
    confirm.mockRejectedValue('cancel')
    const w = await mountView()
    await w.find('[data-test="release"]').trigger('click')
    await flushPromises()
    expect(releaseWorkOrder).not.toHaveBeenCalled()
  })

  it('成功：传 version，显示 warnings 并重新读取', async () => {
    getWorkOrder.mockResolvedValueOnce(APPROVED).mockResolvedValueOnce(RELEASED)
    confirm.mockResolvedValue('confirm')
    releaseWorkOrder.mockResolvedValue({
      id: '42',
      workOrderNo: 'WO-1',
      orderStatus: 30,
      version: 4,
      warnings: [{ code: 70117, msgId: 'MSG-FIN-117', message: '未设定标准成本' }],
    })
    const w = await mountView()
    await w.find('[data-test="release"]').trigger('click')
    await flushPromises()
    expect(releaseWorkOrder).toHaveBeenCalledWith('42', { version: 3 })
    expect(success).toHaveBeenCalled()
    expect(getWorkOrder).toHaveBeenCalledTimes(2)
    expect(w.find('[data-test="warning"]').text()).toContain('[MSG-FIN-117] 未设定标准成本')
    expect(w.find('[data-test="release"]').exists()).toBe(false)
  })

  it('60020（422）：显示 [MSG-PRD-020] 后端 message，不重读', async () => {
    getWorkOrder.mockResolvedValue(APPROVED)
    confirm.mockResolvedValue('confirm')
    releaseWorkOrder.mockRejectedValue(bizErr(422, 60020, '没有有效 BOM', 'MSG-PRD-020'))
    const w = await mountView()
    await w.find('[data-test="release"]').trigger('click')
    await flushPromises()
    expect(w.find('[data-test="error"]').text()).toBe('[MSG-PRD-020] 没有有效 BOM')
    expect(w.find('[data-test="error"]').text()).not.toContain('刷新')
    expect(getWorkOrder).toHaveBeenCalledTimes(1)
  })

  it('重复下达 4002（422）：显示后端 message、无刷新提示，并重读最新状态', async () => {
    getWorkOrder.mockResolvedValueOnce(APPROVED).mockResolvedValueOnce(RELEASED)
    confirm.mockResolvedValue('confirm')
    releaseWorkOrder.mockRejectedValue(
      bizErr(422, 4002, '该记录当前状态不允许此操作。', 'MSG-COM-034'),
    )
    const w = await mountView()
    await w.find('[data-test="release"]').trigger('click')
    await flushPromises()
    const text = w.find('[data-test="error"]').text()
    expect(text).toBe('[MSG-COM-034] 该记录当前状态不允许此操作。')
    expect(text).not.toContain(MSG_CONFLICT)
    expect(getWorkOrder).toHaveBeenCalledTimes(2)
    expect(w.find('[data-test="release"]').exists()).toBe(false)
  })

  it('4003（409）：刷新提示并重读', async () => {
    getWorkOrder.mockResolvedValue(APPROVED)
    confirm.mockResolvedValue('confirm')
    releaseWorkOrder.mockRejectedValue(bizErr(409, 4003, '版本冲突', 'MSG-COM-033'))
    const w = await mountView()
    await w.find('[data-test="release"]').trigger('click')
    await flushPromises()
    expect(w.find('[data-test="error"]').text()).toBe(MSG_CONFLICT)
    expect(getWorkOrder).toHaveBeenCalledTimes(2)
  })
})
