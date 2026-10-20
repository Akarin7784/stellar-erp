#!/usr/bin/env bash
# 已清理路径中禁止出现 `tenant_id ... DEFAULT 0`（应为 DEFAULT current_setting('app.tenant_id')::bigint）。
# 仅匹配 tenant_id 列；company_id 等其他列不在检查范围。
# 追加目录：在 CLEAN_PATHS 中加一行（例如 #49 合并后加 docs/design/02-mdm）。
set -euo pipefail
cd "$(dirname "$0")/.."
CLEAN_PATHS=(
  docs/design/00-common
  docs/design/_template
  docs/design/00-common/09-cross-domain-flow.md
  docs/design/01-system
  docs/design/02-mdm
  docs/design/03-sales
  docs/design/04-purchase
  docs/design/05-inventory
  docs/design/06-production
  docs/design/07-finance
  docs/design/09-integration
  docs/design/10-analytics
)
# 行内 tenant_id 后（不跨行）出现 DEFAULT 0（后接非数字/非小数点）
PATTERN='\btenant_id\b.*\bDEFAULT[[:space:]]+0([^0-9.]|$)'
# 同一行已写 current_setting 的属于"禁止 DEFAULT 0"的说明文字，排除
if hits=$(grep -rnIE "$PATTERN" "${CLEAN_PATHS[@]}" | grep -v "current_setting"); then
  echo "ERROR: 以下位置的 tenant_id 仍使用 DEFAULT 0：" >&2
  echo "$hits" >&2
  exit 1
fi
echo "OK: tenant_id DEFAULT 0 检查通过（${#CLEAN_PATHS[@]} 个路径）"
