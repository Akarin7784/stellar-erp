package com.stellar.erp.production.internal;

import java.sql.Array;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * 工場次元のデータ範囲（01-system 02 BR-07 / CALC-02、06/91 §3.15・02 §4.7）。
 *
 * <p>実効値は「ユーザ個別（{@code sys_user_data_scope}）＞ロールのリソース別（{@code sys_role_data_scope}、
 * resource 完全一致＞{@code '*'}）＞ロール既定（{@code sys_role.data_scope_type}）」で解決する。
 * 工場の制限になるのは {@code scope_type=6}（{@code factory_ids}）と {@code 5}（{@code custom_rule.factoryIds} があれば）のみ。
 * 複数ロールは和集合（いずれかが工場無制限なら無制限）。部門・本人・倉庫次元は本クラスでは扱わない。</p>
 *
 * @return {@link Optional#empty()} = 工場無制限、値あり = 参照可能な工場 ID 集合（空集合は参照不可）
 */
@Component
public class FactoryDataScope {

    static final short SCOPE_CUSTOM = 5, SCOPE_FACTORY = 6;

    private final JdbcClient jdbc;

    public FactoryDataScope(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    record Entry(short scopeType, Long[] factoryIds) {
    }

    /** 呼出し元トランザクション内（RLS の {@code app.tenant_id} 設定済み）で呼ぶ。 */
    public Optional<Set<Long>> allowedFactories(long userId, long companyId, String module, String resource) {
        List<Entry> user = jdbc.sql("""
                        SELECT s.scope_type, %s
                          FROM sys_user_data_scope s
                         WHERE s.user_id = :user AND s.company_id = :company AND s.resource_code IN (:res, '*')
                           AND (s.valid_from IS NULL OR s.valid_from <= CURRENT_DATE)
                           AND (s.valid_to IS NULL OR s.valid_to >= CURRENT_DATE)
                         ORDER BY (s.resource_code = :res) DESC, s.id
                         LIMIT 1
                        """.formatted(factoryArray("s")))
                .param("user", userId).param("company", companyId).param("res", resource)
                .query((rs, i) -> new Entry(rs.getShort(1), longs(rs.getArray(2)))).list();
        // ユーザ個別が工場型（6、または 5 で factoryIds あり）のときのみロールより優先。
        // 工場型でない個別範囲（部門・本人等）は工場次元を規定しないため、ロール側の工場範囲へフォールバックする（全開にしない）。
        if (!user.isEmpty() && isFactoryScope(user.get(0))) {
            Long[] ids = user.get(0).factoryIds();
            return Optional.of(ids == null ? new HashSet<>() : new HashSet<>(List.of(ids)));
        }
        List<Entry> roles = jdbc.sql("""
                        SELECT COALESCE(ds.scope_type, r.data_scope_type), %s
                          FROM sys_user_role ur
                          JOIN sys_role r
                            ON r.id = ur.role_id AND r.tenant_id = ur.tenant_id AND r.deleted = FALSE AND r.status = 1
                          LEFT JOIN LATERAL (
                                SELECT d.scope_type, d.factory_ids, d.custom_rule
                                  FROM sys_role_data_scope d
                                 WHERE d.role_id = r.id AND d.tenant_id = r.tenant_id
                                   AND d.resource_code IN (:res, '*') AND d.module_code IN (:module, '*')
                                 ORDER BY (d.resource_code = :res) DESC, (d.module_code = :module) DESC, d.id
                                 LIMIT 1) ds ON TRUE
                         WHERE ur.user_id = :user AND ur.company_id = :company AND ur.status = 1
                           AND (ur.valid_from IS NULL OR ur.valid_from <= CURRENT_DATE)
                           AND (ur.valid_to IS NULL OR ur.valid_to >= CURRENT_DATE)
                        """.formatted(factoryArray("ds")))
                .param("user", userId).param("company", companyId).param("res", resource).param("module", module)
                .query((rs, i) -> new Entry(rs.getShort(1), longs(rs.getArray(2)))).list();
        Set<Long> allowed = new HashSet<>();
        for (Entry e : roles) {
            if (isFactoryScope(e)) {
                if (e.factoryIds() != null) {
                    allowed.addAll(List.of(e.factoryIds()));
                }
            } else {
                return Optional.empty();
            }
        }
        // ロールなしは権限チェック（3001）で先に弾かれる。ここに来た場合は参照可能工場なし
        return Optional.of(allowed);
    }

    private static boolean isFactoryScope(Entry e) {
        return e.scopeType() == SCOPE_FACTORY || (e.scopeType() == SCOPE_CUSTOM && e.factoryIds() != null);
    }

    /** scope_type=6 は factory_ids、5 は custom_rule.factoryIds（文字列・数値の JSON 配列）を BIGINT[] に。 */
    private static String factoryArray(String a) {
        return """
                CASE WHEN %1$s.scope_type = 6 THEN ARRAY(SELECT x::bigint FROM jsonb_array_elements_text(
                          COALESCE(%1$s.factory_ids, '[]'::jsonb)) x)
                     WHEN %1$s.scope_type = 5 AND jsonb_typeof(%1$s.custom_rule -> 'factoryIds') = 'array'
                     THEN ARRAY(SELECT x::bigint FROM jsonb_array_elements_text(%1$s.custom_rule -> 'factoryIds') x)
                END""".formatted(a);
    }

    private static Long[] longs(Array a) throws java.sql.SQLException {
        return a == null ? null : (Long[]) a.getArray();
    }
}
