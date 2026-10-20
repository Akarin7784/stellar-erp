package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.workflow.WorkflowService;

/**
 * issue #7：Flowable 引擎表由 Flyway 预建在独立 schema flowable，public 中不得出现 ACT_* / FLW_* 表；
 * 引擎以 database-schema-update=false 启动（只校验版本），并能经应用数据源正常查询。
 */
@DbIntegrationTest
class FlowableSchemaTest {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    WorkflowService workflowService;

    @Test
    void noFlowableTablesInPublic() {
        Integer n = jdbc.queryForObject("""
                SELECT count(*) FROM pg_tables
                WHERE schemaname = 'public' AND (tablename LIKE 'act\\_%' OR tablename LIKE 'flw\\_%')
                """, Integer.class);
        assertThat(n).isZero();
    }

    @Test
    void flowableTablesLiveInFlowableSchema() {
        Integer n = jdbc.queryForObject(
                "SELECT count(*) FROM pg_tables WHERE schemaname = 'flowable' AND tablename IN ('act_ge_property', 'act_ru_execution', 'act_ru_task', 'act_hi_procinst', 'act_id_user', 'flw_event_definition')",
                Integer.class);
        assertThat(n).isEqualTo(6);
    }

    @Test
    void flowableTablesAreOwnedByMigrationRoleNotAppRole() {
        Integer n = jdbc.queryForObject(
                "SELECT count(*) FROM pg_tables WHERE schemaname = 'flowable' AND tableowner = 'erp_app'", Integer.class);
        assertThat(n).isZero();
    }

    @Test
    void schemaVersionMatchesEngine() {
        String v = jdbc.queryForObject(
                "SELECT value_ FROM flowable.act_ge_property WHERE name_ = 'schema.version'", String.class);
        assertThat(v).isEqualTo(org.flowable.engine.ProcessEngine.VERSION);
    }

    @Test
    void engineQueriesWorkThroughAppDataSource() {
        assertThat(workflowService.runningProcessCount()).isZero();
    }
}
