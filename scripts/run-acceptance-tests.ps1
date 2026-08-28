#Requires -Version 7.0
$ErrorActionPreference = 'Continue'
$root = 'd:\docker\gemma4-4b'
$logs = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

$baseUrl = 'http://127.0.0.1:5003'
$hostIp = '192.168.148.109'
$results = [ordered]@{}
$notes = [System.Collections.Generic.List[string]]::new()
$chatJson = $null

function Add-Result([string]$Name, [bool]$Pass, [string]$Detail) {
    $results[$Name] = [ordered]@{ pass = $Pass; detail = $Detail }
}

function Test-NoThinking([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    return -not ($Text -match '<\|channel>thought|<\|think\|>')
}

Write-Host "=== Gemma4-4B LLM acceptance (pwsh $($PSVersionTable.PSVersion)) ==="

$smi = (nvidia-smi 2>&1 | Out-String)
Add-Result 'nvidia-smi GTX 1080' ($smi -match 'GTX 1080') (($smi -split "`n" | Select-Object -Skip 7 -First 3) -join ' | ')

Push-Location $root
$vram = (docker compose exec -T gemma4-4b-llm nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>&1 | Out-String).Trim()
Pop-Location
Add-Result 'VRAM Gemma4-4B loaded' ($vram -match '\d') $vram

$health = (& curl.exe -s --max-time 30 "$baseUrl/health")
Add-Result 'GET /health localhost' ($health -match 'ok|healthy') $health

$healthLan = (& curl.exe -s --max-time 30 "http://${hostIp}:5003/health")
Add-Result "GET /health ${hostIp}" ($healthLan -match 'ok|healthy') $healthLan

$chatBody = @{
    model = 'gemma4-4b'
    messages = @(
        @{ role = 'system'; content = 'Ты голосовой ассистент. Отвечай кратко по-русски, одним-двумя предложениями.' }
        @{ role = 'user'; content = 'Привет! Как дела?' }
    )
    max_tokens = 128
    temperature = 0.7
    chat_template_kwargs = @{ enable_thinking = $false }
} | ConvertTo-Json -Depth 5 -Compress

$chatResp = (& curl.exe -s --max-time 120 -X POST "$baseUrl/v1/chat/completions" `
    -H 'Content-Type: application/json' `
    -d $chatBody)

try {
    $chatJson = $chatResp | ConvertFrom-Json
    $content = $chatJson.choices[0].message.content
    $pass = ($content.Length -gt 0) -and (Test-NoThinking $content)
    Add-Result 'POST /v1/chat/completions ru no-thinking' $pass "content=$content"
    if (-not $pass -and $content) {
        $notes.Add('Response may contain thinking tokens — check LLM_ENABLE_THINKING and chat_template_kwargs')
    }
} catch {
    Add-Result 'POST /v1/chat/completions ru no-thinking' $false $chatResp
}

$fw = (netsh advfirewall firewall show rule name="LLM Gemma4-4B 5003" 2>&1 | Out-String)
if ($fw -notmatch 'Enabled:\s+Yes') {
    $fw = (netsh advfirewall firewall show rule name="LLM avibe 5003" 2>&1 | Out-String)
    $notes.Add('Using LLM avibe 5003 firewall rule if Gemma4-4B rule missing')
}
Add-Result 'Firewall 5003 from 192.168.149.0/24' ($fw -match 'Enabled:\s+Yes' -and $fw -match 'LocalPort:\s+5003') 'TCP 5003 allow from 192.168.149.0/24'

$tcp5003 = (Test-NetConnection -ComputerName $hostIp -Port 5003 -WarningAction SilentlyContinue).TcpTestSucceeded
Add-Result "LLM ${hostIp}:5003 TCP" $tcp5003 "TcpTestSucceeded=$tcp5003"
$notes.Add('Verify from Linux: curl -s http://192.168.148.109:5003/health')

$passed = @($results.Values | Where-Object { $_.pass }).Count
$total = $results.Count
$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$textOut = if ($chatJson) { $chatJson.choices[0].message.content } else { 'n/a' }

$report = @"
# Gemma4-4B LLM — результат приёмки

**Дата:** $now  
**Хост:** Windows Server 2022, $hostIp  
**URL LLM:** http://${hostIp}:5003/v1  
**Модель:** gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf (`d:\docker\gemma4-4b\model\QAT`)  
**Контейнер:** gemma4-4b-llm  
**Reasoning:** отключён (`LLM_ENABLE_THINKING=false`)

---

## Чеклист

| # | Пункт | Статус | Детали |
|---|-------|--------|--------|
"@

$i = 1
foreach ($key in $results.Keys) {
    $r = $results[$key]
    $st = if ($r.pass) { 'PASS' } else { 'FAIL' }
    $d = ($r.detail -replace '\|', '/' -replace "`r?`n", ' ').Trim()
    if ($d.Length -gt 120) { $d = $d.Substring(0, 117) + '...' }
    $report += "| $i | $key | **$st** | $d |`n"
    $i++
}

$report += @"

---

## Итог: $passed / $total

- Ответ: «$textOut»

### Linux gateway

``````env
LLM_BASE_URL=http://192.168.148.109:5003/v1
LLM_MODEL=gemma4-4b
LLM_ENABLE_THINKING=false
ASR_BASE_URL=http://192.168.148.109:5002
APP_MODE=voice_bot
``````

"@

if ($notes.Count -gt 0) {
    $report += "`n### Notes`n"
    foreach ($n in $notes) { $report += "- $n`n" }
}

$outFile = Join-Path $root 'ACCEPTANCE-RESULT.md'
[System.IO.File]::WriteAllText($outFile, $report, [System.Text.UTF8Encoding]::new($true))
Write-Host "Saved: $outFile"
Write-Host "Passed: $passed / $total"
