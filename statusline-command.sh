#!/usr/bin/env bash
input=$(cat)

parse() {
  python3 -c "
import json, sys, datetime, os, subprocess, re, time, tempfile, hashlib

data = json.loads(sys.stdin.read())

# ── ANSI 색상 ──
def c(code, s): return f'\033[{code}m{s}\033[0m'
DIM='2'; BOLD='1'; RED='31'; GREEN='32'; YELLOW='33'; BLUE='34'; MAGENTA='35'; CYAN='36'

def get(path, default='0'):
    v = data
    for k in path.split('.'):
        v = v.get(k, {}) if isinstance(v, dict) else {}
    return v if v != {} else default

def fmt_remaining(ts):  # 리셋까지 남은 시간 → H:MM
    if not ts or ts == '0': return ''
    diff = datetime.datetime.fromtimestamp(int(ts)) - datetime.datetime.now()
    if diff.total_seconds() <= 0: return '0:00'
    h = int(diff.total_seconds() // 3600)
    m = int((diff.total_seconds() % 3600) // 60)
    return f'{h}:{m:02d}'

def fmt_reset(ts):  # 리셋 시각
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

def short_model(dn, ctx_size=0):  # 'Opus 4.8 (1M context)' -> 'Opus4.8(1M)', 'Sonnet 4.6' -> 'Sonnet4.6(200k)'
    m = re.match(r'([A-Za-z]+)\s+([\d.]+)', dn)
    if not m: return dn
    s = m.group(1) + m.group(2)
    n = int(ctx_size) if ctx_size else 0
    if n >= 900000:   s += '(1M)'
    elif n >= 1000:   s += f'({n//1000}k)'
    return s

def model_color(dn):  # 계열별 색상 구분
    d = dn.lower()
    if 'opus' in d: return '95'    # 밝은 마젠타
    if 'sonnet' in d: return '94'  # 밝은 파랑
    if 'haiku' in d: return '92'   # 밝은 초록
    return '1'

# ── 데이터 ──
raw_model = get('model.display_name', 'Claude')
ctx_size = get('context_window.context_window_size', '0')
model = short_model(raw_model, ctx_size)
effort = get('effort.level', '')

five_pct = int(round(float(get('rate_limits.five_hour.used_percentage', '0'))))
five_rem = fmt_remaining(get('rate_limits.five_hour.resets_at', '0'))
seven_pct = int(round(float(get('rate_limits.seven_day.used_percentage', '0'))))
seven_reset = fmt_reset(get('rate_limits.seven_day.resets_at', '0'))

ctx_pct = int(round(float(get('context_window.used_percentage', '0'))))
ctx_tok = get('context_window.total_input_tokens', '0')

cwd = get('cwd', '') or get('workspace.current_dir', '')
proj = os.path.basename(cwd) if cwd else ''

# ── git 브랜치 (맨 뒤, session_id+cwd 키로 5초 캐시) ──
branch = ''
if cwd and os.path.isdir(cwd):
    session_id = re.sub(r'[^A-Za-z0-9_-]', '', get('session_id', ''))
    cache_dir = tempfile.gettempdir()
    cache_file = ''
    if session_id:
        cwd_hash = hashlib.sha1(cwd.encode()).hexdigest()[:8]
        cache_file = os.path.join(cache_dir, f'claude-statusline-git-{session_id}-{cwd_hash}')
        try:  # 하루 넘은 캐시 파일 정리
            for fn in os.listdir(cache_dir):
                if fn.startswith('claude-statusline-git-'):
                    fp = os.path.join(cache_dir, fn)
                    if time.time() - os.path.getmtime(fp) > 86400:
                        os.remove(fp)
        except Exception:
            pass
    cached = None
    if cache_file and os.path.exists(cache_file) and time.time() - os.path.getmtime(cache_file) <= 5:
        try:
            with open(cache_file) as f:
                cached = f.read()
        except Exception:
            cached = None
    if cached is None:
        cached = ''
        try:
            b = subprocess.run(['git','-C',cwd,'rev-parse','--abbrev-ref','HEAD'],
                               capture_output=True, text=True, timeout=0.5)
            if b.returncode == 0:
                cached = b.stdout.strip()
                d = subprocess.run(['git','-C',cwd,'status','--porcelain'],
                                   capture_output=True, text=True, timeout=0.5)
                if d.stdout.strip(): cached += '*'
        except Exception:
            cached = ''
        if cache_file:
            try:
                fd, tmp_path = tempfile.mkstemp(dir=cache_dir, prefix='.claude-statusline-git-')
                with os.fdopen(fd, 'w') as f:
                    f.write(cached)
                os.replace(tmp_path, cache_file)
            except Exception:
                pass
    branch = cached

# ── 세그먼트 (중요 순서: 모델 → 사용량 → git) ──
seg = []

mtxt = c('1;' + model_color(raw_model), model)
if effort and effort != 'none':
    mtxt += ' ' + c(DIM, effort)
if get('thinking.enabled', False):
    mtxt += ' ' + c(DIM, 'think')
seg.append(mtxt)

s = f'S:{five_pct}%({five_rem})' if five_rem else f'S:{five_pct}%'
seg.append(c(pct_color(five_pct), s))

w = f'W:{seven_pct}%({seven_reset})' if seven_reset else f'W:{seven_pct}%'
seg.append(c(pct_color(seven_pct), w))

seg.append(c(pct_color(ctx_pct), f'ctx:{ctx_pct}%({human(ctx_tok)})'))

if proj:
    g = c(CYAN, proj)
    if branch: g += c(DIM, ' ⎇ ') + c(MAGENTA, branch)
    seg.append(g)

print(c(DIM,' | ').join(seg))
" <<< "$input"
}

parse
