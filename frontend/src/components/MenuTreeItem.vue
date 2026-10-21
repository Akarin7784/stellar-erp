<template>
  <el-sub-menu v-if="node.children.length > 0" :index="`menu-${node.id}`">
    <template #title>
      <span>{{ label }}</span>
    </template>
    <MenuTreeItem v-for="child in node.children" :key="child.id" :node="child" />
  </el-sub-menu>
  <el-menu-item v-else :index="path ?? `menu-${node.id}`" :disabled="!path">
    <template #title>{{ label }}</template>
  </el-menu-item>
</template>

<script setup lang="ts">
import { computed } from 'vue'

import { toRoutePath, type MenuNode } from '@/utils/menuTree'

const props = defineProps<{ node: MenuNode }>()

const path = computed(() => toRoutePath(props.node.routePath))
/** 显示 /auth/me 的 menuName；为空时退回 menuCode。 */
const label = computed(() => props.node.menuName || props.node.menuCode)
</script>
