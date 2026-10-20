import axios, { type AxiosError, type AxiosInstance } from 'axios'
import { ElMessage } from 'element-plus'

export interface ApiResult<T> {
  code: number
  message: string
  data: T
}

export const TOKEN_KEY = 'erp_token'

export const MSG_CONFLICT = '数据已被他人修改，请刷新后重试'
export const MSG_UNAUTHORIZED = '登录已失效，请重新登录'
export const MSG_SERVER_ERROR = '服务器异常，请稍后重试'
export const MSG_NETWORK_ERROR = '网络异常，请检查网络后重试'
export const MSG_TIMEOUT = '请求超时，请稍后重试'
export const MSG_REQUEST_FAILED = '请求失败'

/** 统一的接口错误，调用方可 `catch` 后按 status / code 分支处理。 */
export class ApiError extends Error {
  /** HTTP 状态码；业务错误（HTTP 200 + code≠0）或网络错误时为 undefined。 */
  readonly status?: number
  /** 后端业务错误码，Result.code（§6.1），如 4003、60001。 */
  readonly code?: number
  readonly data?: unknown

  constructor(message: string, opts: { status?: number; code?: number; data?: unknown } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = opts.status
    this.code = opts.code
    this.data = opts.data
  }
}

export interface BackendError {
  code?: number
  message?: string
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
} as const

/** 冲突类错误码（HTTP 409）：提示刷新后重试。 */
export const CONFLICT_CODES: readonly number[] = [
  ERROR_CODES.STATE_CONFLICT,
  ERROR_CODES.OPTIMISTIC_LOCK,
  ERROR_CODES.DUPLICATE_PROCESSING,
]

/** 领域业务规则错误码（HTTP 422）：10000-99999，按 §6.1 的各领域区间。 */
export function isDomainCode(code: number): boolean {
  return code >= 10000 && code <= 99999
}

/**
 * 从后端响应体 Result<T>{code,message,data} 中取出错误码和文案。
 * TODO: 后端 G2-18 会在群里贴出具体领域错误码及 code↔MSG-xxx 对照表；
 * 如需在前端显示 MSG 编号或调整字段名，只改这里。
 */
export function extractBackendError(body: unknown): BackendError {
  if (!body || typeof body !== 'object') return {}
  const b = body as Record<string, unknown>
  return {
    code: typeof b.code === 'number' ? b.code : undefined,
    message: typeof b.message === 'string' && b.message ? b.message : undefined,
  }
}

type ErrorKind = 'unauthorized' | 'conflict' | 'business' | 'server' | 'other'

/** 先按 code 判断，再按 HTTP 状态兜底（当前 GlobalExceptionHandler 对 BizException 返回 HTTP 200 + code）。 */
export function classifyError(status: number | undefined, code: number | undefined): ErrorKind {
  if (code !== undefined && code !== 0) {
    if (code === ERROR_CODES.UNAUTHENTICATED) return 'unauthorized'
    if (CONFLICT_CODES.includes(code)) return 'conflict'
    if (isDomainCode(code)) return 'business'
    if (code >= 5000 && code <= 5999) return 'server'
  }
  if (status === 401) return 'unauthorized'
  if (status === 409) return 'conflict'
  if (status === 422) return 'business'
  if (status !== undefined && status >= 500) return 'server'
  return 'other'
}

function notify(status: number | undefined, body: unknown, fallback?: string): ApiError {
  const { code, message } = extractBackendError(body)
  const opts = { status, code, data: body }
  let msg: string
  switch (classifyError(status, code)) {
    case 'unauthorized':
      // 目前还没有登录页，只清除 token，不做跳转
      localStorage.removeItem(TOKEN_KEY)
      msg = message || MSG_UNAUTHORIZED
      ElMessage.error(msg)
      break
    case 'conflict':
      msg = message ? `${MSG_CONFLICT}（${message}）` : MSG_CONFLICT
      ElMessage.warning(msg)
      break
    case 'business': {
      const text = message || MSG_REQUEST_FAILED
      msg = code !== undefined ? `[${code}] ${text}` : text
      ElMessage.error(msg)
      break
    }
    case 'server':
      msg = MSG_SERVER_ERROR
      ElMessage.error(msg)
      break
    default:
      msg = message || fallback || MSG_REQUEST_FAILED
      ElMessage.error(msg)
  }
  return new ApiError(msg, opts)
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
    ElMessage.error(msg)
    return new ApiError(msg)
  }
  return notify(response.status, response.data, error.message)
}

http.interceptors.response.use(
  (response) => {
    const result = response.data as ApiResult<unknown> | undefined
    if (result && typeof result.code === 'number' && result.code !== 0) {
      return Promise.reject(notify(response.status, result))
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
