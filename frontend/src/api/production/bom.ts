import http, { ApiError, type ApiResult } from '../http'

/** 有効 BOM（backend BomQueryService.EffectiveBom，PR #32）。 */
export interface EffectiveBom {
  id: string | number
  bomNo: string
  materialId: string | number
  materialCode: string
  factoryId: string | number
  versionNo: number
  baseQty: string | number
  baseUomCode: string
  validFrom: string
  validTo: string | null
  isDefault: boolean
  lines: unknown[]
}

/** 有効 BOM なし（422 / MSG-PRD-020）。 */
export const CODE_BOM_NOT_FOUND = 60020

/**
 * GET /api/production/boms/effective?materialId&factoryId&date（三个参数都必填）。
 * 60020 → 返回 null（由画面提示「无有效 BOM」），其他错误继续抛出。
 */
export async function getEffectiveBom(
  materialId: string,
  factoryId: string,
  date: string,
): Promise<EffectiveBom | null> {
  try {
    const res = await http.get<ApiResult<EffectiveBom>>('/production/boms/effective', {
      params: { materialId, factoryId, date },
      silent: true,
    })
    return res.data.data
  } catch (e) {
    if (e instanceof ApiError && e.code === CODE_BOM_NOT_FOUND) return null
    throw e
  }
}
