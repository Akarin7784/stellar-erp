import { describe, expect, it } from 'vitest'

import type { MenuInfo } from '@/api/system/auth'
import { buildMenuTree, toRoutePath } from './menuTree'

const m = (
  id: string,
  parentId: string,
  sortNo: number,
  routePath: string | null = null,
  isVisible = true,
): MenuInfo => ({
  id,
  parentId,
  menuType: routePath ? 2 : 1,
  menuCode: `M${id}`,
  menuName: `菜单${id}`,
  routePath,
  sortNo,
  isVisible,
})

describe('buildMenuTree', () => {
  it('空数组返回空树', () => {
    expect(buildMenuTree([])).toEqual([])
  })

  it('按 parentId 组树并按 sortNo 排序', () => {
    const tree = buildMenuTree([
      m('11', '1', 2, 'system/roles'),
      m('2', '0', 2),
      m('1', '0', 1),
      m('10', '1', 1, 'system/users'),
      m('20', '2', 1, 'production/work-orders/new'),
    ])
    expect(tree.map((n) => n.id)).toEqual(['1', '2'])
    expect(tree[0].children.map((n) => n.id)).toEqual(['10', '11'])
    expect(tree[1].children.map((n) => n.id)).toEqual(['20'])
    expect(tree[0].children[0].children).toEqual([])
  })

  it('isVisible=false 的菜单及其下级不进入侧边栏树', () => {
    const tree = buildMenuTree([
      m('1', '0', 1),
      m('10', '1', 1, 'system/users'),
      m('11', '1', 2, 'system/users/edit', false),
      m('2', '0', 2, null, false),
      m('20', '2', 1, 'production/work-orders'),
    ])
    expect(tree.map((n) => n.id)).toEqual(['1'])
    expect(tree[0].children.map((n) => n.id)).toEqual(['10'])
  })

  it('父节点不在列表中时作为根', () => {
    expect(buildMenuTree([m('5', '99', 1, 'x')]).map((n) => n.id)).toEqual(['5'])
  })
})

describe('toRoutePath', () => {
  it('补前导斜杠', () => {
    expect(toRoutePath('system/users')).toBe('/system/users')
    expect(toRoutePath('/a')).toBe('/a')
    expect(toRoutePath(null)).toBeNull()
  })
})
