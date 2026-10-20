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
        <el-menu-item index="/system/users">
          <el-icon><User /></el-icon>
          <template #title>用户管理</template>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="layout__header">
        <el-button text @click="appStore.toggleSidebar">
          <el-icon><Fold /></el-icon>
        </el-button>
        <span class="layout__breadcrumb">{{ route.meta.title ?? '' }}</span>
      </el-header>
      <el-main class="layout__main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { Fold, Odometer, User } from '@element-plus/icons-vue'
import { useRoute } from 'vue-router'

import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const route = useRoute()
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
