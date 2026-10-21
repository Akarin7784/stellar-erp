<template>
  <el-card shadow="never">
    <template #header>
      <div class="toolbar">
        <span>超产申请一览（SCR-PRD-034）</span>
        <el-button v-if="can.create" type="primary" data-test="create" @click="openCreate"
          >新建申请</el-button
        >
      </div>
    </template>

    <el-form inline class="filters" @submit.prevent="search">
      <el-form-item label="状态">
        <el-select
          v-model="query.approvalStatus"
          data-test="filter-status"
          clearable
          placeholder="全部"
          style="width: 120px"
        >
          <el-option
            v-for="(label, v) in OPA_STATUS_LABELS"
            :key="v"
            :label="label"
            :value="Number(v)"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="销售订单明细ID">
        <el-input v-model="query.salesOrderLineId" data-test="filter-line" clearable />
      </el-form-item>
      <el-form-item label="工单ID">
        <el-input v-model="query.workOrderId" data-test="filter-wo" clearable />
      </el-form-item>
      <el-form-item>
        <el-button native-type="submit" data-test="search">查询</el-button>
      </el-form-item>
    </el-form>

    <el-alert
      v-if="errorText"
      data-test="error"
      :title="errorText"
      :type="errorKind === 'conflict' ? 'warning' : 'error'"
      show-icon
      :closable="false"
      class="mb"
    />

    <el-table v-loading="loading" :data="rows" border data-test="table">
      <el-table-column label="申请号" min-width="140">
        <template #default="{ row }">
          <el-link type="primary" data-test="detail" @click="openDetail(asRow(row))">{{
            row.approvalNo
          }}</el-link>
        </template>
      </el-table-column>
      <el-table-column label="销售订单明细ID" prop="salesOrderLineId" min-width="110" />
      <el-table-column label="对象" min-width="120">
        <template #default="{ row }">{{
          row.workOrderId ? `工单 ${row.workOrderId}` : '销售订单行'
        }}</template>
      </el-table-column>
      <el-table-column label="申请超产数量" prop="requestQty" min-width="110" align="right" />
      <el-table-column label="申请时允许上限" min-width="120" align="right">
        <template #default="{ row }">{{ row.currentAllowedQty ?? '—' }}</template>
      </el-table-column>
      <el-table-column label="状态" min-width="90">
        <template #default="{ row }">{{
          OPA_STATUS_LABELS[row.approvalStatus] ?? row.approvalStatus
        }}</template>
      </el-table-column>
      <el-table-column label="申请时间" min-width="150">
        <template #default="{ row }">{{
          row.requestedAt ? formatDateTime(row.requestedAt) : ''
        }}</template>
      </el-table-column>
      <el-table-column label="操作" min-width="200" fixed="right">
        <template #default="{ row }">
          <el-button
            v-if="can.submit && row.approvalStatus === OPA_STATUS.DRAFT"
            link
            type="primary"
            data-test="submit"
            @click="onSubmit(asRow(row))"
            >提交</el-button
          >
          <el-button
            v-if="can.approve && row.approvalStatus === OPA_STATUS.SUBMITTED"
            link
            type="primary"
            data-test="approve"
            @click="openApprove(asRow(row))"
            >审批</el-button
          >
          <el-button
            v-if="
              can.cancel &&
              (row.approvalStatus === OPA_STATUS.DRAFT ||
                row.approvalStatus === OPA_STATUS.SUBMITTED)
            "
            link
            type="danger"
            data-test="cancel"
            @click="onCancel(asRow(row))"
            >取消</el-button
          >
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      layout="total, prev, pager, next"
      :total="total"
      :page-size="query.size"
      :current-page="query.page"
      @current-change="onPage"
    />

    <!-- 新建 -->
    <el-dialog v-model="createVisible" title="新建超产申请" width="480px" data-test="create-dialog">
      <el-alert
        v-if="createError"
        data-test="create-error"
        :title="createError"
        type="error"
        show-icon
        :closable="false"
        class="mb"
      />
      <el-form label-width="110px" @submit.prevent>
        <el-form-item label="销售订单明细ID" required>
          <el-input v-model="createForm.salesOrderLineId" data-test="c-line" />
        </el-form-item>
        <el-form-item label="工单ID">
          <el-input
            v-model="createForm.workOrderId"
            data-test="c-wo"
            placeholder="不填＝销售订单行级"
          />
        </el-form-item>
        <el-form-item label="申请超产数量" required>
          <el-input
            v-model="createForm.requestQty"
            data-test="c-qty"
            placeholder="超出部分（基本单位）"
          />
        </el-form-item>
        <el-form-item label="备注">
          <el-input
            v-model="createForm.remark"
            data-test="c-remark"
            type="textarea"
            maxlength="500"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" data-test="c-save" :loading="busy" @click="onCreate"
          >保存</el-button
        >
      </template>
    </el-dialog>

    <!-- 审批（批准 / 驳回） -->
    <el-dialog v-model="approveVisible" title="超产审批" width="480px" data-test="approve-dialog">
      <el-alert
        v-if="errorText"
        data-test="approve-error"
        :title="errorText"
        :type="errorKind === 'conflict' ? 'warning' : 'error'"
        show-icon
        :closable="false"
        class="mb"
      />
      <el-descriptions v-if="target" :column="1" border class="mb">
        <el-descriptions-item label="申请号">{{ target.approvalNo }}</el-descriptions-item>
        <el-descriptions-item label="申请超产数量">{{ target.requestQty }}</el-descriptions-item>
        <el-descriptions-item label="申请时允许上限">{{
          target.currentAllowedQty ?? '—'
        }}</el-descriptions-item>
      </el-descriptions>
      <el-form label-width="80px" @submit.prevent>
        <el-form-item
          label="驳回理由"
          required
          :error="rejectReasonError"
          data-test="reject-reason-item"
        >
          <el-input
            v-model="rejectReason"
            data-test="reject-reason"
            type="textarea"
            maxlength="500"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="approveVisible = false">关闭</el-button>
        <el-button type="danger" data-test="do-reject" :loading="busy" @click="onReject"
          >驳回</el-button
        >
        <el-button type="primary" data-test="do-approve" :loading="busy" @click="onApprove"
          >批准</el-button
        >
      </template>
    </el-dialog>

    <!-- 详细 -->
    <el-dialog v-model="detailVisible" title="超产申请详细" width="560px" data-test="detail-dialog">
      <el-descriptions v-if="detail" :column="2" border>
        <el-descriptions-item label="申请号">{{ detail.approvalNo }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{
          OPA_STATUS_LABELS[detail.approvalStatus]
        }}</el-descriptions-item>
        <el-descriptions-item label="销售订单明细ID">{{
          detail.salesOrderLineId
        }}</el-descriptions-item>
        <el-descriptions-item label="工单ID">{{
          detail.workOrderId ?? '销售订单行级'
        }}</el-descriptions-item>
        <el-descriptions-item label="申请超产数量">{{ detail.requestQty }}</el-descriptions-item>
        <el-descriptions-item label="申请时允许上限">{{
          detail.currentAllowedQty ?? '—'
        }}</el-descriptions-item>
        <el-descriptions-item label="批准后允许上限">{{
          detail.approvedAllowedQty ?? '—'
        }}</el-descriptions-item>
        <el-descriptions-item label="审批时间">{{
          detail.approvedAt ? formatDateTime(detail.approvedAt) : '—'
        }}</el-descriptions-item>
        <el-descriptions-item label="驳回理由" :span="2">{{
          detail.rejectReason ?? ''
        }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{
          detail.remark ?? ''
        }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

import {
  approveOverproductionApproval,
  cancelOverproductionApproval,
  createOverproductionApproval,
  getOverproductionApproval,
  listOverproductionApprovals,
  OPA_PERMISSIONS,
  OPA_STATUS,
  OPA_STATUS_LABELS,
  rejectOverproductionApproval,
  submitOverproductionApproval,
  toOpaErrorView,
  type OpaErrorView,
  type OverproductionApproval,
} from '@/api/production/overproduction'
import { useAuthStore } from '@/stores/auth'
import { formatDateTime } from '@/utils/format'
import { msgRequired, msgTooLong } from '@/views/system/loginRules'

/** el-table 插槽的 row 类型为 DefaultRow，转回 API 类型 */
const asRow = (r: unknown) => r as OverproductionApproval

const auth = useAuthStore()
const has = (code: string) => auth.me?.permissions.includes(code) ?? false
/** 按 /auth/me permissions 控制按钮（91 #39a〜39g） */
const can = computed(() => ({
  create: has(OPA_PERMISSIONS.create),
  submit: has(OPA_PERMISSIONS.submit),
  approve: has(OPA_PERMISSIONS.approve),
  cancel: has(OPA_PERMISSIONS.cancel),
}))

const query = reactive({
  approvalStatus: undefined as number | undefined,
  salesOrderLineId: '',
  workOrderId: '',
  page: 1,
  size: 20,
})
const rows = ref<OverproductionApproval[]>([])
const total = ref(0)
const loading = ref(false)
const busy = ref(false)
const errorText = ref('')
const errorKind = ref<OpaErrorView['kind'] | null>(null)

function showError(e: unknown): OpaErrorView {
  const v = toOpaErrorView(e)
  errorText.value = v.message
  errorKind.value = v.kind
  return v
}

async function load() {
  loading.value = true
  try {
    const r = await listOverproductionApprovals({
      approvalStatus: query.approvalStatus,
      salesOrderLineId: query.salesOrderLineId.trim(),
      workOrderId: query.workOrderId.trim(),
      page: query.page,
      size: query.size,
    })
    rows.value = r.list
    total.value = r.total
  } catch (e) {
    showError(e)
  } finally {
    loading.value = false
  }
}

function search() {
  errorText.value = ''
  query.page = 1
  void load()
}

function onPage(p: number) {
  query.page = p
  void load()
}

/** 执行状态操作：成功提示并重读；4003 刷新提示并重读；其他显示 [msgId] message。 */
async function run(action: () => Promise<unknown>, okText: string): Promise<boolean> {
  busy.value = true
  errorText.value = ''
  try {
    await action()
    ElMessage.success(okText)
    await load()
    return true
  } catch (e) {
    const v = showError(e)
    if (v.reload) {
      await load()
      showError(e)
    }
    return false
  } finally {
    busy.value = false
  }
}

// 新建
const createVisible = ref(false)
const createError = ref('')
const createForm = reactive({ salesOrderLineId: '', workOrderId: '', requestQty: '', remark: '' })
function openCreate() {
  Object.assign(createForm, { salesOrderLineId: '', workOrderId: '', requestQty: '', remark: '' })
  createError.value = ''
  createVisible.value = true
}
async function onCreate() {
  createError.value = ''
  if (!createForm.salesOrderLineId.trim()) {
    createError.value = '请输入必填项「销售订单明细ID」。'
    return
  }
  if (!createForm.requestQty.trim()) {
    createError.value = '请输入必填项「申请超产数量」。'
    return
  }
  busy.value = true
  try {
    const r = await createOverproductionApproval({ ...createForm })
    createVisible.value = false
    ElMessage.success(`已保存超产申请 ${r.approvalNo}`)
    await load()
  } catch (e) {
    createError.value = toOpaErrorView(e).message
  } finally {
    busy.value = false
  }
}

// 提交 / 取消
async function confirm(text: string): Promise<boolean> {
  try {
    await ElMessageBox.confirm(text, '确认', {
      type: 'warning',
      confirmButtonText: '确定',
      cancelButtonText: '取消',
    })
    return true
  } catch {
    return false
  }
}
async function onSubmit(row: OverproductionApproval) {
  if (!(await confirm(`确认提交超产申请 ${row.approvalNo}？`))) return
  await run(() => submitOverproductionApproval(row.id, row.version), '已提交')
}
async function onCancel(row: OverproductionApproval) {
  if (!(await confirm(`确认取消超产申请 ${row.approvalNo}？`))) return
  await run(() => cancelOverproductionApproval(row.id, row.version), '已取消')
}

// 审批
const approveVisible = ref(false)
const target = ref<OverproductionApproval | null>(null)
const rejectReason = ref('')
const rejectReasonError = ref('')
/** 驳回理由必填、≤500 字（BA 2026-10-21 决定；与后端 @Size(max=500) 一致）。文案同 MSG-COM-040 / 041 */
const REJECT_REASON_LABEL = '驳回理由'
const REJECT_REASON_MAX = 500
function validateRejectReason(): boolean {
  const v = rejectReason.value.trim()
  if (!v) rejectReasonError.value = msgRequired(REJECT_REASON_LABEL)
  else if (v.length > REJECT_REASON_MAX)
    rejectReasonError.value = msgTooLong(REJECT_REASON_LABEL, REJECT_REASON_MAX)
  else rejectReasonError.value = ''
  return !rejectReasonError.value
}
function openApprove(row: OverproductionApproval) {
  errorText.value = ''
  target.value = row
  rejectReason.value = ''
  rejectReasonError.value = ''
  approveVisible.value = true
}
/** 失败时保留对话框与驳回理由；若一览已重读，用最新行（version）更新对象 */
function afterDialogAction(ok: boolean) {
  if (ok) {
    approveVisible.value = false
    return
  }
  const latest = rows.value.find((r) => r.id === target.value?.id)
  if (latest) target.value = latest
}
async function onApprove() {
  const t = target.value
  if (!t) return
  afterDialogAction(await run(() => approveOverproductionApproval(t.id, t.version), '已批准'))
}
async function onReject() {
  const t = target.value
  if (!t || !validateRejectReason()) return
  afterDialogAction(
    await run(() => rejectOverproductionApproval(t.id, t.version, rejectReason.value), '已驳回'),
  )
}

// 详细
const detailVisible = ref(false)
const detail = ref<OverproductionApproval | null>(null)
async function openDetail(row: OverproductionApproval) {
  errorText.value = ''
  try {
    detail.value = await getOverproductionApproval(row.id)
    detailVisible.value = true
  } catch (e) {
    showError(e)
  }
}

onMounted(load)
</script>

<style scoped lang="scss">
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.mb {
  margin-bottom: 12px;
}
.pager {
  margin-top: 12px;
  justify-content: flex-end;
}
</style>
