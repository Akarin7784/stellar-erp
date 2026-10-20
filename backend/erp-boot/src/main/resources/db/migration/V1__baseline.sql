-- 基线迁移：系统管理模块
CREATE TABLE IF NOT EXISTS sys_user (
    id         BIGINT       PRIMARY KEY,
    tenant_id  BIGINT       NOT NULL DEFAULT 0,
    username   VARCHAR(64)  NOT NULL,
    nickname   VARCHAR(64),
    password   VARCHAR(128) NOT NULL,
    status     SMALLINT     NOT NULL DEFAULT 1,
    deleted    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE sys_user IS '用户表';
COMMENT ON COLUMN sys_user.tenant_id IS '租户 ID，首期固定 0';
COMMENT ON COLUMN sys_user.status IS '1=启用，0=停用';

CREATE UNIQUE INDEX IF NOT EXISTS uk_sys_user_tenant_username
    ON sys_user (tenant_id, username)
    WHERE deleted = FALSE;
