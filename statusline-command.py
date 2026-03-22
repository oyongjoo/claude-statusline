#!/usr/bin/env python3
import sys
import json
import datetime

sys.stdout.reconfigure(encoding='utf-8')
sys.stdin.reconfigure(encoding='utf-8')


def get_val(data, path, default='0'):
    v = data
    for k in path.split('.'):
        v = v.get(k, {}) if isinstance(v, dict) else {}
    return v if v != {} else default


def fmt_remaining(ts):
    if not ts or ts == '0':
        return ''
    dt = datetime.datetime.fromtimestamp(int(ts))
    now = datetime.datetime.now()
    diff = dt - now
    if diff.total_seconds() <= 0:
        return '0시간00분'
    hours = int(diff.total_seconds() // 3600)
    mins = int((diff.total_seconds() % 3600) // 60)
    return f'{hours}시간{mins:02d}분'


def fmt_reset(ts):
    if not ts or ts == '0':
        return ''
    dt = datetime.datetime.fromtimestamp(int(ts))
    now = datetime.datetime.now()
    if dt.date() == now.date():
        return dt.strftime('%H:%M')
    return dt.strftime('%m/%d %H:%M')


data = json.loads(sys.stdin.read())

model = get_val(data, 'model.display_name', 'Claude')
cost = float(get_val(data, 'cost.total_cost_usd', '0'))

five_hr_pct = int(round(float(get_val(data, 'rate_limits.five_hour.used_percentage', '0'))))
five_hr_remaining = fmt_remaining(get_val(data, 'rate_limits.five_hour.resets_at', '0'))
seven_day_pct = int(round(float(get_val(data, 'rate_limits.seven_day.used_percentage', '0'))))
seven_day_reset = fmt_reset(get_val(data, 'rate_limits.seven_day.resets_at', '0'))

ctx = int(round(float(get_val(data, 'context_window.used_percentage', '0'))))

dur_ms = int(get_val(data, 'cost.total_duration_ms', '0'))
mins_val = dur_ms // 60000
secs_val = (dur_ms % 60000) // 1000

session = f'세션:{five_hr_pct}%({five_hr_remaining})' if five_hr_remaining else f'세션:{five_hr_pct}%'
week = f'주간:{seven_day_pct}%({seven_day_reset})' if seven_day_reset else f'주간:{seven_day_pct}%'

print(f'[{model}] ${cost:.2f} | {session} | {week} | ctx:{ctx}% | {mins_val}m{secs_val}s')
