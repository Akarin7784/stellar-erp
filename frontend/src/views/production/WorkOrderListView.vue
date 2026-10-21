<template>
  <el-card shadow="never">
    <template #header>
      <div class="toolbar">
        <span>工单一览（SCR-PRD-008）</span>
        <el-button v-if="canCreate" type="primary" data-test="create" @click="goCreate"
          >新建</el-button
        >
      </div>
    </template>

    <el-form inline class="filters" @submit.prevent="search">
      <el-form-item label="工单号">
        <el-input
          v-model="form.workOrderNo"
          data-test="f-no"
          clearable
          placeholder="前方一致"
          style="width: 150px"
        />
      </el-form-item>
      <el-form-item label="物料">
        <el-input
          v-model="form.material"
          data-test="f-material"
          clearable
          placeholder="编码或名称"
          style="width: 150px"
        />
      </el-form-item>
      <el-form-item label="状态">
        <el-select
          v-model="form.status"
          data-test="f-status"
          multiple
          collapse-tags
          clearable
          placeholder="全部"
          style="width: 200px"
        >
          <el-option v-for="s in STATUS_OPTIONS" :key="s.value" :label="s.label" :value="s.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="工单类型">
        <el-select v-model="form.workOrderType" clearable placeholder="全部" style="width: 130px">
          <el-option
            v-for="t in WORK_ORDER_TYPES"
            :key="t.value"
            :label="t.label"
            :value="t.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="计划完成日">
        <el-date-picker
          v-model="form.plannedEnd"
          data-test="f-end"
          type="daterange"
          value-format="YYYY-MM-DD"
          start-placeholder="开始"
          end-placeholder="结束"
          style="width: 240px"
        />
      </el-form-item>
      <el-form-item label="计划开工日">
        <el-date-picker
          v-model="form.plannedStart"
          type="daterange"
          value-format="YYYY-MM-DD"
          start-placeholder="开始"
          end-placeholder="结束"
          style="width: 240px"
        />
      </el-form-item>
      <el-form-item label="工厂">
        <el-select
          v-model="form.factoryId"
          data-test="f-factory"
          clearable
          placeholder="全部"
          style="width: 160px"
        >
          <el-option
            v-for="f in factories"
            :key="f.id"
            :label="`${f.factoryCode} ${f.factoryName}`"
            :value="String(f.id)"
          />
        </el-select>
        <el-alert
          v-if="factoryLoadFailed"
          data-test="factory-load-warning"
          :title="MSG_FACTORY_LOAD_FAILED"
          type="warning"
          show-icon
          :closable="false"
          class="inline-warning"
        />
      </el-form-item>
      <el-form-item label="部门">
        <el-select v-model="form.departmentId" clearable placeholder="全部" style="width: 160px">
          <el-option
            v-for="d in departments"
            :key="d.id"
            :label="`${d.departmentCode} ${d.departmentName}`"
            :value="d.id"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="销售订单号">
        <el-input
          v-model="form.salesOrderNo"
          data-test="f-so"
          clearable
          placeholder="部分一致"
          style="width: 150px"
        />
      </el-form-item>
      <el-form-item label="优先级">
        <el-select v-model="form.priorityNo" clearable placeholder="全部" style="width: 90px">
          <el-option v-for="n in 9" :key="n" :label="String(n)" :value="n" />
        </el-select>
      </el-form-item>
      <el-form-item label="来源">
        <el-select v-model="form.sourceType" clearable placeholder="全部" style="width: 130px">
          <el-option
            v-for="(label, v) in SOURCE_TYPE_LABELS"
            :key="v"
            :label="label"
            :value="Number(v)"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="冻结">
        <el-select v-model="form.isHold" clearable placeholder="全部" style="width: 90px">
          <el-option label="是" :value="true" />
          <el-option label="否" :value="false" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" native-type="submit" data-test="search">查询</el-button>
        <el-button data-test="reset" @click="reset">重置</el-button>
      </el-form-item>
    </el-form>

    <el-alert
      v-if="errorText"
      data-test="error"
      :title="errorText"
      type="error"
      show-icon
      :closable="false"
      class="mb"
    />

    <el-table v-loading="loading" :data="rows" border data-test="table" @sort-change="onSort">
      <el-table-column label="工单号" prop="workOrderNo" min-width="140" sortable="custom">
        <template #default="{ row }">
          <el-link type="primary" data-test="row-link" @click="goDetail(asRow(row))">{{
            row.workOrderNo
          }}</el-link>
        </template>
      </el-table-column>
      <el-table-column label="状态" prop="orderStatus" min-width="90" sortable="custom">
        <template #default="{ row }">{{
          ORDER_STATUS_LABELS[row.orderStatus] ?? row.orderStatus
        }}</template>
      </el-table-column>
      <el-table-column label="工单类型" min-width="90">
        <template #default="{ row }">{{ typeLabel(row.workOrderType) }}</template>
      </el-table-column>
      <el-table-column label="物料" min-width="180">
        <template #default="{ row }"
          >{{ row.materialCode }} {{ row.materialName
          }}{{ row.materialSpec ? `（${row.materialSpec}）` : '' }}</template
        >
      </el-table-column>
      <el-table-column label="订单数量" min-width="100" align="right">
        <template #default="{ row }">{{ row.orderQty }} {{ row.uomCode }}</template>
      </el-table-column>
      <el-table-column label="完工数量" prop="completedQty" min-width="100" align="right" />
      <el-table-column label="进度" min-width="80" align="right">
        <template #default="{ row }">{{ formatRatePercent(row.progressRate) }}</template>
      </el-table-column>
      <el-table-column
        label="计划开工日"
        prop="plannedStartDate"
        min-width="120"
        sortable="custom"
      />
      <el-table-column label="计划完成日" prop="plannedEndDate" min-width="120" sortable="custom" />
      <el-table-column label="优先级" prop="priorityNo" min-width="90" sortable="custom" />
      <el-table-column label="工厂" min-width="120">
        <template #default="{ row }">{{ row.factoryName ?? row.factoryId }}</template>
      </el-table-column>
      <el-table-column label="部门" min-width="110">
        <template #default="{ row }">{{ row.departmentName ?? '' }}</template>
      </el-table-column>
      <el-table-column label="销售订单号" min-width="130">
        <template #default="{ row }">{{ row.salesOrderNo || 'MTS（库存生产）' }}</template>
      </el-table-column>
      <el-table-column label="客户" min-width="120">
        <template #default="{ row }">{{ row.customerName ?? '' }}</template>
      </el-table-column>
      <el-table-column label="来源" min-width="100">
        <template #default="{ row }">{{
          SOURCE_TYPE_LABELS[row.sourceType] ?? row.sourceType
        }}</template>
      </el-table-column>
      <el-table-column label="冻结" min-width="70">
        <template #default="{ row }">{{ row.isHold ? '是' : '否' }}</template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pager"
      layout="total, sizes, prev, pager, next"
      :total="total"
      :page-sizes="[20, 50, 100, 200]"
      :page-size="pageSize"
      :current-page="pageNum"
      @current-change="onPage"
      @size-change="onSize"
    />
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'

import { listFactories, type FactoryOption } from '@/api/mdm/lookup'
import {
  formatRatePercent,
  LIST_DEFAULT_END_DAYS,
  LIST_DEFAULT_STATUSES,
  LIST_SORT_KEYS,
  listWorkOrders,
  ORDER_STATUS_LABELS,
  shanghaiDate,
  SOURCE_TYPE_LABELS,
  toListErrorText,
  WO_PERMISSIONS,
  WORK_ORDER_TYPES,
  type ListSortKey,
  type WorkOrderListQuery,
  type WorkOrderListRow,
} from '@/api/production/workOrder'
import { listDeptOptions, type DeptOption } from '@/api/system/dept'
import { useAuthStore } from '@/stores/auth'

const asRow = (r: unknown) => r as WorkOrderListRow

const router = useRouter()
const auth = useAuthStore()
/** 按 /auth/me permissions 控制按钮（同 WorkOrderDetailView） */
const has = (code: string) => auth.me?.permissions.includes(code) ?? false
const canCreate = computed(() => has(WO_PERMISSIONS.create))

const STATUS_OPTIONS = Object.entries(ORDER_STATUS_LABELS).map(([v, label]) => ({
  value: Number(v),
  label,
}))
const typeLabel = (v: number) => WORK_ORDER_TYPES.find((t) => t.value === v)?.label ?? String(v)

interface FilterForm {
  workOrderNo: string
  material: string
  status: number[]
  workOrderType: number | undefined
  plannedEnd: [string, string] | null
  plannedStart: [string, string] | null
  factoryId: string | undefined
  departmentId: string | undefined
  salesOrderNo: string
  priorityNo: number | undefined
  sourceType: number | undefined
  isHold: boolean | undefined
}

/**
 * 默认条件：状态 10〜35、计划完成日 当天〜+90 天（上海时区）；
 * 工厂：可选工厂恰好 1 个时默认选中，0 个或多个时不指定（蓝色大肥鱼 2026-10-21 决定）。
 */
function defaults(): FilterForm {
  return {
    workOrderNo: '',
    material: '',
    status: [...LIST_DEFAULT_STATUSES],
    workOrderType: undefined,
    plannedEnd: [shanghaiDate(0), shanghaiDate(LIST_DEFAULT_END_DAYS)],
    plannedStart: null,
    factoryId: defaultFactoryId.value,
    departmentId: undefined,
    salesOrderNo: '',
    priorityNo: undefined,
    sourceType: undefined,
    isHold: undefined,
  }
}

const factories = ref<FactoryOption[]>([])
const defaultFactoryId = computed(() =>
  factories.value.length === 1 ? String(factories.value[0]!.id) : undefined,
)
/** 工厂下拉加载失败：下拉旁警告，不弹全局提示，一览仍可查询（同工单登记的部门下拉） */
const factoryLoadFailed = ref(false)
/** MSG-PRD-107（W，仅前端；06/93） */
const MSG_FACTORY_LOAD_FAILED = '工厂列表加载失败，可不选工厂继续查询。'
const form = reactive<FilterForm>(defaults())
const sort = ref<WorkOrderListQuery['sort']>()
const pageNum = ref(1)
const pageSize = ref(20)
const rows = ref<WorkOrderListRow[]>([])
const total = ref(0)
const loading = ref(false)
const errorText = ref('')
const departments = ref<DeptOption[]>([])

function toQuery(): WorkOrderListQuery {
  return {
    workOrderNo: form.workOrderNo,
    material: form.material,
    status: form.status,
    workOrderType: form.workOrderType,
    plannedEndDateFrom: form.plannedEnd?.[0],
    plannedEndDateTo: form.plannedEnd?.[1],
    plannedStartDateFrom: form.plannedStart?.[0],
    plannedStartDateTo: form.plannedStart?.[1],
    factoryId: form.factoryId,
    departmentId: form.departmentId,
    salesOrderNo: form.salesOrderNo,
    priorityNo: form.priorityNo,
    sourceType: form.sourceType,
    isHold: form.isHold,
    sort: sort.value,
    pageNum: pageNum.value,
    pageSize: pageSize.value,
  }
}

async function load() {
  loading.value = true
  errorText.value = ''
  try {
    const r = await listWorkOrders(toQuery())
    rows.value = r.list
    total.value = r.total
  } catch (e) {
    rows.value = []
    total.value = 0
    errorText.value = toListErrorText(e)
  } finally {
    loading.value = false
  }
}

function search() {
  pageNum.value = 1
  void load()
}
function reset() {
  Object.assign(form, defaults())
  sort.value = undefined
  search()
}
function onPage(p: number) {
  pageNum.value = p
  void load()
}
function onSize(s: number) {
  pageSize.value = s
  pageNum.value = 1
  void load()
}
/** 只允许 §3.15 的 6 个排序键 */
function onSort({ prop, order }: { prop: string | null; order: string | null }) {
  sort.value =
    prop && order && (LIST_SORT_KEYS as readonly string[]).includes(prop)
      ? { key: prop as ListSortKey, dir: order === 'descending' ? 'desc' : 'asc' }
      : undefined
  search()
}

function goCreate() {
  void router.push({ name: 'production-work-order-create' })
}
function goDetail(r: WorkOrderListRow) {
  void router.push({ name: 'production-work-order-detail', params: { id: r.id } })
}

async function loadFactories() {
  try {
    factories.value = await listFactories({ silent: true, resource: 'work-order' })
    factoryLoadFailed.value = false
  } catch {
    factories.value = []
    factoryLoadFailed.value = true
  }
}

onMounted(async () => {
  // 先取工厂（唯一时作为默认条件），再做初次查询；失败也照常查询
  await loadFactories()
  form.factoryId = defaultFactoryId.value
  void load()
  listDeptOptions({ silent: true })
    .then((d) => (departments.value = d))
    .catch(() => undefined)
})
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
.inline-warning {
  margin-left: 8px;
  width: auto;
}
.pager {
  margin-top: 12px;
  justify-content: flex-end;
}
</style>
