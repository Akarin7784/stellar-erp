import http, { ApiError, type ApiResult } from '../http'

/**
 * 工单登録 API（docs/design/06-production/02-work-order.md §7 No.3 / 91-api-design #26）。
 * 字段严格对应后端 WorkOrderCreateCommand / WorkOrderCreated（PR #18）。
 * ID 类字段为 BIGINT，按 03-common-api-spec 以字符串传输以免精度丢失。
 */
export interface WorkOrderCreateRequest {
  workOrderType?: number | null
  factoryId: string
  materialId: string
  /** NUMERIC(18,4)，字符串传输 */
  orderQty: string
  uomCode: string
  /** YYYY-MM-DD */
  plannedStartDate: string
  plannedEndDate: string
  priorityNo?: number | null
  departmentId?: string | null
  warehouseId?: string | null
  salesOrderLineId?: string | null
  isBackflush?: boolean | null
  remark?: string | null
}

export interface WorkOrderCreated {
  id: string | number
  workOrderNo: string
  orderStatus: number
  materialCode: string
  materialName: string
  orderQty: string | number
  /** 完工超収容差スナップショット（NUMERIC(5,4) 比率），只读 */
  overReceiptRate: string | number
  allowedQty: string | number | null
  /** 创建时恒为 null（下达时快照） */
  standardCost: string | number | null
  version: number
  /** 91 §3.1：201 也可能带警告，例如无有效 BOM → 60020 / MSG-PRD-020 */
  warnings?: WorkOrderWarning[] | null
}

/** 业务警告（backend WorkOrderReleased.Warning）。 */
export interface WorkOrderWarning {
  code: number
  msgId: string
  message: string
}

/** 工单类型（90-db-design prd_work_order.work_order_type）。 */
export const WORK_ORDER_TYPES = [
  { value: 10, label: '量产' },
  { value: 20, label: '试制' },
  { value: 30, label: '返工' },
  { value: 40, label: '拆分/合并生成' },
] as const

/** 工单状态（90-db-design prd_work_order.order_status）。 */
export const ORDER_STATUS_LABELS: Record<number, string> = {
  10: '草稿',
  20: '承認待ち',
  25: '承認済',
  30: '下达済',
  35: '製造中',
  40: '完工',
  90: '取消',
  95: '却下',
}

export const DEFAULT_ORDER_STATUS = 10
export const DEFAULT_WORK_ORDER_TYPE = 10
export const DEFAULT_PRIORITY_NO = 5

/** 生产域需要在画面上展示的 422 业务码（91-api-design §9）。 */
export const PRD_BUSINESS_CODES = [
  60001, 60021, 60022, 60040, 60056, 60100, 60101, 60102, 60103, 60104,
] as const

/** 业务码 → 关联的表单字段（用于在字段下方显示错误）。 */
export const PRD_CODE_FIELD: Partial<Record<number, keyof WorkOrderCreateRequest>> = {
  60001: 'materialId',
  60056: 'salesOrderLineId',
}

/** 后端未给消息文本时的默认提示。 */
export const PRD_CODE_DEFAULT_MESSAGE: Partial<Record<number, string>> = {
  /** 审批时无工序（CHK-PRD-002-08 / MSG-PRD-021） */
  60021: '至少需要 1 道工序',
  /** 物料单位与 BOM 单位不一致且无法换算（MSG-PRD-022，后端待实现） */
  60022: '物料单位与 BOM 单位不一致且无法换算',
}

/** 后端未给 msgId 时的默认 msgId。 */
export const MSG_ID_BY_CODE: Partial<Record<number, string>> = {
  60021: 'MSG-PRD-021',
  60022: 'MSG-PRD-022',
}

export const MSG_GENERIC_ERROR = '系统异常，请稍后重试或联系管理员'

export interface CreateErrorView {
  /** 页面顶部提示文本 */
  message: string
  /** 若可定位到字段则给出字段名 */
  field?: keyof WorkOrderCreateRequest
  kind: 'business' | 'validation' | 'generic'
}

/** 把 ApiError 转为画面展示用结构：422 业务码显示字段/消息，5000 等显示通用错误。 */
export function toCreateErrorView(err: unknown): CreateErrorView {
  if (err instanceof ApiError) {
    const code = err.code
    if (code !== undefined && (PRD_BUSINESS_CODES as readonly number[]).includes(code)) {
      const id = err.msgId ?? MSG_ID_BY_CODE[code] ?? String(code)
      const text = backendMessage(err) ?? PRD_CODE_DEFAULT_MESSAGE[code] ?? err.message
      return { kind: 'business', message: `[${id}] ${text}`, field: PRD_CODE_FIELD[code] }
    }
    if (code === 1001 || err.status === 400) {
      return { kind: 'validation', message: backendMessage(err) ?? err.message }
    }
    if (code !== undefined && code >= 10000 && code <= 99999) {
      const id = err.msgId ?? String(code)
      return { kind: 'business', message: `[${id}] ${backendMessage(err) ?? err.message}` }
    }
  }
  return { kind: 'generic', message: MSG_GENERIC_ERROR }
}

function backendMessage(err: ApiError): string | undefined {
  const d = err.data as { message?: unknown } | undefined
  return d && typeof d.message === 'string' && d.message ? d.message : undefined
}

/** 比率（0.0500）→ 百分比文本（5.00%）。null/非数值显示「—」。 */
export function formatRatePercent(rate: string | number | null | undefined, digits = 2): string {
  if (rate === null || rate === undefined || rate === '') return '—'
  const n = typeof rate === 'number' ? rate : Number(rate)
  if (!Number.isFinite(n)) return '—'
  return `${(n * 100).toFixed(digits)}%`
}

/** 请求体白名单（WorkOrderCreateCommand）。companyId / overReceiptRate 等不在其中，不会被发送。 */
const CREATE_REQUEST_KEYS: readonly (keyof WorkOrderCreateRequest)[] = [
  'workOrderType',
  'factoryId',
  'materialId',
  'orderQty',
  'uomCode',
  'plannedStartDate',
  'plannedEndDate',
  'priorityNo',
  'departmentId',
  'warehouseId',
  'salesOrderLineId',
  'isBackflush',
  'remark',
]

/** 仅保留白名单字段，并去掉空串可选字段，避免向后端传 "" 。 */
export function buildCreateRequest(form: WorkOrderCreateRequest): WorkOrderCreateRequest {
  const out: Record<string, unknown> = {}
  for (const k of CREATE_REQUEST_KEYS) {
    const v = form[k]
    if (v === '' || v === null || v === undefined) continue
    out[k] = typeof v === 'string' ? v.trim() : v
  }
  return out as unknown as WorkOrderCreateRequest
}

export async function createWorkOrder(body: WorkOrderCreateRequest): Promise<WorkOrderCreated> {
  const res = await http.post<ApiResult<WorkOrderCreated>>(
    '/production/work-orders',
    buildCreateRequest(body),
    { silent: true },
  )
  return res.data.data
}

/** 工单详细（backend WorkOrderDetail，GET /api/production/work-orders/{id}）。仅列出画面使用的字段。 */
export interface WorkOrderDetail {
  id: string | number
  workOrderNo: string
  workOrderType: number
  orderStatus: number
  statusName: string | null
  materialId: string | number
  materialCode: string
  materialName: string
  materialSpec: string | null
  uomCode: string
  factoryId: string | number
  departmentId: string | number | null
  warehouseId: string | number | null
  orderQty: string | number
  allowedQty: string | number | null
  completedQty: string | number | null
  plannedStartDate: string
  plannedEndDate: string
  priorityNo: number
  salesOrderLineId: string | number | null
  salesOrderNo: string | null
  overReceiptRate: string | number | null
  standardCost: string | number | null
  remark: string | null
  version: number
}

export async function getWorkOrder(id: string): Promise<WorkOrderDetail> {
  const res = await http.get<ApiResult<WorkOrderDetail>>(`/production/work-orders/${id}`)
  return res.data.data
}
