# Claude Code Statusline

Claude Code 하단에 사용량 정보를 실시간으로 표시합니다.

```
o4.8(1M) high | S:38%(0:38) | W:9%(06/16 01:00) | ctx:10%(100k) | myproject ⎇ main*
```

> 중요한 정보(사용량)를 앞쪽에 배치하고, git 정보는 맨 뒤에 둬서 폭이 좁아지면 먼저 잘립니다.
> 사용률(S/W/ctx)은 50% 이상이면 노랑, 80% 이상이면 빨강으로 표시됩니다.

## 표시 항목

| 항목 | 설명 |
|------|------|
| `o4.8(1M) high` | 모델(축약) + reasoning effort 레벨 |
| `S:38%(0:38)` | 5시간 세션 사용량 + 리셋까지 남은 시간(시:분) |
| `W:9%(06/16 01:00)` | 7일 주간 사용량 + 리셋 시각 |
| `ctx:10%(100k)` | 컨텍스트 윈도우 사용률 + 입력 토큰 수 |
| `myproject ⎇ main*` | 현재 디렉토리명 + git 브랜치 (`*`=변경사항 있음) |

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
