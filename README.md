# Claude 用量显示教程

这个工具会在两个地方显示 Claude 的用量，和 Claude Code 里 `/usage` 看到的数字一样：

1. **Claude Code 底部状态栏**：`Opus 5.5 | 会话 23% · 2小时1分后重置 | 本周 41%`
2. **GNOME 屏幕右上角（顶栏）**：一直显示 `Claude 23%`，点它会弹出详情。

适用环境：Fedora + GNOME 45～50（本机是 GNOME 50），已安装 Claude Code。

---

## 一、文件夹里有什么

```
Claude用量显示教程/
├── 教程.md                        ← 本文件
├── 安装.sh                        ← 一键安装
├── 卸载.sh                        ← 一键卸载
└── 源文件/
    ├── statusline-usage.py         ← 状态栏脚本（Python）
    └── claude-usage@pepsi.local/   ← GNOME 顶栏扩展
        ├── extension.js            ← 扩展主程序
        └── metadata.json           ← 扩展说明信息
```

---

## 二、工作原理

```
Claude Code ──(每60秒把用量数据交给)──▶ statusline-usage.py
                                          │
                     ┌────────────────────┴────────────────────┐
                     ▼                                         ▼
          在 Claude Code 底部显示一行文字        写入 ~/.cache/claude-usage.json
                                                               │
                                                               ▼
                                         GNOME 顶栏扩展每 15 秒读取一次并显示
```

- Claude Code 自己知道你的用量。它会定时运行状态栏脚本，并把用量数据交给它。
- 脚本做两件事：一是输出一行文字，显示在 Claude Code 底部；二是把数据存进一个小文件。
- 顶栏扩展不联网，只是读那个小文件。

所以：**数据只在 Claude Code 运行时更新**。关掉 Claude Code 后，顶栏显示的是最后一次记录的数值，弹出菜单里会写明「数据更新于 X 分钟前」。

---

## 三、安装方法

### 方法 A：一键安装（推荐）

1. 打开「文件」，进入 `文档/Claude用量显示教程`。
2. 在空白处点右键 →「在终端中打开」。
3. 输入下面这行，按回车：
   ```
   bash 安装.sh
   ```
4. 新开一个 Claude Code 窗口，就能看到底部状态栏。
5. **注销再登录一次**，屏幕右上角就会出现 `Claude xx%`。

> 为什么要注销？因为本机用的是 Wayland，GNOME 只在登录时查找新扩展。

安装脚本会先把原来的 `~/.claude/settings.json` 备份为 `settings.json.bak`。

### 方法 B：手动安装（想了解每一步时用）

**第 1 步：复制状态栏脚本**
```
cp 源文件/statusline-usage.py ~/.claude/
chmod +x ~/.claude/statusline-usage.py
```

**第 2 步：让 Claude Code 使用这个脚本**

用文本编辑器打开 `~/.claude/settings.json`，在最外层的大括号里加上这一段（注意前一项末尾要有英文逗号）：
```json
"statusLine": {
  "type": "command",
  "command": "/home/pepsi/.claude/statusline-usage.py",
  "refreshInterval": 60
}
```
`refreshInterval` 是刷新间隔，单位是秒。

**第 3 步：安装顶栏扩展**
```
cp -r 源文件/claude-usage@pepsi.local ~/.local/share/gnome-shell/extensions/
```

**第 4 步：注销再登录，然后启用扩展**
```
gnome-extensions enable claude-usage@pepsi.local
```

---

## 四、日常使用

| 位置 | 显示内容 |
|---|---|
| Claude Code 底部 | 模型名、当前会话用量、多久后重置、本周用量 |
| 顶栏文字 | `Claude 23%`（当前会话用量） |
| 顶栏颜色 | 低于 70% 为白色，70% 以上橙色，90% 以上红色 |
| 点击顶栏 | 当前会话用量、本周用量、各自多久后重置、数据是几分钟前更新的 |

说明：
- 「会话」就是 `/usage` 里的 current session，也就是 **5 小时**的用量窗口；「本周」是 7 天窗口。
- 刚装好时显示 `Claude --`，在 Claude Code 里对话一次后就会出现数字。
- 5 小时窗口过期后，顶栏会自动显示 `Claude 0%`。

---

## 五、自己修改

改完源文件后，需要把它复制到安装位置才会生效（或者直接改安装位置里的文件）：

| 文件 | 安装位置 | 改完后怎么生效 |
|---|---|---|
| `statusline-usage.py` | `~/.claude/statusline-usage.py` | 下一次刷新自动生效 |
| `extension.js` | `~/.local/share/gnome-shell/extensions/claude-usage@pepsi.local/` | 注销再登录 |

常见修改：

**改变色阈值或颜色**：打开 `extension.js`，找到这一行：
```js
this._label.style = p >= 90 ? 'color:#ff6b6b;' : p >= 70 ? 'color:#ffb347;' : '';
```
把 `90`、`70` 改成你想要的百分比；`#ff6b6b`（红）、`#ffb347`（橙）是颜色代码。

**改顶栏文字**：在 `extension.js` 里找 `` `Claude ${p}%` ``，把 `Claude` 改成别的字，比如 `C`。

**改顶栏刷新频率**：在 `extension.js` 里找 `timeout_add_seconds(GLib.PRIORITY_DEFAULT, 15,`，`15` 就是秒数。

**改底部状态栏内容**：打开 `statusline-usage.py`，`parts.append(...)` 那几行决定显示什么。

> 修改前建议先复制一份备份。改坏了可以从本文件夹的 `源文件` 里重新复制。

---

## 六、常见问题

**顶栏没有出现？**
在终端运行：
```
gnome-extensions info claude-usage@pepsi.local
```
- 如果显示「已启用 / ENABLED」但看不到：再注销登录一次。
- 如果显示「已禁用 / DISABLED」：运行 `gnome-extensions enable claude-usage@pepsi.local`。
- 如果显示「出错 / ERROR」：运行 `journalctl -b /usr/bin/gnome-shell | grep -i claude`，查看错误原因。
- 如果提示找不到扩展：检查扩展文件夹是否已复制到 `~/.local/share/gnome-shell/extensions/`。

**底部状态栏没有出现？**
- 确认 `~/.claude/settings.json` 里有 `statusLine` 那一段。
- 确认脚本可以运行：`ls -l ~/.claude/statusline-usage.py`，权限里要有 `x`。
- 需要新开 Claude Code 窗口才会生效。

**顶栏数字一直不变？**
数据只在 Claude Code 运行时更新。打开 Claude Code 对话一次，等一分钟即可。

**GNOME 升级后扩展失效？**
GNOME 大版本升级（比如升到 51）后，打开 `metadata.json`，在 `"shell-version"` 列表里加上新版本号，比如 `"51"`，然后注销再登录。

---

## 七、卸载

在本文件夹打开终端，运行：
```
bash 卸载.sh
```
它会删除脚本、设置项和扩展。注销再登录后，顶栏图标就会彻底消失。本文件夹不会被删除。
