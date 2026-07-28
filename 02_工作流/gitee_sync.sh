#!/bin/bash
# =============================================================================
# Gitee 一键同步脚本
# 将本地 32 个 Obsidian 仓库的最新内容同步到 Gitee 企业版镜像
# 自动处理 LFS 文件转换（Gitee 免费版不支持 LFS）
# 用法: bash gitee_sync.sh              # 检查状态并询问是否推送
#       bash gitee_sync.sh --dry-run    # 只检查状态，不推送
#       bash gitee_sync.sh --force      # 跳过确认，直接推送所有
#       bash gitee_sync.sh 仓库名        # 只推送指定仓库
# =============================================================================

# ─── 颜色 ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── 配置 ─────────────────────────────────────────────────────────────────────
BASE_DIR="/Users/wangzirui"
GITEE_REMOTE="gitee"
GITEE_BRANCH="main"
TIMEOUT=300  # 单仓库推送超时（秒）

# 需要 LFS 转换的仓库列表（已知有 LFS 文件的仓库）
# 脚本会自动检测，这个列表用于提前提示
LFS_REPOS=(
    "孩子们的知识点"
    "丁美霞AI视频"
    "课题与论文知识库"
    "FreeCAD模型制作知识库"
    "草图设计知识库"
    "教科研数据仓库"
)

# ─── 辅助函数 ────────────────────────────────────────────────────────────────

log()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }
info()    { echo -e "${BLUE}[i]${NC} $1"; }
header()  { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ─── 检测 LFS 文件 ──────────────────────────────────────────────────────────

has_lfs_files() {
    local repo_path="$1"
    local count
    count=$(cd "$repo_path" 2>/dev/null && git lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
    echo "$count"
}

# ─── 检查与 Gitee 的同步状态 ────────────────────────────────────────────────

check_sync_status() {
    local repo_path="$1"
    local current_branch
    
    current_branch=$(cd "$repo_path" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # 检查是否有未提交的变更
    local has_uncommitted
    has_uncommitted=$(cd "$repo_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    
    # 检查与 Gitee 的差异
    local gitee_remote_exists
    gitee_remote_exists=$(cd "$repo_path" && git remote -v 2>/dev/null | grep -q "$GITEE_REMOTE" && echo "yes" || echo "no")
    
    local behind="?"
    local ahead="?"
    
    if [ "$gitee_remote_exists" = "yes" ]; then
        # 尝试获取 Gitee 远程的最新 commit
        cd "$repo_path" && git fetch "$GITEE_REMOTE" --quiet 2>/dev/null || true
        
        local local_commit
        local_commit=$(cd "$repo_path" && git rev-parse HEAD 2>/dev/null)
        local remote_commit
        remote_commit=$(cd "$repo_path" && git rev-parse "$GITEE_REMOTE/$GITEE_BRANCH" 2>/dev/null || echo "")
        
        if [ -n "$remote_commit" ]; then
            if [ "$local_commit" = "$remote_commit" ]; then
                ahead="0"
                behind="0"
            else
                ahead=$(cd "$repo_path" && git rev-list --count "$GITEE_REMOTE/$GITEE_BRANCH..HEAD" 2>/dev/null || echo "?")
                behind=$(cd "$repo_path" && git rev-list --count "HEAD..$GITEE_REMOTE/$GITEE_BRANCH" 2>/dev/null || echo "?")
            fi
        else
            # Gitee 仓库为空或不存在
            ahead="NEW"
            behind="-"
        fi
    fi
    
    echo "$has_uncommitted|$ahead|$behind|$gitee_remote_exists|$current_branch"
}

# ─── 推送仓库到 Gitee（无 LFS） ──────────────────────────────────────────────

push_normal() {
    local repo_path="$1"
    local name="$2"
    
    cd "$repo_path" || return 1
    
    # 先提交未提交的变更
    local dirty
    dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$dirty" -gt 0 ]; then
        info "提交 $dirty 个未提交的文件..."
        git add -A
        git commit -m "sync: $(date '+%Y-%m-%d %H:%M') 自动同步到 Gitee" 2>/dev/null || true
    fi
    
    # 推送到 Gitee
    info "推送到 Gitee..."
    if git push "$GITEE_REMOTE" "$GITEE_BRANCH" 2>&1; then
        return 0
    else
        return 1
    fi
}

# ─── 推送仓库到 Gitee（含 LFS 转换） ─────────────────────────────────────────

push_lfs() {
    local repo_path="$1"
    local name="$2"
    
    cd "$repo_path" || return 1
    
    CURRENT_BRANCH=$(git branch --show-current)
    TEMP_BRANCH="gitee-sync-temp"
    
    warn "开始 LFS 转换流程..."
    
    # 保存当前工作区
    local has_stash=false
    if [ -n "$(git status --porcelain)" ]; then
        git stash push -m "gitee-sync-auto-stash" 2>/dev/null || true
        has_stash=true
    fi
    
    # 创建临时分支
    git checkout -b "$TEMP_BRANCH" 2>/dev/null
    
    # 临时添加 LFS 跟踪规则（确保 git lfs checkout 能检出真实文件）
    cat >> .gitattributes << 'LFS_RULES'
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
*.docx filter=lfs diff=lfs merge=lfs -text
*.pptx filter=lfs diff=lfs merge=lfs -text
*.m4a filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
LFS_RULES
    
    git add .gitattributes
    git commit -m "temp: add LFS rules for Gitee sync" 2>/dev/null
    
    # 检出真实文件内容
    info "检出 LFS 真实文件..."
    git lfs checkout 2>&1 || warn "部分 LFS 文件可能未检出"
    
    # 移除 LFS filter，防止 clean filter 转回指针
    git config --local --remove-section filter.lfs 2>/dev/null || true
    
    # 恢复原始 .gitattributes
    git show "$CURRENT_BRANCH:.gitattributes" > .gitattributes 2>/dev/null || rm -f .gitattributes
    
    # 强制重新添加文件（真实内容进入索引）
    git add --renormalize . 2>/dev/null
    git add -A
    
    # 提交并推送
    if [ -n "$(git status --porcelain)" ]; then
        git commit -m "gitee: sync $(date '+%Y-%m-%d %H:%M')"
    fi
    
    info "推送到 Gitee（强制覆盖）..."
    if git push "$GITEE_REMOTE" "$TEMP_BRANCH:main" --force 2>&1; then
        # 清理
        git checkout "$CURRENT_BRANCH" 2>/dev/null
        git branch -D "$TEMP_BRANCH" 2>/dev/null || true
        git lfs install 2>/dev/null
        git lfs checkout 2>/dev/null
        
        if $has_stash; then
            git stash pop 2>/dev/null || true
        fi
        
        return 0
    else
        # 失败时也清理
        git checkout "$CURRENT_BRANCH" 2>/dev/null
        git branch -D "$TEMP_BRANCH" 2>/dev/null || true
        git lfs install 2>/dev/null
        git lfs checkout 2>/dev/null
        
        if $has_stash; then
            git stash pop 2>/dev/null || true
        fi
        
        return 1
    fi
}

# ─── 主流程 ──────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Gitee 一键同步脚本                        ║${NC}"
    echo -e "${CYAN}║        $(date '+%Y-%m-%d %H:%M')                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 解析参数
    DRY_RUN=false
    FORCE=false
    SINGLE_REPO=""
    
    for arg in "$@"; do
        case "$arg" in
            --dry-run) DRY_RUN=true ;;
            --force)   FORCE=true ;;
            --help)
                echo "用法: bash gitee_sync.sh [选项] [仓库名]"
                echo ""
                echo "选项:"
                echo "  --dry-run    只检查状态，不推送"
                echo "  --force      跳过确认，直接推送所有"
                echo "  --help       显示帮助"
                echo ""
                echo "示例:"
                echo "  bash gitee_sync.sh              检查所有仓库并推送"
                echo "  bash gitee_sync.sh --dry-run    只检查状态"
                echo "  bash gitee_sync.sh 孩子们的知识点  只推送指定仓库"
                exit 0
                ;;
            *)
                SINGLE_REPO="$arg"
                ;;
        esac
    done
    
    # ─── 扫描仓库 ───────────────────────────────────────────────────────
    header "扫描仓库状态"
    
    declare -a ALL_REPOS=()
    declare -a NEED_PUSH=()
    declare -a LFS_REPOS_DETECTED=()
    declare -a SYNCED_REPOS=()
    declare -a ERROR_REPOS=()
    
    while IFS= read -r -d '' dir; do
        # 去掉末尾的 /.git
        dir="${dir%/.git}"
        name=$(basename "$dir")
        
        # 如果指定了单仓库，跳过其他
        if [ -n "$SINGLE_REPO" ] && [ "$name" != "$SINGLE_REPO" ]; then
            continue
        fi
        
        ALL_REPOS+=("$name")
        
        # 检查状态
        status=$(check_sync_status "$dir")
        IFS='|' read -r has_uncommitted ahead behind gitee_has branch <<< "$status"
        
        lfs_count=$(has_lfs_files "$dir")
        
        # 显示状态
        if [ "$gitee_has" = "yes" ]; then
            if [ "$ahead" = "NEW" ]; then
                echo -e "  ${YELLOW}[新仓库]${NC} $name (LFS: $lfs_count)"
                NEED_PUSH+=("$name")
            elif [ "$ahead" != "0" ] || [ "$has_uncommitted" -gt 0 ]; then
                if [ "$lfs_count" -gt 0 ]; then
                    echo -e "  ${YELLOW}[需同步]${NC} $name (领先 $ahead, 未提交 $has_uncommitted, LFS: $lfs_count)"
                    LFS_REPOS_DETECTED+=("$name")
                else
                    echo -e "  ${YELLOW}[需同步]${NC} $name (领先 $ahead, 未提交 $has_uncommitted)"
                fi
                NEED_PUSH+=("$name")
            else
                echo -e "  ${GREEN}[已同步]${NC} $name"
                SYNCED_REPOS+=("$name")
            fi
        else
            echo -e "  ${RED}[无Gitee]${NC} $name"
            ERROR_REPOS+=("$name")
        fi
    done < <(find "$BASE_DIR" -maxdepth 2 -name ".git" -type d -print0 2>/dev/null | sort -z)
    
    # ─── 汇总 ───────────────────────────────────────────────────────────
    echo ""
    header "扫描结果汇总"
    echo -e "  总仓库数: ${#ALL_REPOS[@]}"
    echo -e "  ${GREEN}已同步:   ${#SYNCED_REPOS[@]}${NC}"
    echo -e "  ${YELLOW}待推送:   ${#NEED_PUSH[@]}${NC}"
    echo -e "  ${RED}错误:     ${#ERROR_REPOS[@]}${NC}"
    
    if [ "${#NEED_PUSH[@]}" -eq 0 ] && [ "${#ERROR_REPOS[@]}" -eq 0 ]; then
        echo ""
        log "所有仓库已与 Gitee 保持同步，无需操作！"
        exit 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo ""
        info "仅检查模式（--dry-run），不执行推送。"
        info "要推送，执行: bash gitee_sync.sh"
        exit 0
    fi
    
    # ─── 确认推送 ───────────────────────────────────────────────────────
    if [ "$FORCE" != true ]; then
        echo ""
        warn "以上 ${#NEED_PUSH[@]} 个仓库将推送到 Gitee"
        echo -e "  其中 ${#LFS_REPOS_DETECTED[@]} 个含 LFS 文件，将自动转换"
        echo ""
        read -r -p "是否继续推送？(y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            info "已取消"
            exit 0
        fi
        echo ""
    fi
    
    # ─── 执行推送 ───────────────────────────────────────────────────────
    header "开始推送"
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    TOTAL=${#NEED_PUSH[@]}
    INDEX=0
    
    for name in "${NEED_PUSH[@]}"; do
        INDEX=$((INDEX + 1))
        repo_path="$BASE_DIR/$name"
        
        echo ""
        echo -e "${CYAN}[$INDEX/$TOTAL] 处理: $name${NC}"
        
        # 检测 LFS
        lfs_count=$(has_lfs_files "$repo_path")
        
        start_time=$(date +%s)
        
        if [ "$lfs_count" -gt 0 ]; then
            warn "检测到 $lfs_count 个 LFS 文件，使用转换模式..."
            if push_lfs "$repo_path" "$name"; then
                log "推送成功: $name"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                error "推送失败: $name"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        else
            info "无 LFS 文件，直接推送..."
            if push_normal "$repo_path" "$name"; then
                log "推送成功: $name"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                error "推送失败: $name"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
        
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        info "耗时: ${elapsed}s"
    done
    
    # ─── 最终报告 ───────────────────────────────────────────────────────
    echo ""
    header "推送完成"
    echo -e "  ${GREEN}成功: $SUCCESS_COUNT${NC}"
    echo -e "  ${RED}失败: $FAIL_COUNT${NC}"
    echo -e "  总耗时: $(date -u -d @$(($(date +%s) - $(date +%s -d "$(ps -o lstart= -p $$)" 2>/dev/null || echo "now")) + 2>/dev/null || echo "N/A") '+%M分%S秒')"
    
    if [ "$FAIL_COUNT" -gt 0 ]; then
        echo ""
        warn "失败的仓库可能需要手动处理："
        echo "  bash gitee_sync.sh --force 仓库名"
    fi
}

# ─── 执行 ────────────────────────────────────────────────────────────────────
main "$@"