# 仅用于测试：postgres:18.6 + pgTAP。生产迁移中不创建 pgtap 扩展。
FROM postgres:18.6
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-18-pgtap \
 && rm -rf /var/lib/apt/lists/*
