#!/bin/bash
set -euo pipefail

# 旧入口仅保留只读审计。实际上传必须由 dual-git-ssh-sync Skill/MCP
# 在用户确认后执行，避免覆盖远端历史或产生 LFS 断链。

REPO_DIR="${1:-$(pwd)}"
BRANCH="${2:-main}"
SYNC_CLI="/Users/wangzirui/.zcode/skills/dual-git-ssh-sync/scripts/dual_git_sync.py"

if [[ ! -f "$SYNC_CLI" ]]; then
    echo "未找到 dual-git-ssh-sync：$SYNC_CLI" >&2
    exit 1
fi

echo "此兼容脚本只执行双远端只读审计，不提交、不推送。"
python3 "$SYNC_CLI" status \
    --repo "$REPO_DIR" \
    --branch "$BRANCH"

echo "如需上传，请在 Zcode 中调用 dual_git_push，并在用户确认后设置 confirm=true。"
