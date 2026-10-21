package com.stellar.erp.production;

import java.math.BigDecimal;

import jakarta.validation.constraints.Size;

/**
 * 超产申请の草稿修正（#39h、91 §3.14、AC-PRD-18、lead 2026-10-21 最終決定）。状態 10 のみ
 * （それ以外は他操作と同じ 422 / 60101 / MSG-PRD-101）、{@code version} 必須（不一致は 409 / 4003）。
 *
 * <p>可変項目は {@code requestQty}・{@code workOrderId}（NULL＝受注行級）・{@code remark}。{@code salesOrderLineId}
 * は受け付けない（body にあっても無視）。受注行・品目・{@code current_allowed_qty} スナップショット、
 * 受注行／工单の {@code allowed_qty} は変更しない。{@code remark} が 500 字超は 400 / 1001 / MSG-COM-041。
 *入力検証は登録（#39c）と同一（60103・60056・60101・5000）。</p>
 */
public record OverproductionUpdateCommand(Integer version, Long workOrderId, BigDecimal requestQty,
                                          @Size(max = 500) String remark) {
}
