<template>
  <div class="no-permission">
    <el-result icon="info" title="暂无权限，请联系管理员">
      <template #extra>
        <el-button type="primary" @click="onLogout">退出登录</el-button>
      </template>
    </el-result>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

async function onLogout() {
  await auth.logout().catch(() => undefined)
  router.push({ name: 'login' })
}
</script>

<style scoped lang="scss">
.no-permission {
  display: flex;
  height: 100%;
  align-items: center;
  justify-content: center;
}
</style>
