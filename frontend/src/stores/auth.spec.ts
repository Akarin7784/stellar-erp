import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

import { TOKEN_KEY } from '@/api/http'

const getMe = vi.fn()
const logout = vi.fn()
vi.mock('@/api/system/auth', () => ({
  getMe: (...a: unknown[]) => getMe(...a),
  logout: (...a: unknown[]) => logout(...a),
}))

import { useAuthStore } from './auth'

const menu = (id: string, parentId: string, sortNo: number) => ({
  id,
  parentId,
  menuType: 2,
  menuCode: `M${id}`,
  routePath: `p${id}`,
  sortNo,
})
const ME = {
  userInfo: { id: '1', username: 'admin', nickname: null },
  companyId: '1',
  roles: [],
  permissions: [],
  menus: [menu('2', '0', 2), menu('1', '0', 1), menu('3', '1', 1)],
}

describe('useAuthStore', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  it('初始化时从 localStorage 读取 token', () => {
    localStorage.setItem(TOKEN_KEY, 'old')
    setActivePinia(createPinia())
    expect(useAuthStore().token).toBe('old')
  })

  it('setToken 写入 state 与 localStorage', () => {
    setActivePinia(createPinia())
    const s = useAuthStore()
    s.setToken('tok')
    expect(s.token).toBe('tok')
    expect(localStorage.getItem(TOKEN_KEY)).toBe('tok')
  })

  it('fetchMe 后生成菜单树；clear 清空 token / me / localStorage', async () => {
    setActivePinia(createPinia())
    const s = useAuthStore()
    s.setToken('tok')
    getMe.mockResolvedValue(ME)
    await s.fetchMe()
    expect(s.menuTree.map((n) => n.id)).toEqual(['1', '2'])
    expect(s.menuTree[0].children.map((n) => n.id)).toEqual(['3'])
    s.clear()
    expect(s.token).toBeNull()
    expect(s.me).toBeNull()
    expect(s.menuTree).toEqual([])
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
  })

  it('hasNoPermission：未加载 me 为 false，menus=[] 为 true，有菜单为 false', async () => {
    setActivePinia(createPinia())
    const s = useAuthStore()
    expect(s.hasNoPermission).toBe(false)
    getMe.mockResolvedValueOnce({ ...ME, menus: [] })
    await s.fetchMe()
    expect(s.hasNoPermission).toBe(true)
    getMe.mockResolvedValueOnce(ME)
    await s.fetchMe()
    expect(s.hasNoPermission).toBe(false)
  })

  it('fetchMe 失败时不改 me', async () => {
    setActivePinia(createPinia())
    const s = useAuthStore()
    getMe.mockRejectedValue(new Error('x'))
    await expect(s.fetchMe()).rejects.toThrow('x')
    expect(s.me).toBeNull()
  })

  it('logout：API 失败也清除本地状态', async () => {
    setActivePinia(createPinia())
    const s = useAuthStore()
    s.setToken('tok')
    logout.mockRejectedValue(new Error('net'))
    await expect(s.logout()).rejects.toThrow('net')
    expect(s.token).toBeNull()
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
  })
})
