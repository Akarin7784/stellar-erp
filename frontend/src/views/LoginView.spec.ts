import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'

import { ApiError, TOKEN_KEY } from '@/api/http'

const replace = vi.fn()
const query: Record<string, string> = {}
vi.mock('vue-router', () => ({
  useRouter: () => ({ replace, push: vi.fn() }),
  useRoute: () => ({ query }),
}))

const login = vi.fn()
const getMe = vi.fn()
vi.mock('@/api/system/auth', () => ({
  login: (...a: unknown[]) => login(...a),
  getMe: (...a: unknown[]) => getMe(...a),
  logout: vi.fn(),
}))

import LoginView from './LoginView.vue'

const ME = {
  userInfo: { id: '1', username: 'admin', nickname: null },
  companyId: '1',
  roles: [],
  permissions: [],
  menus: [
    {
      id: '1',
      parentId: '0',
      menuType: 2,
      menuCode: 'SYS_USER',
      routePath: 'system/users',
      sortNo: 1,
    },
  ],
}

function mountView() {
  return mount(LoginView, { global: { plugins: [ElementPlus] }, attachTo: document.body })
}

async function fill(w: ReturnType<typeof mountView>, t: string, u: string, p: string) {
  await w.find('input[name="tenantCode"]').setValue(t)
  await w.find('input[name="username"]').setValue(u)
  await w.find('input[name="password"]').setValue(p)
}

async function submit(w: ReturnType<typeof mountView>) {
  await w.find('form').trigger('submit')
  await flushPromises()
  // el-form-item 的错误状态有 100ms debounce（validateStateDebounced）
  await new Promise((r) => setTimeout(r, 150))
  await nextTick()
}

const itemError = (w: ReturnType<typeof mountView>, f: string) =>
  w.find(`[data-test="item-${f}"] .el-form-item__error`).exists()
    ? w.find(`[data-test="item-${f}"] .el-form-item__error`).text()
    : ''

describe('LoginView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    vi.clearAllMocks()
    for (const k of Object.keys(query)) delete query[k]
    document.body.innerHTML = ''
  })

  it('从 localStorage 恢复企业代码，输入转大写', async () => {
    localStorage.setItem('stellar.login.tenantCode', 'HDJM')
    const w = mountView()
    const input = w.find('input[name="tenantCode"]')
    expect((input.element as HTMLInputElement).value).toBe('HDJM')
    await input.setValue('abc1')
    expect((input.element as HTMLInputElement).value).toBe('ABC1')
  })

  it('客户端校验失败时不调用 API，并显示各字段错误', async () => {
    const w = mountView()
    await fill(w, 'HD-JM', '', '')
    await submit(w)
    expect(login).not.toHaveBeenCalled()
    expect(itemError(w, 'tenantCode')).toBe('「企业代码」只能输入半角英数字。')
    expect(itemError(w, 'username')).toBe('请输入必填项「账号」。')
    expect(itemError(w, 'password')).toBe('请输入必填项「密码」。')
    expect(document.activeElement).toBe(w.find('input[name="tenantCode"]').element)
  })

  it('成功：保存 token 与企业代码，调用 /auth/me 后跳转 redirect', async () => {
    query.redirect = '/system/users'
    login.mockResolvedValue({ token: 'tok', menus: [] })
    getMe.mockResolvedValue(ME)
    const w = mountView()
    await fill(w, 'hdjm', 'admin', 'secret')
    await submit(w)
    expect(login).toHaveBeenCalledWith({
      tenantCode: 'HDJM',
      username: 'admin',
      password: 'secret',
    })
    expect(localStorage.getItem(TOKEN_KEY)).toBe('tok')
    expect(localStorage.getItem('stellar.login.tenantCode')).toBe('HDJM')
    expect(getMe).toHaveBeenCalled()
    expect(replace).toHaveBeenCalledWith('/system/users')
  })

  it('外部 redirect 不跳转', async () => {
    query.redirect = '//evil.example.com'
    login.mockResolvedValue({ token: 'tok' })
    getMe.mockResolvedValue(ME)
    const w = mountView()
    await fill(w, 'HDJM', 'admin', 'secret')
    await submit(w)
    expect(replace).toHaveBeenCalledWith('/')
  })

  it('登录成功但 /auth/me 失败：清除 token，留在登录页并显示 message', async () => {
    login.mockResolvedValue({ token: 'tok' })
    getMe.mockRejectedValue(
      new ApiError('x', {
        status: 500,
        code: 5000,
        data: { code: 5000, message: '系统异常', data: null, msgId: null },
      }),
    )
    const w = mountView()
    await fill(w, 'HDJM', 'admin', 'secret')
    await submit(w)
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
    expect(replace).not.toHaveBeenCalled()
    expect(w.find('[data-test="form-error"]').text()).toBe('系统异常')
  })

  it('menus=[] 跳转到暂无权限页', async () => {
    login.mockResolvedValue({ token: 'tok' })
    getMe.mockResolvedValue({ ...ME, menus: [] })
    const w = mountView()
    await fill(w, 'HDJM', 'admin', 'secret')
    await submit(w)
    expect(replace).toHaveBeenCalledWith({ name: 'no-permission' })
  })

  it('1001：fieldErrors 映射到字段并聚焦第一个', async () => {
    login.mockRejectedValue(
      new ApiError('[MSG-COM-087] x', {
        status: 200,
        code: 1001,
        data: {
          code: 1001,
          message: '「账号」只能输入半角英数字。',
          msgId: 'MSG-COM-087',
          data: {
            fieldErrors: [
              { field: 'username', message: '「账号」只能输入半角英数字。' },
              { field: 'password', message: '请输入必填项「密码」。' },
            ],
          },
        },
      }),
    )
    const w = mountView()
    await fill(w, 'HDJM', 'admin', 'secret')
    await submit(w)
    expect(itemError(w, 'tenantCode')).toBe('')
    expect(itemError(w, 'username')).toBe('「账号」只能输入半角英数字。')
    expect(itemError(w, 'password')).toBe('请输入必填项「密码」。')
    expect(w.find('[data-test="form-error"]').exists()).toBe(false)
    expect(document.activeElement).toBe(w.find('input[name="username"]').element)
  })

  it.each([
    [2002, '企业代码、账号或密码错误'],
    [4003, '数据已被他人修改'],
    [10900, '账号已停用'],
  ])('code=%i：原样显示后端 message，不加前缀', async (code, message) => {
    login.mockRejectedValue(
      new ApiError(`prefixed ${message}`, {
        status: 200,
        code,
        data: { code, message, data: null, msgId: null },
      }),
    )
    const w = mountView()
    await fill(w, 'HDJM', 'admin', 'secret')
    await submit(w)
    expect(w.find('[data-test="form-error"]').text()).toBe(message)
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull()
    expect(replace).not.toHaveBeenCalled()
  })
})
