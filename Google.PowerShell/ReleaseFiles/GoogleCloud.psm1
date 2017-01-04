$script:GCloudModule = $ExecutionContext.SessionState.Module
$script:GCloudModulePath = $script:GCloudModule.ModuleBase

$gCloudSDK = Get-Command gcloud -ErrorAction SilentlyContinue

# Gets Cloud SDK non-interactively.
function Install-GCloudSdk {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [switch]$Force
    )

    $query = "Do you want to install Google Cloud SDK? If you want to force the installation without prompt, set `$env:GCLOUD_SDK_INSTALLATION_NO_PROMPT to true"
    $caption = "Installing Google Cloud SDK"

    if ($PSCmdlet.ShouldProcess("Google Cloud SDK", "Install")) {
        if ($Force -or $PSCmdlet.ShouldContinue($query, $caption)) {
            $cloudSdkUri = "https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip"
            Invoke-WebRequest -Uri $cloudSdkUri -OutFile "$env:APPDATA\gcloudsdk.zip"
            Add-Type -AssemblyName System.IO.Compression.FileSystem

            # This will extract it to a folder $env:APPDATA\google-cloud-sdk.
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$env:APPDATA\gcloudsdk.zip", "$env:APPDATA")
    
            $installationPath = "$env:LOCALAPPDATA\Google\Cloud SDK"

            md $installationPath
            Copy-Item "$env:APPDATA\google-cloud-sdk" $installationPath -Recurse -Force

            # Set this to true to disable prompts.
            $env:CLOUDSDK_CORE_DISABLE_PROMPTS = $true
            & "$installationPath\google-cloud-sdk\install.bat" --quiet 2>$null

            $cloudBinPath = "$installationPath\google-cloud-sdk\bin"
            $envPath = [System.Environment]::GetEnvironmentVariable("Path")
            if (-not $envPath.Contains($cloudBinPath)) {
                [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$cloudBinPath")
            }
        }
    }
}

if ($null -ne $gCloudSDK) {
    Write-Host "Google Cloud SDK is not found in PATH."
    $force = $env:GCLOUD_SDK_INSTALLATION_NO_PROMPT -eq $true
    Install-GCloudSdk -Force:$force
}
