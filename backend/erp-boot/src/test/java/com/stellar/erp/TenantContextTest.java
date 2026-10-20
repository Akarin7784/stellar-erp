package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import com.stellar.erp.common.TenantContext;

/** 没有默认租户：未设置时必须抛异常，不得回落到 0。 */
class TenantContextTest {

    @AfterEach
    void clear() {
        TenantContext.clear();
    }

    @Test
    void currentTenantIdWithoutContextThrows() {
        assertThat(TenantContext.current()).isEmpty();
        assertThatThrownBy(TenantContext::currentTenantId).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void callAsRestoresPreviousState() {
        assertThat(TenantContext.callAs(7L, TenantContext::currentTenantId)).isEqualTo(7L);
        assertThat(TenantContext.current()).isEmpty();
    }
}
