<template>
  <el-card v-loading="loading" shadow="never">
    <template #header>
      <div class="toolbar">
        <span>工单详细（SCR-PRD-010）</span>
        <span>
          <el-tag v-if="detail">{{ statusLabel }}</el-tag>
          <!-- 06/02 §4.7：order_status=25 时显示下达按钮 -->
          <el-button
            v-if="canRelease"
            type="primary"
            size="small"
            class="ml"
            data-test="release"
            :loading="releasing"
            @click="onRelease"
            >下达</el-button
          >
        </span>
      </div>
    </template>
    <el-alert
      v-for="w in warnings"
      :key="`${w.code}-${w.msgId}`"
      data-test="warning"
      :title="`[${w.msgId || w.code}] ${w.message}`"
      type="warning"
      show-icon
      :closable="false"
      class="mb"
    />
    <el-alert
      v-if="errorText"
      data-test="error"
      :title="errorText"
      :type="errorKind === 'conflict' ? 'warning' : 'error'"
      show-icon
      :closable="false"
      class="mb"
    />
    <!-- 最小实现：仅基本信息。用料/工序/报工/入库等页签见后续 PR -->
    <el-descriptions v-if="detail" :column="3" border>
      <el-descriptions-item label="工单号">{{ detail.workOrderNo }}</el-descriptions-item>
      <el-descriptions-item label="物料"
        >{{ detail.materialCode }} {{ detail.materialName }}</el-descriptions-item
      >
      <el-descriptions-item label="订单数量"
        >{{ detail.orderQty }} {{ detail.uomCode }}</el-descriptions-item
      >
      <el-descriptions-item label="计划开工日">{{ detail.plannedStartDate }}</el-descriptions-item>
      <el-descriptions-item label="计划完成日">{{ detail.plannedEndDate }}</el-descriptions-item>
      <el-descriptions-item label="优先级">{{ detail.priorityNo }}</el-descriptions-item>
      <el-descriptions-item label="完工超产容差">{{
        formatRatePercent(detail.overReceiptRate)
      }}</el-descriptions-item>
      <el-descriptions-item label="允许完工上限">{{
        detail.allowedQty ?? '—'
      }}</el-descriptions-item>
      <el-descriptions-item label="销售订单">{{ detail.salesOrderNo ?? '—' }}</el-descriptions-item>
      <el-descriptions-item label="备注" :span="3">{{ detail.remark ?? '' }}</el-descriptions-item>
    </el-descriptions>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  formatRatePercent,
  getWorkOrder,
  ORDER_STATUS_LABELS,
  releaseWorkOrder,
  toReleaseErrorView,
  type ReleaseErrorView,
  type WorkOrderDetail,
  type WorkOrderWarning,
} from '@/api/production/workOrder'

const props = defineProps<{ id: string }>()
const loading = ref(false)
const detail = ref<WorkOrderDetail | null>(null)
const errorText = ref('')
const errorKind = ref<ReleaseErrorView['kind'] | null>(null)
const releasing = ref(false)

/** 已承认（25）可下达 */
const STATUS_APPROVED = 25
const canRelease = computed(() => detail.value?.orderStatus === STATUS_APPROVED)
const warnings = ref<WorkOrderWarning[]>(takeWarnings())

/** 从 history.state 取建单时的 warnings，取完即清掉，刷新/返回不再显示 */
function takeWarnings(): WorkOrderWarning[] {
  const st = (window.history.state ?? {}) as { warnings?: unknown }
  const list = Array.isArray(st.warnings) ? (st.warnings as WorkOrderWarning[]) : []
  if (st.warnings !== undefined) {
    window.history.replaceState({ ...st, warnings: undefined }, '')
  }
  return list
}

const statusLabel = computed(() => {
  const s = detail.value?.orderStatus
  return s == null ? '' : `${s} ${detail.value?.statusName ?? ORDER_STATUS_LABELS[s] ?? ''}`
})

async function load() {
  loading.value = true
  try {
    detail.value = await getWorkOrder(props.id)
  } catch {
    errorText.value = '工单读取失败'
    errorKind.value = 'generic'
  } finally {
    loading.value = false
  }
}

/**
 * 下达（91 §3.2）：只传 version（releaseDate 省略＝上海当日；引当方式等属于 SCR-PRD-011 向导，后端未实装）。
 * 成功后显示 warnings（如 MSG-FIN-117）并重新读取；4003 提示刷新并重读；4002/60020 等 422 显示后端 message。
 */
async function onRelease() {
  const d = detail.value
  if (!d || releasing.value) return
  try {
    await ElMessageBox.confirm(`确认下达工单 ${d.workOrderNo}？`, '下达确认', {
      type: 'warning',
      confirmButtonText: '下达',
      cancelButtonText: '取消',
    })
  } catch {
    return
  }
  releasing.value = true
  errorText.value = ''
  errorKind.value = null
  try {
    const r = await releaseWorkOrder(props.id, { version: d.version })
    warnings.value = r.warnings ?? []
    ElMessage.success(`工单 ${r.workOrderNo} 已下达`)
    await load()
  } catch (e) {
    const v = toReleaseErrorView(e)
    errorText.value = v.message
    errorKind.value = v.kind
    if (v.reload) {
      const keep = errorText.value
      await load()
      errorText.value = keep
      errorKind.value = v.kind
    }
  } finally {
    releasing.value = false
  }
}

onMounted(load)
</script>

<style scoped lang="scss">
.mb {
  margin-bottom: 12px;
}
.ml {
  margin-left: 8px;
}
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
