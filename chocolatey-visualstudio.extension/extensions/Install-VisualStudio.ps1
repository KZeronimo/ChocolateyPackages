﻿function Install-VisualStudio {
<#
.SYNOPSIS
Installs Visual Studio

.DESCRIPTION
Installs Visual Studio with ability to specify additional features and supply product key.

.PARAMETER PackageName
The name of the VisualStudio package - this is arbitrary.
It's recommended you call it the same as your nuget package id.

.PARAMETER Url
This is the url to download the VS web installer.

.PARAMETER ChecksumSha1
The SHA-1 hash of the VS web installer file.

.EXAMPLE
Install-VisualStudio -PackageName VisualStudio2015Community -Url 'http://download.microsoft.com/download/zzz/vs_community.exe' -ChecksumSha1 'ABCDEF0123456789ABCDEF0123456789ABCDEF12'

.OUTPUTS
None

.NOTES
This helper reduces the number of lines one would have to write to download and install Visual Studio.
This method has no error handling built into it.

.LINK
Install-ChocolateyPackage
#>
    [CmdletBinding()]
    param(
      [string] $PackageName,
      [string] $ApplicationName,
      [string] $Url,
      [string] $Checksum,
      [string] $ChecksumType,
      [ValidateSet('MsiVS2015OrEarlier', 'WillowVS2017OrLater')] [string] $InstallerTechnology,
      [string] $ProgramsAndFeaturesDisplayName = $ApplicationName
    )
    if ($Env:ChocolateyPackageDebug -ne $null)
    {
        $VerbosePreference = 'Continue'
        $DebugPreference = 'Continue'
        Write-Warning "VerbosePreference and DebugPreference set to Continue due to the presence of ChocolateyPackageDebug environment variable"
    }
    Write-Debug "Running 'Install-VisualStudio' for $PackageName with ApplicationName:'$ApplicationName' Url:'$Url' Checksum:$Checksum ChecksumType:$ChecksumType InstallerTechnology:'$InstallerTechnology' ProgramsAndFeaturesDisplayName:'$ProgramsAndFeaturesDisplayName'";

    $assumeNewVS2017Installer = $InstallerTechnology -eq 'WillowVS2017OrLater'

    $uninstallKey = Get-VSUninstallRegistryKey -ApplicationName $ProgramsAndFeaturesDisplayName
    $count = ($uninstallKey | Measure-Object).Count
    if ($count -gt 0)
    {
        if ($assumeNewVS2017Installer)
        {
            # TODO: implement detection of products installed by Willow
            # (there is a single Programs and Features entry for all products, so its presence is not enough)
            Write-Debug "Programs and Features entry '$ProgramsAndFeaturesDisplayName' detected, this or other product from this family is installed"
        }
        else
        {
            Write-Warning "$ApplicationName is already installed. Please use Programs and Features in the Control Panel to modify or repair it."
            return
        }
    }

    $packageParameters = Parse-Parameters $env:chocolateyPackageParameters
    if ($assumeNewVS2017Installer)
    {
        $adminFile = $null
        $logFilePath = $null
    }
    else
    {
        $defaultAdminFile = (Join-Path $PSScriptRoot 'AdminDeployment.xml')
        Write-Debug "Default AdminFile: $defaultAdminFile"

        $adminFile = Generate-AdminFile $packageParameters $defaultAdminFile $PackageName
        Write-Debug "AdminFile: $adminFile"

        Update-AdminFile $packageParameters $adminFile

        $logFilePath = Join-Path $Env:TEMP "${PackageName}.log"
        Write-Debug "Log file path: $logFilePath"
    }

    $silentArgs = Generate-InstallArgumentsString -parameters $packageParameters -adminFile $adminFile -logFilePath $logFilePath -assumeNewVS2017Installer:$assumeNewVS2017Installer

    $arguments = @{
        packageName = $PackageName
        silentArgs = $silentArgs
        url = $Url
        checksum = $Checksum
        checksumType = $ChecksumType
        logFilePath = $logFilePath
        assumeNewVS2017Installer = $assumeNewVS2017Installer
    }
    $argumentsDump = ($arguments.GetEnumerator() | % { '-{0}:''{1}''' -f $_.Key,"$($_.Value)" }) -join ' '
    Write-Debug "Install-VSChocolateyPackage $argumentsDump"
    Install-VSChocolateyPackage @arguments
}
