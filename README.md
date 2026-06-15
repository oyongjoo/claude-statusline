# Claude Code Statusline

Claude Code 하단에 사용량 정보를 실시간으로 표시합니다.

```
myproject ⎇ main* | [Opus 4.8 (1M context)] 🧠 | $1.22 | +42/-7 | 세션:2%(3시간41분) | 주간:9%(03/27 13:00) | ctx:4%(78k) | 15m3s
```

> 사용률(세션/주간/ctx)은 50% 이상이면 노랑, 80% 이상이면 빨강으로 표시됩니다.

## 표시 항목

| 항목 | 설명 |
|------|------|
| `myproject ⎇ main*` | 현재 디렉토리명 + git 브랜치 (`*`=변경사항 있음) |
| `[Opus 4.8]` | 현재 사용 중인 모델 |
| `🧠` / `⚡fast` / `high` | 확장 사고 / fast 모드 / reasoning effort 표시기 |
| `$1.22` | 세션 누적 비용 |
| `+42/-7` | 세션 중 코드 변경 줄 수 (추가/삭제) |
| `세션:2%(3시간41분)` | 5시간 세션 사용량 + 리셋까지 남은 시간 |
| `주간:9%(03/27 13:00)` | 7일 주간 사용량 + 리셋 시각 |
| `ctx:4%(78k)` | 컨텍스트 윈도우 사용률 + 입력 토큰 수 |
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
