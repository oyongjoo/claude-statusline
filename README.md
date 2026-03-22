# Claude Code Statusline

Claude Code 하단에 사용량 정보를 실시간으로 표시합니다.

```
[Opus 4.6 (1M context)] $1.22 | 세션:2%(3시간41분) | 주간:9%(03/27 13:00) | ctx:4% | 15m3s
```

## 표시 항목

| 항목 | 설명 |
|------|------|
| `[Opus 4.6]` | 현재 사용 중인 모델 |
| `$1.22` | 세션 누적 비용 |
| `세션:2%(3시간41분)` | 5시간 세션 사용량 + 리셋까지 남은 시간 |
| `주간:9%(03/27 13:00)` | 7일 주간 사용량 + 리셋 시각 |
| `ctx:4%` | 컨텍스트 윈도우 사용률 |
| `15m3s` | 세션 경과 시간 |

## 설치

```bash
git clone https://github.com/사용자명/claude-statusline.git
cd claude-statusline
bash install.sh
```

설치 후 Claude Code를 재시작하면 적용됩니다.

## 요구사항

- Claude Code CLI
- python3

## 제거

```bash
# 스크립트 삭제
rm ~/.claude/statusline-command.sh

# settings.json에서 "statusLine" 항목 제거
```
