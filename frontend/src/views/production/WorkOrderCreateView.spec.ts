import { describe, expect, it, vi, beforeEach } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'

const push = vi.fn()
vi.mock('vue-router', () => ({ useRouter: () => ({ push, back: vi.fn() }) }))

const searchMaterials = vi.fn()
const listWarehouseOptions = vi.fn()
vi.mock('@/api/mdm/lookup', () => ({
  listFactories: vi
    .fn()
    .mockResolvedValue([{ id: '1', factoryCode: 'F01', factoryName: '本社工场', plantType: null }]),
  listWarehouseOptions: (...a: unknown[]) => listWarehouseOptions(...a),
  searchMaterials: (...a: unknown[]) => searchMaterials(...a),
}))

// 后端约定：ID 为字符串，分页 total/pages 为数字
const M1 = {
  id: '2',
  materialCode: 'M-001',
  materialName: '轴',
  spec: null,
  materialType: 1,
  baseUomCode: 'PCE',
  unitId: '7',
  unitName: '个',
  status: 1,
}
const M2 = { ...M1, id: '5', materialCode: 'M-005', materialName: '齿轮', unitName: '件' }
const page = (list: unknown[]) => ({ list, total: list.length, pageNum: 1, pageSize: 20, pages: 1 })

function deferred<T>() {
  let resolve!: (v: T) => void
  const promise = new Promise<T>((r) => (resolve = r))
  return { promise, resolve }
}

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
  onMaterialSearch: (k: string) => Promise<void>
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
    searchMaterials.mockReset().mockResolvedValue(page([M1]))
    listWarehouseOptions
      .mockReset()
      .mockResolvedValue([
        {
          id: '3',
          warehouseCode: 'W01',
          warehouseName: '成品库',
          warehouseType: 1,
          factoryId: '1',
        },
      ])
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
    createWorkOrder.mockResolvedValue({ id: '42', workOrderNo: 'WO-1', orderStatus: 10 })
    const w = await mountView()
    await fillAll(w)
    await w.get('[data-test="save"]').trigger('click')
    await flushPromises()
    expect(push).toHaveBeenCalledWith({
      name: 'production-work-order-detail',
      params: { id: '42' },
      state: { warnings: [] },
    })
  })

  it('201 warnings 只通过 router state 交给详情页，建单页不显示', async () => {
    const warnings = [{ code: 60020, msgId: 'MSG-PRD-020', message: '无有效 BOM' }]
    createWorkOrder.mockResolvedValue({ id: '42', workOrderNo: 'WO-1', orderStatus: 10, warnings })
    const w = await mountView()
    await fillAll(w)
    await w.get('[data-test="save"]').trigger('click')
    await flushPromises()
    expect(push.mock.calls[0]![0].state).toEqual({ warnings })
    expect(w.find('.el-alert').exists()).toBe(false)
  })

  it('BOM 竞态：先发后到的旧响应被丢弃', async () => {
    const w = await mountView()
    await fillAll(w)
    const vm = w.vm as unknown as VM
    const slow = deferred<unknown>()
    const fast = deferred<unknown>()
    getEffectiveBom.mockReturnValueOnce(slow.promise).mockReturnValueOnce(fast.promise)
    vm.form.plannedStartDate = '2026-11-13'
    await flushPromises()
    vm.form.plannedStartDate = '2026-11-14'
    await flushPromises()
    fast.resolve({ bomNo: 'BOM-NEW', versionNo: 3 })
    await flushPromises()
    slow.resolve({ bomNo: 'BOM-OLD', versionNo: 1 })
    await flushPromises()
    expect(w.get('[data-test="bom"]').text()).toBe('BOM-NEW v3')
  })

  it('切换工厂会清空仓库并重新取仓库选项', async () => {
    const w = await mountView()
    await fillAll(w)
    const vm = w.vm as unknown as VM
    expect(vm.form.warehouseId).toBe('3')
    vm.form.factoryId = '9'
    await vm.onFactoryChange('9')
    expect(vm.form.warehouseId).toBe('')
    expect(listWarehouseOptions).toHaveBeenLastCalledWith('9')
  })

  it('开始日期为空时 BOM 按上海当天查询', async () => {
    vi.useFakeTimers({ toFake: ['Date'] })
    // UTC 2026-10-21 17:00 = 上海 2026-10-22 01:00
    vi.setSystemTime(new Date('2026-10-21T17:00:00Z'))
    try {
      const w = await mountView()
      const vm = w.vm as unknown as VM
      vm.form.factoryId = '1'
      vm.form.materialId = '2'
      await flushPromises()
      expect(getEffectiveBom).toHaveBeenLastCalledWith('2', '1', '2026-10-22')
    } finally {
      vi.useRealTimers()
    }
  })

  it('物料检索乱序：只采用最后一次检索；已选物料不在结果里也照样显示', async () => {
    const w = await mountView()
    await fillAll(w)
    const vm = w.vm as unknown as VM
    const first = deferred<unknown>()
    const second = deferred<unknown>()
    searchMaterials.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise)
    const p1 = vm.onMaterialSearch('M')
    const p2 = vm.onMaterialSearch('齿')
    second.resolve(page([M2]))
    await p2
    first.resolve(page([M1]))
    await p1
    await flushPromises()
    const opts = (w.vm as unknown as { materialOptions: { id: string }[] }).materialOptions
    // 当前结果只有 M2，但已选 M1 仍保留在选项里
    expect(opts.map((m) => m.id)).toEqual(['2', '5'])
    expect(w.text()).toContain('个')
    expect(w.text()).toContain('M-001 轴')
  })

  it('部门：后端无部门选项接口，保留手填 ID', async () => {
    const w = await mountView()
    expect(w.find('[data-test="department"]').exists()).toBe(true)
  })
})
