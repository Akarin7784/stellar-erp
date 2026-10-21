import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import { MENU_ROUTES } from './menuRoutes'
import { menuChildren } from './index'

// vitest 在 frontend/ 下运行
const DOC = resolve(process.cwd(), '../docs/design/01-system/94-sample-data.md')

/** 从 94 付録 A 解析 menu_type=2 行：[画面 ID, route_path]。 */
function docMenus(): [string, string][] {
  const text = readFileSync(DOC, 'utf8')
  const start = text.indexOf('## 6. 付録 A')
  const section = text.slice(start, text.indexOf('\n## ', start + 1))
  return section
    .split('\n')
    .filter((l) => /^\| \d+ \|/.test(l))
    .map((l) => l.split('|').map((c) => c.trim().replace(/`/g, '')))
    .filter((c) => c[4].startsWith('2'))
    .map((c) => [c[2], c[7]])
}

describe('menuRoutes（94 付録 A）', () => {
  it('与文档的菜单行完全一致（画面 ID、route_path、顺序）', () => {
    const doc = docMenus()
    expect(doc.length).toBe(340)
    expect(MENU_ROUTES.map((m) => [m.screenId, m.path])).toEqual(doc)
  })

  it('route_path 与路由名均唯一', () => {
    expect(new Set(MENU_ROUTES.map((m) => m.path)).size).toBe(MENU_ROUTES.length)
    expect(new Set(menuChildren.map((r) => r.name)).size).toBe(menuChildren.length)
  })

  it('已实现画面保留原路由名，其余为占位', () => {
    const byPath = new Map(menuChildren.map((r) => [r.path, r]))
    expect(byPath.get('system/users')?.name).toBe('system-users')
    expect(byPath.get('production/work-orders/new')?.name).toBe('production-work-order-create')
    const detail = byPath.get('production/work-orders/:id')
    expect(detail?.name).toBe('production-work-order-detail')
    expect(detail?.props).toBe(true)
    expect(menuChildren.filter((r) => !r.meta?.placeholder)).toHaveLength(4)
    const opa = byPath.get('production/overproduction-approvals')
    expect(opa?.name).toBe('production-overproduction-approvals')
    expect(opa?.meta?.placeholder).toBe(false)
    const ph = byPath.get('production/work-orders/release')
    expect(ph?.name).toBe('SCR-PRD-011')
    expect(ph?.meta?.placeholder).toBe(true)
  })
})
