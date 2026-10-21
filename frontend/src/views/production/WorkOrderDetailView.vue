<template>
  <el-card v-loading="loading" shadow="never">
    <template #header>
      <div class="toolbar">
        <span>生产订单詳細（SCR-PRD-010）</span>
        <el-tag v-if="detail">{{ statusLabel }}</el-tag>
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
    <el-alert v-if="errorText" :title="errorText" type="error" show-icon :closable="false" />
    <!-- 最小实现：仅基本信息。用料/工序/报工/入库等页签见后续 PR -->
    <el-descriptions v-if="detail" :column="3" border>
      <el-descriptions-item label="工单号">{{ detail.workOrderNo }}</el-descriptions-item>
      <el-descriptions-item label="品目"
        >{{ detail.materialCode }} {{ detail.materialName }}</el-descriptions-item
      >
      <el-descriptions-item label="注文数量"
        >{{ detail.orderQty }} {{ detail.uomCode }}</el-descriptions-item
      >
      <el-descriptions-item label="计划着手日">{{ detail.plannedStartDate }}</el-descriptions-item>
      <el-descriptions-item label="计划完成日">{{ detail.plannedEndDate }}</el-descriptions-item>
      <el-descriptions-item label="優先度">{{ detail.priorityNo }}</el-descriptions-item>
      <el-descriptions-item label="完工超収容差">{{
        formatRatePercent(detail.overReceiptRate)
      }}</el-descriptions-item>
      <el-descriptions-item label="許容完工上限">{{
        detail.allowedQty ?? '—'
      }}</el-descriptions-item>
      <el-descriptions-item label="受注">{{ detail.salesOrderNo ?? '—' }}</el-descriptions-item>
      <el-descriptions-item label="備考" :span="3">{{ detail.remark ?? '' }}</el-descriptions-item>
    </el-descriptions>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  formatRatePercent,
  getWorkOrder,
  ORDER_STATUS_LABELS,
  type WorkOrderDetail,
  type WorkOrderWarning,
} from '@/api/production/workOrder'

const props = defineProps<{ id: string }>()
const loading = ref(false)
const detail = ref<WorkOrderDetail | null>(null)
const errorText = ref('')
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

onMounted(async () => {
  loading.value = true
  try {
    detail.value = await getWorkOrder(props.id)
  } catch {
    errorText.value = '工单读取失败'
  } finally {
    loading.value = false
  }
})
</script>

<style scoped lang="scss">
.mb {
  margin-bottom: 12px;
}
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
