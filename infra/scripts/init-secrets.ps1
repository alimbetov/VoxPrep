param(
    [ValidateSet('dev', 'test')]
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'

$InfraRoot = Split-Path -Parent $PSScriptRoot
$TargetDir = Join-Path $InfraRoot "secrets/$Environment"
$BackendDir = Join-Path $TargetDir 'backend'
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
New-Item -ItemType Directory -Force -Path $BackendDir | Out-Null

function New-HexValue {
    param([int]$Bytes)

    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    }
    finally {
        $rng.Dispose()
    }

    return ([System.BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant()
}

function New-AccessKey {
    return (New-HexValue -Bytes 16).ToUpperInvariant()
}

function Write-SecretIfMissing {
    param(
        [string]$Name,
        [string]$Value
    )

    $path = Join-Path $TargetDir $Name
    if (Test-Path $path) {
        Write-Host "keep   $path"
        return
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $Value + [Environment]::NewLine, $utf8NoBom)
    Write-Host "create $path"
}

function Project-BackendSecret {
    param([string]$Name)

    $source = Join-Path $TargetDir $Name
    $destination = Join-Path $BackendDir $Name
    Copy-Item -Force $source $destination
}

Write-SecretIfMissing 'postgres_bootstrap_password' (New-HexValue -Bytes 32)
Write-SecretIfMissing 'postgres_migrator_password' (New-HexValue -Bytes 32)
Write-SecretIfMissing 'postgres_backend_password' (New-HexValue -Bytes 32)
Write-SecretIfMissing 'rustfs_root_access_key' (New-AccessKey)
Write-SecretIfMissing 'rustfs_root_secret_key' (New-HexValue -Bytes 32)
Write-SecretIfMissing 'rustfs_backend_access_key' (New-AccessKey)
Write-SecretIfMissing 'rustfs_backend_secret_key' (New-HexValue -Bytes 32)

Project-BackendSecret 'postgres_migrator_password'
Project-BackendSecret 'postgres_backend_password'
Project-BackendSecret 'rustfs_backend_access_key'
Project-BackendSecret 'rustfs_backend_secret_key'

Write-Host "Local $Environment infrastructure secrets are ready under $TargetDir"
Write-Host "Backend-only secret projection is ready under $BackendDir"
