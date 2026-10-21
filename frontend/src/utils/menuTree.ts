import type { MenuInfo } from '@/api/system/auth'

export interface MenuNode extends MenuInfo {
  children: MenuNode[]
}

/** 把 /auth/me 的扁平 menus[] 组装成树：parentId 为 '0'/0/null 或父节点不在列表中时视为根；同级按 sortNo、id 排序。 */
export function buildMenuTree(menus: readonly MenuInfo[]): MenuNode[] {
  const nodes = new Map<string, MenuNode>()
  for (const m of menus) nodes.set(String(m.id), { ...m, children: [] })
  const roots: MenuNode[] = []
  for (const node of nodes.values()) {
    const pid = node.parentId == null ? '0' : String(node.parentId)
    const parent = pid !== '0' && pid !== String(node.id) ? nodes.get(pid) : undefined
    if (parent) parent.children.push(node)
    else roots.push(node)
  }
  const sort = (list: MenuNode[]) => {
    list.sort((a, b) => a.sortNo - b.sortNo || String(a.id).localeCompare(String(b.id)))
    list.forEach((n) => sort(n.children))
  }
  sort(roots)
  return roots
}

/** route_path 无前导斜杠（90 §3.12），转为路由路径。 */
export function toRoutePath(routePath: string | null): string | null {
  if (!routePath) return null
  return routePath.startsWith('/') ? routePath : `/${routePath}`
}
