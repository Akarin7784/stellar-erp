package com.stellar.erp.mdm;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.system.FactoryDataScope;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.PageResult;

/**
 * 他域参照用の選択 API（02-mdm 91 #1 / #55 / #138、03-warehouse-location §7 No.13/14）。
 * tenant は RLS、company は登录上下文で明示条件。未削除・有効のみ返す。
 *
 * <p>DTO（FactoryDto / WarehouseOptionDto / MaterialListDto）の項目は設計書未定義のため、
 * 選択用途の最小項目（id・コード・名称等）を暫定で返す。</p>
 */
@Service
public class MdmLookupService {

    public record FactoryDto(long id, String factoryCode, String factoryName, Short plantType) {
    }

    public record WarehouseOptionDto(long id, String warehouseCode, String warehouseName, short warehouseType,
                                     long factoryId) {
    }

    public record MaterialListDto(long id, String materialCode, String materialName, String spec,
                                  short materialType, String baseUomCode, Long unitId, String unitName,
                                  short status) {
    }

    private final JdbcClient jdbc;
    private final FactoryDataScope scope;

    public MdmLookupService(JdbcClient jdbc, FactoryDataScope scope) {
        this.jdbc = jdbc;
        this.scope = scope;
    }

    /**
     * 工厂下拉（当前公司的有效工厂）。{@code resource}（例 {@code work-order} → production 模块・{@code production:work-order}）
     * 指定時は CALC-02a（{@link FactoryDataScope}）で絞る：ユーザ個別が工厂型なら優先、そうでなければロール和集合
     * （いずれか無制限なら無制限）、有効ロールなしは空。未知の値は 400。未指定は絞らない（负责人决定）。
     */
    /** {@code resource} 参数值 → {module, resource_code}（01-system 文档 #135）。 */
    static final java.util.Map<String, String[]> FACTORY_SCOPE_RESOURCES = java.util.Map.of(
            "work-order", new String[] {"production", "production:work-order"});

    @Transactional(readOnly = true)
    public List<FactoryDto> factories(String resource) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        Optional<Set<Long>> allowed = Optional.empty();
        if (resource != null) {
            String[] mr = FACTORY_SCOPE_RESOURCES.get(resource.trim());
            if (mr == null) {
                // 未知の resource（暫定：400 / 1001 / MSG-COM-049。正式な扱いは负责人确认待ち）
                throw new BizException(1001, "MSG-COM-049", "resource 取值不正确");
            }
            allowed = scope.allowedFactories(login.userId(), company, mr[0], mr[1]);
        }
        Optional<Set<Long>> scoped = allowed;
        if (scoped.isPresent() && scoped.get().isEmpty()) {
            return List.of();
        }
        return jdbc.sql("""
                        SELECT id, factory_code, factory_name, plant_type FROM mdm_factory
                         WHERE company_id = :c AND deleted = FALSE AND is_active = TRUE ORDER BY factory_code
                        """).param("c", company)
                .query((rs, i) -> new FactoryDto(rs.getLong(1), rs.getString(2), rs.getString(3),
                        rs.getObject(4, Short.class)))
                .list().stream()
                .filter(f -> scoped.isEmpty() || scoped.get().contains(f.id()))
                .toList();
    }

    /** {@code factoryId} 任意（03-warehouse-location §7 No.13 のリクエスト）。指定時は当前公司の工厂であることを確認。 */
    @Transactional(readOnly = true)
    public List<WarehouseOptionDto> warehouseOptions(Long factoryId) {
        long company = LoginContext.require().companyId();
        if (factoryId != null && jdbc.sql("SELECT count(*) FROM mdm_factory WHERE id = :f AND company_id = :c AND deleted = FALSE")
                .param("f", factoryId).param("c", company).query(Long.class).single() == 0) {
            throw new BizException(4001, "工厂不存在");
        }
        return jdbc.sql("""
                        SELECT id, warehouse_code, warehouse_name, warehouse_type, factory_id FROM mdm_warehouse
                         WHERE company_id = :c AND deleted = FALSE AND status = 1
                           AND (CAST(:f AS BIGINT) IS NULL OR factory_id = :f)
                         ORDER BY warehouse_code
                        """).param("c", company).param("f", factoryId)
                .query((rs, i) -> new WarehouseOptionDto(rs.getLong(1), rs.getString(2), rs.getString(3),
                        rs.getShort(4), rs.getLong(5)))
                .list();
    }

    /** 物料一覧（keyword＝コード・名称の部分一致、pageNum/pageSize は 03 §7.1）。 */
    @Transactional(readOnly = true)
    public PageResult<MaterialListDto> materials(String keyword, int pageNum, int pageSize) {
        long company = LoginContext.require().companyId();
        if (pageNum < 1 || pageSize < 1 || pageSize > 200) {
            throw new BizException(1003, "分页参数超出范围");
        }
        String like = keyword == null || keyword.isBlank() ? null
                : "%" + keyword.trim().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
        String where = """
                 WHERE m.company_id = :c AND m.deleted = FALSE
                   AND (CAST(:k AS TEXT) IS NULL OR m.material_code LIKE :k OR m.material_name LIKE :k)
                """;
        long total = jdbc.sql("SELECT count(*) FROM mdm_material m" + where)
                .param("c", company).param("k", like).query(Long.class).single();
        List<MaterialListDto> list = jdbc.sql("""
                        SELECT m.id, m.material_code, m.material_name, m.spec, m.material_type, m.base_uom_code,
                               u.id AS unit_id, u.uom_name, m.status
                          FROM mdm_material m
                          -- 单位は base_uom_code で引く（mdm_material に単位 ID 列はない）。tenant・company を明示一致
                          LEFT JOIN mdm_uom u ON u.tenant_id = m.tenant_id AND u.company_id = m.company_id
                                             AND u.uom_code = m.base_uom_code AND u.deleted = FALSE
                        """ + where + " ORDER BY m.material_code LIMIT :lim OFFSET :off")
                .param("c", company).param("k", like).param("lim", pageSize).param("off", (long) (pageNum - 1) * pageSize)
                .query((rs, i) -> new MaterialListDto(rs.getLong(1), rs.getString(2), rs.getString(3), rs.getString(4),
                        rs.getShort(5), rs.getString(6), rs.getObject(7, Long.class), rs.getString(8), rs.getShort(9)))
                .list();
        return PageResult.of(list, total, pageNum, pageSize);
    }
}
