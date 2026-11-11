<#
.SYNOPSIS
    GIANBEST Audio Latency Optimizer - instalador / desinstalador (PowerShell 7, Windows 11).

.DESCRIPTION
    Descarga nssm.exe y REAL.exe a C:\AudioLatencyReducer y registra REAL.exe como
    servicio de Windows (GIANBESTAudio) con inicio automático.
    También permite desinstalarlo y consultar el estado.

    Todo en uno: clic derecho > "Ejecutar con PowerShell". Si se abre con Windows PowerShell 5.1,
    el script busca PowerShell 7 (o lo instala con winget) y se relanza ahí como administrador.

    Nota para editar: el bloque de arranque debe poder parsearse en Windows PowerShell 5.1,
    así que en este archivo no se usan los operadores ??, ?:, && ni ||.

.PARAMETER Action
    Install | Uninstall | Status. Sin este parámetro se muestra un menú interactivo.

.PARAMETER NoPause
    No espera una tecla al terminar (útil para automatizar).

.EXAMPLE
    pwsh -File .\AudioLatency.ps1
    pwsh -File .\AudioLatency.ps1 -Action Install
    pwsh -File .\AudioLatency.ps1 -Action Uninstall -NoPause
#>
[CmdletBinding()]
param(
    [ValidateSet('Install', 'Uninstall', 'Status')]
    [string]$Action,

    [switch]$NoPause
)

#region Argumentos de relanzamiento
$relaunch = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
if ($Action)  { $relaunch += @('-Action', $Action) }
if ($NoPause) { $relaunch += '-NoPause' }
#endregion

#region Arranque: asegurar PowerShell 7 (si se abrió con Windows PowerShell 5.1)
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    $pwsh  = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    if (-not $pwsh -and (Test-Path $pwsh7)) { $pwsh = $pwsh7 }

    if (-not $pwsh) {
        Write-Host 'PowerShell 7 no está instalado.' -ForegroundColor Yellow
        if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
            $answer = Read-Host '¿Instalarlo ahora con winget? [s/N]'
            if ($answer -match '^[sSyY]') {
                winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
                if (Test-Path $pwsh7) { $pwsh = $pwsh7 }   # el PATH de esta ventana aún no se actualizó
            }
        }
    }

    if (-not $pwsh) {
        Write-Host 'No se pudo obtener PowerShell 7. Descárgalo desde https://aka.ms/powershell' -ForegroundColor Red
        [void](Read-Host 'Presiona Enter para salir')
        exit 1
    }

    try {
        Start-Process -FilePath $pwsh -ArgumentList $relaunch -Verb RunAs
    }
    catch {
        Write-Host 'Se necesitan permisos de administrador. Operación cancelada.' -ForegroundColor Red
        [void](Read-Host 'Presiona Enter para salir')
    }
    exit
}
#endregion

$ErrorActionPreference = 'Stop'

#region Auto-elevación a administrador
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin  = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    try {
        Start-Process -FilePath ([Environment]::ProcessPath) -ArgumentList $relaunch -Verb RunAs
    }
    catch {
        Write-Host 'Se necesitan permisos de administrador. Operación cancelada.' -ForegroundColor Red
    }
    exit
}
#endregion

#region Configuración
$ServiceName = 'GIANBESTAudio'
$DisplayName = 'GIANBEST Audio Latency Reducer Service'
$Description = 'Reduces Audio Latency (GIANBEST)'
$TargetDir   = "$env:SystemDrive\AudioLatencyReducer"
$NssmExe     = Join-Path $TargetDir 'nssm.exe'
$RealExe     = Join-Path $TargetDir 'REAL.exe'

# En nssm, AppAffinity es una lista de índices de procesador (0 = primero).
$CpuAffinity = '1'

# Opcional pero recomendado: pega aquí el SHA-256 de cada archivo para verificarlo.
# Si lo dejas vacío, el script solo comprueba que sea un ejecutable y muestra el hash.
$BaseUrl    = 'https://raw.githubusercontent.com/GIANBEST/AudioLatency/refs/heads/main'
$Components = @(
    @{ Name = 'nssm.exe'; Url = "$BaseUrl/nssm.exe"; Sha256 = '' }
    @{ Name = 'REAL.exe'; Url = "$BaseUrl/REAL.exe"; Sha256 = '' }
)
#endregion

#region Interfaz
$Reset  = $PSStyle.Reset
$Bold   = $PSStyle.Bold
$Cyan   = $PSStyle.Foreground.BrightCyan
$Green  = $PSStyle.Foreground.BrightGreen
$Yellow = $PSStyle.Foreground.BrightYellow
$Red    = $PSStyle.Foreground.BrightRed
$Gray   = $PSStyle.Foreground.BrightBlack

$script:HadError = $false

function Write-Banner {
    param([string]$Subtitle)

    Clear-Host
    $logo = @(
        '   ██████╗ ██╗ █████╗ ███╗   ██╗██████╗  ███████╗ ███████╗████████╗'
        '  ██╔════╝ ██║██╔══██╗████╗  ██║██╔══██╗ ██╔════╝ ██╔════╝╚══██╔══╝'
        '  ██║  ███╗██║███████║██╔██╗ ██║██████╔╝ █████╗   ███████╗   ██║   '
        '  ██║   ██║██║██╔══██║██║╚██╗██║██╔══██╗ ██╔══╝   ╚════██║   ██║   '
        '  ╚██████╔╝██║██║  ██║██║ ╚████║██████╔╝ ███████╗ ███████║   ██║   '
        '   ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝  ╚══════╝ ╚══════╝   ╚═╝   '
    )

    Write-Host
    for ($i = 0; $i -lt $logo.Count; $i++) {
        $t = $i / ($logo.Count - 1)
        $color = $PSStyle.Foreground.FromRgb([int](0 + 170 * $t), [int](220 - 120 * $t), 255)
        Write-Host "${color}$($logo[$i])${Reset}"
    }

    Write-Host
    Write-Host "  ${Gray}$('─' * 66)${Reset}"
    Write-Host "  ${Bold}Optimizador de Latencia de Audio · por GIANBEST${Reset}"
    if ($Subtitle) { Write-Host "  ${Cyan}$Subtitle${Reset}" }
    Write-Host "  ${Gray}$('─' * 66)${Reset}"
    Write-Host
}

function Write-Section {
    param([int]$Current, [int]$Total, [string]$Title)
    Write-Host
    Write-Host "  ${Bold}${Cyan}[ PASO $Current de $Total ]${Reset} ${Bold}$Title${Reset}"
    Write-Host
}

function Write-Step { param([string]$Message) Write-Host "  ${Cyan}➜${Reset} $Message" }
function Write-Ok   { param([string]$Message) Write-Host "  ${Green}✔${Reset} $Message" }
function Write-Warn { param([string]$Message) Write-Host "  ${Yellow}!${Reset} $Message" }
function Write-Fail { param([string]$Message) Write-Host "  ${Red}✖${Reset} $Message" }
function Write-Dim  { param([string]$Message) Write-Host "    ${Gray}$Message${Reset}" }

function Write-Box {
    param(
        [string]$Title,
        [string[]]$Lines = @(),
        [string]$Color = $Green
    )
    $inner = 60
    $edge  = '─' * $inner

    Write-Host "  ${Color}╭${edge}╮${Reset}"
    Write-Host "  ${Color}│${Reset}${Bold}$("  $Title".PadRight($inner))${Reset}${Color}│${Reset}"
    if ($Lines.Count -gt 0) {
        Write-Host "  ${Color}│${Reset}$(' ' * $inner)${Color}│${Reset}"
        foreach ($line in $Lines) {
            Write-Host "  ${Color}│${Reset}$("  $line".PadRight($inner))${Color}│${Reset}"
        }
    }
    Write-Host "  ${Color}╰${edge}╯${Reset}"
}

function Wait-Key {
    param([string]$Message = 'Presiona cualquier tecla para continuar...')
    if ($NoPause) { return }
    Write-Host
    Write-Host "  ${Gray}$Message${Reset}"
    [void][Console]::ReadKey($true)
}

function Confirm-Action {
    param([string]$Question)
    Write-Host "  ${Yellow}?${Reset} $Question ${Gray}[s/N]${Reset} " -NoNewline
    $key = [Console]::ReadKey($true).KeyChar
    Write-Host $key
    return ("$key" -match '^[sSyY]$')
}
#endregion

#region Utilidades
function Test-PEFile {
    # Comprueba la cabecera 'MZ' para detectar descargas rotas (p. ej. una página "404: Not Found").
    param([string]$Path)
    try {
        $fs = [IO.File]::OpenRead($Path)
        try {
            $buf = [byte[]]::new(2)
            return ($fs.Read($buf, 0, 2) -eq 2 -and $buf[0] -eq 0x4D -and $buf[1] -eq 0x5A)
        }
        finally { $fs.Dispose() }
    }
    catch { return $false }
}

function Test-Component {
    param([string]$Path, [string]$ExpectedSha256)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if (-not (Test-PEFile $Path)) { return $false }
    if ($ExpectedSha256) {
        return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq $ExpectedSha256)
    }
    return $true
}

function Invoke-Nssm {
    $output = & $NssmExe @args 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        # nssm escribe en UTF-16; se quitan los nulos para que el mensaje sea legible.
        $detail = $output.Replace("`0", '').Trim()
        throw "nssm $($args[0]) falló (código $LASTEXITCODE). $detail"
    }
}

function Stop-StrayProcesses {
    Get-Process -Name 'REAL', 'nssm' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($TargetDir, [StringComparison]::OrdinalIgnoreCase) } |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

function Install-Component {
    param([hashtable]$Component)

    $dest = Join-Path $TargetDir $Component.Name
    if (Test-Component $dest $Component.Sha256) {
        Write-Ok "$($Component.Name) ya existe. Se omite la descarga."
        return
    }

    $tmp = "$dest.download"
    Write-Step "Descargando $($Component.Name)..."
    try {
        Invoke-WebRequest -Uri $Component.Url -OutFile $tmp -MaximumRetryCount 3 -RetryIntervalSec 2

        if (-not (Test-PEFile $tmp)) {
            throw 'el archivo descargado no es un ejecutable válido (¿enlace roto?).'
        }
        $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash
        if ($Component.Sha256 -and $hash -ne $Component.Sha256) {
            throw "el SHA-256 no coincide (esperado $($Component.Sha256), obtenido $hash)."
        }
        Move-Item -LiteralPath $tmp -Destination $dest -Force
    }
    catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw "Falló la descarga de $($Component.Name): $($_.Exception.Message) Verifica tu conexión a internet o el enlace."
    }

    Write-Ok "$($Component.Name) descargado correctamente."
    Write-Dim "SHA-256: $hash"
}

function Remove-OptimizerService {
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Ok "El servicio '$ServiceName' no está instalado. No hay nada que hacer."
        return
    }

    if ($svc.Status -ne 'Stopped') {
        Write-Step "Deteniendo el servicio $ServiceName..."
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        try { $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(15)) }
        catch { Write-Warn 'El servicio tardó en detenerse; se continúa de todos modos.' }
    }

    Write-Step "Eliminando el servicio $ServiceName..."
    if (Test-Path -LiteralPath $NssmExe) {
        Invoke-Nssm remove $ServiceName confirm
    }
    else {
        Write-Warn 'No se encuentra nssm.exe; se usa el comando sc.exe de Windows.'
        & sc.exe delete $ServiceName | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "sc.exe delete falló (código $LASTEXITCODE)." }
    }
    Write-Ok 'Servicio eliminado correctamente.'
}
#endregion

#region Acciones
function Install-Optimizer {
    Write-Banner 'Instalación'

    # --- Paso 1 ---
    Write-Section 1 3 'Preparando el directorio de instalación'
    if (Test-Path -LiteralPath $TargetDir) {
        Write-Ok "El directorio ya existe: $TargetDir"
    }
    else {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Write-Ok "Directorio creado: $TargetDir"
    }

    $existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Warn "El servicio ya está instalado (estado: $($existing.Status))."
        if (-not (Confirm-Action '¿Quieres reinstalarlo?')) {
            Write-Dim 'Instalación cancelada.'
            return
        }
        Remove-OptimizerService
        Stop-StrayProcesses
    }

    # --- Paso 2 ---
    Write-Section 2 3 'Descargando componentes necesarios'
    foreach ($component in $Components) { Install-Component $component }

    # --- Paso 3 ---
    Write-Section 3 3 'Instalando y configurando el servicio'
    try {
        Write-Step 'Registrando el servicio...'
        Invoke-Nssm install $ServiceName $RealExe
        Write-Step 'Configurando nombre y descripción...'
        Invoke-Nssm set $ServiceName DisplayName $DisplayName
        Invoke-Nssm set $ServiceName Description $Description
        Write-Step 'Estableciendo inicio automático...'
        Invoke-Nssm set $ServiceName Start SERVICE_AUTO_START
        Write-Step "Asignando afinidad de CPU ($CpuAffinity)..."
        Invoke-Nssm set $ServiceName AppAffinity $CpuAffinity
    }
    catch {
        Write-Fail 'Falló la configuración; se revierte el servicio.'
        try { Remove-OptimizerService } catch { }
        throw
    }

    Write-Step 'Iniciando el servicio...'
    $started = $false
    try {
        Start-Service -Name $ServiceName
        (Get-Service -Name $ServiceName).WaitForStatus('Running', [TimeSpan]::FromSeconds(10))
        $started = $true
    }
    catch {
        Write-Warn "El servicio se instaló, pero no pudo iniciarse: $($_.Exception.Message)"
    }

    Write-Host
    if ($started) {
        Write-Box 'INSTALACIÓN COMPLETA' @(
            "El servicio '$DisplayName'",
            'se instaló e inició correctamente.',
            '',
            "Archivos: $TargetDir",
            'Puedes verlo en la aplicación Servicios (services.msc).'
        ) $Green
    }
    else {
        $script:HadError = $true
        Write-Box 'INSTALADO CON ADVERTENCIAS' @(
            'El servicio quedó instalado pero no está en ejecución.',
            'Revisa services.msc o ejecuta la opción "Ver estado".'
        ) $Yellow
    }
}

function Uninstall-Optimizer {
    Write-Banner 'Desinstalación'

    Write-Section 1 2 'Deteniendo y eliminando el servicio'
    Remove-OptimizerService
    Stop-StrayProcesses

    Write-Section 2 2 'Eliminando archivos y directorio'
    if (-not (Test-Path -LiteralPath $TargetDir)) {
        Write-Ok "La carpeta '$TargetDir' no existe."
    }
    else {
        Set-Location -LiteralPath $env:SystemRoot   # por si la consola está dentro de la carpeta
        Write-Step "Eliminando la carpeta $TargetDir y su contenido..."
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                Remove-Item -LiteralPath $TargetDir -Recurse -Force -ErrorAction Stop
                break
            }
            catch {
                if ($attempt -eq 5) { throw }
                Start-Sleep -Seconds 1   # el servicio puede tardar en liberar los archivos
            }
        }
        Write-Ok 'Carpeta eliminada.'
    }

    Write-Host
    Write-Box 'DESINSTALACIÓN COMPLETA' @(
        'El sistema ha sido limpiado.',
        'Ya puedes volver a probar la instalación.'
    ) $Green
}

function Show-Status {
    Write-Banner 'Estado'

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        $statusColor = if ($svc.Status -eq 'Running') { $Green } else { $Yellow }
        Write-Ok "Servicio instalado: $DisplayName"
        Write-Host "      Estado: ${statusColor}$($svc.Status)${Reset}   Inicio: $($svc.StartType)"
    }
    else {
        Write-Warn "El servicio '$ServiceName' no está instalado."
    }

    foreach ($component in $Components) {
        $path = Join-Path $TargetDir $component.Name
        if (Test-Path -LiteralPath $path) {
            $kb = [math]::Round((Get-Item -LiteralPath $path).Length / 1KB)
            Write-Ok "$($component.Name) ($kb KB)"
        }
        else {
            Write-Fail "$($component.Name) no encontrado"
        }
    }
    Write-Dim "Directorio: $TargetDir"
}

function Invoke-Action {
    param([string]$Name)
    try {
        switch ($Name) {
            'Install'   { Install-Optimizer }
            'Uninstall' { Uninstall-Optimizer }
            'Status'    { Show-Status }
        }
    }
    catch {
        $script:HadError = $true
        Write-Host
        Write-Fail $_.Exception.Message
    }
    Wait-Key
}

function Show-Menu {
    while ($true) {
        Write-Banner
        Write-Host "   ${Cyan}[1]${Reset} Instalar el optimizador"
        Write-Host "   ${Cyan}[2]${Reset} Desinstalar"
        Write-Host "   ${Cyan}[3]${Reset} Ver estado"
        Write-Host "   ${Gray}[0] Salir${Reset}"
        Write-Host
        Write-Host '  Elige una opción: ' -NoNewline

        switch ([Console]::ReadKey($true).KeyChar) {
            '1' { Invoke-Action 'Install' }
            '2' { Invoke-Action 'Uninstall' }
            '3' { Invoke-Action 'Status' }
            '0' { return }
        }
    }
}
#endregion

# --- Punto de entrada ---
$Host.UI.RawUI.WindowTitle = 'GIANBEST Audio Latency Optimizer'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

if ($Action) { Invoke-Action $Action } else { Show-Menu }

exit ([int]$script:HadError)
