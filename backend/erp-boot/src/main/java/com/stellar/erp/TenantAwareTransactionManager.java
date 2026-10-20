package com.stellar.erp;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.springframework.jdbc.support.JdbcTransactionManager;
import org.springframework.transaction.TransactionDefinition;

import com.stellar.erp.common.TenantContext;

/**
 * 在每个事务开始时执行 {@code SELECT set_config('app.tenant_id', ?, true)}（事务级，等价 SET LOCAL），
 * 使 RLS 策略 {@code tenant_id = current_setting('app.tenant_id')::bigint} 生效。
 * 事务提交/回滚后设置自动失效，连接归还连接池时不会残留租户。
 */
public class TenantAwareTransactionManager extends JdbcTransactionManager {

    static final String SET_TENANT_SQL = "SELECT set_config('app.tenant_id', ?, true)";

    public TenantAwareTransactionManager(DataSource dataSource) {
        super(dataSource);
    }

    @Override
    protected void prepareTransactionalConnection(Connection con, TransactionDefinition definition) throws SQLException {
        super.prepareTransactionalConnection(con, definition);
        try (PreparedStatement ps = con.prepareStatement(SET_TENANT_SQL)) {
            ps.setString(1, Long.toString(TenantContext.currentTenantId()));
            ps.execute();
        }
    }
}
