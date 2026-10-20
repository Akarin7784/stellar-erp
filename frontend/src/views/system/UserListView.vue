<template>
  <el-card shadow="never">
    <template #header>
      <div class="toolbar">
        <span>用户管理</span>
        <el-button type="primary">新增用户</el-button>
      </div>
    </template>

    <el-table :data="users" stripe>
      <el-table-column prop="username" label="用户名" width="160" />
      <el-table-column prop="nickname" label="姓名" width="160" />
      <el-table-column prop="role" label="角色" width="160" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'">
            {{ row.status === 1 ? '启用' : '停用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" />
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { formatDateTime } from '@/utils/format'

interface UserRow {
  username: string
  nickname: string
  role: string
  status: number
  createdAt: string
}

const users: UserRow[] = [
  {
    username: 'admin',
    nickname: '系统管理员',
    role: '超级管理员',
    status: 1,
    createdAt: formatDateTime('2026-10-20T10:00:00+08:00'),
  },
]
</script>

<style scoped lang="scss">
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
