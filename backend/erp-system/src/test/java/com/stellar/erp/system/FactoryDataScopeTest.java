package com.stellar.erp.system;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.Test;

/** {@link FactoryDataScope#resolve} の解決規則（ユーザ個別 ＞ ロール、工場型でなければロールへフォールバック）。 */
class FactoryDataScopeTest {

    static FactoryDataScope.Entry e(int type, Long... ids) {
        return new FactoryDataScope.Entry((short) type, ids.length == 0 && type != 6 ? null : ids);
    }

    static Optional<Set<Long>> resolve(List<FactoryDataScope.Entry> user, List<FactoryDataScope.Entry> roles) {
        return FactoryDataScope.resolve(user, () -> roles);
    }

    @Test
    void userFactoryScopeWinsEvenIfRoleIsCompanyWide() {
        assertThat(resolve(List.of(e(6, 2L)), List.of(e(1)))).contains(Set.of(2L));
        assertThat(resolve(List.of(e(5, 3L)), List.of(e(1)))).contains(Set.of(3L));
    }

    @Test
    void userFactoryScopeDoesNotLoadRoles() {
        assertThat(FactoryDataScope.resolve(List.of(e(6, 2L)), () -> {
            throw new AssertionError("roles must not be loaded");
        })).contains(Set.of(2L));
    }

    @Test
    void userNonFactoryScopeFallsBackToRole() {
        assertThat(resolve(List.of(e(1)), List.of(e(6, 1L)))).contains(Set.of(1L));
        assertThat(resolve(List.of(e(4)), List.of(e(6, 1L)))).contains(Set.of(1L));
    }

    @Test
    void userCustomScopeWithoutFactoryIdsFallsBackToRole() {
        assertThat(resolve(List.of(e(5)), List.of(e(6, 1L)))).contains(Set.of(1L));
    }

    @Test
    void rolesAreUnionedAndAnyUnlimitedRoleIsUnlimited() {
        assertThat(resolve(List.of(e(1)), List.of(e(6, 1L), e(5, 2L)))).contains(Set.of(1L, 2L));
        assertThat(resolve(List.of(e(1)), List.of(e(6, 1L), e(1)))).isEmpty();
        assertThat(resolve(List.of(), List.of(e(6, 1L), e(5)))).isEmpty();
    }

    @Test
    void userNonFactoryScopeWithoutRolesIsEmptySetNotUnlimited() {
        assertThat(resolve(List.of(e(1)), List.of())).contains(Set.of());
        assertThat(resolve(List.of(), List.of())).contains(Set.of());
    }
}
