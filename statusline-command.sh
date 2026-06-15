#!/usr/bin/env bash
input=$(cat)

parse() {
  python3 -c "
import json, sys, datetime, os, subprocess

data = json.loads(sys.stdin.read())

# ── ANSI 색상 ──
def c(code, s): return f'\033[{code}m{s}\033[0m'
DIM='2'; BOLD='1'; RED='31'; GREEN='32'; YELLOW='33'; BLUE='34'; MAGENTA='35'; CYAN='36'

def get(path, default='0'):
    v = data
    for k in path.split('.'):
        v = v.get(k, {}) if isinstance(v, dict) else {}
    return v if v != {} else default

def fmt_remaining(ts):
    if not ts or ts == '0': return ''
    diff = datetime.datetime.fromtimestamp(int(ts)) - datetime.datetime.now()
    if diff.total_seconds() <= 0: return '0시간00분'
    h = int(diff.total_seconds() // 3600)
    m = int((diff.total_seconds() % 3600) // 60)
    return f'{h}시간{m:02d}분'

def fmt_reset(ts):
    if not ts or ts == '0': return ''
    dt = datetime.datetime.fromtimestamp(int(ts))
    now = datetime.datetime.now()
    return dt.strftime('%H:%M') if dt.date() == now.date() else dt.strftime('%m/%d %H:%M')

def pct_color(p):
    return RED if p >= 80 else (YELLOW if p >= 50 else GREEN)

def human(n):
    n = int(n)
    if n >= 1000: return f'{n/1000:.0f}k' if n >= 10000 else f'{n/1000:.1f}k'
    return str(n)

# ── 데이터 추출 ──
model = get('model.display_name', 'Claude')
cwd = get('cwd', '') or get('workspace.current_dir', '')
proj = os.path.basename(cwd) if cwd else ''

cost = float(get('cost.total_cost_usd', '0'))
added = int(get('cost.total_lines_added', '0'))
removed = int(get('cost.total_lines_removed', '0'))

five_pct = int(round(float(get('rate_limits.five_hour.used_percentage', '0'))))
five_rem = fmt_remaining(get('rate_limits.five_hour.resets_at', '0'))
seven_pct = int(round(float(get('rate_limits.seven_day.used_percentage', '0'))))
seven_reset = fmt_reset(get('rate_limits.seven_day.resets_at', '0'))

ctx_pct = int(round(float(get('context_window.used_percentage', '0'))))
ctx_tok = get('context_window.total_input_tokens', '0')

dur_ms = int(get('cost.total_duration_ms', '0'))
mins, secs = dur_ms // 60000, (dur_ms % 60000) // 1000

effort = get('effort.level', '')
thinking = bool(data.get('thinking', {}).get('enabled', False))
fast = bool(data.get('fast_mode', False))

# ── git 브랜치 ──
branch = ''
if cwd and os.path.isdir(cwd):
    try:
        b = subprocess.run(['git','-C',cwd,'rev-parse','--abbrev-ref','HEAD'],
                           capture_output=True, text=True, timeout=0.5)
        if b.returncode == 0:
            branch = b.stdout.strip()
            dirty = subprocess.run(['git','-C',cwd,'status','--porcelain'],
                                   capture_output=True, text=True, timeout=0.5)
            if dirty.stdout.strip(): branch += '*'
    except Exception:
        pass

# ── 세그먼트 조립 ──
seg = []
loc = c(CYAN, proj) if proj else ''
if branch: loc += c(DIM, ' ⎇ ') + c(MAGENTA, branch)
if loc: seg.append(loc)

mode = c(BOLD, f'[{model}]')
flags = []
if fast: flags.append(c(YELLOW, '⚡fast'))
if thinking: flags.append(c(MAGENTA, '🧠'))
if effort and effort not in ('medium','none'): flags.append(c(DIM, effort))
if flags: mode += ' ' + ''.join(flags)
seg.append(mode)

seg.append(c(GREEN, f'\${cost:.2f}'))

if added or removed:
    seg.append(c(GREEN, f'+{added}') + c(DIM,'/') + c(RED, f'-{removed}'))

s = f'세션:{five_pct}%({five_rem})' if five_rem else f'세션:{five_pct}%'
seg.append(c(pct_color(five_pct), s))

w = f'주간:{seven_pct}%({seven_reset})' if seven_reset else f'주간:{seven_pct}%'
seg.append(c(pct_color(seven_pct), w))

seg.append(c(pct_color(ctx_pct), f'ctx:{ctx_pct}%({human(ctx_tok)})'))

seg.append(c(DIM, f'{mins}m{secs}s'))

print(c(DIM,' | ').join(seg))
" <<< "$input"
}

parse
