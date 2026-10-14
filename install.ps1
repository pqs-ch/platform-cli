param([string]$Version = 'latest', [switch]$NoPathUpdate)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer supports Windows x64 and ARM64. Use install.sh on macOS or Linux.'
}
function Get-PlatformWindowsRuntime {
    param(
        [string]$Architecture = $env:PROCESSOR_ARCHITECTURE,
        [string]$NativeArchitecture = $env:PROCESSOR_ARCHITEW6432
    )
    # An emulated PowerShell process reports its own architecture; prefer the OS.
    $architectureName = if ($NativeArchitecture) { $NativeArchitecture } else { $Architecture }
    switch ($architectureName) {
        'AMD64' { return 'win-x64' }
        'ARM64' { return 'win-arm64' }
        default { throw "Unsupported Windows architecture: $architectureName. Expected x64 or ARM64." }
    }
}
$runtime = Get-PlatformWindowsRuntime
$repository = 'https://github.com/pqs-ch/platform-cli'
if ($Version -eq 'latest') {
    $release = Invoke-RestMethod 'https://api.github.com/repos/pqs-ch/platform-cli/releases/latest'
    $Version = $release.tag_name
}
if ($Version -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') { throw 'Version must be vMAJOR.MINOR.PATCH.' }
$root = Join-Path $env:LOCALAPPDATA 'PlatformCli'
$bin = Join-Path $root 'bin'
$null = New-Item -ItemType Directory -Force -Path $root
$stage = Join-Path $root ('.install.' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $stage
try {
    $asset = "platform-$runtime.zip"
    $archive = Join-Path $stage $asset
    Invoke-WebRequest "$repository/releases/download/$Version/$asset" -OutFile $archive -UseBasicParsing
    $checksumFile = Join-Path $stage 'SHA256SUMS'
    Invoke-WebRequest "$repository/releases/download/$Version/SHA256SUMS" -OutFile $checksumFile -UseBasicParsing
    $checksums = Get-Content -LiteralPath $checksumFile -Raw
    $checksumPattern = '^[0-9a-f]{64}  ' + [regex]::Escape($asset) + '$'
    $matches = @($checksums -split '\r?\n' | Where-Object { $_ -cmatch $checksumPattern })
    if ($matches.Count -ne 1) { throw 'Missing or ambiguous checksum.' }
    $expected = $matches[0].Substring(0, 64)
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expected) { throw 'Checksum verification failed.' }
    $package = Join-Path $stage 'package'
    Expand-Archive -LiteralPath $archive -DestinationPath $package
    $executable = Join-Path $package 'platform.exe'
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Release does not contain platform.exe.' }
    & $executable --version
    if ($LASTEXITCODE -ne 0) { throw 'Platform CLI could not start.' }
    # Move the verified package as a unit, retaining the old installation if replacement fails.
    $previous = Join-Path $root ('.previous.' + [Guid]::NewGuid().ToString('N'))
    if (Test-Path -LiteralPath $bin) { Move-Item -LiteralPath $bin -Destination $previous }
    try { Move-Item -LiteralPath $package -Destination $bin }
    catch {
        if (Test-Path -LiteralPath $previous) { Move-Item -LiteralPath $previous -Destination $bin }
        throw
    }
    if (Test-Path -LiteralPath $previous) {
        $resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
        if (-not [IO.Path]::GetFullPath($previous).StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected previous installation path.' }
        Remove-Item -LiteralPath $previous -Recurse -Force
    }
    $userPath = [string][Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $NoPathUpdate -and $bin -notin @($userPath -split ';')) {
        [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ';' + $bin).TrimStart(';')), 'User')
    }
    if (-not $NoPathUpdate -and $bin -notin @($env:Path -split ';')) { $env:Path = $bin + ';' + $env:Path }
    Write-Host "Installed Platform CLI $Version. Obtain your connection command from your authenticated Platform Portal's CLI setup page."
} finally {
    # The path is a freshly created child of this installer's fixed user-owned root.
    $resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
    if (-not [IO.Path]::GetFullPath($stage).StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected installer scratch path.' }
    Remove-Item -LiteralPath $stage -Recurse -Force
}
