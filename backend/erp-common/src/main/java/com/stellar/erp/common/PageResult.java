package com.stellar.erp.common;

import java.util.List;

/**
 * 分页结果（00-common 03-common-api-spec §7.2）。
 * {@code total} / {@code pages} は件数のため int とし、JSON では数値のまま返す（BIGINT ID の文字列化対象外、Lead 2026-10-21 決定）。
 */
public record PageResult<T>(List<T> list, int total, int pageNum, int pageSize, int pages) {

    /** {@code count(*)} の long を受け取る。int 範囲外は {@link ArithmeticException}（実運用で到達しない）。 */
    public static <T> PageResult<T> of(List<T> list, long total, int pageNum, int pageSize) {
        int t = Math.toIntExact(total);
        return new PageResult<>(list, t, pageNum, pageSize, pageSize == 0 ? 0 : (t + pageSize - 1) / pageSize);
    }
}
