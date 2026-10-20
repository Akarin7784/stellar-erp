package com.stellar.erp.production.internal;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

/** 伝票番号 {@code {PREFIX}{YYMMDD}{4桁日序}}（00-common 08 §2、日付は採番実行日）。 */
public final class DocumentNumbers {

    private static final DateTimeFormatter YYMMDD = DateTimeFormatter.ofPattern("yyMMdd");

    private DocumentNumbers() {
    }

    public static String format(String prefix, LocalDate date, long seq) {
        return prefix + YYMMDD.format(date) + String.format("%04d", seq);
    }

    public static String next(ProductionRepository repo, long companyId, String sequenceKey, String prefix,
                              LocalDate date) {
        long seq = repo.nextSequence(companyId, sequenceKey, date, IdWorker.getId());
        return format(prefix, date, seq);
    }
}
