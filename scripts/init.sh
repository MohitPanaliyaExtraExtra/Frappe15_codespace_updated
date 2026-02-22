#!/usr/bin/env bash
set -e

BENCH_DIR="/workspace/frappe-bench"

echo "🚀 Initializing Frappe Framework v15 Codespace..."

# Skip if bench already exists
if [[ -d "$BENCH_DIR/apps/frappe" ]]; then
    echo "✅ Bench already exists, skipping initialization"
    exit 0
fi

# Remove repo git history (Codespace best practice)
rm -rf /workspace/.git || true

# -----------------------------
# Node.js (nvm + Node 20)
# -----------------------------
export NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
else
    echo "❌ nvm not found"
    exit 1
fi

nvm install 20
nvm alias default 20
nvm use 20

echo 'nvm use 20' >> ~/.bashrc

node -v
npm install -g yarn

# -----------------------------
# Python (uv)
# -----------------------------
if ! command -v uv &> /dev/null; then
    echo "❌ uv not found"
    exit 1
fi

# Recommended Python for Frappe 15
uv python install 3.12 --default

# -----------------------------
# Bench CLI
# -----------------------------
if ! command -v bench &> /dev/null; then
    uv tool install frappe-bench
fi

bench --version

# -----------------------------
# Initialize Bench (Frappe v15)
# -----------------------------
cd /workspace

bench init frappe-bench \
    --frappe-branch version-15 \
    --ignore-exist \
    --skip-redis-config-generation

cd frappe-bench

# -----------------------------
# Container-based Services (FIXED FOR v15)
# -----------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-socketio:6379

# Remove redis services from Procfile (Docker-managed)
sed -i '/redis/d' Procfile

# -----------------------------
# Create Development Site
# -----------------------------
bench new-site dev.localhost \
    --mariadb-root-password 123 \
    --admin-password admin \
    --mariadb-user-host-login-scope='%' \
    --force

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

# Start bench

bench start

echo "✅ Frappe 15 setup complete!"
echo "➡️  Run: bench start"
