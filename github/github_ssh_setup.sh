#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-geekheart}"
KEY_NAME="${KEY_NAME:-id_ed25519_github}"
KEY_PATH="${HOME}/.ssh/${KEY_NAME}"
KEY_CREATED_THIS_RUN=0

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

cleanup() {
  local code="$1"

  if [ "$code" -ne 0 ] && [ "$KEY_CREATED_THIS_RUN" -eq 1 ]; then
    rm -f "$KEY_PATH" "${KEY_PATH}.pub"
    log "脚本未成功完成，已删除本次生成的 SSH 密钥。"
  fi
}

trap 'cleanup 130' INT
trap 'cleanup 1' HUP TERM
trap 'code=$?; cleanup "$code"' EXIT

is_wsl() {
  if [ -n "${WSL_INTEROP:-}" ] || [ -n "${WSL_DISTRO_NAME:-}" ]; then
    return 0
  fi
  if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
    return 0
  fi
  return 1
}

copy_to_clipboard() {
  local text="$1"

  if have wl-copy; then
    printf '%s' "$text" | wl-copy
    return 0
  fi

  if have xclip; then
    printf '%s' "$text" | xclip -selection clipboard
    return 0
  fi

  if have xsel; then
    printf '%s' "$text" | xsel --clipboard --input
    return 0
  fi

  if have pbcopy; then
    printf '%s' "$text" | pbcopy
    return 0
  fi

  if have powershell.exe; then
    powershell.exe -NoProfile -Command "Set-Clipboard -Value @'
$text
'@" >/dev/null 2>&1
    return 0
  fi

  return 1
}

open_url() {
  local url="$1"
  if is_wsl; then
    if have powershell.exe; then
      powershell.exe -NoProfile -Command "Start-Process 'msedge.exe' '${url}'" >/dev/null 2>&1 \
        || powershell.exe -NoProfile -Command "Start-Process '${url}'" >/dev/null 2>&1 \
        || true
      return 0
    fi
  fi

  if have xdg-open; then
    xdg-open "$url" >/dev/null 2>&1 || true
  elif have open; then
    open "$url" >/dev/null 2>&1 || true
  fi
}

ensure_packages() {
  local missing=()
  for bin in git ssh-keygen curl; do
    if ! have "$bin"; then
      missing+=("$bin")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    return 0
  fi

  log "缺少以下命令：${missing[*]}"
  if ! have sudo; then
    die "需要 sudo 才能安装缺失的依赖"
  fi

  if have apt-get; then
    log "正在使用 apt-get 安装所需依赖..."
    sudo apt-get update
    sudo apt-get install -y git curl openssh-client
  else
    die "当前仅支持在基于 apt-get 的系统上自动安装依赖"
  fi
}

generate_ssh_key() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  if [ -f "$KEY_PATH" ]; then
    log "SSH 密钥已存在：$KEY_PATH"
    return 0
  fi

  log "正在生成 SSH 密钥：$KEY_PATH"
  ssh-keygen -t ed25519 -C "${GITHUB_USER}@github" -f "$KEY_PATH" -N ""
  KEY_CREATED_THIS_RUN=1
}

copy_pubkey_and_open_page() {
  local pub="${KEY_PATH}.pub"
  if [ ! -f "$pub" ]; then
    die "未找到公钥文件：$pub"
  fi

  log ""
  log "正在把公钥复制到剪贴板..."
  if copy_to_clipboard "$(cat "$pub")"; then
    log "公钥已复制到剪贴板。"
  else
    log "当前环境没有可用的剪贴板工具，请手动复制下面的公钥。"
  fi

  log ""
  log "请打开 GitHub 新增 SSH Key 页面："
  log "https://github.com/settings/ssh/new"
  open_url "https://github.com/settings/ssh/new"

  log ""
  log "然后在页面中找到 Add new SSH key，"
  log "把公钥粘贴到 key 输入框里，填写标题后确认保存。"
}

ensure_ssh_auth() {
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$KEY_PATH" >/dev/null
  log "SSH 密钥已加载到 ssh-agent。"
}

main() {
  ensure_packages
  generate_ssh_key
  ensure_ssh_auth
  copy_pubkey_and_open_page

  log ""
  log "完成。"
  log "可执行以下命令测试 SSH 连接："
  log "ssh -T git@github.com"
}

main "$@"
