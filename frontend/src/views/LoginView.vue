<template>
  <div class="login">
    <el-card class="login__card" shadow="always">
      <template #header>
        <div class="login__title">用户登录</div>
      </template>
      <el-alert
        v-if="formError"
        class="login__alert"
        data-test="form-error"
        type="error"
        :title="formError"
        :closable="false"
        show-icon
      />
      <el-form label-width="80px" @submit.prevent="onSubmit">
        <el-form-item label="企业代码" :error="errors.tenantCode" data-test="item-tenantCode">
          <el-input
            ref="tenantCodeRef"
            v-model="form.tenantCode"
            name="tenantCode"
            autocomplete="organization"
            :maxlength="LOGIN_MAX_LENGTH.tenantCode"
            :input-style="{ imeMode: 'disabled' }"
            @input="onTenantInput"
          />
        </el-form-item>
        <el-form-item label="账号" :error="errors.username" data-test="item-username">
          <el-input
            ref="usernameRef"
            v-model="form.username"
            name="username"
            autocomplete="username"
            :maxlength="LOGIN_MAX_LENGTH.username"
            :input-style="{ imeMode: 'disabled' }"
          />
        </el-form-item>
        <el-form-item label="密码" :error="errors.password" data-test="item-password">
          <el-input
            ref="passwordRef"
            v-model="form.password"
            name="password"
            type="password"
            autocomplete="current-password"
            show-password
            :maxlength="LOGIN_MAX_LENGTH.password"
          />
        </el-form-item>
        <!-- 验证码（BR-05 / §4.4 No.3-4）：后端 captcha API 未实现，后续 PR 接入，这里只留插槽，不传给登录 API -->
        <slot name="captcha" />
        <el-form-item>
          <el-button
            type="primary"
            native-type="submit"
            class="login__submit"
            data-test="submit"
            :loading="submitting"
          >
            登 录
          </el-button>
        </el-form-item>
        <div class="login__hint">忘记密码？请联系系统管理员</div>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { ApiError, MSG_REQUEST_FAILED, extractBackendError } from '@/api/http'
import { login, type FieldError } from '@/api/system/auth'
import { useAuthStore } from '@/stores/auth'
import {
  LOGIN_FIELDS,
  LOGIN_MAX_LENGTH,
  TENANT_CODE_STORAGE_KEY,
  normalizeTenantCode,
  validateLoginForm,
  type LoginField,
} from '@/views/system/loginRules'

/** 03 §6.1：入力チェック失敗。 */
const CODE_PARAM_INVALID = 1001

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const form = reactive<Record<LoginField, string>>({
  tenantCode: localStorage.getItem(TENANT_CODE_STORAGE_KEY) ?? '',
  username: '',
  password: '',
})
const errors = reactive<Partial<Record<LoginField, string>>>({})
const formError = ref('')
const submitting = ref(false)

const tenantCodeRef = ref<{ focus: () => void } | null>(null)
const usernameRef = ref<{ focus: () => void } | null>(null)
const passwordRef = ref<{ focus: () => void } | null>(null)
const refs = { tenantCode: tenantCodeRef, username: usernameRef, password: passwordRef }

function focus(field: LoginField) {
  nextTick(() => refs[field].value?.focus())
}

function onTenantInput(v: string) {
  form.tenantCode = normalizeTenantCode(v)
}

function resetErrors() {
  for (const f of LOGIN_FIELDS) delete errors[f]
  formError.value = ''
}

/** 1001：data.fieldErrors[] 按表单顺序映射到各字段，聚焦第一个。 */
function applyFieldErrors(list: FieldError[]): boolean {
  let first: LoginField | null = null
  for (const fe of list) {
    if ((LOGIN_FIELDS as readonly string[]).includes(fe.field)) {
      const f = fe.field as LoginField
      if (!errors[f]) errors[f] = fe.message
      if (!first) first = f
    }
  }
  if (first) focus(first)
  return first !== null
}

function extractFieldErrors(body: unknown): FieldError[] {
  const data = (body as { data?: { fieldErrors?: unknown } } | null)?.data
  return Array.isArray(data?.fieldErrors) ? (data.fieldErrors as FieldError[]) : []
}

async function onSubmit() {
  if (submitting.value) return
  resetErrors()
  const clientErrors = validateLoginForm(form)
  const firstInvalid = LOGIN_FIELDS.find((f) => clientErrors[f])
  if (firstInvalid) {
    Object.assign(errors, clientErrors)
    focus(firstInvalid)
    return
  }
  submitting.value = true
  try {
    const result = await login({ ...form })
    auth.setToken(result.token)
    localStorage.setItem(TENANT_CODE_STORAGE_KEY, form.tenantCode)
    const me = await auth.fetchMe()
    if (me.menus.length === 0) {
      await router.replace({ name: 'no-permission' })
    } else {
      const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
      await router.replace(redirect.startsWith('/') && !redirect.startsWith('//') ? redirect : '/')
    }
  } catch (e) {
    if (e instanceof ApiError) {
      if (e.code === CODE_PARAM_INVALID && applyFieldErrors(extractFieldErrors(e.data))) return
      // 登录页原样显示后端 message（BR-15，含 4003），不加全局前缀 / 刷新提示
      formError.value = extractBackendError(e.data).message || e.message || MSG_REQUEST_FAILED
    } else {
      formError.value = MSG_REQUEST_FAILED
    }
  } finally {
    submitting.value = false
  }
}

onMounted(() => focus(form.tenantCode ? 'username' : 'tenantCode'))
</script>

<style scoped lang="scss">
.login {
  display: flex;
  height: 100%;
  min-height: 100vh;
  align-items: center;
  justify-content: center;
  background: #f0f2f5;

  &__card {
    width: 420px;
  }

  &__title {
    font-size: 18px;
    font-weight: 600;
  }

  &__alert {
    margin-bottom: 16px;
  }

  &__submit {
    width: 100%;
  }

  &__hint {
    color: #909399;
    font-size: 12px;
    text-align: center;
  }
}
</style>
