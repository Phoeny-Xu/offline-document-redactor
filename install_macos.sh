#!/bin/bash
# 在当前 Mac 安装法律文书脱敏助手 WorkBuddy 技能，并生成桌面双击入口。
# 与 Windows 安装器 install_windows.py 镜像同一套逻辑；本包同时适配 Windows 与 macOS。
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "仅支持 macOS。Windows 请运行 install_windows.bat。" >&2
  exit 1
fi

bundle_dir="$(cd "$(dirname "$0")" && pwd)"
package_dir="$bundle_dir/contract-desensitizer-offline"
skills_dir="${CONTRACT_DESENSITIZER_SKILLS_DIR:-$HOME/.workbuddy/skills}"
target_dir="$skills_dir/contract-desensitizer-offline"
desktop_dir="${CONTRACT_DESENSITIZER_DESKTOP_DIR:-$HOME/Desktop}"
desktop_app="$desktop_dir/法律文书脱敏助手（WorkBuddy）.app"
desktop_stop_app="$desktop_dir/停止法律文书脱敏助手服务.app"
legacy_desktop_app="$desktop_dir/合同脱敏（WorkBuddy）.app"

# 与 install_windows.py 的 BUILD_ID 保持一致的版本标记
build_id="contract-desensitizer-v1.3.0-20261102-r110"
prev_build_ids=(
  "contract-desensitizer-v1.3.0-20261102-r109"
  "contract-desensitizer-v1.3.0-20261101-r108"
  "contract-desensitizer-v1.3.0-20261101-r106"
  "contract-desensitizer-v1.3.0-20261101-r105"
  "contract-desensitizer-v1.3.0-20261101-r104"
  "contract-desensitizer-v1.3.0-20261031-r103"
  "contract-desensitizer-v1.3.0-20261031-r102"
  "contract-desensitizer-v1.3.0-20261031-r101"
  "contract-desensitizer-v1.3.0-20261031-r100"
  "contract-desensitizer-v1.3.0-20261031-r99"
  "contract-desensitizer-v1.3.0-20261030-r98"
  "contract-desensitizer-v1.3.0-20261030-r97"
  "contract-desensitizer-v1.3.0-20261030-r96"
  "contract-desensitizer-v1.3.0-20261030-r95"
  "contract-desensitizer-v1.3.0-20261029-r93"
  "contract-desensitizer-v1.3.0-20261028-r92"
  "contract-desensitizer-v1.3.0-20261028-r91"
  "contract-desensitizer-v1.3.0-20261028-r90"
  "contract-desensitizer-v1.3.0-20261028-r89"
  "contract-desensitizer-v1.3.0-20261027-r87"
  "contract-desensitizer-v1.3.0-20261027-r86"
  "contract-desensitizer-v1.3.0-20261027-r85"
  "contract-desensitizer-v1.3.0-20261026-r84"
  "contract-desensitizer-v1.3.0-20261026-r83"
  "contract-desensitizer-v1.3.0-20261026-r82"
  "contract-desensitizer-v1.3.0-20261026-r80"
  "contract-desensitizer-v1.3.0-20261026-r79"
  "contract-desensitizer-v1.3.0-20261023-r78"
  "contract-desensitizer-v1.3.0-20261023-r77"
  "contract-desensitizer-v1.3.0-20261023-r76"
  "contract-desensitizer-v1.3.0-20261023-r75"
  "contract-desensitizer-v1.3.0-20261022-r74"
  "contract-desensitizer-v1.3.0-20261022-r73"
  "contract-desensitizer-v1.3.0-20261022-r72"
  "contract-desensitizer-v1.3.0-20261022-r71"
  "contract-desensitizer-v1.3.0-20261022-r70"
  "contract-desensitizer-v1.3.0-20261022-r69"
  "contract-desensitizer-v1.3.0-20261021-r68"
  "contract-desensitizer-v1.3.0-20261021-r67"
  "contract-desensitizer-v1.3.0-20261021-r66"
  "contract-desensitizer-v1.3.0-20261014-macosocr"
  "contract-desensitizer-v1.3.0-20261014"
  "contract-desensitizer-v1.3.0-20261011"
  "contract-desensitizer-v1.3.0-dev-20261003"
  "contract-desensitizer-v1.2.3-20261002"
)

if [ ! -f "$package_dir/SKILL.md" ]; then
  echo "安装包不完整：缺少 contract-desensitizer-offline/SKILL.md。" >&2
  exit 1
fi

python_bin=""
for name in python3.13 python3.12 python3.11 python3.10 python3; do
  candidate="$(command -v "$name" 2>/dev/null || true)"
  if [ -n "$candidate" ] && "$candidate" -c 'import sys; assert sys.version_info >= (3, 9)' 2>/dev/null; then
    python_bin="$candidate"
    break
  fi
done
if [ -z "$python_bin" ]; then
  echo "需要 Python 3.9 或更新版本。请让 WorkBuddy 先安装 Python，然后重新运行此脚本。" >&2
  exit 1
fi

is_prev_build() {
  local candidate="$1"
  local b
  for b in "${prev_build_ids[@]}"; do
    [ "$candidate" = "$b" ] && return 0
  done
  return 1
}

write_skill_path_resource() {
  local app="$1"
  /bin/mkdir -p "$app/Contents/Resources"
  /usr/bin/printf '%s\n' "$target_dir" > "$app/Contents/Resources/contract-desensitizer-path.txt"
  /bin/chmod 600 "$app/Contents/Resources/contract-desensitizer-path.txt"
}

ensure_desktop_app() {
  local app="$1"
  local source="$2"
  local label="$3"
  if [ -e "$app" ]; then
    local resource="$app/Contents/Resources/contract-desensitizer-path.txt"
    if [ ! -f "$resource" ]; then
      echo "$label已存在但无法确认属于本工具，未覆盖：$app" >&2
      exit 1
    fi
    write_skill_path_resource "$app"
    echo "$label已存在，已更新其工具路径：$app"
  else
    /usr/bin/osacompile -o "$app" "$source" >/dev/null
    write_skill_path_resource "$app"
    echo "$label已创建：$app"
  fi
}

assert_owned_or_absent_app() {
  local app="$1"
  local label="$2"
  if [ -e "$app" ] && [ ! -f "$app/Contents/Resources/contract-desensitizer-path.txt" ]; then
    echo "$label已存在但无法确认属于本工具，未覆盖：$app" >&2
    exit 1
  fi
}

assert_owned_or_absent_app "$desktop_app" "桌面启动入口"
assert_owned_or_absent_app "$desktop_stop_app" "桌面停止入口"

mkdir -p "$skills_dir" "$desktop_dir"
if [ -e "$target_dir" ]; then
  installed_build="$(cat "$target_dir/.workbuddy-package-build" 2>/dev/null || true)"
  if is_prev_build "$installed_build"; then
    /usr/bin/ditto "$package_dir" "$target_dir"
    printf '%s\n' "$build_id" > "$target_dir/.workbuddy-package-build"
    echo "已更新上一份 WorkBuddy 本地包；旧版生成的脱敏文件仍需从原件重新生成。"
  elif [ "$installed_build" != "$build_id" ]; then
    echo "目标目录已有另一份技能，未覆盖：$target_dir" >&2
    exit 1
  else
    echo "同版本技能已安装。"
  fi
else
  staging_dir="$(mktemp -d "$skills_dir/.contract-desensitizer-offline.XXXXXX")"
  /usr/bin/ditto "$package_dir" "$staging_dir"
  printf '%s\n' "$build_id" > "$staging_dir/.workbuddy-package-build"
  mv "$staging_dir" "$target_dir"
  echo "WorkBuddy 技能已安装：$target_dir"
fi

if [ ! -f "$target_dir/scripts/pdf_vision_ocr" ]; then
  echo "安装包不完整：缺少macOS Vision识别组件。" >&2
  exit 1
fi
chmod 755 "$target_dir/scripts/pdf_vision_ocr"
if [ ! -f "$bundle_dir/stop.applescript" ]; then
  echo "安装包不完整：缺少stop.applescript。" >&2
  exit 1
fi

venv_python="$target_dir/scripts/.venv/bin/python"
if [ ! -x "$venv_python" ] ||
   ! "$venv_python" -c 'import docx, pdfplumber, pypdf, reportlab, pypdfium2, PIL, regex' 2>/dev/null; then
  echo "正在建立独立 Python 环境并安装依赖（首次安装依赖需要联网）…"
  "$python_bin" -m venv "$target_dir/scripts/.venv"
  "$venv_python" -m pip install \
    --disable-pip-version-check --quiet -r "$target_dir/scripts/requirements.txt"
fi

echo "正在检查识别和脱敏引擎…"
"$venv_python" "$target_dir/scripts/contract_sensitive_detector.py" --selftest --quiet
"$venv_python" "$target_dir/scripts/contract_redactor.py" --selftest >/dev/null

ensure_desktop_app "$desktop_app" "$bundle_dir/launcher.applescript" "桌面启动入口"
ensure_desktop_app "$desktop_stop_app" "$bundle_dir/stop.applescript" "桌面停止入口"
if [ -d "$legacy_desktop_app" ] && [ "$legacy_desktop_app" != "$desktop_app" ]; then
  legacy_resource="$legacy_desktop_app/Contents/Resources/contract-desensitizer-path.txt"
  if [ -f "$legacy_resource" ]; then
    /bin/rm -rf "$legacy_desktop_app"
    echo "已移除旧名称桌面入口：$legacy_desktop_app"
  else
    echo "发现未标记的旧名称桌面入口，未删除：$legacy_desktop_app" >&2
  fi
fi
echo "安装完成。双击桌面应用，或对 WorkBuddy 说：帮我把法律文书脱敏。"
echo "首次安装依赖需要联网，安装完成后文书处理不联网。"
