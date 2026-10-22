#!/usr/bin/env bash
# emoji-wisp-skill 一键发布脚本
#
# 流程：校验 SKILL.md 标准 -> (可选)更新版本号 -> 服务健康检查 -> 提交推送 -> 远端安装验证
#
# 用法:
#   bash scripts/publish.sh                          # 校验 + 推送 + 验证（无改动则跳过提交）
#   bash scripts/publish.sh -m "docs: update tools"  # 携带提交信息发布
#   bash scripts/publish.sh --version 1.2.0          # 同步更新 SKILL.md metadata.version 后发布
#   bash scripts/publish.sh --skip-health            # 跳过 emoji-wisp 服务健康检查
#   bash scripts/publish.sh --dry-run                # 只校验，不提交不推送
set -euo pipefail

REPO_SLUG="emoji-wisp/emoji-wisp-skill"
REPO_URL="https://github.com/${REPO_SLUG}"
SERVICE_URL="https://emoji.i68.ltd"
BRANCH="main"

COMMIT_MSG=""
NEW_VERSION=""
SKIP_HEALTH=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m)          COMMIT_MSG="$2"; shift 2 ;;
    --version)   NEW_VERSION="$2"; shift 2 ;;
    --skip-health) SKIP_HEALTH=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    *) echo "未知参数: $1"; echo "用法: bash scripts/publish.sh [-m <msg>] [--version x.y.z] [--skip-health] [--dry-run]"; exit 1 ;;
  esac
done

# 始终以仓库根为工作目录（脚本位于 <root>/scripts/ 下）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

step() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
die()  { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ---------- 1. 校验 SKILL.md（agentskills.io 规范必填项） ----------
step "校验 SKILL.md frontmatter"

[[ -f SKILL.md ]] || die "缺少 SKILL.md"

# name：仅小写字母/数字/连字符，不以连字符开头结尾、无连续连字符，≤64 字符
NAME="$(grep -m1 '^name:' SKILL.md | sed 's/^name:[[:space:]]*//' | tr -d '[:space:]')"
[[ -n "$NAME" ]] || die "frontmatter 缺少 name"
[[ ${#NAME} -le 64 ]] || die "name 超过 64 字符: ${#NAME}"
[[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "name 不合规（需小写字母/数字/单连字符）: $NAME"
ok "name: $NAME"

# description：折叠块拼接后非空且 ≤1024 字符
DESC="$(awk '/^description:/{flag=1; sub(/^description:[[:space:]]*>?[[:space:]]*/,""); if($0!=""){printf "%s ",$0}; next} flag && /^[^[:space:]#-]/{flag=0} flag{gsub(/^[[:space:]]+/,""); if($0!="") printf "%s ",$0}' SKILL.md)"
[[ -n "${DESC// }" ]] || die "frontmatter 缺少 description"
DESC_LEN=${#DESC}
[[ $DESC_LEN -le 1024 ]] || die "description 超过 1024 字符: $DESC_LEN"
ok "description: ${DESC_LEN} 字符（上限 1024）"

grep -q '^license:' SKILL.md || die "缺少 license 字段（仓库含 MIT LICENSE，规范要求声明）"
ok "license 已声明"

# ---------- 2. （可选）更新 metadata.version ----------
if [[ -n "$NEW_VERSION" ]]; then
  step "更新版本号 -> ${NEW_VERSION}"
  [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "版本号需为 x.y.z 格式: $NEW_VERSION"
  if [[ $DRY_RUN -eq 1 ]]; then
    ok "dry-run：跳过写入（发布时将设 metadata.version = ${NEW_VERSION}）"
  else
    sed -i "s|^\(  version: \".*\"\)$|  version: \"${NEW_VERSION}\"|" SKILL.md
    grep -q "  version: \"${NEW_VERSION}\"" SKILL.md || die "版本号更新失败"
    ok "SKILL.md metadata.version = ${NEW_VERSION}"
  fi
fi

# ---------- 3. 服务健康检查 ----------
if [[ $SKIP_HEALTH -eq 0 ]]; then
  step "检查 emoji-wisp 服务可达性"
  HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$SERVICE_URL" || echo 000)"
  [[ "$HTTP_CODE" == 2* || "$HTTP_CODE" == 3* ]] || die "服务不可达（HTTP ${HTTP_CODE}）: ${SERVICE_URL}（可用 --skip-health 跳过）"
  ok "服务在线（HTTP ${HTTP_CODE}）"
fi

# ---------- 4. git 状态检查 ----------
step "检查 git 状态"
[[ "$(git rev-parse --abbrev-ref HEAD)" == "$BRANCH" ]] || die "当前不在 ${BRANCH} 分支"
[[ "$(git remote get-url origin)" == *"/${REPO_SLUG}" || "$(git remote get-url origin)" == *"/${REPO_SLUG}.git" ]] || die "origin 不是 ${REPO_URL}"
ok "分支 ${BRANCH}，origin 指向 ${REPO_SLUG}"

if [[ $DRY_RUN -eq 1 ]]; then
  step "dry-run 结束：校验全部通过，未提交未推送"
  exit 0
fi

# ---------- 5. 提交并推送 ----------
step "提交并推送"
if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  if [[ -z "$COMMIT_MSG" ]]; then
    COMMIT_MSG="chore: publish skill update ($(date +%Y-%m-%d))"
  fi
  git commit -m "$COMMIT_MSG"
  ok "已提交: ${COMMIT_MSG}"
else
  ok "工作区无改动，跳过提交"
fi
git push origin "$BRANCH" || die "推送失败（远端可能有新提交，请先 git pull --rebase）"
ok "已推送到 ${REPO_URL}"

# ---------- 6. 远端安装验证 ----------
step "验证远端可被 npx skills add 发现"
LIST_OUTPUT="$(npx -y skills@latest add "$REPO_SLUG" --list -y 2>&1 || true)"
echo "$LIST_OUTPUT" | grep -q "$NAME" || die "远端验证失败：skills CLI 未发现技能 ${NAME}。原始输出:\n${LIST_OUTPUT}"
ok "技能 ${NAME} 已可通过 npx skills add ${REPO_SLUG} 安装"

printf '\n\033[32m✅ 发布完成\033[0m\n'
echo "  仓库:   ${REPO_URL}"
echo "  安装:   npx skills add ${REPO_SLUG}"
echo "  上榜:   安装后自动出现在 https://skills.sh/${REPO_SLUG}（按安装量遥测排名，无需提交审核）"
