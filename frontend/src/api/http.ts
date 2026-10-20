import axios, { type AxiosInstance } from 'axios'
import { ElMessage } from 'element-plus'

export interface ApiResult<T> {
  code: number
  message: string
  data: T
}

const http: AxiosInstance = axios.create({
  baseURL: '/api',
  timeout: 15000,
})

http.interceptors.request.use((config) => {
  const token = localStorage.getItem('erp_token')
  if (token) {
    config.headers.Authorization = token
  }
  return config
})

http.interceptors.response.use(
  (response) => {
    const result = response.data as ApiResult<unknown> | undefined
    if (result && typeof result.code === 'number' && result.code !== 0) {
      ElMessage.error(result.message || '请求失败')
      return Promise.reject(new Error(result.message || '请求失败'))
    }
    return response
  },
  (error: Error) => {
    ElMessage.error(error.message || '网络异常')
    return Promise.reject(error)
  },
)

export default http
