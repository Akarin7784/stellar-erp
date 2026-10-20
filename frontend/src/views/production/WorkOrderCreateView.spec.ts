import { describe, expect, it, vi, beforeEach } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'

const push = vi.fn()
vi.mock('vue-router', () => ({ useRouter: () => ({ push, back: vi.fn() }) }))

vi.mock('@/api/mdm/lookup', () => ({
  listFactories: vi
    .fn()
    .mockResolvedValue([{ id: 1, factoryCode: 'F01', factoryName: '本社工场', plantType: null }]),
  listWarehouseOptions: vi
    .fn()
    .mockResolvedValue([
      { id: 3, warehouseCode: 'W01', warehouseName: '成品库', warehouseType: 1, factoryId: 1 },
    ]),
  searchMaterials: vi.fn().mockResolvedValue({
    list: [
      {
        id: 2,
        materialCode: 'M-001',
        materialName: '轴',
        spec: null,
        materialType: 1,
        baseUomCode: 'PCE',
        unitId: 7,
        unitName: '个',
        status: 1,
      },
    ],
    total: 1,
    pageNum: 1,
    pageSize: 20,
    pages: 1,
  }),
}))

const getEffectiveBom = vi.fn()
vi.mock('@/api/production/bom', () => ({
  getEffectiveBom: (...a: unknown[]) => getEffectiveBom(...a),
}))

const createWorkOrder = vi.fn()
vi.mock('@/api/production/workOrder', async (orig) => ({
  ...(await orig<typeof import('@/api/production/workOrder')>()),
  createWorkOrder: (...a: unknown[]) => createWorkOrder(...a),
}))

import { ApiError } from '@/api/http'
import WorkOrderCreateView from './WorkOrderCreateView.vue'

type VM = {
  form: Record<string, unknown>
  onFactoryChange: (id: string) => Promise<void>
  onMaterialChange: () => void
}

async function mountView() {
  const w = mount(WorkOrderCreateView, { global: { plugins: [ElementPlus] } })
  await flushPromises()
  return w
}

async function fillAll(w: Awaited<ReturnType<typeof mountView>>) {
  const vm = w.vm as unknown as VM
  vm.form.factoryId = '1'
  await vm.onFactoryChange('1')
  vm.form.materialId = '2'
  vm.onMaterialChange()
  vm.form.warehouseId = '3'
  vm.form.orderQty = '10'
  vm.form.plannedStartDate = '2026-11-12'
  vm.form.plannedEndDate = '2026-11-17'
  await flushPromises()
}

const saveBtn = (w: Awaited<ReturnType<typeof mountView>>) =>
  w.get('[data-test="save"]').element as HTMLButtonElement

describe('WorkOrderCreateView', () => {
  beforeEach(() => {
    push.mockReset()
    createWorkOrder.mockReset()
    getEffectiveBom.mockReset().mockResolvedValue({ bomNo: 'BOM-1', versionNo: 2 })
  })

  it('必填未齐时保存按钮 disabled；仓库为空也 disabled', async () => {
    const w = await mountView()
    expect(saveBtn(w).disabled).toBe(true)
    await fillAll(w)
    expect(saveBtn(w).disabled).toBe(false)
    ;(w.vm as unknown as VM).form.warehouseId = ''
    await flushPromises()
    expect(saveBtn(w).disabled).toBe(true)
  })

  it('选品目后带出 uomCode 并显示 unitName；BOM 按 materialId/factoryId/date 查询', async () => {
    const w = await mountView()
    await fillAll(w)
    expect((w.vm as unknown as VM).form.uomCode).toBe('PCE')
    expect(w.text()).toContain('个')
    expect(getEffectiveBom).toHaveBeenLastCalledWith('2', '1', '2026-11-12')
    expect(w.get('[data-test="bom"]').text()).toBe('BOM-1 v2')
  })

  it('60020 → 显示无有效 BOM', async () => {
    getEffectiveBom.mockResolvedValue(null)
    const w = await mountView()
    await fillAll(w)
    expect(w.get('[data-test="bom"]').text()).toContain('MSG-PRD-020')
  })

  it('60001 → 品目字段下方显示错误', async () => {
    createWorkOrder.mockRejectedValue(
      new ApiError('x', {
        status: 422,
        code: 60001,
        msgId: 'MSG-PRD-001',
        data: { code: 60001, message: '指定品目不是制造品', msgId: 'MSG-PRD-001' },
      }),
    )
    const w = await mountView()
    await fillAll(w)
    await w.get('[data-test="save"]').trigger('click')
    await flushPromises()
    // el-form-item 的错误显示有 debounce
    await new Promise((r) => setTimeout(r, 200))
    await flushPromises()
    const err = w.find('.el-form-item__error')
    expect(err.exists()).toBe(true)
    expect(err.text()).toBe('[MSG-PRD-001] 指定品目不是制造品')
    expect(push).not.toHaveBeenCalled()
  })

  it('创建成功后跳转到 SCR-PRD-010', async () => {
    createWorkOrder.mockResolvedValue({ id: 42, workOrderNo: 'WO-1', orderStatus: 10 })
    const w = await mountView()
    await fillAll(w)
    await w.get('[data-test="save"]').trigger('click')
    await flushPromises()
    expect(push).toHaveBeenCalledWith({
      name: 'production-work-order-detail',
      params: { id: '42' },
    })
  })
})
