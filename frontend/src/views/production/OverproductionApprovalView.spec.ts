import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'
import { createPinia, setActivePinia } from 'pinia'

const api = {
  list: vi.fn(),
  get: vi.fn(),
  create: vi.fn(),
  submit: vi.fn(),
  approve: vi.fn(),
  reject: vi.fn(),
  cancel: vi.fn(),
  update: vi.fn(),
  lines: vi.fn(),
}
vi.mock('@/api/production/overproduction', async (orig) => ({
  ...(await orig<typeof import('@/api/production/overproduction')>()),
  listOverproductionApprovals: (...a: unknown[]) => api.list(...a),
  getOverproductionApproval: (...a: unknown[]) => api.get(...a),
  createOverproductionApproval: (...a: unknown[]) => api.create(...a),
  submitOverproductionApproval: (...a: unknown[]) => api.submit(...a),
  approveOverproductionApproval: (...a: unknown[]) => api.approve(...a),
  rejectOverproductionApproval: (...a: unknown[]) => api.reject(...a),
  cancelOverproductionApproval: (...a: unknown[]) => api.cancel(...a),
  updateOverproductionApproval: (...a: unknown[]) => api.update(...a),
  searchSalesOrderLines: (...a: unknown[]) => api.lines(...a),
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

import { ApiError, MSG_CONFLICT } from '@/api/http'
import { useAuthStore } from '@/stores/auth'
import OverproductionApprovalView from './OverproductionApprovalView.vue'

const ALL = [
  'production:overproduction-approval:view',
  'production:overproduction-approval:create',
  'production:overproduction-approval:submit',
  'production:overproduction-approval:approve',
  'production:overproduction-approval:cancel',
]

const row = (id: string, approvalStatus: number, extra = {}) => ({
  id,
  approvalNo: `OPA-${id}`,
  salesOrderId: '1',
  salesOrderLineId: '11',
  workOrderId: null,
  materialId: '5',
  salesOrderNo: 'SO-001',
  workOrderNo: null,
  materialCode: 'M001',
  materialName: '螺栓',
  requestedByName: '张三',
  requestQty: '10.0000',
  currentAllowedQty: '100.0000',
  approvedAllowedQty: null,
  approvalStatus,
  requestedBy: '1',
  requestedAt: '2026-10-21T01:00:00Z',
  approvedBy: null,
  approvedAt: null,
  rejectReason: null,
  remark: null,
  version: 2,
  ...extra,
})
const page = (list: unknown[]) => ({ list, total: list.length, pageNum: 1, pageSize: 20, pages: 1 })
const bizErr = (status: number, code: number, message: string, msgId: string | null) =>
  new ApiError('x', {
    status,
    code,
    msgId: msgId ?? undefined,
    data: { code, message, data: null, msgId },
  })

async function mountView(perms = ALL) {
  setActivePinia(createPinia())
  useAuthStore().me = {
    userInfo: { id: '1', username: 'u', nickname: null },
    companyId: '1',
    roles: [],
    permissions: perms,
    menus: [],
  }
  const w = mount(OverproductionApprovalView, {
    global: { plugins: [ElementPlus] },
    attachTo: document.body,
  })
  await flushPromises()
  return w
}

const body = () => document.body
/** el-input 的 data-test 可能落在 input/textarea 本身或外层 */
function field(sel: string): HTMLInputElement {
  const el = body().querySelector(`[data-test="${sel}"]`) as HTMLElement
  return (
    el.matches('input,textarea') ? el : el.querySelector('input,textarea')
  ) as HTMLInputElement
}

describe('OverproductionApprovalView（SCR-PRD-034）', () => {
  beforeEach(() => {
    Object.values(api).forEach((f) => f.mockReset())
    confirm.mockReset().mockResolvedValue('confirm')
    success.mockReset()
    document.body.innerHTML = ''
  })

  it('挂载时查询第 1 页；按状态显示按钮', async () => {
    api.list.mockResolvedValue(page([row('1', 10), row('2', 20), row('3', 30)]))
    const w = await mountView()
    expect(api.list).toHaveBeenCalledWith({
      approvalStatus: undefined,
      salesOrderLineId: '',
      workOrderId: '',
      pageNum: 1,
      pageSize: 20,
    })
    const rows = w.findAll('.el-table__body-wrapper tr')
    expect(rows).toHaveLength(3)
    expect(rows[0]!.find('[data-test="submit"]').exists()).toBe(true)
    expect(rows[0]!.find('[data-test="cancel"]').exists()).toBe(true)
    expect(rows[0]!.find('[data-test="approve"]').exists()).toBe(false)
    expect(rows[1]!.find('[data-test="approve"]').exists()).toBe(true)
    expect(rows[1]!.find('[data-test="cancel"]').exists()).toBe(true)
    expect(rows[2]!.find('button').exists()).toBe(false)
    expect(rows[2]!.text()).toContain('已批准')
    expect(w.find('[data-test="create"]').exists()).toBe(true)
  })

  it('无权限时不显示新建 / 操作按钮', async () => {
    api.list.mockResolvedValue(page([row('1', 10), row('2', 20)]))
    const w = await mountView(['production:overproduction-approval:view'])
    expect(w.find('[data-test="create"]').exists()).toBe(false)
    expect(w.find('[data-test="submit"]').exists()).toBe(false)
    expect(w.find('[data-test="approve"]').exists()).toBe(false)
    expect(w.find('[data-test="cancel"]').exists()).toBe(false)
  })

  it('提交：传 id/version，成功后重读', async () => {
    api.list.mockResolvedValue(page([row('1', 10)]))
    api.submit.mockResolvedValue(row('1', 20))
    const w = await mountView()
    await w.find('[data-test="submit"]').trigger('click')
    await flushPromises()
    expect(api.submit).toHaveBeenCalledWith('1', 2)
    expect(success).toHaveBeenCalledWith('已提交')
    expect(api.list).toHaveBeenCalledTimes(2)
  })

  it('取消确认被拒绝时不调用 API', async () => {
    api.list.mockResolvedValue(page([row('1', 10)]))
    confirm.mockRejectedValue('cancel')
    const w = await mountView()
    await w.find('[data-test="cancel"]').trigger('click')
    await flushPromises()
    expect(api.cancel).not.toHaveBeenCalled()
  })

  it('审批对话框：批准', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    api.approve.mockResolvedValue({})
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    ;(body().querySelector('[data-test="do-approve"]') as HTMLElement).click()
    await flushPromises()
    expect(api.approve).toHaveBeenCalledWith('2', 2)
    expect(success).toHaveBeenCalledWith('已批准')
  })

  it('审批对话框：驳回带理由', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    api.reject.mockResolvedValue({})
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    const ta = field('reject-reason')
    ta.value = '超出过多'
    ta.dispatchEvent(new Event('input'))
    ;(body().querySelector('[data-test="do-reject"]') as HTMLElement).click()
    await flushPromises()
    expect(api.reject).toHaveBeenCalledWith('2', 2, '超出过多')
  })

  it('自批 60005（422）：显示 [MSG-PRD-005] message，无刷新提示', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    api.approve.mockRejectedValue(bizErr(422, 60005, '起案者与审批者相同', 'MSG-PRD-005'))
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    ;(body().querySelector('[data-test="do-approve"]') as HTMLElement).click()
    await flushPromises()
    const t = w.find('[data-test="error"]').text()
    expect(t).toBe('[MSG-PRD-005] 起案者与审批者相同')
    expect(t).not.toContain(MSG_CONFLICT)
  })

  it('驳回理由为空（含空白）时不调用 API，显示 MSG-COM-040 文案', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    const ta = field('reject-reason')
    ta.value = '   '
    ta.dispatchEvent(new Event('input'))
    ;(body().querySelector('[data-test="do-reject"]') as HTMLElement).click()
    await flushPromises()
    await new Promise((r) => setTimeout(r, 150)) // el-form-item 错误显示有 debounce
    await flushPromises()
    expect(api.reject).not.toHaveBeenCalled()
    expect(
      body().querySelector('[data-test="reject-reason-item"] .el-form-item__error')!.textContent,
    ).toBe('请输入必填项「驳回理由」。')
    expect((w.vm as unknown as { approveVisible: boolean }).approveVisible).toBe(true)
  })

  it('驳回理由超过 500 字时不调用 API（MSG-COM-041 文案）', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    ;(w.vm as unknown as { rejectReason: string }).rejectReason = 'a'.repeat(501)
    await flushPromises()
    ;(body().querySelector('[data-test="do-reject"]') as HTMLElement).click()
    await flushPromises()
    expect(api.reject).not.toHaveBeenCalled()
    expect((w.vm as unknown as { rejectReasonError: string }).rejectReasonError).toBe(
      '「驳回理由」不能超过 500 个字符。',
    )
  })

  it('后端返回 1001（HTTP 400）：对话框内显示 [msgId] message，保持打开', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    api.reject.mockRejectedValue(bizErr(400, 1001, '请输入必填项「驳回理由」。', 'MSG-COM-040'))
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    const ta = field('reject-reason')
    ta.value = '理由'
    ta.dispatchEvent(new Event('input'))
    ;(body().querySelector('[data-test="do-reject"]') as HTMLElement).click()
    await flushPromises()
    expect(api.reject).toHaveBeenCalledWith('2', 2, '理由')
    expect(body().querySelector('[data-test="approve-error"]')!.textContent).toContain(
      '[MSG-COM-040] 请输入必填项「驳回理由」。',
    )
    expect((w.vm as unknown as { approveVisible: boolean }).approveVisible).toBe(true)
  })

  it('审批成功后关闭对话框', async () => {
    api.list.mockResolvedValue(page([row('2', 20)]))
    api.approve.mockResolvedValue({})
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    ;(body().querySelector('[data-test="do-approve"]') as HTMLElement).click()
    await flushPromises()
    const vm = w.vm as unknown as { approveVisible: boolean }
    expect(vm.approveVisible).toBe(false)
  })

  it('驳回失败（4002）：对话框保持打开、理由保留、显示错误并重读', async () => {
    api.list
      .mockResolvedValueOnce(page([row('2', 20)]))
      .mockResolvedValueOnce(page([row('2', 30, { version: 3 })]))
    api.reject.mockRejectedValue(bizErr(422, 4002, '该记录当前状态不允许此操作。', 'MSG-COM-034'))
    const w = await mountView()
    await w.find('[data-test="approve"]').trigger('click')
    await flushPromises()
    const ta = field('reject-reason')
    ta.value = '超出过多'
    ta.dispatchEvent(new Event('input'))
    ;(body().querySelector('[data-test="do-reject"]') as HTMLElement).click()
    await flushPromises()
    const vm = w.vm as unknown as {
      approveVisible: boolean
      rejectReason: string
      target: { version: number }
    }
    expect(vm.approveVisible).toBe(true)
    expect(vm.rejectReason).toBe('超出过多')
    expect(field('reject-reason').value).toBe('超出过多')
    expect(api.list).toHaveBeenCalledTimes(2)
    expect(vm.target.version).toBe(3)
    expect(body().querySelector('[data-test="approve-error"]')!.textContent).toContain(
      '[MSG-COM-034] 该记录当前状态不允许此操作。',
    )
  })

  it('4003（409）：刷新提示并重读一览', async () => {
    api.list.mockResolvedValue(page([row('1', 10)]))
    api.submit.mockRejectedValue(bizErr(409, 4003, '版本冲突', 'MSG-COM-033'))
    const w = await mountView()
    await w.find('[data-test="submit"]').trigger('click')
    await flushPromises()
    expect(w.find('[data-test="error"]').text()).toBe(MSG_CONFLICT)
    expect(api.list).toHaveBeenCalledTimes(2)
  })

  const line = {
    salesOrderLineId: '11',
    salesOrderId: '1',
    salesOrderNo: 'SO-001',
    lineNo: 1,
    materialId: '5',
    materialCode: 'M001',
    materialName: '螺栓',
    baseUomCode: 'PCS',
    baseQty: '100',
    allowedQty: '100',
    completedQty: '0',
  }
  const click = (sel: string) =>
    (body().querySelector(`[data-test="${sel}"]`) as HTMLElement).click()
  const set = (sel: string, v: string) => {
    const i = field(sel)
    i.value = v
    i.dispatchEvent(new Event('input'))
  }
  async function pickFirstLine() {
    click('c-line-pick')
    await flushPromises()
    click('p-pick')
    await flushPromises()
  }

  it('一览・详细显示销售订单号、工单号、物料、申请人', async () => {
    const r = row('1', 10, { workOrderId: '8', workOrderNo: 'WO-008' })
    api.list.mockResolvedValue(page([r]))
    api.get.mockResolvedValue(r)
    const w = await mountView()
    const t = w.find('[data-test="table"]').text()
    for (const x of ['SO-001', '工单 WO-008', 'M001 螺栓', '张三']) expect(t).toContain(x)
    await w.find('[data-test="detail"]').trigger('click')
    await flushPromises()
    const d = body().querySelector('[data-test="detail-dialog"]')!.textContent!
    for (const x of ['SO-001', 'WO-008', 'M001 螺栓', '张三']) expect(d).toContain(x)
  })

  it('新建：未选销售订单行时不调用 API；60103 显示在对话框内', async () => {
    api.list.mockResolvedValue(page([]))
    api.lines.mockResolvedValue(page([line]))
    const w = await mountView()
    await w.find('[data-test="create"]').trigger('click')
    await flushPromises()
    click('c-save')
    await flushPromises()
    expect(api.create).not.toHaveBeenCalled()
    expect(body().querySelector('[data-test="create-error"]')!.textContent).toContain(
      '请输入必填项「销售订单行」。',
    )

    await pickFirstLine()
    expect(api.lines).toHaveBeenCalledWith({
      salesOrderNo: '',
      material: '',
      pageNum: 1,
      pageSize: 20,
    })
    expect(body().querySelector('[data-test="c-line-text"]')!.textContent).toContain(
      'SO-001 第1行 M001 螺栓',
    )
    set('c-qty', '999')
    api.create.mockRejectedValue(bizErr(422, 60103, '超产申请数量不正', 'MSG-PRD-103'))
    click('c-save')
    await flushPromises()
    expect(api.create).toHaveBeenCalledWith({
      salesOrderLineId: '11',
      workOrderId: '',
      requestQty: '999',
      remark: '',
    })
    expect(body().querySelector('[data-test="create-error"]')!.textContent).toContain(
      '[MSG-PRD-103] 超产申请数量不正',
    )
  })

  it('选择器：按条件查询', async () => {
    api.list.mockResolvedValue(page([]))
    api.lines.mockResolvedValue(page([line]))
    const w = await mountView()
    await w.find('[data-test="create"]').trigger('click')
    await flushPromises()
    click('c-line-pick')
    await flushPromises()
    set('p-so', 'SO-0')
    set('p-material', '螺栓')
    click('p-search')
    await flushPromises()
    expect(api.lines).toHaveBeenLastCalledWith({
      salesOrderNo: 'SO-0',
      material: '螺栓',
      pageNum: 1,
      pageSize: 20,
    })
  })

  it('新建成功：关闭并重读', async () => {
    api.list.mockResolvedValue(page([]))
    api.lines.mockResolvedValue(page([line]))
    api.create.mockResolvedValue({ id: '9', approvalNo: 'OPA-9', approvalStatus: 10 })
    const w = await mountView()
    await w.find('[data-test="create"]').trigger('click')
    await flushPromises()
    await pickFirstLine()
    set('c-qty', '5')
    click('c-save')
    await flushPromises()
    expect(success).toHaveBeenCalledWith('已保存超产申请 OPA-9')
    expect(api.list).toHaveBeenCalledTimes(2)
  })

  describe('草稿修正', () => {
    async function openEdit(r = row('1', 10, { remark: '旧' })) {
      api.list.mockResolvedValue(page([r]))
      const w = await mountView()
      await w.find('[data-test="edit"]').trigger('click')
      await flushPromises()
      return w
    }
    /** el-form-item 错误显示有 debounce */
    async function settleFormError() {
      await flushPromises()
      await new Promise((r) => setTimeout(r, 150))
      await flushPromises()
    }
    const editErr = () => body().querySelector('[data-test="edit-error"]')

    it('仅状态 10 且有 create 权限时显示「修改」', async () => {
      api.list.mockResolvedValue(page([row('1', 10), row('2', 20)]))
      let w = await mountView()
      expect(w.findAll('[data-test="edit"]')).toHaveLength(1)
      w.unmount()
      w = await mountView(ALL.filter((p) => !p.endsWith(':create')))
      expect(w.findAll('[data-test="edit"]')).toHaveLength(0)
    })

    it('成功：PUT 带 version，关闭并重读', async () => {
      const w = await openEdit()
      api.update.mockResolvedValue({})
      set('e-qty', '20')
      set('e-wo', '8')
      click('e-save')
      await flushPromises()
      expect(api.update).toHaveBeenCalledWith('1', {
        version: 2,
        workOrderId: '8',
        requestQty: '20',
        remark: '旧',
      })
      expect(success).toHaveBeenCalledWith('已修改超产申请 OPA-1')
      expect(api.list).toHaveBeenCalledTimes(2)
      expect((w.vm as unknown as { editVisible: boolean }).editVisible).toBe(false)
    })

    it('备注超过 500 字：不调用 API，显示 MSG-COM-041 文案', async () => {
      await openEdit()
      set('e-remark', 'x'.repeat(501))
      click('e-save')
      await settleFormError()
      expect(api.update).not.toHaveBeenCalled()
      expect(
        body().querySelector('[data-test="e-remark-item"] .el-form-item__error')!.textContent,
      ).toContain('「备注」不能超过 500 个字符。')
    })

    it('1001 fieldErrors：表单字段挂到字段上，保持打开', async () => {
      const w = await openEdit()
      api.update.mockRejectedValue(
        new ApiError('x', {
          status: 400,
          code: 1001,
          msgId: 'MSG-COM-041',
          data: {
            code: 1001,
            message: 'm',
            msgId: 'MSG-COM-041',
            data: { fieldErrors: [{ field: 'remark', message: '「备注」不能超过 500 个字符。' }] },
          },
        }),
      )
      click('e-save')
      await settleFormError()
      expect(
        body().querySelector('[data-test="e-remark-item"] .el-form-item__error')!.textContent,
      ).toContain('「备注」不能超过 500 个字符。')
      expect(editErr()).toBeNull()
      expect((w.vm as unknown as { editVisible: boolean }).editVisible).toBe(true)
    })

    it('1001 fieldErrors 为 version（表单外字段）：对话框顶部整体提示', async () => {
      await openEdit()
      api.update.mockRejectedValue(
        new ApiError('x', {
          status: 400,
          code: 1001,
          msgId: 'MSG-COM-040',
          data: {
            code: 1001,
            message: '请输入必填项「version」。',
            msgId: 'MSG-COM-040',
            data: { fieldErrors: [{ field: 'version', message: '请输入必填项「version」。' }] },
          },
        }),
      )
      click('e-save')
      await flushPromises()
      expect(editErr()!.textContent).toContain('请输入必填项「version」。')
      expect(
        body().querySelectorAll('[data-test="edit-dialog"] .el-form-item__error'),
      ).toHaveLength(0)
    })

    it('422 / 60101：顶部显示 [msgId] message，保持打开', async () => {
      await openEdit()
      api.update.mockRejectedValue(bizErr(422, 60101, '当前状态不允许修改。', 'MSG-PRD-101'))
      click('e-save')
      await flushPromises()
      expect(editErr()!.textContent).toContain('[MSG-PRD-101] 当前状态不允许修改。')
      expect(success).not.toHaveBeenCalled()
      expect(api.list).toHaveBeenCalledTimes(1)
    })

    it('409 / 4003：刷新提示并重读，保持打开', async () => {
      const w = await openEdit()
      api.update.mockRejectedValue(bizErr(409, 4003, '版本冲突', 'MSG-COM-033'))
      click('e-save')
      await flushPromises()
      expect(editErr()!.textContent).toContain(MSG_CONFLICT)
      expect(api.list).toHaveBeenCalledTimes(2)
      expect((w.vm as unknown as { editVisible: boolean }).editVisible).toBe(true)
    })
  })
})
