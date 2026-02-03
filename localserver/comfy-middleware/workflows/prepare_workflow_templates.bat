@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

echo [Tapnow] 扫描 workflows 子目录...

for /d %%D in (*) do (
  if exist "%%D\" (
    pushd "%%D"

    set /a jsonCount=0
    set "onlyJson="
    for %%F in (*.json) do (
      set /a jsonCount+=1
      set "onlyJson=%%F"
    )

    if !jsonCount! equ 1 (
      if /i not "!onlyJson!"=="template.json" (
        echo [Rename] %%D\!onlyJson! -> template.json
        ren "!onlyJson!" "template.json"
      )
    )

    if exist "template.json" (
      echo [Meta] Generating meta.json in %%D
      powershell -ExecutionPolicy Bypass -NoProfile -Command ^
        "$tplPath = Join-Path (Get-Location) 'template.json';" ^
        "if (Test-Path $tplPath) {" ^
        "  $metaPath = Join-Path (Get-Location) 'meta.json';" ^
        "  $tpl = Get-Content $tplPath -Raw | ConvertFrom-Json;" ^
        "  $params = [ordered]@{};" ^
        "  $tpl.PSObject.Properties | ForEach-Object {" ^
        "    $nodeId = $_.Name;" ^
        "    $node = $_.Value;" ^
        "    if ($null -ne $node.inputs) {" ^
        "      $node.inputs.PSObject.Properties | ForEach-Object {" ^
        "        $key = \"$($nodeId).$($_.Name)\";" ^
        "        $params[$key] = [ordered]@{ node_id = $nodeId; field = \"inputs.$($_.Name)\" };" ^
        "      }" ^
        "    }" ^
        "  };" ^
        "  $meta = [ordered]@{ name = (Split-Path -Leaf (Get-Location)); params_map = $params; generated_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') };" ^
        "  $meta | ConvertTo-Json -Depth 6 | Set-Content -Path $metaPath -Encoding UTF8;" ^
        "}"
    ) else (
      echo [Skip] %%D (no template.json)
    )

    popd
  )
)

echo [Done] workflows 扫描完成。
endlocal
