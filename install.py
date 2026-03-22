#!/usr/bin/env python3
import sys
import json
import os
import shutil

sys.stdout.reconfigure(encoding='utf-8')
sys.stdin.reconfigure(encoding='utf-8')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLAUDE_DIR = os.path.join(os.path.expanduser('~'), '.claude')
SETTINGS   = os.path.join(CLAUDE_DIR, 'settings.json')
TARGET     = os.path.join(CLAUDE_DIR, 'statusline-command.py')

os.makedirs(CLAUDE_DIR, exist_ok=True)

shutil.copy(os.path.join(SCRIPT_DIR, 'statusline-command.py'), TARGET)
print(f'스크립트 설치 완료: {TARGET}')

# settings.json에 등록할 커맨드 (슬래시 통일, 현재 Python 경로 사용)
python_exe = sys.executable.replace('\\', '/')
target_fwd = TARGET.replace('\\', '/')
command    = f'{python_exe} "{target_fwd}"'

if os.path.exists(SETTINGS):
    with open(SETTINGS, encoding='utf-8') as f:
        data = json.load(f)
    if 'statusLine' in data:
        answer = input('settings.json에 statusLine 설정이 이미 있습니다. 덮어쓸까요? (y/n): ')
        if answer.strip().lower() != 'y':
            print('설정 변경을 건너뜁니다.')
            print('\n설치 완료! Claude Code를 재시작하세요.')
            sys.exit(0)
else:
    data = {}

data['statusLine'] = {'type': 'command', 'command': command}
with open(SETTINGS, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('settings.json 업데이트 완료')

print()
print('설치 완료! Claude Code를 재시작하세요.')
print('표시 예시: [Opus 4.6] $1.22 | 세션:2%(3시간41분) | 주간:9%(03/27 13:00) | ctx:4% | 15m3s')
