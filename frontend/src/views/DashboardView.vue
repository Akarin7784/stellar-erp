<template>
  <div class="dashboard">
    <el-row :gutter="16">
      <el-col v-for="card in cards" :key="card.label" :span="6">
        <el-card shadow="hover">
          <div class="dashboard__label">{{ card.label }}</div>
          <div class="dashboard__value">{{ card.value }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card class="dashboard__api" shadow="never">
      <template #header>后端连通性</template>
      <el-button type="primary" :loading="loading" @click="checkBackend"
        >调用 /api/v1/system/ping</el-button
      >
      <pre v-if="pingResult" class="dashboard__result">{{ pingResult }}</pre>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

import http from '@/api/http'

const cards = [
  { label: '今日销售订单', value: '0' },
  { label: '待审核单据', value: '0' },
  { label: '库存预警', value: '0' },
  { label: '在途工单', value: '0' },
]

const loading = ref(false)
const pingResult = ref('')

async function checkBackend() {
  loading.value = true
  pingResult.value = ''
  try {
    const { data } = await http.get('/v1/system/ping')
    pingResult.value = JSON.stringify(data, null, 2)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped lang="scss">
.dashboard {
  &__label {
    color: #909399;
    font-size: 13px;
  }

  &__value {
    margin-top: 8px;
    font-size: 28px;
    font-weight: 600;
    color: #303133;
  }

  &__api {
    margin-top: 16px;
  }

  &__result {
    margin-top: 12px;
    padding: 12px;
    background: #f5f7fa;
    border-radius: 4px;
    font-size: 12px;
  }
}
</style>
