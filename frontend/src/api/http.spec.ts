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
  MSG_FORBIDDEN,
  MSG_STATE_CONFLICT,
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

  it('HTTP 409 无 code 时显示后端 message', async () => {
    await catchError(respond(409, { message: '单据已审核' }))
    expect(ElMessage.error).toHaveBeenCalledWith('单据已审核')
    expect(ElMessage.warning).not.toHaveBeenCalled()
  })

  it('HTTP 409 无响应体时显示通用状态冲突提示', async () => {
    await catchError(respond(409, ''))
    expect(ElMessage.error).toHaveBeenCalledWith(MSG_STATE_CONFLICT)
    expect(MSG_STATE_CONFLICT).not.toContain('刷新')
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

  it.each([4002, 4005])('code=%i 显示后端 message', async (code) => {
    await catchError(respond(409, { code, message: '处理中，请稍后再试', data: null }))
    expect(ElMessage.error).toHaveBeenCalledWith('处理中，请稍后再试')
    expect(ElMessage.warning).not.toHaveBeenCalled()
  })

  it('HTTP 409 + 领域码（如 70127）只显示 message，不弹刷新提示', async () => {
    const err = await catchError(
      respond(409, { code: 70127, message: '损益转记已执行', data: null }),
    )
    expect(err.status).toBe(409)
    expect(err.code).toBe(70127)
    expect(ElMessage.error).toHaveBeenCalledWith('损益转记已执行')
    expect(ElMessage.warning).not.toHaveBeenCalled()
  })

  it.each([4002, 4005])('code=%i 无 message 时显示通用文案', async (code) => {
    await catchError(respond(200, { code, message: '', data: null }))
    expect(ElMessage.error).toHaveBeenCalledWith(MSG_STATE_CONFLICT)
  })

  it('422 有 msgId 时显示 [msgId] message 并带入 ApiError', async () => {
    const err = await catchError(
      respond(422, { code: 60040, msgId: 'MSG-PRD-040', message: '超出超入库容许率', data: null }),
    )
    expect(err.msgId).toBe('MSG-PRD-040')
    expect(err.code).toBe(60040)
    expect(ElMessage.error).toHaveBeenCalledWith('[MSG-PRD-040] 超出超入库容许率')
  })

  it('msgId 为 null 时回退为 [code] message', async () => {
    const err = await catchError(
      respond(200, { code: 50001, msgId: null, message: '库存不足', data: null }),
    )
    expect(err.msgId).toBeUndefined()
    expect(ElMessage.error).toHaveBeenCalledWith('[50001] 库存不足')
  })

  it('silent: true 不弹提示但仍 reject ApiError', async () => {
    const cases = [
      respond(422, { code: 50001, message: '库存不足', data: null }),
      respond(200, { code: 4003, message: '', data: null }),
      (config: InternalAxiosRequestConfig) =>
        Promise.reject(new AxiosError('Network Error', AxiosError.ERR_NETWORK, config)),
    ] as AxiosAdapter[]
    for (const adapter of cases) {
      await expect(http.get('/x', { adapter, silent: true })).rejects.toBeInstanceOf(ApiError)
    }
    expect(ElMessage.error).not.toHaveBeenCalled()
    expect(ElMessage.warning).not.toHaveBeenCalled()
  })

  it('3xxx / HTTP 403 显示无权限', async () => {
    await catchError(respond(200, { code: 3001, message: '缺少审批权限', data: null }))
    expect(ElMessage.error).toHaveBeenCalledWith(`${MSG_FORBIDDEN}（缺少审批权限）`)
    await catchError(respond(403, ''))
    expect(ElMessage.error).toHaveBeenCalledWith(MSG_FORBIDDEN)
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

describe('业务码 10035 / 20077（HTTP 422）', () => {
  beforeEach(() => vi.clearAllMocks())

  it('10035：显示后端 message 与 msgId，不弹刷新提示', async () => {
    const message = '公司代码「C01」或统一社会信用代码已存在，请使用其他代码。'
    const err = await catchError(
      respond(422, { code: 10035, message, data: null, msgId: 'MSG-SYS-093' }),
    )
    expect(err.status).toBe(422)
    expect(err.code).toBe(10035)
    expect(err.message).toBe(`[MSG-SYS-093] ${message}`)
    expect(ElMessage.error).toHaveBeenCalledWith(`[MSG-SYS-093] ${message}`)
    expect(ElMessage.warning).not.toHaveBeenCalled()
  })

  it('10035：缺 msgId 时按 code 补 MSG-SYS-093，message 仍用后端', async () => {
    const err = await catchError(
      respond(422, { code: 10035, message: '重复', data: null, msgId: null }),
    )
    expect(err.message).toBe('[MSG-SYS-093] 重复')
    expect(err.msgId).toBeUndefined()
  })

  it('20077：显示后端 message 与 msgId', async () => {
    const err = await catchError(
      respond(422, { code: 20077, message: '期间重复', data: null, msgId: 'MSG-MDM-178' }),
    )
    expect(err.message).toBe('[MSG-MDM-178] 期间重复')
    expect(ElMessage.error).toHaveBeenCalledWith('[MSG-MDM-178] 期间重复')
  })

  it('20077：缺 message/msgId 时用中文默认文案', async () => {
    const err = await catchError(
      respond(422, { code: 20077, message: '', data: null, msgId: null }),
    )
    expect(err.message).toBe('[MSG-MDM-178] 有效期与已有换算率重叠，请调整有效期。')
  })

  it('10035 缺 message 时退回通用文案（不自造含占位符的文案）', async () => {
    const err = await catchError(
      respond(422, { code: 10035, message: '', data: null, msgId: null }),
    )
    expect(err.message).toBe('[MSG-SYS-093] 请求失败')
  })

  it('其他 422 业务码不受影响', async () => {
    const err = await catchError(
      respond(422, { code: 10001, message: '已存在', data: null, msgId: 'MSG-COM-050' }),
    )
    expect(err.message).toBe('[MSG-COM-050] 已存在')
  })
})
