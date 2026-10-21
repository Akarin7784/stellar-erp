package com.stellar.erp.system;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/** GET /api/system/depts/options：会社・テナント境界、有効・未削除のみ、ID は文字列、sort_no→コード順。 */
@DbIntegrationTest
class DeptOptionIntegrationTest {

    static final long TENANT = 306L, OTHER_TENANT = 307L, CO = 61L, CO2 = 62L, USER = 7301L;

    @Autowired PostgreSQLContainer pg;
    @Autowired WebApplicationContext wac;

    JdbcTemplate owner;

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO sys_department (id, tenant_id, company_id, department_code, department_name, sort_no, status, deleted) VALUES
              (996001, 306, 61, 'D003', '生产部', 1, 1, FALSE),
              (996002, 306, 61, 'D001', '总经办', 2, 1, FALSE),
              (996003, 306, 61, 'D002', '采购部', 1, 1, FALSE),
              (996004, 306, 61, 'D004', '停用部', 0, 0, FALSE),
              (996005, 306, 61, 'D005', '删除部', 0, 1, TRUE),
              (996006, 306, 62, 'D001', '他社部门', 0, 1, FALSE),
              (996007, 307, 61, 'D009', '他租户部门', 0, 1, FALSE);
            """);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("DELETE FROM sys_department WHERE tenant_id IN (306, 307)");
    }

    @Test
    void returnsActiveDeptsOfCurrentCompanyOnlyInOrder() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, CO));
        // 期待順：sort_no 1（D002, D003）→ sort_no 2（D001）。停用・删除・他社・他租户は含まない
        mvc.perform(get("/api/system/depts/options"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.length()").value(3))
                .andExpect(jsonPath("$.data[0].id").value("996003"))
                .andExpect(jsonPath("$.data[0].departmentCode").value("D002"))
                .andExpect(jsonPath("$.data[0].departmentName").value("采购部"))
                .andExpect(jsonPath("$.data[1].id").value("996001"))
                .andExpect(jsonPath("$.data[2].id").value("996002"));
    }

    @Test
    void otherCompanySeesOnlyItsOwn() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, CO2));
        mvc.perform(get("/api/system/depts/options").param("companyId", String.valueOf(CO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value("996006"))
                .andExpect(jsonPath("$.data[0].departmentName").value("他社部门"));
    }
}
