package com.stellar.erp.mdm;

import java.util.List;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
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
                                  short materialType, String baseUomCode, short status) {
    }

    private final JdbcClient jdbc;

    public MdmLookupService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<FactoryDto> factories() {
        long company = LoginContext.require().companyId();
        return jdbc.sql("""
                        SELECT id, factory_code, factory_name, plant_type FROM mdm_factory
                         WHERE company_id = :c AND deleted = FALSE AND is_active = TRUE ORDER BY factory_code
                        """).param("c", company)
                .query((rs, i) -> new FactoryDto(rs.getLong(1), rs.getString(2), rs.getString(3),
                        rs.getObject(4, Short.class)))
                .list();
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
                 WHERE company_id = :c AND deleted = FALSE
                   AND (CAST(:k AS TEXT) IS NULL OR material_code LIKE :k OR material_name LIKE :k)
                """;
        long total = jdbc.sql("SELECT count(*) FROM mdm_material" + where)
                .param("c", company).param("k", like).query(Long.class).single();
        List<MaterialListDto> list = jdbc.sql("""
                        SELECT id, material_code, material_name, spec, material_type, base_uom_code, status
                          FROM mdm_material""" + where + " ORDER BY material_code LIMIT :lim OFFSET :off")
                .param("c", company).param("k", like).param("lim", pageSize).param("off", (long) (pageNum - 1) * pageSize)
                .query((rs, i) -> new MaterialListDto(rs.getLong(1), rs.getString(2), rs.getString(3), rs.getString(4),
                        rs.getShort(5), rs.getString(6), rs.getShort(7)))
                .list();
        return PageResult.of(list, total, pageNum, pageSize);
    }
}
