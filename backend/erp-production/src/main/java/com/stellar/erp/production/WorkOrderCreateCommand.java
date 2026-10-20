package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 工单登録请求（02-work-order §7 WorkOrderCreateRequest 的最小子集）。
 *
 * <p>刻意不含 {@code companyId}：公司只取登录上下文。未知字段（含 companyId）由 Jackson 忽略，不会被采用。
 * 不含 {@code standardCost}：创建时恒为 NULL，下达时快照（任务 D）。</p>
 */
public record WorkOrderCreateCommand(
        Short workOrderType,
        @NotNull Long factoryId,
        @NotNull Long materialId,
        @NotNull @DecimalMin(value = "0", inclusive = false) @Digits(integer = 14, fraction = 4) BigDecimal orderQty,
        @NotBlank @Size(max = 16) String uomCode,
        @NotNull LocalDate plannedStartDate,
        @NotNull LocalDate plannedEndDate,
        @Min(1) @Max(9) Short priorityNo,
        Long departmentId,
        Long warehouseId,
        Long salesOrderLineId,
        Boolean isBackflush,
        @Size(max = 500) String remark) {
}
