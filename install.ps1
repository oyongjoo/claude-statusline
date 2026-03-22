# Claude Code Statusline - Windows 설치 스크립트
$ErrorActionPreference = "Stop"
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Settings  = Join-Path $ClaudeDir "settings.json"
$Target    = Join-Path $ClaudeDir "statusline-command.py"

# Python 3 체크
$PythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            $ver = & $cmd -c "import sys; print(sys.version)" 2>$null
            if ($ver -match "^3\.") {
                $PythonCmd = $cmd
                break
            }
        } catch {}
    }
}
if (-not $PythonCmd) {
    Write-Error "ERROR: Python 3가 필요합니다. 설치 후 다시 시도해주세요."
    exit 1
}

# ~/.claude 디렉토리 확인
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

# 스크립트 복사
Copy-Item "$ScriptDir\statusline-command.py" $Target -Force
Write-Host "스크립트 설치 완료: $Target"

# 경로 구분자를 슬래시로 통일 (JSON 내 이스케이프 방지)
$TargetFwd = $Target.Replace('\', '/')
$CommandStr = "$PythonCmd `"$TargetFwd`""

# settings.json 업데이트 (Python으로 처리)
$UpdateScript = @"
import json, os, sys

settings_path = r'$Settings'
command = r'$CommandStr'

if os.path.exists(settings_path):
    with open(settings_path, encoding='utf-8') as f:
        data = json.load(f)
    if 'statusLine' in data:
        answer = input('settings.json에 statusLine 설정이 이미 있습니다. 덮어쓸까요? (y/n): ')
        if answer.strip().lower() != 'y':
            print('설정 변경을 건너뜁니다.')
            sys.exit(0)
else:
    data = {}

data['statusLine'] = {'type': 'command', 'command': command}
with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('settings.json 업데이트 완료')
"@

& $PythonCmd -c $UpdateScript

Write-Host ""
Write-Host "설치 완료! Claude Code를 재시작하세요."
Write-Host '표시 예시: [Opus 4.6] $1.22 | 세션:2%(3시간41분) | 주간:9%(03/27 13:00) | ctx:4% | 15m3s'
