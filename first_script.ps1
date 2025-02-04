# Defines variables for vm creation
$ResourceGroup = "az_test_resource_group"
$Location = "uksouth"
$VMName = "MyVM1"
$AdminUsername = "azureuser"

# Creates a virtual machine 
az vm create --resource-group $ResourceGroup --location $Location --name $VMName --image Ubuntu2404 --admin-username $AdminUsername --ssh-key-values $env:USERPROFILE\.ssh\id_rsa.pub --generate-ssh-keys


$FilePath = "C:\Users\alyxi\package-lock.json"
$ContainerName = "test1container"
$BlobName = "package_example_file.json"

$StorageAccount = "test1storacc" + (Get-Random -Minimum 1000 -Maximum 9999)

az storage account create --name $StorageAccount --resource-group $ResourceGroup --location $Location --sku Standard_LRS

$StorageKey = (az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query '[0].value' -o tsv)

az storage container create --name $ContainerName --account-name $StorageAccount --account-key $StorageKey

az storage blob upload --account-name $StorageAccount --account-key $StorageKey --container-name $ContainerName --file $FilePath --name $BlobName

az storage blob list --account-name $StorageAccount --account-key $StorageKey --container-name $ContainerName --output table

az storage container set-permission --name $ContainerName --account-name $StorageAccount --account-key $StorageKey --public-access blob

az group delete --name $ResourceGroup --yes --no-wait