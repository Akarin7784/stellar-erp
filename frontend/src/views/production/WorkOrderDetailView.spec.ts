import { afterEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'

const getWorkOrder = vi.fn()
vi.mock('@/api/production/workOrder', async (orig) => ({
  ...(await orig<typeof import('@/api/production/workOrder')>()),
  getWorkOrder: (...a: unknown[]) => getWorkOrder(...a),
}))

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

const mountView = async () => {
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
