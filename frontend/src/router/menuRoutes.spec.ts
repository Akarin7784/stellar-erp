import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import { MENU_ROUTES } from './menuRoutes'
import { menuChildren } from './index'

// vitest 在 frontend/ 下运行
const DOC = resolve(process.cwd(), '../docs/design/01-system/94-sample-data.md')

interface DocMenu {
  screenId: string
  title: string
  path: string
  permission: string
  hidden: boolean
}

/** 94 付録 A 的表格行（列：# | menu_code | menu_name | menu_type | module | 親 | route_path | permission_code | sort_no | 備考）。 */
function docRows(): string[][] {
  const text = readFileSync(DOC, 'utf8')
  const start = text.indexOf('## 6. 付録 A')
  const section = text.slice(start, text.indexOf('\n## ', start + 1))
  return section
    .split('\n')
    .filter((l) => /^\| \d+ \|/.test(l))
    .map((l) => l.split('|').map((c) => c.trim().replace(/`/g, '')))
}

/** menu_type=2 行。 */
function docMenus(): DocMenu[] {
  return docRows()
    .filter((c) => c[4]!.startsWith('2'))
    .map((c) => ({
      screenId: c[2]!,
      title: c[3]!,
      path: c[7]!,
      permission: c[8]!,
      hidden: c[10]!.includes('is_visible=FALSE'),
    }))
}

describe('menuRoutes（94 付録 A）', () => {
  it('与文档的菜单行完全一致（画面 ID、menu_name、route_path、permission_code、非表示、顺序）', () => {
    const doc = docMenus()
    expect(doc.length).toBe(340)
    expect(MENU_ROUTES.map((m) => ({ ...m }))).toEqual(doc)
  })

  it('文档中没有 menu_type=4（外部链接）行；将来出现时不生成路由、不检查权限', () => {
    expect(docRows().some((c) => c[4]!.startsWith('4'))).toBe(false)
  })

  it('每个菜单路由的 meta 带 title / permission / hidden', () => {
    for (const r of menuChildren) {
      const m = MENU_ROUTES.find((x) => x.path === r.path)!
      expect(r.meta).toMatchObject({ title: m.title, permission: m.permission, hidden: m.hidden })
    }
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
