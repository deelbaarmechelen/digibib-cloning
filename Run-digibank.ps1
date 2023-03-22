if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ 
    try {
        # $PSCommandPath: Contains the full path and filename of the script that's being run
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    catch {
        Write-Host $_.ScriptStackTrace
    }
    exit 
}
Write-Host "started"

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$API_Key = Get-Content -Path $ScriptDir\ApiKeyDigibank.txt
# Leading '&' is aka the call operator
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3&viewFallbackFrom=powershell-6#call-operator-
#& "$ScriptDir\Check_Flowchart.ps1" -
& "$ScriptDir\Check_Flowchart.ps1" -baseUrl "https://digibank.deelbaarmechelen.be" -API_Key $API_Key
Write-Host "End"
Read-Host "Press enter"
