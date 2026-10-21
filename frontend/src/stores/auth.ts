import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

import { TOKEN_KEY } from '@/api/http'
import { getMe, logout as apiLogout, type MeResult } from '@/api/system/auth'
import { buildMenuTree } from '@/utils/menuTree'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem(TOKEN_KEY))
  const me = ref<MeResult | null>(null)

  const menuTree = computed(() => buildMenuTree(me.value?.menus ?? []))
  /** menus=[]（无角色）时登录仍成功，前端显示「暂无权限，请联系管理员」（01-auth-login.md 前提 #4）。 */
  const hasNoPermission = computed(() => me.value !== null && me.value.menus.length === 0)

  function setToken(t: string) {
    token.value = t
    localStorage.setItem(TOKEN_KEY, t)
  }

  function clear() {
    token.value = null
    me.value = null
    localStorage.removeItem(TOKEN_KEY)
  }

  async function fetchMe(): Promise<MeResult> {
    me.value = await getMe()
    return me.value
  }

  async function logout() {
    try {
      await apiLogout()
    } finally {
      clear()
    }
  }

  return { token, me, menuTree, hasNoPermission, setToken, clear, fetchMe, logout }
})
