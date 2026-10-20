import type { AxiosAdapter, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { AxiosError } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('element-plus', () => ({
  ElMessage: { error: vi.fn(), warning: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

import { ElMessage } from 'element-plus'
import http, {
  ApiError,
  MSG_CONFLICT,
  MSG_NETWORK_ERROR,
  MSG_SERVER_ERROR,
  TOKEN_KEY,
} from './http'

function respond(status: number, data: unknown): AxiosAdapter {
  return (config: InternalAxiosRequestConfig) => {
    const response: AxiosResponse = { data, status, statusText: '', headers: {}, config }
    if (status >= 200 && status < 300) return Promise.resolve(response)
    return Promise.reject(
      new AxiosError(
        `Request failed with status code ${status}`,
        String(status),
        config,
        null,
        response,
      ),
    )
  }
}

async function catchError(adapter: AxiosAdapter): Promise<ApiError> {
  try {
    await http.get('/x', { adapter })
  } catch (e) {
    return e as ApiError
  }
  throw new Error('expected rejection')
}

describe('http 错误处理', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('成功响应原样返回', async () => {
    const res = await http.get('/x', { adapter: respond(200, { code: 0, message: 'ok', data: 1 }) })
    expect(res.data.data).toBe(1)
    expect(ElMessage.error).not.toHaveBeenCalled()
  })

  it('409 提示刷新后重试并附带后端文案', async () => {
    const err = await catchError(respond(409, { code: 4003, message: '他人已更新', data: null }))
    expect(err).toBeInstanceOf(ApiError)
    expect(err.status).toBe(409)
    expect(ElMessage.warning).toHaveBeenCalledWith(`${MSG_CONFLICT}（他人已更新）`)
  })

  it('409 无响应体时只显示通用提示', async () => {
    await catchError(respond(409, ''))
    expect(ElMessage.warning).toHaveBeenCalledWith(MSG_CONFLICT)
  })

  it('422 显示 MSG 编号和文案', async () => {
    const err = await catchError(respond(422, { code: 50001, message: '库存不足', data: null }))
    expect(err.status).toBe(422)
    expect(err.code).toBe(50001)
    expect(ElMessage.error).toHaveBeenCalledWith('[50001] 库存不足')
  })

  it('HTTP 200 + code=4003（现行 BizException）按冲突处理', async () => {
    const err = await catchError(respond(200, { code: 4003, message: '', data: null }))
    expect(err.code).toBe(4003)
    expect(ElMessage.warning).toHaveBeenCalledWith(MSG_CONFLICT)
  })

  it.each([4002, 4005])('HTTP 200 + code=%i 按冲突处理', async (code) => {
    await catchError(respond(200, { code, message: '状态已变化', data: null }))
    expect(ElMessage.warning).toHaveBeenCalledWith(`${MSG_CONFLICT}（状态已变化）`)
  })

  it('HTTP 200 + 领域码按业务规则错误显示', async () => {
    await catchError(respond(200, { code: 60001, message: 'BOM 循环参照', data: null }))
    expect(ElMessage.error).toHaveBeenCalledWith('[60001] BOM 循环参照')
  })

  it('HTTP 200 + code=2001 清除 token', async () => {
    localStorage.setItem(TOKEN_KEY, 'abc')
    await catchError(respond(200, { code: 2001, message: '未登录', data: null }))
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
  })

  it('HTTP 200 且 code≠0 按业务错误处理', async () => {
    const err = await catchError(respond(200, { code: 1001, message: '物料不存在', data: null }))
    expect(err).toBeInstanceOf(ApiError)
    expect(err.code).toBe(1001)
    expect(ElMessage.error).toHaveBeenCalledWith('物料不存在')
  })

  it('网络错误显示通用提示', async () => {
    const adapter: AxiosAdapter = (config) =>
      Promise.reject(new AxiosError('Network Error', AxiosError.ERR_NETWORK, config))
    const err = await catchError(adapter)
    expect(err.message).toBe(MSG_NETWORK_ERROR)
    expect(ElMessage.error).toHaveBeenCalledWith(MSG_NETWORK_ERROR)
  })

  it('5xx 显示通用提示', async () => {
    await catchError(respond(500, { message: 'NullPointerException' }))
    expect(ElMessage.error).toHaveBeenCalledWith(MSG_SERVER_ERROR)
  })

  it('401 清除 erp_token', async () => {
    localStorage.setItem(TOKEN_KEY, 'abc')
    const err = await catchError(respond(401, { code: 2001, message: '未登录', data: null }))
    expect(err.status).toBe(401)
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
  })
})
