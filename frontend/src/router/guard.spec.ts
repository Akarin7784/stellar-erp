import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import type { RouteLocationNormalized } from 'vue-router'

vi.mock('@/api/system/auth', () => ({ getMe: vi.fn(), logout: vi.fn() }))

import { useAuthStore } from '@/stores/auth'
import router, { authGuard, hasRoutePermission } from './index'

function login(permissions: string[], menus: unknown[] = [{ id: '1' }]) {
  const auth = useAuthStore()
  auth.setToken('tok')
  auth.me = {
    userInfo: { id: '1', username: 'u', nickname: null },
    companyId: '1',
    roles: [],
    permissions,
    menus: menus as never,
  }
}

// router.resolve 返回 RouteLocationResolved（name 可为 null），守卫只读 meta/name/fullPath，按 Normalized 传入
const to = (path: string) => router.resolve(path) as unknown as RouteLocationNormalized

describe('authGuard 权限码', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  it('有权限：放行', async () => {
    login(['system:user:view'])
    expect(await authGuard(to('/system/users'))).toBe(true)
  })

  it('无权限：跳转 /no-permission（不是 404）', async () => {
    login(['system:user:view'])
    expect(await authGuard(to('/production/overproduction-approvals'))).toEqual({
      name: 'no-permission',
    })
  })

  it('非表示路由（is_visible=FALSE）有权限时可达，无权限时拦截', async () => {
    const detail = to('/production/work-orders/42')
    expect(detail.meta.hidden).toBe(true)
    expect(detail.meta.permission).toBe('production:work-order:view')
    login(['production:work-order:view'])
    expect(await authGuard(detail)).toBe(true)
    setActivePinia(createPinia())
    login(['system:user:view'])
    expect(await authGuard(detail)).toEqual({ name: 'no-permission' })
  })

  it('无 permission 的路由（工作台）与 /no-permission 本身不检查', async () => {
    login([])
    expect(await authGuard(to('/'))).toBe(true)
    expect(await authGuard(to('/no-permission'))).toBe(true)
  })

  it('未登录：跳登录页并带 redirect', async () => {
    expect(await authGuard(to('/system/users'))).toEqual({
      name: 'login',
      query: { redirect: '/system/users' },
    })
  })

  it('menus=[]：跳 /no-permission', async () => {
    login(['system:user:view'], [])
    expect(await authGuard(to('/system/users'))).toEqual({ name: 'no-permission' })
  })

  it('hasRoutePermission', () => {
    expect(hasRoutePermission({}, [])).toBe(true)
    expect(hasRoutePermission({ permission: 'a:b:view' }, ['a:b:view'])).toBe(true)
    expect(hasRoutePermission({ permission: 'a:b:view' }, ['a:b:create'])).toBe(false)
  })
})
