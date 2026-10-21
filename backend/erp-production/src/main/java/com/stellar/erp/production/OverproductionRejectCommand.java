package com.stellar.erp.production;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 超产申请却下（91 §3.14：{@code version}, {@code rejectReason}）。
 *
 * <p>{@code rejectReason} 必須（空白のみ不可）・500 字以内（91:589）。違反は Controller で
 * 400 / 1001 / MSG-COM-040（必須）・MSG-COM-041（桁数）+ {@code data.fieldErrors[]} に変換する。</p>
 */
public record OverproductionRejectCommand(@NotNull Integer version, @NotBlank @Size(max = 500) String rejectReason) {
}
