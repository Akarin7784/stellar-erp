import http, { type ApiResult } from '../http'

/**
 * MDM 选择器 API（backend/erp-mdm MdmLookupController / MdmLookupService，PR #32）。
 * 后端按当前租户・公司过滤，前端不传 companyId。
 */
export interface FactoryOption {
  id: string | number
  factoryCode: string
  factoryName: string
  plantType: number | null
}

export interface WarehouseOption {
  id: string | number
  warehouseCode: string
  warehouseName: string
  warehouseType: number
  factoryId: string | number
}

export interface MaterialOption {
  id: string | number
  materialCode: string
  materialName: string
  spec: string | null
  materialType: number
  baseUomCode: string | null
  unitId: string | number | null
  unitName: string | null
  status: number
}

export interface PageResult<T> {
  list: T[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

/** GET /api/mdm/factories */
/**
 * silent：失败时不弹全局提示，由画面自行显示（工单一览用下拉旁警告）。
 * resource：按业务资源取数据范围内工厂（如 'work-order'）；后端支持前忽略此参数。
 */
export async function listFactories(
  opts: { silent?: boolean; resource?: string } = {},
): Promise<FactoryOption[]> {
  const cfg: { silent?: boolean; params?: { resource: string } } = {}
  if (opts.silent) cfg.silent = true
  if (opts.resource) cfg.params = { resource: opts.resource }
  const res = await http.get<ApiResult<FactoryOption[]>>(
    '/mdm/factories',
    Object.keys(cfg).length ? cfg : undefined,
  )
  return res.data.data
}

/** GET /api/mdm/warehouses/options?factoryId= */
export async function listWarehouseOptions(factoryId?: string | null): Promise<WarehouseOption[]> {
  const params = factoryId ? { factoryId } : undefined
  const res = await http.get<ApiResult<WarehouseOption[]>>('/mdm/warehouses/options', { params })
  return res.data.data
}

/** GET /api/mdm/materials?keyword=&pageNum=&pageSize= */
export async function searchMaterials(
  keyword = '',
  pageNum = 1,
  pageSize = 20,
): Promise<PageResult<MaterialOption>> {
  const params: Record<string, unknown> = { pageNum, pageSize }
  if (keyword.trim()) params.keyword = keyword.trim()
  const res = await http.get<ApiResult<PageResult<MaterialOption>>>('/mdm/materials', { params })
  return res.data.data
}
