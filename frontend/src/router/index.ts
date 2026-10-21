import {
  createRouter,
  createWebHistory,
  type RouteComponent,
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

router.beforeEach(async (to) => {
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
  if (auth.hasNoPermission && to.name !== 'no-permission') return { name: 'no-permission' }
  return true
})

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
