import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'
import { h } from 'vue'
import { ElMenu } from 'element-plus'

import MenuTreeItem from './MenuTreeItem.vue'
import { buildMenuTree } from '@/utils/menuTree'
import type { MenuInfo } from '@/api/system/auth'

const m = (
  id: string,
  parentId: string,
  menuName: string,
  routePath: string | null,
  isVisible = true,
): MenuInfo => ({
  id,
  parentId,
  menuType: routePath ? 2 : 1,
  menuCode: `CODE-${id}`,
  menuName,
  routePath,
  sortNo: Number(id),
  isVisible,
})

function render(menus: MenuInfo[]) {
  const tree = buildMenuTree(menus)
  return mount(
    {
      render: () =>
        h(ElMenu, { defaultOpeneds: tree.map((n) => `menu-${n.id}`) }, () =>
          tree.map((node) => h(MenuTreeItem, { key: node.id, node })),
        ),
    },
    { global: { plugins: [ElementPlus] } },
  )
}

describe('MenuTreeItem（侧边栏）', () => {
  it('显示 /auth/me 的 menuName，不显示 isVisible=false 的菜单', () => {
    const w = render([
      m('1', '0', '系统管理', null),
      m('2', '1', '用户一览', 'system/users'),
      m('3', '1', '用户登记编辑', 'system/users/edit', false),
    ])
    const text = w.text()
    expect(text).toContain('系统管理')
    expect(text).toContain('用户一览')
    expect(text).not.toContain('用户登记编辑')
    expect(text).not.toContain('CODE-')
  })

  it('menuName 为空时退回 menuCode', () => {
    const w = render([m('5', '0', '', 'system/users')])
    expect(w.text()).toContain('CODE-5')
  })
})
