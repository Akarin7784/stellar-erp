import axios, { type AxiosError, type AxiosInstance } from 'axios'
import { ElMessage } from 'element-plus'

declare module 'axios' {
  interface AxiosRequestConfig {
    /** 为 true 时拦截器不弹 ElMessage，但仍 reject ApiError，由调用方自行提示。 */
    silent?: boolean
  }
}

export interface ApiResult<T> {
  code: number
  message: string
  data: T
  /** 消息 ID，如 MSG-PRD-040（可选，可为 null）。 */
  msgId?: string | null
}

export const TOKEN_KEY = 'erp_token'

let unauthorizedHandler: (() => void) | null = null

/** 注册 2001（HTTP 401）时的处理（由 router 注册：跳转登录页）。 */
export function setUnauthorizedHandler(fn: (() => void) | null): void {
  unauthorizedHandler = fn
}

export const MSG_CONFLICT = '数据已被他人修改，请刷新后重试'
export const MSG_STATE_CONFLICT = '操作未能完成，数据状态不允许此操作'
export const MSG_FORBIDDEN = '没有权限执行此操作'
export const MSG_UNAUTHORIZED = '登录已失效，请重新登录'
export const MSG_SERVER_ERROR = '服务器异常，请稍后重试'
export const MSG_NETWORK_ERROR = '网络异常，请检查网络后重试'
export const MSG_TIMEOUT = '请求超时，请稍后重试'
export const MSG_REQUEST_FAILED = '请求失败'

export interface ApiErrorOptions {
  status?: number
  code?: number
  msgId?: string
  data?: unknown
}

/** 统一的接口错误，调用方可 `catch` 后按 status / code / msgId 分支处理。 */
export class ApiError extends Error {
  /** HTTP 状态码；网络错误时为 undefined。 */
  readonly status?: number
  /** 后端业务错误码，Result.code（§6.1），如 4003、60001。 */
  readonly code?: number
  /** 后端消息 ID，如 MSG-PRD-040。 */
  readonly msgId?: string
  readonly data?: unknown

  constructor(message: string, opts: ApiErrorOptions = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = opts.status
    this.code = opts.code
    this.msgId = opts.msgId
    this.data = opts.data
  }
}

export interface BackendError {
  code?: number
  message?: string
  msgId?: string
}

/**
 * 业务错误码，依据 docs/design/00-common/03-common-api-spec.md §6.1 / §6.2 / §9 / §10。
 */
export const ERROR_CODES = {
  UNAUTHENTICATED: 2001,
  STATE_CONFLICT: 4002,
  OPTIMISTIC_LOCK: 4003,
  DUPLICATE_PROCESSING: 4005,
  SYSTEM_ERROR: 5000,
  SERVICE_UNAVAILABLE: 5001,
  RATE_LIMITED: 5002,
  /** 公司代码・统一社会信用代码重复（公司登録）：HTTP 422 / MSG-SYS-093（01-system/91-api-design.md §1.1、93-messages.md:70）。 */
  COMPANY_DUPLICATE: 10035,
  /** 单位换算率有效期间重复：HTTP 422 / MSG-MDM-178（02-mdm/91-api-design.md §4.1、93-messages.md:113）。 */
  UOM_CONVERSION_PERIOD_OVERLAP: 20077,
} as const

/** 后端未给 msgId 时按 code 补的消息 ID（只收录设计文档已定义的）。 */
export const MSG_ID_BY_CODE: Partial<Record<number, string>> = {
  [ERROR_CODES.COMPANY_DUPLICATE]: 'MSG-SYS-093',
  [ERROR_CODES.UOM_CONVERSION_PERIOD_OVERLAP]: 'MSG-MDM-178',
}

/**
 * 后端未给 message 时的默认文案（中文，译自 93-messages.md）。
 * 10035 的文案含占位符「{0}」（公司代码），前端无法补全，故不设默认，依赖后端 message。
 */
export const DEFAULT_MESSAGE_BY_CODE: Partial<Record<number, string>> = {
  [ERROR_CODES.UOM_CONVERSION_PERIOD_OVERLAP]: '有效期与已有换算率重叠，请调整有效期。',
}

/** 状态冲突类错误码（HTTP 422，非乐观锁；409 只用于 4003 版本冲突）：显示后端 message。 */
export const STATE_CONFLICT_CODES: readonly number[] = [
  ERROR_CODES.STATE_CONFLICT,
  ERROR_CODES.DUPLICATE_PROCESSING,
]

/** 领域业务规则错误码（HTTP 422）：10000-99999，按 §6.1 的各领域区间。 */
export function isDomainCode(code: number): boolean {
  return code >= 10000 && code <= 99999
}

/**
 * 从后端响应体 Result<T>{code,message,data} 中取出错误码和文案。
 * msgId 为可选字段（后端 PR #39 / 规范更新）。
 * TODO: 后端会在群里贴出最终领域错误码；字段名如有调整只改这里。
 */
export function extractBackendError(body: unknown): BackendError {
  if (!body || typeof body !== 'object') return {}
  const b = body as Record<string, unknown>
  return {
    code: typeof b.code === 'number' ? b.code : undefined,
    message: typeof b.message === 'string' && b.message ? b.message : undefined,
    msgId: typeof b.msgId === 'string' && b.msgId ? b.msgId : undefined,
  }
}

type ErrorKind =
  | 'unauthorized'
  | 'forbidden'
  | 'optimisticLock'
  | 'stateConflict'
  | 'business'
  | 'server'
  | 'other'

/** 先按 code 判断，再按 HTTP 状态兜底（当前 GlobalExceptionHandler 对 BizException 返回 HTTP 200 + code）。 */
export function classifyError(status: number | undefined, code: number | undefined): ErrorKind {
  if (code !== undefined && code !== 0) {
    if (code === ERROR_CODES.OPTIMISTIC_LOCK) return 'optimisticLock'
    // HTTP 409 只有 4003（MSG-COM-033 版本冲突）弹刷新提示，其余 409 一律显示后端 message
    if (status === 409 && code !== ERROR_CODES.UNAUTHENTICATED && !(code >= 3000 && code <= 3999))
      return 'stateConflict'
    if (code === ERROR_CODES.UNAUTHENTICATED) return 'unauthorized'
    if (code >= 3000 && code <= 3999) return 'forbidden'
    if (STATE_CONFLICT_CODES.includes(code)) return 'stateConflict'
    if (isDomainCode(code)) return 'business'
    if (code >= 5000 && code <= 5999) return 'server'
  }
  if (status === 401) return 'unauthorized'
  if (status === 403) return 'forbidden'
  if (status === 409) return 'stateConflict'
  if (status === 422) return 'business'
  if (status !== undefined && status >= 500) return 'server'
  return 'other'
}

function notify(
  status: number | undefined,
  body: unknown,
  silent: boolean,
  fallback?: string,
): ApiError {
  const { code, message, msgId } = extractBackendError(body)
  let msg: string
  let level: 'error' | 'warning' = 'error'
  switch (classifyError(status, code)) {
    case 'unauthorized':
      localStorage.removeItem(TOKEN_KEY)
      unauthorizedHandler?.()
      msg = message || MSG_UNAUTHORIZED
      break
    case 'forbidden':
      msg = message ? `${MSG_FORBIDDEN}（${message}）` : MSG_FORBIDDEN
      break
    case 'optimisticLock':
      msg = message ? `${MSG_CONFLICT}（${message}）` : MSG_CONFLICT
      level = 'warning'
      break
    case 'stateConflict':
      // 非版本冲突：不弹刷新提示，直接显示后端 message
      msg = message || MSG_STATE_CONFLICT
      break
    case 'business': {
      const text =
        message || (code !== undefined && DEFAULT_MESSAGE_BY_CODE[code]) || MSG_REQUEST_FAILED
      const id = msgId ?? (code !== undefined ? MSG_ID_BY_CODE[code] : undefined) ?? code
      msg = id !== undefined ? `[${id}] ${text}` : text
      break
    }
    case 'server':
      msg = MSG_SERVER_ERROR
      break
    default:
      msg = message || fallback || MSG_REQUEST_FAILED
  }
  if (!silent) ElMessage[level](msg)
  return new ApiError(msg, { status, code, msgId, data: body })
}

const http: AxiosInstance = axios.create({
  baseURL: '/api',
  timeout: 15000,
})

http.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers.Authorization = token
  }
  return config
})

function handleHttpError(error: AxiosError): ApiError {
  const response = error.response
  if (!response) {
    const timeout = error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT'
    const msg = timeout ? MSG_TIMEOUT : MSG_NETWORK_ERROR
    if (!error.config?.silent) ElMessage.error(msg)
    return new ApiError(msg)
  }
  return notify(response.status, response.data, !!error.config?.silent, error.message)
}

http.interceptors.response.use(
  (response) => {
    const result = response.data as ApiResult<unknown> | undefined
    if (result && typeof result.code === 'number' && result.code !== 0) {
      return Promise.reject(notify(response.status, result, !!response.config.silent))
    }
    return response
  },
  (error: unknown) => {
    if (axios.isAxiosError(error)) {
      return Promise.reject(handleHttpError(error))
    }
    const msg = (error instanceof Error && error.message) || MSG_NETWORK_ERROR
    ElMessage.error(msg)
    return Promise.reject(error)
  },
)

export default http
