<template>
  <el-container class="layout">
    <el-aside :width="appStore.sidebarCollapsed ? '64px' : '220px'" class="layout__aside">
      <div class="layout__logo">
        <span v-if="!appStore.sidebarCollapsed">{{ appStore.appName }}</span>
        <span v-else>SE</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="appStore.sidebarCollapsed"
        router
        class="layout__menu"
      >
        <el-menu-item index="/">
          <el-icon><Odometer /></el-icon>
          <template #title>工作台</template>
        </el-menu-item>
        <MenuTreeItem v-for="node in auth.menuTree" :key="node.id" :node="node" />
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="layout__header">
        <el-button text @click="appStore.toggleSidebar">
          <el-icon><Fold /></el-icon>
        </el-button>
        <span class="layout__breadcrumb">{{ route.meta.title ?? '' }}</span>
        <span class="layout__spacer" />
        <span class="layout__user">{{
          auth.me?.userInfo.nickname || auth.me?.userInfo.username
        }}</span>
        <el-button text data-test="logout" @click="onLogout">退出登录</el-button>
      </el-header>
      <el-main class="layout__main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { Fold, Odometer } from '@element-plus/icons-vue'
import { useRoute, useRouter } from 'vue-router'

import MenuTreeItem from '@/components/MenuTreeItem.vue'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'

const appStore = useAppStore()
const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

async function onLogout() {
  await auth.logout().catch(() => undefined)
  router.push({ name: 'login' })
}
</script>

<style scoped lang="scss">
.layout {
  height: 100%;

  &__aside {
    background: #1f2d3d;
    transition: width 0.2s;
  }

  &__logo {
    display: flex;
    height: 56px;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-size: 16px;
    font-weight: 600;
    letter-spacing: 1px;
  }

  &__menu {
    border-right: none;
    background: transparent;
    --el-menu-bg-color: transparent;
    --el-menu-text-color: #c0c4cc;
    --el-menu-active-color: #409eff;
  }

  &__spacer {
    flex: 1;
  }

  &__header {
    display: flex;
    align-items: center;
    gap: 12px;
    background: #fff;
    border-bottom: 1px solid #e4e7ed;
  }

  &__main {
    background: #f5f7fa;
  }
}
</style>
