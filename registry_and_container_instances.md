# 🚀 Déploiement et gestion d'un conteneur Azure avec stockage des logs

Ce guide explique comment :

- Déployer un conteneur Docker sur Azure via **l'interface web** et **Azure CLI**
- Stocker les logs de Nginx dans **Azure Blob Storage**
- Automatiser la création et suppression du conteneur

---

## 📌 Prérequis

Avant de commencer, assurez-vous d'avoir :

- Un compte Azure
- [Azure CLI installé](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli)
- [Docker installé](https://www.docker.com/get-started/)
- Connecté Azure CLI avec :
  ```powershell
  az login
  ```

---

## 1️⃣ Création du groupe de ressources

### 🖥️ Via l'interface Azure

1. Allez sur le **Portail Azure** ([portal.azure.com](https://portal.azure.com))
2. Recherchez **Groupes de ressources**
3. Cliquez sur **Créer**
4. Donnez un nom au groupe (`azure-test-group`)
5. Sélectionnez une **région** (ex: `UK South`)
6. Cliquez sur **Créer**

### ⌨️ Via Azure CLI

```powershell
$resourceGroup = "azure-test-group"
$location = "uksouth"
az group create --name $resourceGroup --location $location
```

---

## 2️⃣ Création d'un registre de conteneurs

### 🖥️ Via l'interface Azure

1. Allez sur **Registres de conteneurs**
2. Cliquez sur **Créer**
3. Remplissez :
   - Groupe de ressources : `azure-test-group`
   - Nom : `azuretestregistry`
   - Niveau de tarification : `Basic`
4. Cliquez sur **Créer**

### ⌨️ Via Azure CLI

```powershell
$acrName = "azuretestregistry"
az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location
az acr update --name $acrName --admin-enabled true
```

---

## 3️⃣ Création et déploiement de l'image Docker

### 🖥️ Via Docker Desktop

1. **Créer un fichier `Dockerfile`**
   ```Dockerfile
   FROM nginx:latest
   COPY index.html /usr/share/nginx/html/index.html
   ```
2. **Construire l’image Docker**
   ```sh
   docker build -t nginx-image .
   ```
3. **Taguer et pousser l’image vers Azure**
   ```sh
   docker tag nginx-image azuretestregistry.azurecr.io/nginx-image
   docker push azuretestregistry.azurecr.io/nginx-image
   ```

### ⌨️ Via Azure CLI

```powershell
$acrLoginServer = "azuretestregistry.azurecr.io"
$imageName = "nginx-image"

docker login $acrLoginServer --username $(az acr credential show --name $acrName --query "username" -o tsv) --password $(az acr credential show --name $acrName --query "passwords[0].value" -o tsv)

docker build -t $imageName .
docker tag $imageName $acrLoginServer/$imageName
docker push $acrLoginServer/$imageName
```

---

## 4️⃣ Création d’un conteneur avec une IP publique

### 🖥️ Via l'interface Azure

1. Allez sur **Instances de conteneurs**
2. Cliquez sur **Créer**
3. Sélectionnez :
   - Groupe de ressources : `azure-test-group`
   - Nom du conteneur : `nginx-container`
   - Image : `azuretestregistry.azurecr.io/nginx-image`
   - CPU/Mémoire : `1 vCPU / 1.5 GiB`
   - Activer **DNS public**
   - Port 80
4. Cliquez sur **Créer**

### ⌨️ Via Azure CLI

```powershell
$containerName = "nginx-container"
$dnsName = "nginx-container-public"

az container create --resource-group $resourceGroup --name $containerName --image $acrLoginServer/$imageName --cpu 1 --memory 1.5 --os-type Linux --restart-policy OnFailure --registry-login-server $acrLoginServer --registry-username $(az acr credential show --name $acrName --query "username" -o tsv) --registry-password $(az acr credential show --name $acrName --query "passwords[0].value" -o tsv) --dns-name-label $dnsName --ports 80

$publicIP = az container show --resource-group $resourceGroup --name $containerName --query "ipAddress.ip" --output tsv
Write-Host "IP publique du conteneur : $publicIP"
```

---

## 5️⃣ Création du compte de stockage et du conteneur Blob

### ⌨️ Via Azure CLI

```powershell
$storageAccountName = "storage$(Get-Random)"
$containerNameBlob = "nginx-logs"

az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location --sku Standard_LRS
az storage container create --account-name $storageAccountName --name $containerNameBlob
```

---

## 6️⃣ Vérification du statut de Nginx et stockage des logs

### ⌨️ Script PowerShell

```powershell
Start-Sleep -Seconds 10

$nginxStatus = curl -s "http://$publicIP" | Select-String "nginx" ? "nginx est actif" : "nginx n'est pas actif"
Write-Host "Statut de nginx : $nginxStatus" | Out-File -FilePath ".
ginx_status_log.txt" -Append

$containerExists = az storage container exists --account-name $storageAccountName --name $containerNameBlob --query "exists" --output tsv

if ($containerExists -eq "false") {
    az storage container create --account-name $storageAccountName --name $containerNameBlob
}

Write-Host "Envoi du log vers Azure Blob Storage..."
$storageAccountKey = az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv

az storage blob upload --account-name $storageAccountName --container-name $containerNameBlob --file ".
ginx_status_log.txt" --name "nginx_status_log.txt" --account-key $storageAccountKey
```

---

## 7️⃣ Suppression automatique du conteneur

### ⌨️ Via Azure CLI

```powershell
Write-Host "Suppression du conteneur..."
az container delete --resource-group $resourceGroup --name $containerName --yes
Write-Host "Conteneur supprimé avec succès."
```
