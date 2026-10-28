#!/usr/bin/python3
# Claude Code 状态栏脚本：显示当前会话(5小时)用量，并写入缓存供 GNOME 顶栏扩展读取
import json, os, sys, time

data = json.load(sys.stdin)
rl = data.get("rate_limits") or {}
cache = os.path.expanduser("~/.cache/claude-usage.json")


def fmt_reset(ts):
    left = int(ts - time.time())
    if left <= 0:
        return "已重置"
    h, m = divmod(left // 60, 60)
    return f"{h}小时{m}分后重置" if h else f"{m}分后重置"


parts = []
five = rl.get("five_hour")
if five:
    parts.append(f"会话 {five['used_percentage']:.0f}% · {fmt_reset(five['resets_at'])}")
week = rl.get("seven_day")
if week:
    parts.append(f"本周 {week['used_percentage']:.0f}%")

if rl:
    rl["updated_at"] = int(time.time())
    tmp = cache + ".tmp"
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    with open(tmp, "w") as f:
        json.dump(rl, f)
    os.replace(tmp, cache)

model = (data.get("model") or {}).get("display_name", "")
print(" | ".join([model] + parts) if parts else model)
