package com.stellar.erp.production;

import jakarta.validation.constraints.NotNull;

/**
 * 工单下达请求（91 §3.2 的最小子集：{@code version}）。
 * {@code releaseDate}/{@code reservationMode}/{@code shortageAction} 属于引当（E21）部分，本切片未实装。
 */
public record WorkOrderReleaseCommand(@NotNull Integer version) {
}
