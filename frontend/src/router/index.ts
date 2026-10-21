import { createRouter, createWebHistory } from 'vue-router'

import { setUnauthorizedHandler } from '@/api/http'
import { useAuthStore } from '@/stores/auth'

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
        {
          path: 'system/users',
          name: 'system-users',
          component: () => import('@/views/system/UserListView.vue'),
          meta: { title: '用户管理' },
        },
        {
          path: 'production/work-orders/new',
          name: 'production-work-order-create',
          component: () => import('@/views/production/WorkOrderCreateView.vue'),
          meta: { title: '生产订单登録' },
        },
        {
          path: 'production/work-orders/:id',
          name: 'production-work-order-detail',
          component: () => import('@/views/production/WorkOrderDetailView.vue'),
          props: true,
          meta: { title: '生产订单詳細' },
        },
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
