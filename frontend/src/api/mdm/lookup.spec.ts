import { afterEach, describe, expect, it, vi } from 'vitest'

import http from '../http'
import { listFactories } from './lookup'

const ok = (data: unknown) => ({ data: { code: 0, message: 'ok', data, msgId: null } })

describe('listFactories', () => {
  afterEach(() => vi.restoreAllMocks())

  it('无参数时不带 config（既有调用不变）', async () => {
    const get = vi.spyOn(http, 'get').mockResolvedValue(ok([]))
    await listFactories()
    expect(get).toHaveBeenCalledWith('/mdm/factories', undefined)
  })

  it('silent + resource：带 silent 与 params.resource', async () => {
    const get = vi.spyOn(http, 'get').mockResolvedValue(ok([]))
    await listFactories({ silent: true, resource: 'work-order' })
    expect(get).toHaveBeenCalledWith('/mdm/factories', {
      silent: true,
      params: { resource: 'work-order' },
    })
  })
})
