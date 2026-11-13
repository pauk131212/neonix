# Публикация исходников Neonix на GitHub.
#
#   powershell -ExecutionPolicy Bypass -File .\scripts\publish-repo.ps1
#
# Скрипт ставит git/gh (если их нет), делает первый коммит и создаёт
# репозиторий. ISO сюда НЕ попадает — для него отдельный скрипт
# publish-iso.ps1 (GitHub Releases).

param(
    [string]$RepoName   = 'neonix',
    [string]$Visibility = 'public'   # public | private
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

# PowerShell 5.1 при ErrorActionPreference=Stop превращает любой stderr от
# внешней программы в NativeCommandError и роняет скрипт. Поэтому внешние
# команды запускаем через эти обёртки.
function Invoke-Native {
    param([string]$Name, [scriptblock]$Cmd, [switch]$AllowFailure)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Cmd 2>&1 | ForEach-Object {
        # stderr от внешних программ приходит как ErrorRecord — печатаем
        # его обычным текстом, а не красной ошибкой PowerShell.
        if ($_ -is [System.Management.Automation.ErrorRecord]) { Write-Host $_.ToString() }
        else { Write-Host $_ }
    }
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "Шаг '$Name' завершился с ошибкой (код $code)."
    }
    return $code
}

function Get-NativeOutput {
    param([scriptblock]$Cmd)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & $Cmd 2>$null
    $ErrorActionPreference = $old
    return (($out | Out-String).Trim())
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

# Ставит инструмент, если его нет. Если winget говорит «уже установлено»
# (код 1) или UAC отменён — ищет exe в стандартных папках и добавляет в PATH.
function Ensure-Tool {
    param([string]$Name, [string[]]$FallbackDirs, [string]$WingetId, [string]$Label)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }

    Write-Host "$Label не найден в PATH, ставлю через winget..."
    [void](Invoke-Native "winget $Label" {
        winget install --id $WingetId -e --source winget --accept-package-agreements --accept-source-agreements
    } -AllowFailure)
    Refresh-Path

    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }

    foreach ($dir in $FallbackDirs) {
        $exe = Join-Path $dir "$Name.exe"
        if (Test-Path $exe) {
            $env:Path = "$dir;$env:Path"
            Write-Host "$Label найден: $exe"
            return
        }
    }
    throw "$Label не установлен. Поставь вручную и запусти скрипт ещё раз."
}

Refresh-Path

Ensure-Tool 'git' @('C:\Program Files\Git\cmd', 'C:\Program Files (x86)\Git\cmd') 'Git.Git' 'Git'
Ensure-Tool 'gh'  @('C:\Program Files\GitHub CLI') 'GitHub.cli' 'GitHub CLI'

$auth = Invoke-Native 'gh auth status' { gh auth status } -AllowFailure
if ($auth -ne 0) {
    Write-Host 'Нужно войти в GitHub — сейчас откроется браузер.'
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    gh auth login --web --git-protocol https
    $auth = $LASTEXITCODE
    $ErrorActionPreference = $old
    if ($auth -ne 0) { throw 'Вход в GitHub не выполнен.' }
}

# Имя и почта для коммитов
if (-not (Get-NativeOutput { git config user.name })) {
    $login = Get-NativeOutput { gh api user --jq .login }
    if (-not $login) { throw 'Не удалось получить логин GitHub.' }
    [void](Invoke-Native 'git config user.name' { git config user.name $login })
    [void](Invoke-Native 'git config user.email' { git config user.email "$login@users.noreply.github.com" })
}

if (-not (Test-Path .git)) {
    [void](Invoke-Native 'git init' { git init -b main })
}

[void](Invoke-Native 'git add' { git add -A })
$staged = Get-NativeOutput { git diff --cached --name-only }
if ($staged) {
    [void](Invoke-Native 'git commit' { git commit -m 'Neonix 1.0: исходники, брендинг и документация' })
}

$login = Get-NativeOutput { gh api user --jq .login }

if (-not (Get-NativeOutput { git remote })) {
    [void](Invoke-Native 'gh repo create' { gh repo create $RepoName --$Visibility --source . --remote origin --push })
} else {
    [void](Invoke-Native 'git push' { git push -u origin main })
}

# Подставить логин в README вместо ВАШ_ЛОГИН
$readme = Join-Path (Get-Location) 'README.md'
if (Test-Path $readme) {
    $text = [System.IO.File]::ReadAllText($readme, [System.Text.Encoding]::UTF8)
    if ($text -match 'ВАШ_ЛОГИН') {
        $text = $text -replace 'ВАШ_ЛОГИН', $login
        [System.IO.File]::WriteAllText($readme, $text, (New-Object System.Text.UTF8Encoding($false)))
        [void](Invoke-Native 'git add README' { git add README.md })
        [void](Invoke-Native 'git commit README' { git commit -m "README: ссылка на релизы" })
        [void](Invoke-Native 'git push README' { git push })
    }
}

Write-Host ''
Write-Host "Готово: https://github.com/$login/$RepoName"
Write-Host "Дальше: powershell -ExecutionPolicy Bypass -File .\scripts\publish-iso.ps1"
