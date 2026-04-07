#!/usr/bin/env bash
set -euo pipefail

# Example run script for the gitpush skill.
# WARNING: This script performs real git operations. Review before running.

start_ts=$(date +%s)

cwd=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$cwd" ]; then
  echo "Not inside a git repository." >&2
  exit 1
fi

echo "Checking git status..."
status=$(git status --porcelain)
if [ -z "$status" ]; then
  echo "✓ 工作区没有可提交的内容"
  exit 0
fi

echo "Staging all changes..."
git add -A

echo "Collecting staged changes..."
mapfile -t changes < <(git diff --cached --name-status)
added=0; modified=0; deleted=0
added_files=()
modified_files=()
deleted_files=()
for line in "${changes[@]}"; do
  typ=${line%%$'\t'*}
  file=${line#*$'\t'}
  case "$typ" in
    A) added=$((added+1)); added_files+=("$file") ;;
    M) modified=$((modified+1)); modified_files+=("$file") ;;
    D) deleted=$((deleted+1)); deleted_files+=("$file") ;;
    *) modified=$((modified+1)); modified_files+=("$file") ;;
  esac
done

# Simple commit message heuristic
msg_prefix="chore"
if [ $added -gt 0 ] && [ $modified -eq 0 ] && [ $deleted -eq 0 ]; then
  msg_prefix="feat"
fi
if [ $modified -gt 0 ] && [ $added -eq 0 ]; then
  msg_prefix="fix"
fi

summaries=()
if [ ${#added_files[@]} -gt 0 ]; then
  summaries+=("新增 ${added_files[0]}")
fi
if [ ${#modified_files[@]} -gt 0 ]; then
  summaries+=("修改 ${modified_files[0]}")
fi
if [ ${#deleted_files[@]} -gt 0 ]; then
  summaries+=("删除 ${deleted_files[0]}")
fi

summary=$(IFS='，'; echo "${summaries[*]}")
commit_msg="$msg_prefix: $summary"

echo "Committing: $commit_msg"
git commit -m "$commit_msg"

# Ensure upstream exists
branch=$(git rev-parse --abbrev-ref HEAD)
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "Pushing to upstream..."
  git push
else
  echo "No upstream, pushing and setting upstream to origin/$branch"
  git push -u origin "$branch"
fi

end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))

echo "✓ 提交成功！"
echo "- 提交信息: $commit_msg"
echo "- 变更文件: $added 个新增, $modified 个修改, $deleted 个删除"
echo "- 耗时: ${elapsed} 秒"
