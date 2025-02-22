$PackageName = "azure-quantum-_client"

$PackageVersion = $env:PYTHON_VERSION 
if ([string]::IsNullOrEmpty($PackageVersion)) {
    $VersionFilePath = Join-Path $PSScriptRoot "../azure/quantum/version.py"
    if (Test-Path $VersionFilePath) {
        $VersionFileContent = Get-Content -Path $VersionFilePath
        $PackageVersion = [regex]::Match($VersionFileContent, '__version__\s*=\s*"(?<version>[^"]+)"').Groups["version"]?.Value
    }
}
if ([string]::IsNullOrEmpty($PackageVersion)) {
    $PackageVersion = "0.0.0.1"
}

$Namespace = "azure.quantum._client"

$SpecsRepo = "https://github.com/Azure/azure-rest-api-specs.git"
$SpecsBranch = "master"
$SpecsCommitId = ""
$PathAllowList = ("specification/quantum")

$TempFolder = Join-Path $PSScriptRoot "../temp/"
$SpecsFolder = Join-Path $TempFolder  "/specs/"

# Check-out specs repo to get the latest swagger API Definition file
$CheckoutScript = Join-Path $PSScriptRoot "./Checkout-Repo.ps1" 
&$CheckoutScript -RepoUrl $SpecsRepo -TargetFolder $SpecsFolder -PathAllowList $PathAllowList -BranchName $SpecsBranch -CommitId $SpecsCommitId -Force | Write-Verbose

# Delete the old generated client in the temp folder
$TempGeneratedClientFolder = Join-Path $TempFolder "generated/_client/"
if (Test-Path $TempGeneratedClientFolder) {
    Remove-Item $TempGeneratedClientFolder -Recurse | Write-Verbose
}

$AutoRestConfig = Join-Path $SpecsFolder "specification/quantum/data-plane/readme.md"

# Make sure we have the latest AutoRest
npm install -g autorest@latest | Write-Verbose

# Generate the client in a temp folder
autorest $AutoRestConfig `
    --verbose `
    --python `
    --package-name=$PackageName `
    --package-version=$PackageVersion `
    --namespace=$Namespace `
    --no-namespace-folders=true `
    --add-credential `
    --credential-scopes="https://quantum.microsoft.com/.default" `
    --python-mode=custom `
    --output-folder=$TempGeneratedClientFolder `
    | Write-Verbose

# Delete the old generated client and copy the new one there
$AzureQuantumClient_Folder =  Join-Path $PSScriptRoot "../azure/quantum/_client/"
if (Test-Path $AzureQuantumClient_Folder) {
    Remove-Item $AzureQuantumClient_Folder -Recurse | Write-Verbose
}
Copy-Item $TempGeneratedClientFolder $AzureQuantumClient_Folder -Recurse -Force | Write-Verbose
