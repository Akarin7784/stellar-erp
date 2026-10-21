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
          <el-form-item label="工厂" prop="factoryId">
            <el-select
              v-model="form.factoryId"
              data-test="factory"
              filterable
              placeholder="请选择工厂"
              @change="onFactoryChange"
            >
              <el-option
                v-for="f in factories"
                :key="String(f.id)"
                :label="`${f.factoryCode} ${f.factoryName}`"
                :value="String(f.id)"
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="品目" prop="materialId" :error="fieldError('materialId')">
            <el-select
              v-model="form.materialId"
              data-test="material"
              filterable
              remote
              :remote-method="onMaterialSearch"
              :loading="materialLoading"
              placeholder="输入编码/名称检索"
              @change="onMaterialChange"
            >
              <el-option
                v-for="m in materialOptions"
                :key="String(m.id)"
                :label="`${m.materialCode} ${m.materialName}`"
                :value="String(m.id)"
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="注文数量" prop="orderQty">
            <el-input v-model="form.orderQty" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="单位" prop="uomCode">
            <el-input v-model="form.uomCode" maxlength="16">
              <template v-if="selectedMaterial?.unitName" #append>{{
                selectedMaterial.unitName
              }}</template>
            </el-input>
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
          <el-form-item label="完工入库倉庫" prop="warehouseId">
            <el-select
              v-model="form.warehouseId"
              data-test="warehouse"
              filterable
              :disabled="!form.factoryId"
              placeholder="请先选择工厂"
            >
              <el-option
                v-for="w in warehouses"
                :key="String(w.id)"
                :label="`${w.warehouseCode} ${w.warehouseName}`"
                :value="String(w.id)"
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="部門" prop="departmentId">
            <el-select
              v-model="form.departmentId"
              data-test="department"
              filterable
              clearable
              placeholder="请选择部门"
            >
              <el-option
                v-for="d in departments"
                :key="d.id"
                :label="`${d.departmentCode} ${d.departmentName}`"
                :value="String(d.id)"
              />
            </el-select>
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
          <el-form-item label="有効 BOM">
            <span data-test="bom">{{ bomText }}</span>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="倒冲">
            <el-checkbox v-model="isBackflush" />
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
      <el-button
        type="primary"
        data-test="save"
        :loading="saving"
        :disabled="!canSubmit"
        @click="onSave"
        >保存</el-button
      >
      <el-button @click="onCancel">キャンセル</el-button>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
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
import { getEffectiveBom, type EffectiveBom } from '@/api/production/bom'
import {
  listFactories,
  listWarehouseOptions,
  searchMaterials,
  type FactoryOption,
  type MaterialOption,
  type WarehouseOption,
} from '@/api/mdm/lookup'
import { listDeptOptions, type DeptOption } from '@/api/system/dept'
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
  warehouseId: [{ ...required, trigger: 'change' }],
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

// isBackflush 类型含 null，el-checkbox 不接受 null
const isBackflush = computed({
  get: () => !!form.isBackflush,
  set: (v: boolean) => {
    form.isBackflush = v
  },
})

const factories = ref<FactoryOption[]>([])
const warehouses = ref<WarehouseOption[]>([])
const departments = ref<DeptOption[]>([])
const materials = ref<MaterialOption[]>([])
const materialLoading = ref(false)
/** 已选品目的快照：即使不在当前检索结果里也照样显示 code/name 和 unitName */
const pickedMaterial = ref<MaterialOption | null>(null)
const selectedMaterial = computed(() => {
  if (!form.materialId) return null
  const hit = materials.value.find((m) => String(m.id) === form.materialId)
  if (hit) return hit
  const p = pickedMaterial.value
  return p && String(p.id) === form.materialId ? p : null
})
const materialOptions = computed(() => {
  const p = selectedMaterial.value
  if (!p || materials.value.some((m) => String(m.id) === String(p.id))) return materials.value
  return [p, ...materials.value]
})

/** undefined=未查询，null=无有效 BOM（60020），'error'=查询失败 */
const bom = ref<EffectiveBom | null | undefined | 'error'>(undefined)
const bomText = computed(() => {
  if (bom.value === undefined) return '—'
  if (bom.value === null) return '[MSG-PRD-020] 无有效 BOM'
  if (bom.value === 'error') return 'BOM 查询失败'
  return `${bom.value.bomNo} v${bom.value.versionNo}`
})

const REQUIRED_FIELDS = [
  'factoryId',
  'materialId',
  'warehouseId',
  'orderQty',
  'uomCode',
  'plannedStartDate',
  'plannedEndDate',
] as const
const canSubmit = computed(
  () => !created.value && !saving.value && REQUIRED_FIELDS.every((k) => !!form[k]),
)

async function onFactoryChange(factoryId: string) {
  form.warehouseId = ''
  warehouses.value = []
  if (!factoryId) return
  try {
    warehouses.value = await listWarehouseOptions(factoryId)
  } catch {
    warehouses.value = []
  }
}

/** 递增序号：只采用最后一次检索的响应，丢弃过期（乱序到达）的响应 */
let materialSeq = 0
async function onMaterialSearch(keyword: string) {
  const seq = ++materialSeq
  materialLoading.value = true
  try {
    const list = (await searchMaterials(keyword)).list
    if (seq === materialSeq) materials.value = list
  } catch {
    if (seq === materialSeq) materials.value = []
  } finally {
    if (seq === materialSeq) materialLoading.value = false
  }
}

function onMaterialChange() {
  const m = selectedMaterial.value
  pickedMaterial.value = m
  if (m?.baseUomCode) form.uomCode = m.baseUomCode
}

let bomSeq = 0
async function refreshBom() {
  const { materialId, factoryId } = form
  const date = form.plannedStartDate || todayShanghai()
  if (!materialId || !factoryId) {
    bom.value = undefined
    return
  }
  const seq = ++bomSeq
  try {
    const r = await getEffectiveBom(materialId, factoryId, date)
    if (seq === bomSeq) bom.value = r
  } catch {
    if (seq === bomSeq) bom.value = 'error'
  }
}
watch(() => [form.materialId, form.factoryId, form.plannedStartDate], refreshBom)

function todayShanghai(): string {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Shanghai' }).format(new Date())
}

async function loadDepartments() {
  try {
    departments.value = await listDeptOptions()
  } catch {
    departments.value = []
  }
}

onMounted(async () => {
  try {
    factories.value = await listFactories()
  } catch {
    factories.value = []
  }
  void loadDepartments()
  void onMaterialSearch('')
})

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
    await router.push({
      name: 'production-work-order-detail',
      params: { id: String(created.value.id) },
      // warnings 只交给详情页显示一次，建单页不重复提示
      state: { warnings: JSON.parse(JSON.stringify(created.value.warnings ?? [])) },
    })
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
