package com.stellar.erp;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

/**
 * {@code erp.auth.trust-preset-context} 的生效判定。该开关仅供集成测试使用（无 token 时信任预先设置的 LoginContext）。
 * <ul>
 *   <li>只有 {@code test} profile 激活时才允许为 true；</li>
 *   <li>在其他 profile（dev / prod / 默认）下设置为 true 时，启动直接失败（fail fast），避免误配置绕过认证。</li>
 * </ul>
 */
@Component
public class TrustPresetContextPolicy {

    static final String PROPERTY = "erp.auth.trust-preset-context";

    private final boolean enabled;

    public TrustPresetContextPolicy(Environment env) {
        boolean requested = env.getProperty(PROPERTY, Boolean.class, false);
        if (requested && !env.acceptsProfiles(Profiles.of("test"))) {
            throw new IllegalStateException(PROPERTY + "=true 仅允许在 test profile 下使用");
        }
        this.enabled = requested;
    }

    public boolean enabled() {
        return enabled;
    }
}
