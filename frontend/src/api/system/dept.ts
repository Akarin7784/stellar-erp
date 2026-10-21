import http, { type ApiResult } from '../http'

/**
 * 部门下拉（backend/erp-system DeptOptionController，PR #61）。
 * GET /api/system/departments/options：只要求登录，后端按当前公司 + RLS 过滤，
 * 只返回启用、未删除的部门，按 sort_no, department_code 排序。前端不传 companyId。
 */
export interface DeptOption {
  id: string
  departmentCode: string
  departmentName: string
}

/** silent：失败时不弹全局提示，由画面自行显示（工单登録画面用页内警告）。 */
export async function listDeptOptions(opts: { silent?: boolean } = {}): Promise<DeptOption[]> {
  const res = await http.get<ApiResult<DeptOption[]>>('/system/departments/options', {
    silent: opts.silent,
  })
  return res.data.data
}
