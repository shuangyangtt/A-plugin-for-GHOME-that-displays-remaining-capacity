import GLib from 'gi://GLib';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const CACHE = GLib.build_filenamev([GLib.get_home_dir(), '.cache', 'claude-usage.json']);

function fmtLeft(ts) {
    const left = Math.floor(ts - Date.now() / 1000);
    if (left <= 0) return '已重置';
    const h = Math.floor(left / 3600), m = Math.floor((left % 3600) / 60);
    return h ? `${h}小时${m}分` : `${m}分`;
}

export default class ClaudeUsageExtension extends Extension {
    enable() {
        this._button = new PanelMenu.Button(0.0, 'Claude 用量');
        this._label = new St.Label({text: 'Claude --', y_align: Clutter.ActorAlign.CENTER});
        this._button.add_child(this._label);
        this._detail = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._button.menu.addMenuItem(this._detail);
        Main.panel.addToStatusArea(this.uuid, this._button, 0, 'right');
        this._refresh();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 15, () => {
            this._refresh();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _refresh() {
        let d;
        try {
            const [, bytes] = GLib.file_get_contents(CACHE);
            d = JSON.parse(new TextDecoder().decode(bytes));
        } catch (e) {
            this._label.text = 'Claude --';
            this._detail.label.text = '暂无数据：请先在 Claude Code 中对话一次';
            return;
        }
        const now = Date.now() / 1000;
        const five = d.five_hour, week = d.seven_day;
        if (five && five.resets_at > now) {
            const p = Math.round(five.used_percentage);
            this._label.text = `Claude ${p}%`;
            this._label.style = p >= 90 ? 'color:#ff6b6b;' : p >= 70 ? 'color:#ffb347;' : '';
        } else {
            this._label.text = 'Claude 0%';
            this._label.style = '';
        }
        const lines = [];
        if (five) lines.push(`当前会话：${Math.round(five.used_percentage)}%（${fmtLeft(five.resets_at)}后重置）`);
        if (week) lines.push(`本周：${Math.round(week.used_percentage)}%（${fmtLeft(week.resets_at)}后重置）`);
        const age = Math.floor((now - (d.updated_at || 0)) / 60);
        lines.push(`数据更新于 ${age} 分钟前`);
        this._detail.label.text = lines.join('\n');
    }

    disable() {
        if (this._timer) GLib.source_remove(this._timer);
        this._timer = null;
        this._button?.destroy();
        this._button = null;
    }
}
