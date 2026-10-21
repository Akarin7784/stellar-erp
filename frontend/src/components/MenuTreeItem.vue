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
import { useRouter } from 'vue-router'

import { toRoutePath, type MenuNode } from '@/utils/menuTree'

const props = defineProps<{ node: MenuNode }>()
const router = useRouter()

const path = computed(() => toRoutePath(props.node.routePath))
/**
 * /auth/me 目前不返回 menu_name，先用前端路由 meta.title，找不到时退回 menuCode。
 * TODO: 后端补 menuName 后改用后端名称。
 */
const label = computed(() => {
  if (path.value) {
    const r = router.resolve(path.value)
    const title = r.matched.length > 0 ? (r.meta.title as string | undefined) : undefined
    if (title) return title
  }
  return props.node.menuCode
})
</script>
