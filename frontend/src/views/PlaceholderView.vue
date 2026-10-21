<template>
  <el-empty class="placeholder" :description="`${title}（${screenId}）画面尚未实现`" />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const title = computed(() => (route.meta.title as string | undefined) ?? '')
const screenId = computed(() => (route.meta.screenId as string | undefined) ?? '')
</script>
