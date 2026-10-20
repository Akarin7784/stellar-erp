package com.stellar.erp.common;

import java.util.List;

/** 分页结果（00-common 03-common-api-spec §7.2）。 */
public record PageResult<T>(List<T> list, long total, int pageNum, int pageSize, long pages) {

    public static <T> PageResult<T> of(List<T> list, long total, int pageNum, int pageSize) {
        return new PageResult<>(list, total, pageNum, pageSize, pageSize == 0 ? 0 : (total + pageSize - 1) / pageSize);
    }
}
