#!/usr/bin/env python3
import sys
import json
import datetime
import os
import subprocess
import re

sys.stdout.reconfigure(encoding='utf-8')
sys.stdin.reconfigure(encoding='utf-8')


# ── ANSI 색상 ──
def c(code, s):
    return f'\033[{code}m{s}\033[0m'


DIM = '2'; BOLD = '1'; RED = '31'; GREEN = '32'
YELLOW = '33'; BLUE = '34'; MAGENTA = '35'; CYAN = '36'


def get_val(data, path, default='0'):
    v = data
    for k in path.split('.'):
        v = v.get(k, {}) if isinstance(v, dict) else {}
    return v if v != {} else default


def fmt_remaining(ts):  # 리셋까지 남은 시간 → H:MM
    if not ts or ts == '0':
        return ''
    diff = datetime.datetime.fromtimestamp(int(ts)) - datetime.datetime.now()
    if diff.total_seconds() <= 0:
        return '0:00'
    h = int(diff.total_seconds() // 3600)
    m = int((diff.total_seconds() % 3600) // 60)
    return f'{h}:{m:02d}'


def fmt_reset(ts):  # 리셋 시각
    if not ts or ts == '0':
        return ''
    dt = datetime.datetime.fromtimestamp(int(ts))
    now = datetime.datetime.now()
    return dt.strftime('%H:%M') if dt.date() == now.date() else dt.strftime('%m/%d %H:%M')


def pct_color(p):
    return RED if p >= 80 else (YELLOW if p >= 50 else GREEN)


def human(n):
    n = int(n)
    if n >= 1000:
        return f'{n/1000:.0f}k' if n >= 10000 else f'{n/1000:.1f}k'
    return str(n)


def short_model(dn):  # 'Opus 4.8 (1M context)' -> 'Opus4.8(1M)'
    m = re.match(r'([A-Za-z]+)\s+([\d.]+)', dn)
    if not m:
        return dn
    s = m.group(1) + m.group(2)
    if '1M' in dn or '1m' in dn:
        s += '(1M)'
    return s


def model_color(dn):  # 계열별 색상 구분
    d = dn.lower()
    if 'opus' in d:
        return '95'    # 밝은 마젠타
    if 'sonnet' in d:
        return '94'    # 밝은 파랑
    if 'haiku' in d:
        return '92'    # 밝은 초록
    return '1'


data = json.loads(sys.stdin.read())

# ── 데이터 ──
raw_model = get_val(data, 'model.display_name', 'Claude')
model = short_model(raw_model)
effort = get_val(data, 'effort.level', '')

five_pct = int(round(float(get_val(data, 'rate_limits.five_hour.used_percentage', '0'))))
five_rem = fmt_remaining(get_val(data, 'rate_limits.five_hour.resets_at', '0'))
seven_pct = int(round(float(get_val(data, 'rate_limits.seven_day.used_percentage', '0'))))
seven_reset = fmt_reset(get_val(data, 'rate_limits.seven_day.resets_at', '0'))

ctx_pct = int(round(float(get_val(data, 'context_window.used_percentage', '0'))))
ctx_tok = get_val(data, 'context_window.total_input_tokens', '0')

cwd = get_val(data, 'cwd', '') or get_val(data, 'workspace.current_dir', '')
proj = os.path.basename(cwd) if cwd else ''

# ── git 브랜치 (맨 뒤) ──
branch = ''
if cwd and os.path.isdir(cwd):
    try:
        b = subprocess.run(['git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'],
                           capture_output=True, text=True, timeout=0.5)
        if b.returncode == 0:
            branch = b.stdout.strip()
            d = subprocess.run(['git', '-C', cwd, 'status', '--porcelain'],
                               capture_output=True, text=True, timeout=0.5)
            if d.stdout.strip():
                branch += '*'
    except Exception:
        pass

# ── 세그먼트 (중요 순서: 모델 → 사용량 → git) ──
seg = []

mtxt = c('1;' + model_color(raw_model), model)
if effort and effort != 'none':
    mtxt += ' ' + c(DIM, effort)
seg.append(mtxt)

s = f'S:{five_pct}%({five_rem})' if five_rem else f'S:{five_pct}%'
seg.append(c(pct_color(five_pct), s))

w = f'W:{seven_pct}%({seven_reset})' if seven_reset else f'W:{seven_pct}%'
seg.append(c(pct_color(seven_pct), w))

seg.append(c(pct_color(ctx_pct), f'ctx:{ctx_pct}%({human(ctx_tok)})'))

if proj:
    g = c(CYAN, proj)
    if branch:
        g += c(DIM, ' ⎇ ') + c(MAGENTA, branch)
    seg.append(g)

print(c(DIM, ' | ').join(seg))
