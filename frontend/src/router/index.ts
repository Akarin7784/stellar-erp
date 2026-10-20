import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
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
      ],
    },
  ],
})

router.afterEach((to) => {
  const title = to.meta.title as string | undefined
  document.title = title ? `${title} - Stellar ERP` : 'Stellar ERP'
})

export default router
