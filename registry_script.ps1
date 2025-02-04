# Variables
$resourceGroup = "azure_test_resource_group"
$location = "uksouth"
$acrName = "azuretest2containerregistry"
$imageName = "nginx-image"
$dockerFilePath = "."  # Replace with the actual path to your Dockerfile
$acrLoginServer = "$acrName.azurecr.io"
$osType = "Linux"  # Specify 'Linux' or 'Windows' for OS type
$containerName = "my-container-instance"  # Valid new container name
$dnsName = "mycontainerpublic"  # DNS name to access the container
$taskName = "CreateDeleteContainerTask"  # Name of the scheduled task
$scriptPath = "./CreateDeleteContainer.ps1"  # Path to the scheduled task script

# Blob Storage Parameters
$storageAccountName = "mystorageaccount" + (Get-Random -Minimum 100000 -Maximum 999999)  # Random storage account name
$containerNameBlob = "nginx-logs"  # Blob storage container name
$blobName = "nginx_status_log.txt"  # Blob file name for logs

# Step 1: Create Resource Group
az group create --name $resourceGroup --location $location

# Step 2: Create Azure Container Registry (ACR)
az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location

# Enable admin user for ACR
az acr update --name $acrName --admin-enabled true

# Get ACR credentials
$acrCredentials = az acr credential show --name $acrName | ConvertFrom-Json
$username = $acrCredentials.username
$password = $acrCredentials.passwords[0].value

Write-Host "ACR Username: $username"
Write-Host "ACR Password: $password"

# Step 3: Login to ACR using credentials
docker login $acrLoginServer --username $username --password $password

# Step 4: Build Docker image from Dockerfile
docker build -t $imageName $dockerFilePath

# Step 5: Tag and push Docker image to ACR
docker tag $imageName $acrLoginServer/$imageName
docker push $acrLoginServer/$imageName

# Step 6: Create Storage Account if it doesn't exist
$storageAccountExists = az storage account check-name --name $storageAccountName | ConvertFrom-Json

if ($storageAccountExists.nameAvailable -eq $true) {
    Write-Host "Storage account does not exist, creating..."
    az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location --sku Standard_LRS
}
else {
    Write-Host "Storage account already exists."
}

# Step 7: Retrieve Storage Account Key
$storageAccountKey = az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv
Write-Host "Storage account key retrieved."

# Step 8: Create Container Instance (ACI)
Write-Host "Creating Container Instance..."
az container create --resource-group $resourceGroup --name $containerName --image $acrLoginServer/$imageName --cpu 1 --memory 1.5 --os-type $osType --restart-policy OnFailure --registry-login-server $acrLoginServer --registry-username $username --registry-password $password --dns-name-label $dnsName --ports 80

# Retrieve public IP of the container
$publicIP = az container show --resource-group $resourceGroup --name $containerName --query "ipAddress.ip" --output tsv
Write-Host "Public IP of container: $publicIP"

# Step 9: Check if nginx is running in the container
$response = curl -s "http://$publicIP"

if ($response -match "nginx") {
    $nginxStatus = "nginx is active"
}
else {
    $nginxStatus = "nginx is not active"
}

# Step 10: Log nginx status to a file
Write-Host "Nginx Status: $nginxStatus" | Out-File -FilePath ".\nginx_status_log.txt" -Append

# Step 11: Check if Blob container exists, if not create it
$containerExists = az storage container exists --account-name $storageAccountName --name $containerNameBlob --query "exists" --output tsv --account-key $storageAccountKey


if ($containerExists -eq "false") {
    Write-Host "Blob container does not exist, creating..."
    az storage container create --account-name $storageAccountName --name $containerNameBlob --account-key $storageAccountKey
}

# Step 12: Upload log file to Blob Storage
Write-Host "Uploading log to Azure Blob Storage..."
az storage blob upload --account-name $storageAccountName --container-name $containerNameBlob --file ".\nginx_status_log.txt" --name $blobName --account-key $storageAccountKey

# Step 13: Delete the container instance
Write-Host "Deleting container..."
az container delete --resource-group $resourceGroup --name $containerName --yes
Write-Host "Container deleted successfully."

# Step 14: Create PowerShell script for scheduled task
$scriptContent = @"
# PowerShell script to run on schedule
az acr login --name $acrName
az container create --resource-group $resourceGroup --name $containerName --image $acrLoginServer/$imageName --cpu 1 --memory 1.5 --os-type $osType --restart-policy OnFailure --registry-login-server $acrLoginServer --registry-username $username --registry-password $password --dns-name-label $dnsName --ports 80
Start-Sleep -Seconds 10
$nginxStatus = docker exec $containerName curl -s http://localhost | findstr 'nginx' && 'nginx is active' || 'nginx is not active'
Write-Host "Nginx Status: $nginxStatus" | Out-File -FilePath '.\nginx_status_log.txt' -Append
az storage blob upload --account-name $storageAccountName --container-name $containerNameBlob --file '.\nginx_status_log.txt' --name $blobName --auth-mode key
az container delete --resource-group $resourceGroup --name $containerName --yes
"@

$scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8

# Step 15: Create scheduled task to run the script daily
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Scheduled task exists, deleting..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Write-Host "Creating scheduled task..."
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)  
$trigger.Repetition = New-ScheduledTaskRepetitionInterval -Interval (New-TimeSpan -Minutes 1) -Duration ([timespan]::MaxValue)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Task to create, verify and delete container with nginx check and log upload to Blob Storage."

Write-Host "Scheduled task created."