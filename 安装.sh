#!/bin/bash
# 一键安装：Claude Code 状态栏脚本 + GNOME 顶栏扩展
# 用法：在本文件夹打开终端，运行  bash 安装.sh
set -e
cd "$(dirname "$0")/源文件"

UUID=claude-usage@pepsi.local
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
SETTINGS="$HOME/.claude/settings.json"

echo "1/3 复制状态栏脚本 → ~/.claude/statusline-usage.py"
mkdir -p "$HOME/.claude"
install -m 755 statusline-usage.py "$HOME/.claude/statusline-usage.py"

echo "2/3 写入 Claude Code 设置 → ~/.claude/settings.json"
[ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak" && echo "    （原设置已备份为 settings.json.bak）"
python3 - "$SETTINGS" <<'EOF'
import json, os, sys
path = sys.argv[1]
s = json.load(open(path)) if os.path.exists(path) else {}
s["statusLine"] = {
    "type": "command",
    "command": os.path.expanduser("~/.claude/statusline-usage.py"),
    "refreshInterval": 60,
}
with open(path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
EOF

echo "3/3 安装 GNOME 顶栏扩展 → $EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$UUID"/extension.js "$UUID"/metadata.json "$EXT_DIR/"
python3 - "$UUID" <<'EOF'
import ast, subprocess, sys
uuid = sys.argv[1]
key = ["org.gnome.shell", "enabled-extensions"]
cur = subprocess.run(["gsettings", "get", *key], capture_output=True, text=True).stdout.strip()
lst = ast.literal_eval(cur.replace("@as ", "")) if cur else []
if uuid not in lst:
    lst.append(uuid)
    subprocess.run(["gsettings", "set", *key, str(lst)], check=True)
EOF

echo
echo "安装完成！"
echo "- 底部状态栏：新开一个 Claude Code 窗口即可看到。"
echo "- 顶栏扩展：请注销并重新登录一次，右上角会出现「Claude xx%」。"
