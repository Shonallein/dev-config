# Windows bootstrap script
# Author: Alexandre CHASSANY
# Email: alexandre.chassany@gmail.com
#
# This script will install all the softwares that
# i need to develop and setup windows to fit my
# preferences.
# This script is incremental and can be re-run to install
# other missing components.

###############################
#           Helpers           #
###############################
function Info($message) {
    Write-Host "[INFO] $message" -foregroundcolor DarkCyan
}

function Error($message) {
    Write-Host "[Error] $message" -foregroundcolor Red
    Exit 1
}

function ReloadPath {
    # Reload path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function Create-Path($path) {
    if(Test-Path $path) {
        Info "$path already exists"
        return
    }
    
    Info "Creating path '$path'"
    New-Item $path -type directory    
}

function Create-Symlink($link, $target) {
    if(Test-Path $link) {
        Info "$link symlink already exists"
    }
    
    $dir= Split-Path $link -parent
    Create-Path $dir
    if(Test-Path $target -pathType container) {
        cmd /c mklink /D $link $target
    } else {
        cmd /c mklink $link $target
    }
}

function Download-File($url, $path) {
    Info "Downloading $url to $path"
    $wc=new-object net.webclient
    $wp=[system.net.WebProxy]::GetDefaultProxy()
    $wp.UseDefaultCredentials=$true
    $wc.Proxy=$wp
    $wc.DownloadFile($url, $path)
}

function Expand-ZIPFile($archive, $dest)
{
    Info "Extracting $archive to $dest"
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($archive)
    foreach($item in $zip.items())
    {
        $shell.Namespace($dest).copyhere($item)
    }
}

###############################
#           Config            #
###############################
$mysrc = "$env:USERPROFILE\dev\src"
$mytools = "$env:USERPROFILE\dev\tools"

###############################
#    Windows Configuration    #
###############################

# Disable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

# Show file extensions and hidden files
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0
Set-ItemProperty $key ShowSuperHidden 1

# Create dir structure
Create-Path $mysrc
Create-Path $mytools
Create-Symlink "$env:USERPROFILE\Links\src" $mysrc
Create-Symlink "$env:USERPROFILE\Links\Home" "$env:USERPROFILE"

###############################
#    Software Installation    #
###############################

# Will check if Chocolatey is already installed. If not, it will perform the installation
function Install-Chocolatey {
    if($env:ChocolateyInstall -or (Test-Path "$env:ChocolateyInstall")){
        Info "Chocolatey already installed"
        return
    }

    Info "Installing Chocolatey"
    # Create a webclient with default proxy config
    $wc=new-object net.webclient
    $wp=[system.net.WebProxy]::GetDefaultProxy()
    $wp.UseDefaultCredentials=$true
    $wc.Proxy=$wp
    $res = iex ($wc.DownloadString("http://chocolatey.org/install.ps1"))
    if(!$res) {
        Error "Chocolatey installation failed"
    }
}

# Will check if cmder is already installed. If not, it will perform the installation
function Install-Cmder {
    $url = "https://github.com/bliker/cmder/releases/download/v1.2/cmder_mini.zip"
    $tempPath = "$env:TEMP\cmder_mini.zip"
    $path = "$mytools\cmder"

    if((Test-Path $path)){
        Info "Cmder already installed"
        return
    }

    Info "Installing cmder"
    Download-File $url $tempPath
    Create-Path $path
    Expand-ZIPFile $tempPath $path
    if(-not (Test-Path $path)) {
        Error "Cmder installation failed!"
    }
    $env:CmderInstall = $path
    [Environment]::SetEnvironmentVariable("CmderInstall", $env:CmderInstall, [System.EnvironmentVariableTarget]::User)
}

function Choco-Install {
    choco install -y $args
    ReloadPath
}

# Install Chocolatey package manager
Install-Chocolatey

# Install softwares using Chocolatey
Choco-Install git # Git scm
Choco-Install emacs # Text editor
Choco-Install windirstat # Small utility to check disk usage
Choco-Install cmake # cross platform build system
Choco-Install python2
Choco-Install pip # Package manager for python
Choco-Install 7zip # compress/extract archivess
#Choco-Install google-chrome-x64 # webbrowser
Choco-Install curl # tool to emit request through different protocols. Great to debug web api :D
Choco-Install launchy # Spotlight for windows
Choco-Install meld # Cross platform merge tool

# Install my favorite console emulator
Install-Cmder

###############################
#            Misc             #
###############################

# Add git bin to path
$gitBin = "C:\Program Files (x86)\Git\bin"
if(-not (Test-Path $gitBin)) {
    Error "Git bin dir doesn't exists!"
}
$userPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if(-not ($userPath -like "*$gitBin*")) {
    Info "Add Git bin to user path"
    [Environment]::SetEnvironmentVariable("PATH", $userPath+";"+$gitBin, [System.EnvironmentVariableTarget]::User)
    ReloadPath
}

# Clone dev-config repository
if(-not (Test-Path "$mysrc\dev-config")) {
    git clone https://github.com/Shonallein/dev-config.git "$mysrc\dev-config"
}

# Make a symbolic link of my emacs configuration in emacs configuration dir
Create-Symlink "$env:USERPROFILE\.emacs.d\init.el" "$mysrc\dev-config\init.el"

# Make a symbolic link of my git config in my HOME
Create-Symlink "$env:USERPROFILE\.gitconfig" "$mysrc\dev-config\.gitconfig"

# Create Home env variable (required by many unix softwares)
[Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, [System.EnvironmentVariableTarget]::User)