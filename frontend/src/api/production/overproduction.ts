import http, { ApiError, MSG_CONFLICT, type ApiResult } from '../http'

/**
 * 超产申请 / 承认 API（06-production/91-api-design.md §3.14、#39a〜39g；
 * backend OverproductionApprovalController）。ID 为字符串（03 §8），数量为 BigDecimal 字符串。
 * 所有调用 silent：错误由画面按 toOpaErrorView 显示。
 */

/** 状态（90 §3.19.1 ck_prd_opa_status）：10 草稿 → 20 待审批 → 30 已批准 / 40 已驳回；10・20 → 90 已取消。 */
export const OPA_STATUS = {
  DRAFT: 10,
  SUBMITTED: 20,
  APPROVED: 30,
  REJECTED: 40,
  CANCELLED: 90,
} as const

export const OPA_STATUS_LABELS: Record<number, string> = {
  10: '草稿',
  20: '待审批',
  30: '已批准',
  40: '已驳回',
  90: '已取消',
}

/** 权限码（91 #39a〜39g；驳回与批准共用 approve）。 */
export const OPA_PERMISSIONS = {
  view: 'production:overproduction-approval:view',
  create: 'production:overproduction-approval:create',
  submit: 'production:overproduction-approval:submit',
  approve: 'production:overproduction-approval:approve',
  cancel: 'production:overproduction-approval:cancel',
} as const

/** backend OverproductionApprovalView。 */
export interface OverproductionApproval {
  id: string
  approvalNo: string
  salesOrderId: string
  salesOrderLineId: string
  /** null＝受注行级 */
  workOrderId: string | null
  materialId: string
  /** 申请增量 delta（基本单位），不是总量 */
  requestQty: string | number
  currentAllowedQty: string | number | null
  approvedAllowedQty: string | number | null
  approvalStatus: number
  requestedBy: string
  requestedAt: string
  approvedBy: string | null
  approvedAt: string | null
  rejectReason: string | null
  remark: string | null
  version: number
}

export interface PageResult<T> {
  list: T[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

export interface OpaListQuery {
  salesOrderLineId?: string
  workOrderId?: string
  approvalStatus?: number
  page?: number
  size?: number
}

/** backend OverproductionRequestCommand（requestQty = 增量 delta，> 0）。 */
export interface OpaCreateRequest {
  salesOrderLineId: string
  workOrderId?: string
  requestQty: string
  remark?: string
}

/** backend OverproductionRequested。 */
export interface OpaCreated {
  id: string
  approvalNo: string
  approvalStatus: number
  requestQty: string | number
  currentAllowedQty: string | number | null
}

/** backend OverproductionApproved。 */
export interface OpaApproved {
  id: string
  approvalNo: string
  approvalStatus: number
  requestQty: string | number
  approvedAllowedQty: string | number | null
  workOrderId: string | null
  version: number
}

const BASE = '/production/overproduction-approvals'

function dropEmpty<T extends object>(o: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(o).filter(([, v]) => v !== undefined && v !== null && v !== ''),
  ) as Partial<T>
}

export async function listOverproductionApprovals(
  q: OpaListQuery = {},
): Promise<PageResult<OverproductionApproval>> {
  const res = await http.get<ApiResult<PageResult<OverproductionApproval>>>(BASE, {
    params: dropEmpty(q),
    silent: true,
  })
  return res.data.data
}

export async function getOverproductionApproval(id: string): Promise<OverproductionApproval> {
  const res = await http.get<ApiResult<OverproductionApproval>>(`${BASE}/${id}`, { silent: true })
  return res.data.data
}

export async function createOverproductionApproval(body: OpaCreateRequest): Promise<OpaCreated> {
  const payload = dropEmpty({
    ...body,
    salesOrderLineId: body.salesOrderLineId.trim(),
    workOrderId: body.workOrderId?.trim(),
    requestQty: body.requestQty.trim(),
    remark: body.remark?.trim(),
  })
  const res = await http.post<ApiResult<OpaCreated>>(BASE, payload, { silent: true })
  return res.data.data
}

export async function submitOverproductionApproval(id: string, version: number) {
  const res = await http.post<ApiResult<OverproductionApproval>>(
    `${BASE}/${id}/submit`,
    { version },
    { silent: true },
  )
  return res.data.data
}

export async function approveOverproductionApproval(id: string, version: number) {
  const res = await http.post<ApiResult<OpaApproved>>(
    `${BASE}/${id}/approve`,
    { version },
    { silent: true },
  )
  return res.data.data
}

export async function rejectOverproductionApproval(
  id: string,
  version: number,
  rejectReason?: string,
) {
  const res = await http.post<ApiResult<OverproductionApproval>>(
    `${BASE}/${id}/reject`,
    dropEmpty({ version, rejectReason: rejectReason?.trim() }),
    { silent: true },
  )
  return res.data.data
}

export async function cancelOverproductionApproval(id: string, version: number) {
  const res = await http.post<ApiResult<OverproductionApproval>>(
    `${BASE}/${id}/cancel`,
    { version },
    { silent: true },
  )
  return res.data.data
}

/** 后端缺 msgId 时按 code 补（06/91 §3.14、§4；06/93）。 */
const OPA_MSG_ID: Partial<Record<number, string>> = {
  4002: 'MSG-COM-034',
  60005: 'MSG-PRD-005',
  60056: 'MSG-PRD-056',
  60101: 'MSG-PRD-101',
  60103: 'MSG-PRD-103',
}

export const MSG_OPA_GENERIC_ERROR = '系统异常，请稍后重试或联系管理员'

export interface OpaErrorView {
  /** conflict：4003（HTTP 409）刷新提示；business：1001/4001/4002/422 业务错误；generic：其他 */
  kind: 'conflict' | 'business' | 'generic'
  message: string
  /** 是否需要重新读取一览（数据已被他人更新） */
  reload: boolean
}

function backendMessage(err: ApiError): string | undefined {
  const d = err.data as { message?: unknown } | undefined
  return d && typeof d.message === 'string' && d.message ? d.message : undefined
}

/** 只有 4003 走刷新提示；其他业务错误显示 `[msgId] 后端 message`。 */
export function toOpaErrorView(err: unknown): OpaErrorView {
  if (err instanceof ApiError && err.code !== undefined) {
    const code = err.code
    if (code === 4003) return { kind: 'conflict', message: MSG_CONFLICT, reload: true }
    if (
      (code >= 1000 && code <= 1999) ||
      (code >= 4000 && code <= 4999) ||
      (code >= 10000 && code <= 99999)
    ) {
      const id = err.msgId ?? OPA_MSG_ID[code] ?? String(code)
      return {
        kind: 'business',
        message: `[${id}] ${backendMessage(err) ?? err.message}`,
        reload: false,
      }
    }
    if (code >= 3000 && code <= 3999) {
      return { kind: 'business', message: backendMessage(err) ?? err.message, reload: false }
    }
  }
  return { kind: 'generic', message: MSG_OPA_GENERIC_ERROR, reload: false }
}
