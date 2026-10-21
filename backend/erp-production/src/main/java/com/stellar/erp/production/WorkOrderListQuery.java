package com.stellar.erp.production;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

/**
 * 工单一覧の検索条件（06/91 §3.15）。null／空は「絞り込まない」。値域・形式は Controller で検証済み。
 *
 * @param sort 許可キー（{@link #SORT_KEYS}）と昇降順。空なら既定順（計画完成日→優先度→工单号）
 */
public record WorkOrderListQuery(String workOrderNo, String material, Short workOrderType, List<Short> status,
                                 LocalDate plannedStartDateFrom, LocalDate plannedStartDateTo,
                                 LocalDate plannedEndDateFrom, LocalDate plannedEndDateTo,
                                 Long factoryId, Long departmentId, String salesOrderNo, Long customerId,
                                 Short priorityNo, Short sourceType, Boolean isHold,
                                 List<Sort> sort, int pageNum, int pageSize) {

    /** §3.15 の sort 許可キー（API 名）。 */
    public static final Set<String> SORT_KEYS = Set.of("workOrderNo", "plannedStartDate", "plannedEndDate",
            "priorityNo", "orderStatus", "createdAt");
    public static final Set<Short> STATUSES = Set.of((short) 10, (short) 20, (short) 25, (short) 30, (short) 35,
            (short) 40, (short) 90);
    public static final Set<Short> WORK_ORDER_TYPES = Set.of((short) 10, (short) 20, (short) 30, (short) 40);
    public static final Set<Short> SOURCE_TYPES = Set.of((short) 10, (short) 20, (short) 30, (short) 40, (short) 50,
            (short) 60, (short) 70);

    public record Sort(String key, boolean desc) {
    }
}
