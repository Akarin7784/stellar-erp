#!/usr/bin/env bash
# 校验 Flyway 迁移文件名与版本唯一性（规则见 docs/design/00-common/04-common-db-spec.md §10）
set -euo pipefail
cd "$(dirname "$0")/../.."

declare -A CODE=([00]=common [01]=sys [02]=mdm [03]=sal [04]=pur [05]=inv [06]=prd [07]=fin [08]=wf [09]=int [10]=rpt)
ALLOW_LEGACY="V1__baseline.sql"
fail=0
declare -A seen=()
declare -A seen_r=()

while IFS= read -r -d '' f; do
  name=$(basename "$f")
  if [[ "$name" != *.sql ]]; then
    echo "ERROR: $f 扩展名必须为小写 .sql"; fail=1; continue
  fi
  if [[ "$name" == "$ALLOW_LEGACY" ]]; then
    ver=1
  elif [[ "$name" =~ ^V([0-9]{8})([0-9]{2})([0-9]{2})__([a-z]+)_[a-z0-9_]+\.sql$ ]]; then
    dd=${BASH_REMATCH[2]}; nn=${BASH_REMATCH[3]}; mod=${BASH_REMATCH[4]}
    ymd=${BASH_REMATCH[1]}
    ver="${ymd}${dd}${nn}"
    if [[ "$(date -u -d "$ymd" +%Y%m%d 2>/dev/null || true)" != "$ymd" ]]; then
      echo "ERROR: $f 日期段 $ymd 不是合法日期（yyyyMMdd）"; fail=1
    fi
    if [[ -z "${CODE[$dd]:-}" ]]; then echo "ERROR: $f 域代码 $dd 未定义"; fail=1; continue; fi
    if [[ "${CODE[$dd]}" != "$mod" ]]; then echo "ERROR: $f 域代码 $dd 应对应模块 ${CODE[$dd]}，实际为 $mod"; fail=1; fi
    if [[ "$nn" == "00" ]]; then echo "ERROR: $f 序号 NN 必须为 01-99"; fail=1; fi
  elif [[ "$name" =~ ^R__(seed_[a-z]+_[a-z0-9_]+)\.sql$ ]]; then
    desc=${BASH_REMATCH[1]}
    if [[ -n "${seen_r[$desc]:-}" ]]; then echo "ERROR: 可重复迁移描述 R__$desc 重复：$f 与 ${seen_r[$desc]}"; fail=1; fi
    seen_r[$desc]=$f
    continue
  else
    echo "ERROR: $f 文件名不符合 V{yyyyMMdd}{DD}{NN}__{module}_{desc}.sql"; fail=1; continue
  fi
  if [[ -n "${seen[$ver]:-}" ]]; then echo "ERROR: 版本 $ver 重复：$f 与 ${seen[$ver]}"; fail=1; fi
  seen[$ver]=$f
done < <(find backend -path '*/src/main/resources/db/migration/*' -iname '*.sql' -print0)

# 版本单调递增：新增迁移的版本号必须大于基线（main）上已有的最大版本号；不开 Flyway outOfOrder。
# 基线由环境变量 MIGRATION_BASE_REF 指定（CI：PR 的 base sha / push 的 before sha），本地默认 origin/main。
base="${MIGRATION_BASE_REF:-origin/main}"
if git rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then
  base_max=0
  declare -A in_base=()
  while IFS= read -r p; do
    n=$(basename "$p"); in_base[$n]=1
    if [[ "$n" =~ ^V([0-9]{12})__ ]] && (( 10#${BASH_REMATCH[1]} > base_max )); then base_max=$((10#${BASH_REMATCH[1]})); fi
  done < <(git ls-tree -r --name-only "$base" -- backend | grep -E '/src/main/resources/db/migration/.*\.sql$' || true)
  for ver in "${!seen[@]}"; do
    f=${seen[$ver]}; n=$(basename "$f")
    [[ -n "${in_base[$n]:-}" ]] && continue
    if (( 10#$ver <= base_max )); then
      echo "ERROR: $f 版本 $ver 不大于基线 $base 上的最大版本 $base_max（新迁移版本号必须单调递增）"; fail=1
    fi
  done
elif [[ -n "${CI:-}" ]]; then
  echo "ERROR: CI 上基线 $base 不存在，无法做版本单调递增检查"; fail=1
else
  echo "WARN: 基线 $base 不存在，跳过版本单调递增检查（仅本地降级）"
fi

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "OK: ${#seen[@]} 个版本化迁移、${#seen_r[@]} 个可重复迁移校验通过"
