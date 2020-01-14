param(

    [ValidateSet('x86', 'x64', 'ARM', 'ARM64')]
    [string[]] $Platforms = ('x86', 'x64', 'ARM', 'ARM64'),

    <#
        Example values:
        14.1
        14.2
        14.16
        14.16.27023
        14.23.27820

        Note. The PlatformToolset will be inferred from this value ('v141', 'v142'...)
    #>
    [version] $VcVersion = '14.1',

    <#
        Example values:
        8.1
        10.0.15063.0
        10.0.17763.0
        10.0.18362.0
    #>
    [version] $WindowsTargetPlatformVersion = '10.0.18362.0',

    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release',

    [System.IO.DirectoryInfo] $VSInstallerFolder = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer",

    # Set the search criteria for VSWHERE.EXE.
    [string[]] $VsWhereCriteria = '-latest',

    [System.IO.FileInfo] $Msys2Bin = 'C:\msys64\usr\bin\bash.exe'
)

function Build-Platform {
    param (
        [System.IO.DirectoryInfo] $SolutionDir,
        [string] $Platform,
        [string] $Configuration,
        [version] $WindowsTargetPlatformVersion,
        [version] $VcVersion,
        [string] $PlatformToolset,
        [string] $VsLatestPath,
        [string] $Msys2Bin = 'C:\msys64\usr\bin\bash.exe'
    )

    $PSBoundParameters | Out-String

    $vcvarsArchs = @{
        'x86' = @{
            'x86'   = 'x86'
            'x64'   = 'x86_amd64'
            'ARM'   = 'x86_arm'
            'ARM64' = 'x86_arm64'
        }
    
        'AMD64' = @{
            'x86'   = 'amd64_x86'
            'x64'   = 'amd64'
            'ARM'   = 'amd64_arm'
            'ARM64' = 'amd64_arm64'
        }
    }

    Write-Host "Building FFmpeg for Windows 10 apps ${Platform}..."
    Write-Host ""
    
    # Load environment from VCVARS.
    $vcvarsArch = $vcvarsArchs[$env:PROCESSOR_ARCHITECTURE][$Platform]

    CMD /c "`"$VsLatestPath\VC\Auxiliary\Build\vcvarsall.bat`" $vcvarsArch uwp $WindowsTargetPlatformVersion -vcvars_ver=$VcVersion && SET" | . {
        PROCESS {
            Write-Host $_
            if ($_ -match '^([^=]+)=(.*)') {
                if ($Matches[1] -notin 'HOME') {
                    Set-Item -Path "Env:\$($Matches[1])" -Value $Matches[2]
                }
            }
        }
    }

    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    New-Item -ItemType Directory -Force $SolutionDir\Libs\Build\$Platform -OutVariable libs

    ('lib', 'licenses', 'include', 'build') | ForEach-Object {
        New-Item -ItemType Directory -Force $libs\$_
    }
    
    $env:LIB += ";${libs}\lib"
    $env:INCLUDE += ";${libs}\include"

    # Clean platform-specific build dir.
    Remove-Item -Force -Recurse $libs\build\*
    Remove-Item -Force -Recurse ${libs}\lib\*
    Remove-Item -Force -Recurse ${libs}\include\*

    MSBuild.exe $SolutionDir\Libs\zlib\SMP\libzlib.vcxproj `
        /p:OutDir="$libs\build\" `
        /p:Configuration="${Configuration}WinRT" `
        /p:Platform=$Platform `
        /p:WindowsTargetPlatformVersion=$WindowsTargetPlatformVersion `
        /p:PlatformToolset=$PlatformToolset

    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    Copy-Item -Path $libs\build\libzlib\include\* -Force -Recurse -Destination $libs\include\ 
    Copy-Item -Recurse $libs\build\libzlib\licenses\* -Destination $libs\licenses\
    Copy-Item $libs\build\libzlib\lib\$Platform\libzlib_winrt.lib $libs\lib\
    Copy-Item $libs\build\libzlib\lib\$Platform\libzlib_winrt.pdb $libs\lib\

    MSBuild.exe $SolutionDir\Libs\bzip2\SMP\libbz2.vcxproj `
        /p:OutDir="$libs\build\" `
        /p:Configuration="${Configuration}WinRT" `
        /p:Platform=$Platform `
        /p:WindowsTargetPlatformVersion=$WindowsTargetPlatformVersion `
        /p:PlatformToolset=$PlatformToolset

    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    Copy-Item -Path $libs\build\libbz2\include\* -Force -Recurse -Destination $libs\include\ 
    Copy-Item -Recurse $libs\build\libbz2\licenses\* -Destination $libs\licenses\
    Copy-Item $libs\build\libbz2\lib\$Platform\libbz2_winrt.lib $libs\lib\
    Copy-Item $libs\build\libbz2\lib\$Platform\libbz2_winrt.pdb $libs\lib\

    MSBuild.exe $SolutionDir\Libs\libiconv\SMP\libiconv.vcxproj `
        /p:OutDir="$libs\build\" `
        /p:Configuration="${Configuration}WinRT" `
        /p:Platform=$Platform `
        /p:WindowsTargetPlatformVersion=$WindowsTargetPlatformVersion `
        /p:PlatformToolset=$PlatformToolset
    
    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    Copy-Item -Path $libs\build\libiconv\include\* -Force -Recurse -Destination $libs\include\ 
    Copy-Item -Recurse $libs\build\libiconv\licenses\* -Destination $libs\licenses\
    Copy-Item $libs\build\libiconv\lib\$Platform\libiconv_winrt.lib $libs\lib\
    Copy-Item $libs\build\libiconv\lib\$Platform\libiconv_winrt.pdb $libs\lib\

    MSBuild.exe $SolutionDir\Libs\liblzma\SMP\liblzma.vcxproj `
        /p:OutDir="$libs\build\" `
        /p:Configuration="${Configuration}WinRT" `
        /p:Platform=$Platform `
        /p:WindowsTargetPlatformVersion=$WindowsTargetPlatformVersion `
        /p:PlatformToolset=$PlatformToolset `
        /p:useenv=true
    
    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    Copy-Item -Path $libs\build\liblzma\include\* -Force -Recurse -Destination $libs\include\
    Copy-Item -Recurse $libs\build\liblzma\licenses\* -Destination $libs\licenses\
    Copy-Item $libs\build\liblzma\lib\$Platform\liblzma_winrt.lib $libs\lib\
    Copy-Item $libs\build\liblzma\lib\$Platform\liblzma_winrt.pdb $libs\lib\

    MSBuild.exe $SolutionDir\Libs\libxml2\SMP\libxml2.vcxproj `
        /p:OutDir="$libs\build\" `
        /p:Configuration="${Configuration}WinRT" `
        /p:Platform=$Platform `
        /p:WindowsTargetPlatformVersion=$WindowsTargetPlatformVersion `
        /p:PlatformToolset=$PlatformToolset `
        /p:useenv=true
    
    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    Copy-Item -Path $libs\build\libxml2\include\* -Force -Recurse -Destination $libs\include\ 
    Copy-Item -Recurse $libs\build\libxml2\licenses\* -Destination $libs\licenses\
    Copy-Item $libs\build\libxml2\lib\$Platform\libxml2_winrt.lib $libs\lib\
    Copy-Item $libs\build\libxml2\lib\$Platform\libxml2_winrt.pdb $libs\lib\

    Rename-Item $libs\lib\libzlib_winrt.lib $libs\lib\zlib.lib -Force
    Rename-Item $libs\lib\libzlib_winrt.pdb $libs\lib\zlib.pdb -Force
    
    Rename-Item $libs\lib\libbz2_winrt.lib $libs\lib\bz2.lib -Force
    Rename-Item $libs\lib\libbz2_winrt.pdb $libs\lib\bz2.pdb -Force
    
    Rename-Item $libs\lib\liblzma_winrt.lib $libs\lib\lzma.lib -Force
    Rename-Item $libs\lib\liblzma_winrt.pdb $libs\lib\lzma.pdb -Force

    Rename-Item $libs\lib\libiconv_winrt.lib $libs\lib\iconv.lib -Force
    Rename-Item $libs\lib\libiconv_winrt.pdb $libs\lib\iconv.pdb -Force

    Rename-Item $libs\lib\libxml2_winrt.lib $libs\lib\libxml2.lib -Force
    Rename-Item $libs\lib\libxml2_winrt.pdb $libs\lib\libxml2.pdb -Force

    # Fixup needed for libxml2 headers, otherwise ffmpeg build fails
    Copy-Item -Path $libs\include\libxml2\libxml -Force -Recurse -Destination $libs\include\ 

    # Export full current PATH from environment into MSYS2
    $env:MSYS2_PATH_TYPE = 'inherit'

    # Build ffmpeg - disable strict error handling since ffmpeg writes to error out
    $ErrorActionPreference = "Continue"
    & $Msys2Bin --login -x $SolutionDir\FFmpegConfig.sh Win10 $Platform
    $ErrorActionPreference = "Stop"

    if ($lastexitcode -ne 0) { Exit $lastexitcode }

    # Copy PDBs to built binaries dir
    Get-ChildItem -Recurse -Include '*.pdb' $SolutionDir\ffmpeg\Output\Windows10\$Platform | `
        Copy-Item -Destination $SolutionDir\ffmpeg\Build\Windows10\$Platform\bin\
}

Write-Host
Write-Host "Building FFmpegInteropX..."
Write-Host

# Stop on all PowerShell command errors
$ErrorActionPreference = "Stop"

if (! (Test-Path $PSScriptRoot\ffmpeg\configure)) {
    Write-Error 'configure is not found in ffmpeg folder. Ensure this folder is populated with ffmpeg snapshot'
    Exit
}

if (!(Test-Path $Msys2Bin)) {

    $msysFound = $false
    @( 'C:\msys64', 'C:\msys' ) | ForEach-Object {
        if (Test-Path $_) {
            $Msys2Bin = "${_}\usr\bin\bash.exe"
            $msysFound = $true

            break
        }
    }

    # Search for MSYS locations
    if (! $msysFound) {
        Write-Error "MSYS2 not found."
        Exit;
    }
}

[System.IO.DirectoryInfo] $vsLatestPath = `
    & "$VSInstallerFolder\vswhere.exe" `
    $VsWhereCriteria `
    -property installationPath `
    -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64

Write-Host "Visual Studio Installation folder: [$vsLatestPath]"

# 14.16.27023 => v141
$platformToolSet = "v$($VcVersion.Major)$("$($VcVersion.Minor)"[0])"
Write-Host "Platform Toolset: [$platformToolSet]"

# Save orignal environment variables
$oldEnv = @{};
foreach ($item in Get-ChildItem env:)
{
    $oldEnv.Add($item.Name, $item.Value);
}

$start = Get-Date

foreach ($platform in $Platforms) {
    Build-Platform `
        -SolutionDir "${PSScriptRoot}\" `
        -Platform $platform `
        -Configuration 'Release' `
        -WindowsTargetPlatformVersion $WindowsTargetPlatformVersion `
        -VcVersion $VcVersion `
        -PlatformToolset $platformToolSet `
        -VsLatestPath $vsLatestPath `
        -Msys2Bin $Msys2Bin

    # Restore orignal environment variables
    foreach ($item in $oldEnv.GetEnumerator())
    {
        Set-Item -Path env:"$($item.Name)" -Value $item.Value
    }
    foreach ($item in Get-ChildItem env:)
    {
        if (!$oldEnv.ContainsKey($item.Name))
        {
             Remove-Item -Path env:"$($item.Name)"
        }
    }
}

Write-Host 'Time elapsed'
Write-Host (' {0}' -f ((Get-Date) - $start))