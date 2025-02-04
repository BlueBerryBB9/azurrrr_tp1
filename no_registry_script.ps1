# Define variables for virtual machine creation
$ResourceGroup = "az_test_resource_group"  # Name of the Azure resource group
$Location = "uksouth"  # Azure region where resources will be created
$VMName = "MyVM1"  # Name of the virtual machine
$AdminUsername = "azureuser"  # Administrator username for the VM

# Create an Ubuntu 24.04 virtual machine with SSH enabled
az vm create --resource-group $ResourceGroup --location $Location --name $VMName --image Ubuntu2404 --admin-username $AdminUsername --ssh-key-values $env:USERPROFILE\.ssh\id_rsa.pub --generate-ssh-keys

# Define storage-related variables
$FilePath = "C:\Users\alyxi\package-lock.json"  # Path to the local file to be uploaded
$ContainerName = "test1container"  # Name of the Blob Storage container
$BlobName = "package_example_file.json"  # Name of the file in Blob Storage

# Generate a random name for the storage account to avoid conflicts
$StorageAccount = "test1storacc" + (Get-Random -Minimum 1000 -Maximum 9999)

# Create an Azure storage account
az storage account create --name $StorageAccount --resource-group $ResourceGroup --location $Location --sku Standard_LRS

# Retrieve the storage account access key
$StorageKey = (az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query '[0].value' -o tsv)

# Create a Blob Storage container within the storage account
az storage container create --name $ContainerName --account-name $StorageAccount --account-key $StorageKey

# Upload the specified file to the Blob Storage container
az storage blob upload --account-name $StorageAccount --account-key $StorageKey --container-name $ContainerName --file $FilePath --name $BlobName

# List files stored in the Blob Storage container
az storage blob list --account-name $StorageAccount --account-key $StorageKey --container-name $ContainerName --output table

# Make the container public so its blobs can be accessed publicly
az storage container set-permission --name $ContainerName --account-name $StorageAccount --account-key $StorageKey --public-access blob

# Delete the resource group (and all associated resources) without confirmation and asynchronously
az group delete --name $ResourceGroup --yes --no-wait
