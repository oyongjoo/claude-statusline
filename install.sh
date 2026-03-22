#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/statusline-command.sh"

# python3 체크
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3이 필요합니다. 설치 후 다시 시도해주세요."
    exit 1
fi

# ~/.claude 디렉토리 확인
mkdir -p "$CLAUDE_DIR"

# 스크립트 복사
cp "$SCRIPT_DIR/statusline-command.sh" "$TARGET"
chmod +x "$TARGET"
echo "스크립트 설치 완료: $TARGET"

# settings.json 업데이트
if [ -f "$SETTINGS" ]; then
    # 이미 statusLine 설정이 있는지 확인
    if python3 -c "
import json, sys
with open('$SETTINGS') as f:
    data = json.load(f)
if 'statusLine' in data:
    print('exists')
" 2>/dev/null | grep -q "exists"; then
        echo "settings.json에 statusLine 설정이 이미 있습니다. 덮어쓸까요? (y/n)"
        read -r answer
        if [ "$answer" != "y" ]; then
            echo "설정 변경을 건너뜁니다."
            echo "설치 완료! Claude Code를 재시작하세요."
            exit 0
        fi
    fi
    # statusLine 추가/업데이트
    python3 -c "
import json
with open('$SETTINGS') as f:
    data = json.load(f)
data['statusLine'] = {
    'type': 'command',
    'command': 'bash $TARGET'
}
with open('$SETTINGS', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
else
    # 새로 생성
    python3 -c "
import json
data = {
    'statusLine': {
        'type': 'command',
        'command': 'bash $TARGET'
    }
}
with open('$SETTINGS', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
fi
echo "settings.json 업데이트 완료"

echo ""
echo "설치 완료! Claude Code를 재시작하세요."
echo "표시 예시: [Opus 4.6] \$1.22 | 세션:2%(3시간41분) | 주간:9%(03/27 13:00) | ctx:4% | 15m3s"
