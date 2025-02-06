# Define Variables
$resourceGroup = "MyResourceGroupnew"
$location = "EastUS"
$storageAccountName = "mystorage321new"
$containerName = "myblobcontainernew"
$blobName = "TASKFILE.txt"
$localFilePath = "C:\$blobName"
$downloadedFilePath = "C:\Temp\downloaded_$blobName" 

# Ensure Temp Directory Exists
if (!(Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

# Create Sample File (Lorem Ipsum Text)
@"
Lorem ipsum dolor sit amet
"@ | Set-Content -Path $localFilePath

# Create Resource Group
Write-Host "Creating Resource Group..."
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create Storage Account
Write-Host "Creating Storage Account..."
New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -Location $location `
    -SkuName "Standard_LRS" `
    -Kind "StorageV2"

# Retrieve Storage Account Context
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$storageContext = $storageAccount.Context

# Create Blob Storage Container
Write-Host "Creating Blob Storage Container..."
New-AzStorageContainer -Name $containerName -Context $storageContext

# Upload File to Blob Storage
Write-Host "Uploading File..."
Set-AzStorageBlobContent -File $localFilePath `
    -Container $containerName `
    -Blob $blobName `
    -Context $storageContext `
    -Force

# Generate SAS Token (Valid for 1 Hour)
Write-Host "Generating SAS URL..."
$startTime = (Get-Date).ToUniversalTime()
$expiryTime = $startTime.AddHours(1)

$sasToken = New-AzStorageBlobSASToken -Container $containerName `
    -Blob $blobName `
    -Context $storageContext `
    -Permission r `
    -StartTime $startTime `
    -ExpiryTime $expiryTime

$sasUrl = "$($storageAccount.PrimaryEndpoints.Blob)$containerName/$blobName$sasToken"

Write-Host "SAS URL: $sasUrl"

# Download File from Blob Storage
Write-Host "Downloading File..."
Get-AzStorageBlobContent -Container $containerName `
    -Blob $blobName `
    -Destination $downloadedFilePath `
    -Context $storageContext `
    -Force

# Compare Files
Write-Host "Comparing Uploaded and Downloaded Files..."
$originalContent = Get-Content -Path $localFilePath
$downloadedContent = Get-Content -Path $downloadedFilePath

if ($originalContent -eq $downloadedContent) { Write-Host "Files are identical!" } else {
    Write-Host "Files are different!"
    Write-Host "Differences:"
    Compare-Object -ReferenceObject $originalContent -DifferenceObject $downloadedContent
}

# Delete Resource Group (Cleanup)
Write-Host "Deleting Resource Group..."
Remove-AzResourceGroup -Name $resourceGroup -Force -AsJob

Write-Host "Script execution completed!"
