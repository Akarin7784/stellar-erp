import {
  createRouter,
  createWebHistory,
  type RouteComponent,
  type RouteLocationNormalized,
  type RouteLocationRaw,
  type RouteRecordRaw,
} from 'vue-router'

import { setUnauthorizedHandler } from '@/api/http'
import { useAuthStore } from '@/stores/auth'
import { MENU_ROUTES } from './menuRoutes'

/** 已实现的画面：route_path → 路由名与组件（保留既有路由名，代码中按名跳转）。 */
const BUILT_VIEWS: Record<string, { name: string; component: RouteComponent }> = {
  'system/users': {
    name: 'system-users',
    component: () => import('@/views/system/UserListView.vue'),
  },
  'production/work-orders': {
    name: 'production-work-orders',
    component: () => import('@/views/production/WorkOrderListView.vue'),
  },
  'production/work-orders/new': {
    name: 'production-work-order-create',
    component: () => import('@/views/production/WorkOrderCreateView.vue'),
  },
  'production/overproduction-approvals': {
    name: 'production-overproduction-approvals',
    component: () => import('@/views/production/OverproductionApprovalView.vue'),
  },
  'production/work-orders/:id': {
    name: 'production-work-order-detail',
    component: () => import('@/views/production/WorkOrderDetailView.vue'),
  },
}

const Placeholder = () => import('@/views/PlaceholderView.vue')

/** 94 付録 A 的全部菜单行；未实现画面指向 PlaceholderView，路由名用画面 ID。 */
export const menuChildren: RouteRecordRaw[] = MENU_ROUTES.map((m) => {
  const built = BUILT_VIEWS[m.path]
  return {
    path: m.path,
    name: built?.name ?? m.screenId,
    component: built?.component ?? Placeholder,
    props: !!built && m.path.includes(':'),
    meta: {
      title: m.title,
      screenId: m.screenId,
      permission: m.permission,
      hidden: m.hidden,
      placeholder: !built,
    },
  }
})

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { title: '登录', public: true },
    },
    {
      path: '/no-permission',
      name: 'no-permission',
      component: () => import('@/views/NoPermissionView.vue'),
      meta: { title: '暂无权限' },
    },
    {
      path: '/',
      component: () => import('@/layouts/MainLayout.vue'),
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { title: '工作台' },
        },
        ...menuChildren,
      ],
    },
  ],
})

/**
 * 路由权限：meta.permission（94 付録 A permission_code）不在 /auth/me permissions 中时 → /no-permission。
 * 非表示（hidden）路由同样有路由并做同样的检查；无 permission 的路由（工作台等）不检查。
 */
export function hasRoutePermission(
  meta: Record<string | number | symbol, unknown>,
  permissions: readonly string[],
): boolean {
  const perm = meta.permission
  return typeof perm !== 'string' || perm === '' || permissions.includes(perm)
}

export async function authGuard(to: RouteLocationNormalized): Promise<RouteLocationRaw | boolean> {
  if (to.meta.public) return true
  const auth = useAuthStore()
  if (!auth.token) return { name: 'login', query: { redirect: to.fullPath } }
  if (!auth.me) {
    try {
      await auth.fetchMe()
    } catch {
      // 2001 已由拦截器清 token 并跳转；其他错误留在登录页
      return auth.token ? false : { name: 'login', query: { redirect: to.fullPath } }
    }
  }
  if (to.name === 'no-permission') return true
  if (auth.hasNoPermission) return { name: 'no-permission' }
  if (!hasRoutePermission(to.meta, auth.me?.permissions ?? [])) return { name: 'no-permission' }
  return true
}

router.beforeEach(authGuard)

// 2001（HTTP 401）：清除登录状态并回到登录页
setUnauthorizedHandler(() => {
  useAuthStore().clear()
  const current = router.currentRoute.value
  if (current.name !== 'login') {
    router.replace({ name: 'login', query: { redirect: current.fullPath } })
  }
})

router.afterEach((to) => {
  const title = to.meta.title as string | undefined
  document.title = title ? `${title} - Stellar ERP` : 'Stellar ERP'
})

export default router
