#!/usr/bin/env bash
input=$(cat)

parse() {
  python3 -c "
import json, sys, datetime

data = json.loads(sys.stdin.read())

def get(path, default='0'):
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

model = get('model.display_name', 'Claude')
cost = float(get('cost.total_cost_usd', '0'))

five_hr_pct = int(round(float(get('rate_limits.five_hour.used_percentage', '0'))))
five_hr_remaining = fmt_remaining(get('rate_limits.five_hour.resets_at', '0'))
seven_day_pct = int(round(float(get('rate_limits.seven_day.used_percentage', '0'))))
seven_day_reset = fmt_reset(get('rate_limits.seven_day.resets_at', '0'))

ctx = int(round(float(get('context_window.used_percentage', '0'))))

dur_ms = int(get('cost.total_duration_ms', '0'))
mins = dur_ms // 60000
secs = (dur_ms % 60000) // 1000

session = f'세션:{five_hr_pct}%({five_hr_remaining})' if five_hr_remaining else f'세션:{five_hr_pct}%'
week = f'주간:{seven_day_pct}%({seven_day_reset})' if seven_day_reset else f'주간:{seven_day_pct}%'

print(f'[{model}] \${cost:.2f} | {session} | {week} | ctx:{ctx}% | {mins}m{secs}s')
" <<< "$input"
}

parse
