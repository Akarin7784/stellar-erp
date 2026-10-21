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
  /** 显示用（后端 JOIN，参照不存在时为 null） */
  salesOrderNo: string | null
  workOrderNo: string | null
  materialCode: string | null
  materialName: string | null
  requestedByName: string | null
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
  pageNum?: number
  pageSize?: number
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

/** backend OverproductionUpdateCommand（草稿修正 #39h，仅状态 10；workOrderId null＝受注行级）。 */
export interface OpaUpdateRequest {
  version: number
  workOrderId: string | null
  requestQty: string
  remark: string | null
}

/** backend SalesOrderLineOption（受注行选择器 1 行）。 */
export interface SalesOrderLineOption {
  salesOrderLineId: string
  salesOrderId: string
  salesOrderNo: string
  lineNo: number
  materialId: string
  materialCode: string
  materialName: string
  baseUomCode: string
  baseQty: string | number
  allowedQty: string | number
  completedQty: string | number
}

export interface SalesOrderLineQuery {
  /** 销售订单号部分一致 */
  salesOrderNo?: string
  /** 物料编码／名称部分一致 */
  material?: string
  pageNum?: number
  pageSize?: number
}

/** 受注行选择器 pageSize 上限（后端超过时 400 / 1001 / MSG-COM-045） */
export const SALES_ORDER_LINE_PAGE_SIZE_MAX = 200

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

export async function updateOverproductionApproval(
  id: string,
  body: OpaUpdateRequest,
): Promise<OverproductionApproval> {
  const workOrderId = body.workOrderId?.trim() || null
  const remark = body.remark?.trim() || null
  const res = await http.put<ApiResult<OverproductionApproval>>(
    `${BASE}/${id}`,
    { version: body.version, workOrderId, requestQty: body.requestQty.trim(), remark },
    { silent: true },
  )
  return res.data.data
}

export async function searchSalesOrderLines(
  q: SalesOrderLineQuery = {},
): Promise<PageResult<SalesOrderLineOption>> {
  const pageSize = Math.min(q.pageSize ?? 20, SALES_ORDER_LINE_PAGE_SIZE_MAX)
  const res = await http.get<ApiResult<PageResult<SalesOrderLineOption>>>(
    `${BASE}/sales-order-lines`,
    {
      params: dropEmpty({
        salesOrderNo: q.salesOrderNo?.trim(),
        material: q.material?.trim(),
        pageNum: q.pageNum ?? 1,
        pageSize,
      }),
      silent: true,
    },
  )
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

/** 只有 4003 走刷新提示；其他业务错误显示 `[msgId] 后端 message`（4003・4002 需重读）。 */
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
        // 4002 状态不整合：数据已变化，重读一览（同 workOrder.ts 下达）
        reload: code === 4002,
      }
    }
    if (code >= 3000 && code <= 3999) {
      return { kind: 'business', message: backendMessage(err) ?? err.message, reload: false }
    }
  }
  return { kind: 'generic', message: MSG_OPA_GENERIC_ERROR, reload: false }
}

/** 1001 的 data.fieldErrors（03 §5.3）；无则空数组。 */
export function fieldErrorsOf(err: unknown): { field: string; message: string }[] {
  if (!(err instanceof ApiError) || err.code !== 1001) return []
  const d = err.data as { data?: { fieldErrors?: unknown } } | undefined
  const fe = d?.data?.fieldErrors
  return Array.isArray(fe)
    ? fe.filter(
        (x): x is { field: string; message: string } =>
          !!x && typeof x.field === 'string' && typeof x.message === 'string',
      )
    : []
}
