<template>
  <el-card shadow="never">
    <template #header>
      <div class="toolbar">
        <span>生产订单登録（SCR-PRD-009）</span>
        <el-tag>{{ statusLabel }}</el-tag>
      </div>
    </template>

    <el-alert
      v-if="error"
      :title="error.message"
      :type="error.kind === 'generic' ? 'error' : 'warning'"
      show-icon
      :closable="false"
      class="mb"
    />

    <el-form ref="formRef" :model="form" :rules="rules" label-width="120px" :disabled="!!created">
      <el-row :gutter="16">
        <el-col :span="8">
          <el-form-item label="工单号">
            <el-input
              :model-value="created?.workOrderNo ?? ''"
              placeholder="保存時自動採番"
              disabled
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="工单类型" prop="workOrderType">
            <el-select v-model="form.workOrderType">
              <el-option
                v-for="t in WORK_ORDER_TYPES"
                :key="t.value"
                :label="`${t.value} ${t.label}`"
                :value="t.value"
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="工厂ID" prop="factoryId">
            <el-input v-model="form.factoryId" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="品目ID" prop="materialId" :error="fieldError('materialId')">
            <el-input v-model="form.materialId" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="注文数量" prop="orderQty">
            <el-input v-model="form.orderQty" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="单位" prop="uomCode">
            <el-input v-model="form.uomCode" maxlength="16" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="计划着手日" prop="plannedStartDate">
            <el-date-picker v-model="form.plannedStartDate" type="date" value-format="YYYY-MM-DD" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="计划完成日" prop="plannedEndDate">
            <el-date-picker v-model="form.plannedEndDate" type="date" value-format="YYYY-MM-DD" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="優先度" prop="priorityNo">
            <el-select v-model="form.priorityNo">
              <el-option v-for="p in 9" :key="p" :label="p" :value="p" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="完工入库倉庫ID" prop="warehouseId">
            <el-input v-model="form.warehouseId" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="部門ID" prop="departmentId">
            <el-input v-model="form.departmentId" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item
            label="受注明細ID"
            prop="salesOrderLineId"
            :error="fieldError('salesOrderLineId')"
          >
            <el-input v-model="form.salesOrderLineId" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="完工超収容差">
            <el-input :model-value="overReceiptRateText" disabled />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="許容完工上限">
            <el-input
              :model-value="created?.allowedQty == null ? '—' : String(created.allowedQty)"
              disabled
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="倒冲">
            <el-checkbox v-model="form.isBackflush" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="備考" prop="remark">
            <el-input v-model="form.remark" type="textarea" maxlength="500" show-word-limit />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>

    <div class="actions">
      <el-button type="primary" :loading="saving" :disabled="!!created" @click="onSave"
        >保存</el-button
      >
      <el-button @click="onCancel">キャンセル</el-button>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import {
  createWorkOrder,
  DEFAULT_ORDER_STATUS,
  DEFAULT_PRIORITY_NO,
  DEFAULT_WORK_ORDER_TYPE,
  formatRatePercent,
  ORDER_STATUS_LABELS,
  toCreateErrorView,
  WORK_ORDER_TYPES,
  type CreateErrorView,
  type WorkOrderCreated,
  type WorkOrderCreateRequest,
} from '@/api/production/workOrder'
import { validateDateRange, validateOrderQty } from './workOrderRules'

const router = useRouter()
const formRef = ref<FormInstance>()
const saving = ref(false)
const created = ref<WorkOrderCreated | null>(null)
const error = ref<CreateErrorView | null>(null)

const form = reactive<WorkOrderCreateRequest>({
  workOrderType: DEFAULT_WORK_ORDER_TYPE,
  factoryId: '',
  materialId: '',
  orderQty: '',
  uomCode: '',
  plannedStartDate: '',
  plannedEndDate: '',
  priorityNo: DEFAULT_PRIORITY_NO,
  departmentId: '',
  warehouseId: '',
  salesOrderLineId: '',
  isBackflush: false,
  remark: '',
})

const required = { required: true, message: '必須項目です', trigger: 'blur' }
const rules: FormRules = {
  factoryId: [required],
  materialId: [required],
  orderQty: [required, { validator: (_r, v, cb) => cb(validateOrderQty(v)), trigger: 'blur' }],
  uomCode: [required],
  plannedStartDate: [required],
  plannedEndDate: [
    required,
    {
      validator: (_r, v, cb) => cb(validateDateRange(form.plannedStartDate, v)),
      trigger: 'change',
    },
  ],
}

const statusLabel = computed(() => {
  const s = created.value?.orderStatus ?? DEFAULT_ORDER_STATUS
  return `${s} ${ORDER_STATUS_LABELS[s] ?? ''}`
})
// 只读：创建时由后端快照，画面不可编辑
const overReceiptRateText = computed(() => formatRatePercent(created.value?.overReceiptRate))

function fieldError(field: keyof WorkOrderCreateRequest): string {
  return error.value?.field === field ? error.value.message : ''
}

async function onSave() {
  if (saving.value) return
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  error.value = null
  try {
    created.value = await createWorkOrder(form)
    ElMessage.success(`工单 ${created.value.workOrderNo} を登録しました`)
  } catch (e) {
    error.value = toCreateErrorView(e)
  } finally {
    saving.value = false
  }
}

function onCancel() {
  router.back()
}
</script>

<style scoped lang="scss">
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.mb {
  margin-bottom: 16px;
}
.actions {
  display: flex;
  justify-content: flex-end;
}
</style>
