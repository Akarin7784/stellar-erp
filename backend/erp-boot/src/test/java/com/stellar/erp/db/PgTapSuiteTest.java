package com.stellar.erp.db;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * 执行 src/test/resources/pgtap/*.sql。每个文件使用一个全新的 owner 连接（新会话，保证 app.tenant_id 未定义），
 * 文件内自行 SET ROLE erp_app 后断言，并以 ROLLBACK 结束。
 * 通过条件：无 "not ok"（"# TODO" 标记的除外），且 plan 与实际条数一致（由 finish() 输出体现）。
 */
@DbIntegrationTest
class PgTapSuiteTest {

    @Autowired
    PostgreSQLContainer pg;


    @ParameterizedTest
    @ValueSource(strings = {"rls_sys_user.sql", "g2_18_order_completion.sql", "inventory_inspection_check.sql", "cost_publish_standard_cost.sql", "mdm_over_receipt_tolerance_rate.sql", "prd_schema.sql", "fin_standard_cost_publish.sql", "sal_schema.sql", "fin_period.sql", "composite_fk.sql"})
    void pgTapFilePasses(String file) throws Exception {
        OwnerJdbc.of(pg).execute("CREATE EXTENSION IF NOT EXISTS pgtap");
        List<String> tap = run(expandIncludes(read("pgtap/" + file)));
        System.out.println("TAP[" + file + "]\n" + String.join("\n", tap));
        assertThat(tap).as("pgTAP 无输出").isNotEmpty();
        Stream<String> failures = tap.stream().filter(l -> l.startsWith("not ok") && !l.contains("# TODO"));
        assertThat(failures).as("%s 输出:%n%s", file, String.join("\n", tap)).isEmpty();
        assertThat(tap.stream().filter(l -> l.startsWith("# Looks like"))).as("plan 不符 / 有失败: %s", tap).isEmpty();
    }

    private List<String> run(String sql) throws Exception {
        List<String> out = new ArrayList<>();
        try (Connection c = DriverManager.getConnection(pg.getJdbcUrl(), pg.getUsername(), pg.getPassword());
             Statement st = c.createStatement()) {
            boolean isRs = st.execute(sql);   // 简单查询协议，多语句一次执行
            while (true) {
                if (isRs) {
                    try (ResultSet rs = st.getResultSet()) {
                        while (rs.next()) {
                            String v = rs.getString(1);
                            if (v != null && (v.startsWith("ok") || v.startsWith("not ok") || v.startsWith("#") || v.matches("^\\d+\\.\\.\\d+$"))) {
                                out.addAll(List.of(v.split("\n")));
                            }
                        }
                    }
                } else if (st.getUpdateCount() == -1) {
                    break;
                }
                isRs = st.getMoreResults();
            }
        }
        return out;
    }

    /** 展开「--!include <classpath 路径>」行为对应资源内容（scripts/local-ci.sh 同一规则）。 */
    static String expandIncludes(String sql) throws IOException {
        StringBuilder sb = new StringBuilder();
        for (String line : sql.split("\n", -1)) {
            if (line.startsWith("--!include")) {
                sb.append(read(line.substring("--!include".length()).trim())).append('\n');
            } else {
                sb.append(line).append('\n');
            }
        }
        return sb.toString();
    }

    static String read(String path) throws IOException {
        try (InputStream in = PgTapSuiteTest.class.getClassLoader().getResourceAsStream(path)) {
            if (in == null) {
                throw new IOException("找不到 " + path);
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}
