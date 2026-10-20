package com.stellar.erp.production;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 承認提出／承認の请求（02-work-order §7 No.5：{@code version}, {@code comment}）。 */
public record WorkOrderStateCommand(@NotNull Integer version, @Size(max = 500) String comment) {
}
