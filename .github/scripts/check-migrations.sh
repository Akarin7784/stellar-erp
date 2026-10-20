#!/usr/bin/env bash
# 校验 Flyway 迁移文件名与版本唯一性（规则见 docs/design/00-common/04-common-db-spec.md §10）
set -euo pipefail
cd "$(dirname "$0")/../.."

declare -A CODE=([00]=common [01]=sys [02]=mdm [03]=sal [04]=pur [05]=inv [06]=prd [07]=fin [08]=wf [09]=int [10]=rpt)
ALLOW_LEGACY="V1__baseline.sql"
fail=0
declare -A seen=()

while IFS= read -r -d '' f; do
  name=$(basename "$f")
  if [[ "$name" == "$ALLOW_LEGACY" ]]; then
    ver=1
  elif [[ "$name" =~ ^V([0-9]{8})([0-9]{2})([0-9]{2})__([a-z]+)_[a-z0-9_]+\.sql$ ]]; then
    dd=${BASH_REMATCH[2]}; nn=${BASH_REMATCH[3]}; mod=${BASH_REMATCH[4]}
    ver="${BASH_REMATCH[1]}${dd}${nn}"
    if [[ -z "${CODE[$dd]:-}" ]]; then echo "ERROR: $f 域代码 $dd 未定义"; fail=1; continue; fi
    if [[ "${CODE[$dd]}" != "$mod" ]]; then echo "ERROR: $f 域代码 $dd 应对应模块 ${CODE[$dd]}，实际为 $mod"; fail=1; fi
    if [[ "$nn" == "00" ]]; then echo "ERROR: $f 序号 NN 必须为 01-99"; fail=1; fi
  elif [[ "$name" =~ ^R__seed_[a-z]+_[a-z0-9_]+\.sql$ ]]; then
    continue
  else
    echo "ERROR: $f 文件名不符合 V{yyyyMMdd}{DD}{NN}__{module}_{desc}.sql"; fail=1; continue
  fi
  if [[ -n "${seen[$ver]:-}" ]]; then echo "ERROR: 版本 $ver 重复：$f 与 ${seen[$ver]}"; fail=1; fi
  seen[$ver]=$f
done < <(find backend -path '*/src/main/resources/db/migration/*' -name '*.sql' -print0)

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "OK: ${#seen[@]} 个版本化迁移文件校验通过"
