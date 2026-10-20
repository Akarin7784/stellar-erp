package com.stellar.erp.production;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;

/**
 * 工单下达请求（91 §3.2 的最小子集：{@code version}、{@code releaseDate}（任意、既定＝当日 Asia/Shanghai、SCR-PRD-011 W3））。
 * {@code releaseDate}/{@code reservationMode}/{@code shortageAction} 属于引当（E21）部分，本切片未实装。
 */
public record WorkOrderReleaseCommand(@NotNull Integer version, LocalDate releaseDate) {

    public WorkOrderReleaseCommand(Integer version) {
        this(version, null);
    }
}
