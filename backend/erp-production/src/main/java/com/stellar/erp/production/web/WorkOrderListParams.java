package com.stellar.erp.production.web;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.util.MultiValueMap;

import com.stellar.erp.production.WorkOrderListQuery;

/**
 * GET /api/production/work-orders のクエリ検証（06/91 §3.15）。型・値域エラーは丸めずに 400 / 1001 + fieldErrors。
 *
 * <ul>
 *   <li>pageNum／pageSize：既定 1／20、&lt; 1 は MSG-COM-044、pageSize &gt; 200 は MSG-COM-045、非数値は MSG-COM-088。</li>
 *   <li>status（カンマ区切り・複数指定可）・workOrderType・sourceType の値域外、sort の許可外キー・方向は MSG-COM-049。</li>
 *   <li>priorityNo 1〜9 外は MSG-COM-089、日付形式は MSG-COM-043、From &gt; To は MSG-COM-046、
 *   ID・数値・真偽値の形式は MSG-COM-088。</li>
 * </ul>
 */
final class WorkOrderListParams {

    static final int PAGE_SIZE_MAX = 200;
    static final String MSG_DATE = "MSG-COM-043", MSG_GREATER_THAN = "MSG-COM-044", MSG_NOT_GREATER_THAN = "MSG-COM-045",
            MSG_DATE_RANGE = "MSG-COM-046", MSG_NOT_EXIST = "MSG-COM-049", MSG_FORMAT = "MSG-COM-088",
            MSG_BETWEEN = "MSG-COM-089";
    static final String NOT_EXIST_TEXT = "所选数据不存在或已失效，请重新选择。";

    record Violation(String field, String message, String msgId) {
    }

    final List<Violation> violations = new ArrayList<>();
    private final MultiValueMap<String, String> raw;

    private WorkOrderListParams(MultiValueMap<String, String> raw) {
        this.raw = raw;
    }

    /** 検証結果。{@code query} は violations が空のときのみ非 null。 */
    record Parsed(WorkOrderListQuery query, List<Violation> violations) {
    }

    static Parsed parse(MultiValueMap<String, String> raw) {
        WorkOrderListParams v = new WorkOrderListParams(raw);
        Integer pageNum = v.integer("pageNum", 1);
        Integer pageSize = v.integer("pageSize", 20);
        if (pageNum != null && pageNum < 1) {
            v.add("pageNum", "「pageNum」必须大于 0。", MSG_GREATER_THAN);
        }
        if (pageSize != null && pageSize < 1) {
            v.add("pageSize", "「pageSize」必须大于 0。", MSG_GREATER_THAN);
        } else if (pageSize != null && pageSize > PAGE_SIZE_MAX) {
            v.add("pageSize", "「pageSize」不能大于「" + PAGE_SIZE_MAX + "」。", MSG_NOT_GREATER_THAN);
        }
        Short woType = v.code("workOrderType", WorkOrderListQuery.WORK_ORDER_TYPES);
        List<Short> status = v.statuses();
        LocalDate psFrom = v.date("plannedStartDateFrom"), psTo = v.date("plannedStartDateTo");
        LocalDate peFrom = v.date("plannedEndDateFrom"), peTo = v.date("plannedEndDateTo");
        if (psFrom != null && psTo != null && psFrom.isAfter(psTo)) {
            v.add("plannedStartDateFrom", "开始日期不能晚于结束日期。", MSG_DATE_RANGE);
        }
        if (peFrom != null && peTo != null && peFrom.isAfter(peTo)) {
            v.add("plannedEndDateFrom", "开始日期不能晚于结束日期。", MSG_DATE_RANGE);
        }
        Long factoryId = v.id("factoryId"), departmentId = v.id("departmentId"), customerId = v.id("customerId");
        Short priorityNo = null;
        Integer pr = v.integer("priorityNo", null);
        if (pr != null) {
            if (pr < 1 || pr > 9) {
                v.add("priorityNo", "「priorityNo」必须在 1 到 9 之间。", MSG_BETWEEN);
            } else {
                priorityNo = pr.shortValue();
            }
        }
        Short sourceType = v.code("sourceType", WorkOrderListQuery.SOURCE_TYPES);
        Boolean isHold = v.bool("isHold");
        List<WorkOrderListQuery.Sort> sort = v.sort();
        if (!v.violations.isEmpty()) {
            return new Parsed(null, List.copyOf(v.violations));
        }
        return new Parsed(new WorkOrderListQuery(v.text("workOrderNo"), v.text("material"), woType, status,
                psFrom, psTo, peFrom, peTo, factoryId, departmentId, v.text("salesOrderNo"), customerId,
                priorityNo, sourceType, isHold, sort, pageNum, pageSize), List.of());
    }

    private void add(String field, String message, String msgId) {
        violations.add(new Violation(field, message, msgId));
    }

    /** 最初の値（前後空白除去）。未指定・空白のみは null（＝絞り込まない）。 */
    private String text(String name) {
        String s = raw.getFirst(name);
        return s == null || s.isBlank() ? null : s.strip();
    }

    private Integer integer(String name, Integer dflt) {
        String s = text(name);
        if (s == null) {
            return dflt;
        }
        try {
            return Integer.valueOf(s);
        } catch (NumberFormatException e) {
            add(name, "「" + name + "」的格式不正确。", MSG_FORMAT);
            return null;
        }
    }

    private Long id(String name) {
        String s = text(name);
        if (s == null) {
            return null;
        }
        try {
            return Long.valueOf(s);
        } catch (NumberFormatException e) {
            add(name, "「" + name + "」的格式不正确。", MSG_FORMAT);
            return null;
        }
    }

    private Short code(String name, Set<Short> allowed) {
        String s = text(name);
        if (s == null) {
            return null;
        }
        Short c = shortOrNull(s);
        if (c == null || !allowed.contains(c)) {
            add(name, NOT_EXIST_TEXT, MSG_NOT_EXIST);
            return null;
        }
        return c;
    }

    /** {@code status=10,20,25} と {@code status=10&status=20} の双方を受け付ける。 */
    private List<Short> statuses() {
        List<String> values = raw.get("status");
        if (values == null) {
            return null;
        }
        List<Short> out = new ArrayList<>();
        for (String v : values) {
            for (String t : v.split(",")) {
                if (t.isBlank()) {
                    continue;
                }
                Short c = shortOrNull(t.strip());
                if (c == null || !WorkOrderListQuery.STATUSES.contains(c)) {
                    add("status", NOT_EXIST_TEXT, MSG_NOT_EXIST);
                    return null;
                }
                if (!out.contains(c)) {
                    out.add(c);
                }
            }
        }
        return out.isEmpty() ? null : out;
    }

    private LocalDate date(String name) {
        String s = text(name);
        if (s == null) {
            return null;
        }
        try {
            return LocalDate.parse(s);
        } catch (DateTimeParseException e) {
            add(name, "「" + name + "」的日期格式不正确。", MSG_DATE);
            return null;
        }
    }

    private Boolean bool(String name) {
        String s = text(name);
        if (s == null) {
            return null;
        }
        return switch (s.toLowerCase(Locale.ROOT)) {
            case "true" -> Boolean.TRUE;
            case "false" -> Boolean.FALSE;
            default -> {
                add(name, "「" + name + "」的格式不正确。", MSG_FORMAT);
                yield null;
            }
        };
    }

    /**
     * 03 §7.1 の {@code field,asc}／{@code field,desc}（カンマ区切りで複数、{@code sort} の複数指定も可）。
     * 方向省略は asc。許可外のキー・方向は 1001。
     */
    private List<WorkOrderListQuery.Sort> sort() {
        List<String> values = raw.get("sort");
        if (values == null) {
            return List.of();
        }
        List<WorkOrderListQuery.Sort> out = new ArrayList<>();
        for (String v : values) {
            String[] t = v.split(",");
            for (int i = 0; i < t.length; i++) {
                String key = t[i].strip();
                if (key.isEmpty()) {
                    continue;
                }
                if (!WorkOrderListQuery.SORT_KEYS.contains(key)) {
                    add("sort", NOT_EXIST_TEXT, MSG_NOT_EXIST);
                    return List.of();
                }
                boolean desc = false;
                if (i + 1 < t.length) {
                    String dir = t[i + 1].strip().toLowerCase(Locale.ROOT);
                    if (dir.equals("asc") || dir.equals("desc")) {
                        desc = dir.equals("desc");
                        i++;
                    }
                }
                out.add(new WorkOrderListQuery.Sort(key, desc));
            }
        }
        return out;
    }

    private static Short shortOrNull(String s) {
        try {
            return Short.valueOf(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
