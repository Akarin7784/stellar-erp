import http, { type ApiResult } from '@/api/http'

/** 01-system 01-auth-login.md §7.1 / AuthController（#71）。 */
export interface LoginParams {
  tenantCode: string
  username: string
  password: string
}

export interface UserInfo {
  id: string
  username: string
  nickname: string | null
}

export interface RoleInfo {
  roleCode: string
  roleName: string
}

/** /auth/me 的 menus[]：扁平数组，parentId '0' 为根（01-auth-login.md §7.1；backend AuthMeService.MenuInfo）。 */
export interface MenuInfo {
  id: string
  parentId: string
  menuType: number
  menuCode: string
  /** sys_menu.menu_name（侧边栏显示名） */
  menuName: string
  routePath: string | null
  sortNo: number
  /** sys_menu.is_visible；false 时不在侧边栏显示（路由与权限检查不变） */
  isVisible: boolean
}

export interface LoginResult {
  token: string
  tokenName: string
  expiresIn: number
  passwordResetRequired: boolean
  userInfo: UserInfo
  roles: RoleInfo[]
  permissions: string[]
  menus: MenuInfo[]
}

export interface MeResult {
  userInfo: UserInfo
  companyId: string
  roles: RoleInfo[]
  permissions: string[]
  menus: MenuInfo[]
}

/** 1001 的 data（03 §5.3）。 */
export interface FieldError {
  field: string
  message: string
}

/**
 * 登录：失败一律 HTTP 200 + body code（BR-15），由拦截器 reject ApiError。
 * silent：不弹全局提示（含 4003 刷新提示），由登录页自行显示 message。
 */
export async function login(params: LoginParams): Promise<LoginResult> {
  const res = await http.post<ApiResult<LoginResult>>('/system/auth/login', params, {
    silent: true,
  })
  return res.data.data
}

export async function logout(): Promise<void> {
  await http.post('/system/auth/logout', undefined, { silent: true })
}

export async function getMe(): Promise<MeResult> {
  const res = await http.get<ApiResult<MeResult>>('/system/auth/me')
  return res.data.data
}
