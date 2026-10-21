package com.stellar.erp.system.internal;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.OffsetDateTime;
import lombok.Getter;
import lombok.Setter;

/**
 * 用户实体（示例，用于验证 MyBatis-Plus Starter 链路）。
 */
@Getter
@Setter
@TableName("sys_user")
public class SysUser {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 租户 ID，首期固定 0，Phase 3 启用多租户 */
    private Long tenantId;

    private String username;

    private String nickname;

    /** BCrypt 哈希（sys/V202610211408 由 password 改名） */
    private String passwordHash;

    /** 1 = 启用，0 = 停用 */
    private Integer status;

    @TableLogic
    private Boolean deleted;

    @TableField(fill = FieldFill.INSERT)
    private OffsetDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private OffsetDateTime updatedAt;
}
