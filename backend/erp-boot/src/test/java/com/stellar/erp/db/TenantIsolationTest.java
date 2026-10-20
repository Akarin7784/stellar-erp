package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/** 租户隔离：租户 A 不能读 / 改 / 删 / 写入租户 B 的行；无租户上下文时报错而非返回全部行。 */
@DbIntegrationTest
class TenantIsolationTest {

    static final long A = 101L;
    static final long B = 202L;

    @Autowired
    JdbcTemplate jdbc;          // 应用数据源（erp_app）

    @Autowired
    TransactionTemplate tx;

    @Autowired
    PostgreSQLContainer pg;

    @BeforeEach
    void seed() {
        JdbcTemplate owner = OwnerJdbc.of(pg);
        owner.update("DELETE FROM sys_user WHERE tenant_id IN (?, ?)", A, B);
        // owner 插入必须显式指定 tenant_id（列默认值依赖 app.tenant_id）
        owner.update("INSERT INTO sys_user (id, tenant_id, username, password) VALUES (?, ?, ?, 'x')", 9001L, A, "alice");
        owner.update("INSERT INTO sys_user (id, tenant_id, username, password) VALUES (?, ?, ?, 'x')", 9002L, B, "bob");
    }

    private <T> T asTenant(long tenant, java.util.function.Supplier<T> body) {
        return TenantContext.callAs(tenant, () -> tx.execute(s -> body.get()));
    }

    @Test
    void tenantSeesOnlyOwnRows() {
        assertThat(asTenant(A, () -> jdbc.queryForList("SELECT username FROM sys_user", String.class)))
                .containsExactly("alice");
        assertThat(asTenant(B, () -> jdbc.queryForList("SELECT username FROM sys_user", String.class)))
                .containsExactly("bob");
    }

    @Test
    void tenantCannotUpdateOrDeleteOtherTenantRows() {
        assertThat(asTenant(A, () -> jdbc.update("UPDATE sys_user SET nickname = 'hacked' WHERE username = 'bob'"))).isZero();
        assertThat(asTenant(A, () -> jdbc.update("DELETE FROM sys_user WHERE username = 'bob'"))).isZero();
        assertThat(OwnerJdbc.of(pg).queryForObject(
                "SELECT nickname IS NULL FROM sys_user WHERE id = 9002", Boolean.class)).isTrue();
    }

    @Test
    void tenantCannotMoveOwnRowToOtherTenant() {
        assertThatThrownBy(() -> asTenant(A, () -> jdbc.update("UPDATE sys_user SET tenant_id = ? WHERE username = 'alice'", B)))
                .isInstanceOf(DataAccessException.class)
                .rootCause().hasMessageContaining("row-level security");
    }

    @Test
    void insertForOtherTenantIsRejectedByWithCheck() {
        assertThatThrownBy(() -> asTenant(A, () -> jdbc.update(
                "INSERT INTO sys_user (id, tenant_id, username, password) VALUES (9003, ?, 'mallory', 'x')", B)))
                .isInstanceOf(DataAccessException.class)
                .rootCause().hasMessageContaining("row-level security");
    }

    @Test
    void insertWithoutTenantIdUsesContextTenant() {
        asTenant(A, () -> jdbc.update("INSERT INTO sys_user (id, username, password) VALUES (9004, 'carol', 'x')"));
        assertThat(OwnerJdbc.of(pg).queryForObject("SELECT tenant_id FROM sys_user WHERE id = 9004", Long.class)).isEqualTo(A);
        OwnerJdbc.of(pg).update("DELETE FROM sys_user WHERE id = 9004");
    }

    @Test
    void withoutTenantContextQueriesFailInsteadOfReturningAllRows() {
        // 事务之外（自动提交）不会设置 app.tenant_id
        assertThatThrownBy(() -> jdbc.queryForList("SELECT username FROM sys_user", String.class))
                .isInstanceOf(DataAccessException.class);
    }

    @Test
    void transactionWithoutTenantContextFails() {
        TenantContext.clear();
        assertThatThrownBy(() -> tx.execute(s -> jdbc.queryForList("SELECT username FROM sys_user", String.class)))
                .isInstanceOf(DataAccessException.class)
                .rootCause().hasMessageContaining("app.tenant_id");
        assertThatThrownBy(() -> tx.execute(s -> jdbc.update(
                "INSERT INTO sys_user (id, username, password) VALUES (9006, 'erin', 'x')")))
                .isInstanceOf(DataAccessException.class);
        assertThat(OwnerJdbc.of(pg).queryForObject("SELECT count(*) FROM sys_user WHERE id = 9006 OR tenant_id = 0", Integer.class))
                .as("不得落到租户 0").isZero();
    }

    @Test
    void insertWithoutTenantContextFails() {
        assertThatThrownBy(() -> jdbc.update("INSERT INTO sys_user (id, username, password) VALUES (9005, 'dave', 'x')"))
                .isInstanceOf(DataAccessException.class);
    }
}
