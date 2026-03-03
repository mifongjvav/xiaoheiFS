Param(
    [string]$BuildOption = '',
    [string]$ImageName = 'xiaoheifs-backend'
)

# stop on any error
$ErrorActionPreference = 'Stop'

# walk up from this script's location to repository root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Resolve-Path "$scriptDir\..\.."
Set-Location $rootDir

# determine version from git or pubspec.yaml
$version = ''
if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        $version = git describe --tags --dirty --always 2>$null
    } catch {}
}
if (-not $version -and (Test-Path 'app/xiaoheifs_app/pubspec.yaml')) {
    $line = Select-String -Path 'app/xiaoheifs_app/pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
    if ($line) {
        $version = ($line -replace '^version:\s*', '') -split '\+' | Select-Object -First 1
    }
}
if (-not $version) { $version = 'local' }

if (-not $BuildOption) {
    Write-Host 'Select build option:'
    Write-Host '  1) latest (debian)'
    Write-Host '  2) alpine'
    Write-Host '  0) all'
    $choice = Read-Host 'Enter choice [1/2/0]'
    switch ($choice) {
        '1' { $BuildOption = 'latest' }
        '2' { $BuildOption = 'alpine' }
        '0' { $BuildOption = 'all' }
        default { throw "Invalid choice: $choice" }
    }
}

# backward compatible: first arg as image name
$validOptions = @('latest', 'alpine', 'all')
if ($BuildOption -notin $validOptions) {
    $ImageName = $BuildOption
    $BuildOption = 'latest'
}

# tags are controlled by build option
$repo = ($ImageName -split ':')[0]

function Build-Image([string]$Dockerfile, [string]$Tag) {
    $image = "$repo`:$Tag"
    docker build -f $Dockerfile --build-arg VERSION="$version" -t $image .
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed with exit code $LASTEXITCODE"
    }
    Write-Host "Image built: $image (version $version)"
}

switch ($BuildOption) {
    'latest' { Build-Image 'docker/build/Dockerfile' 'latest' }
    'alpine' { Build-Image 'docker/build/Dockerfile.alpine' 'alpine' }
    'all' {
        Build-Image 'docker/build/Dockerfile' 'latest'
        Build-Image 'docker/build/Dockerfile.alpine' 'alpine'
    }
}
