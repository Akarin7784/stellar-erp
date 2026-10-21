package com.stellar.erp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class TrustPresetContextPolicyTest {

    @Test
    void defaultIsDisabled() {
        assertThat(new TrustPresetContextPolicy(new MockEnvironment()).enabled()).isFalse();
    }

    @Test
    void trueOutsideTestProfileFailsStartup() {
        for (String profile : new String[] {"prod", "dev"}) {
            MockEnvironment env = new MockEnvironment().withProperty(TrustPresetContextPolicy.PROPERTY, "true");
            env.setActiveProfiles(profile);
            assertThatThrownBy(() -> new TrustPresetContextPolicy(env))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("test profile");
        }
        MockEnvironment none = new MockEnvironment().withProperty(TrustPresetContextPolicy.PROPERTY, "true");
        assertThatThrownBy(() -> new TrustPresetContextPolicy(none)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void trueUnderTestProfileIsEnabled() {
        MockEnvironment env = new MockEnvironment().withProperty(TrustPresetContextPolicy.PROPERTY, "true");
        env.setActiveProfiles("test");
        assertThat(new TrustPresetContextPolicy(env).enabled()).isTrue();
    }
}
