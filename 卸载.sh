#!/bin/bash
# 一键卸载：移除状态栏脚本、设置项和顶栏扩展
# 用法：在本文件夹打开终端，运行  bash 卸载.sh
UUID=claude-usage@pepsi.local
SETTINGS="$HOME/.claude/settings.json"

gnome-extensions disable "$UUID" 2>/dev/null
python3 - "$UUID" <<'EOF'
import ast, subprocess, sys
uuid = sys.argv[1]
key = ["org.gnome.shell", "enabled-extensions"]
cur = subprocess.run(["gsettings", "get", *key], capture_output=True, text=True).stdout.strip()
lst = ast.literal_eval(cur.replace("@as ", "")) if cur else []
if uuid in lst:
    lst.remove(uuid)
    subprocess.run(["gsettings", "set", *key, str(lst)], check=True)
EOF
rm -rf "$HOME/.local/share/gnome-shell/extensions/$UUID"

if [ -f "$SETTINGS" ]; then
python3 - "$SETTINGS" <<'EOF'
import json, sys
path = sys.argv[1]
s = json.load(open(path))
s.pop("statusLine", None)
with open(path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
EOF
fi
rm -f "$HOME/.claude/statusline-usage.py" "$HOME/.cache/claude-usage.json"

echo "卸载完成。注销再登录后顶栏图标会彻底消失。"
