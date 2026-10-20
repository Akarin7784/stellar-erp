package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.SQLException;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

class ProductionDbErrorsTest {

    static DataIntegrityViolationException ex(String state, String constraint) {
        return new DataIntegrityViolationException("x", new SQLException(
                "ERROR: new row for relation \"sal_sales_order_line\" violates check constraint \"" + constraint + "\"", state));
    }

    @Test
    void completedQtyCheckIs60040() {
        assertThat(ProductionDbErrors.translate(ex("23514", "ck_sal_sol_completed_qty"))).hasValueSatisfying(e -> {
            assertThat(e.getCode()).isEqualTo(60040);
            assertThat(e.getMsgId()).isEqualTo("MSG-PRD-040");
        });
    }

    @Test
    void otherConstraintOrStateNotTranslated() {
        assertThat(ProductionDbErrors.translate(ex("23514", "ck_sal_sales_order_line_qty"))).isEmpty();
        assertThat(ProductionDbErrors.translate(ex("23505", "ck_sal_sol_completed_qty"))).isEmpty();
        assertThat(ProductionDbErrors.translate(new IllegalStateException("x"))).isEmpty();
    }
}
