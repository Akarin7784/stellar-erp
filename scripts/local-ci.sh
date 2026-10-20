#!/usr/bin/env bash
# 本地 CI：GitHub Actions 不可用时，在本机复现 .github/workflows/ci.yml 的检查，并补跑 PG18 迁移 + pgTAP。
# 用法：scripts/local-ci.sh [--skip-backend] [--skip-frontend] [--skip-db] [--with-ddl-audit] [--skip-tldts]
#   --skip-tldts      前端安装时忽略 tldts-core 年龄门槛（pnpm minimumReleaseAge）已知问题
#   --with-ddl-audit  额外跑 screen_ddl_audit.py（存在时）
# 退出码：任一必选步骤失败即非 0；结尾打印各步骤结果。
set -uo pipefail
# 环境要求：Docker、JDK 21、Node 24（CI 同版本；Node 20 下 vitest 起不来 worker）。
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
SKIP_BACKEND=0 SKIP_FRONTEND=0 SKIP_DB=0 DDL_AUDIT=0 SKIP_TLDTS=0
for a in "$@"; do case "$a" in
  --skip-backend) SKIP_BACKEND=1;; --skip-frontend) SKIP_FRONTEND=1;; --skip-db) SKIP_DB=1;;
  --with-ddl-audit) DDL_AUDIT=1;; --skip-tldts) SKIP_TLDTS=1;;
  -h|--help) sed -n '2,7p' "$0"; exit 0;; *) echo "未知参数: $a"; exit 2;; esac; done

declare -a RESULTS=(); FAIL=0
step() { local name="$1"; shift; echo; echo "=== $name ==="
  if "$@"; then RESULTS+=("PASS  $name"); else RESULTS+=("FAIL  $name"); FAIL=1; fi; }

MIG_DIR=backend/erp-boot/src/main/resources/db/migration
PGTAP_DIR=backend/erp-boot/src/test/resources/pgtap
PG_IMAGE=stellar-erp/postgres-pgtap:latest
PG_NAME="stellar-local-ci-$$"

db_checks() {
  docker image inspect "$PG_IMAGE" >/dev/null 2>&1 || \
    docker build -q -t "$PG_IMAGE" backend/erp-boot/src/test/docker/postgres-pgtap || return 1
  docker run -d --rm --name "$PG_NAME" -e POSTGRES_PASSWORD=ci -e POSTGRES_DB=erp "$PG_IMAGE" >/dev/null || return 1
  trap 'docker rm -f "$PG_NAME" >/dev/null 2>&1' RETURN
  for _ in $(seq 60); do docker exec "$PG_NAME" pg_isready -U postgres -d erp -q && break; sleep 1; done
  local psql=(docker exec -i "$PG_NAME" psql -U postgres -d erp -v ON_ERROR_STOP=1 -q -X)
  # 按 Flyway 版本号排序；每个文件单独一个事务（psql -1），与 Flyway 一致（wf 的 SET LOCAL search_path 依赖这一点）
  local f n=0
  while read -r f; do n=$((n+1))
    "${psql[@]}" -1 < "$f" >/dev/null || { echo "迁移失败: $f"; return 1; }
  done < <(find "$MIG_DIR" -name 'V*__*.sql' | awk -F/ '{v=$NF; sub(/^V/,"",v); sub(/__.*/,"",v); print v"\t"$0}' | sort -t. -k1,1n -k2,2n | cut -f2)
  echo "迁移 $n 个全部成功"
  "${psql[@]}" -c 'CREATE EXTENSION IF NOT EXISTS pgtap' || return 1
  local t out bad=0
  for t in "$PGTAP_DIR"/*.sql; do
    out=$("${psql[@]}" -At < "$t" 2>&1); local rc=$?
    echo "$out" | grep -E '^(not ok|# )' || true
    if [ $rc -ne 0 ] || echo "$out" | grep -qE '^not ok|ERROR|Looks like'; then echo "pgTAP 失败: $t"; bad=1
    else echo "pgTAP OK: $(basename "$t") ($(echo "$out" | grep -c '^ok'))"; fi
  done
  return $bad
}

frontend_checks() { ( cd frontend || exit 1
  local inst=(pnpm install --frozen-lockfile)
  [ $SKIP_TLDTS -eq 1 ] && inst+=(--config.minimum-release-age=0)
  "${inst[@]}" && { pnpm lint || echo "WARN: lint 失败（CI 中为 continue-on-error）"; } \
    && pnpm build && pnpm test ) ; }

step "迁移文件名 (check-migrations.sh)" bash .github/scripts/check-migrations.sh
step "文档 tenant_id DEFAULT 0 (check-tenant-default.sh)" bash scripts/check-tenant-default.sh
[ $SKIP_DB -eq 0 ] && step "PG18 空库迁移 + pgTAP" db_checks
[ $SKIP_BACKEND -eq 0 ] && step "后端 mvnw verify" bash -c 'cd backend && chmod +x mvnw && ./mvnw -B -ntp verify'
[ $SKIP_FRONTEND -eq 0 ] && step "前端 install/lint/build/test" frontend_checks
if [ $DDL_AUDIT -eq 1 ]; then a=$(find . -name screen_ddl_audit.py -not -path '*/node_modules/*' | head -1)
  [ -n "$a" ] && step "画面×DDL 审计（可选）" python3 "$a" || echo "未找到 screen_ddl_audit.py，跳过"; fi

echo; echo "=== 汇总 ==="; printf '%s\n' "${RESULTS[@]}"; exit $FAIL
