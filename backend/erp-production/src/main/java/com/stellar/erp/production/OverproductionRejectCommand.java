package com.stellar.erp.production;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 超产申请却下（91 §3.14：{@code version}, {@code rejectReason}）。 */
public record OverproductionRejectCommand(@NotNull Integer version, @Size(max = 500) String rejectReason) {
}
