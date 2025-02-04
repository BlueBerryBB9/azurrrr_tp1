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
4. Donnez un nom au groupe (`azure_test_resource_group`)
5. Sélectionnez une **région** (ex: `UK South`)
6. Cliquez sur **Créer**

### ⌨️ Via Azure CLI

```powershell
az group create --name azure_test_resource_group --location uksouth
```

---

## 2️⃣ Création d'un registre de conteneurs

### 🖥️ Via l'interface Azure

1. Allez sur **Registres de conteneurs**
2. Cliquez sur **Créer**
3. Remplissez :
   - Groupe de ressources : `azure_test_resource_group`
   - Nom : `azuretest2containerregistry`
   - Niveau de tarification : `Basic`
4. Cliquez sur **Créer**
5. Une fois créé, activez l'option **Admin utilisateur**

### ⌨️ Via Azure CLI

```powershell
az acr create --resource-group azure_test_resource_group --name azuretest2containerregistry --sku Basic --location uksouth
az acr update --name azuretest2containerregistry --admin-enabled true
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
   docker tag nginx-image azuretest2containerregistry.azurecr.io/nginx-image
   docker push azuretest2containerregistry.azurecr.io/nginx-image
   ```

### ⌨️ Via Azure CLI

```powershell
docker login azuretest2containerregistry.azurecr.io --username $(az acr credential show --name azuretest2containerregistry --query "username" -o tsv) --password $(az acr credential show --name azuretest2containerregistry --query "passwords[0].value" -o tsv)

docker build -t nginx-image .
docker tag nginx-image azuretest2containerregistry.azurecr.io/nginx-image
docker push azuretest2containerregistry.azurecr.io/nginx-image
```

---

## 4️⃣ Création d’un conteneur avec une IP publique

### 🖥️ Via l'interface Azure

1. Allez sur **Instances de conteneurs**
2. Cliquez sur **Créer**
3. Sélectionnez :
   - Groupe de ressources : `azure_test_resource_group`
   - Nom du conteneur : `my-container-instance`
   - Image : `azuretest2containerregistry.azurecr.io/nginx-image`
   - CPU/Mémoire : `1 vCPU / 1.5 GiB`
   - Activer **DNS public**
   - Port 80
4. Cliquez sur **Créer**

### ⌨️ Via Azure CLI

```powershell
az container create --resource-group azure_test_resource_group --name my-container-instance --image azuretest2containerregistry.azurecr.io/nginx-image --cpu 1 --memory 1.5 --os-type Linux --restart-policy OnFailure --registry-login-server azuretest2containerregistry.azurecr.io --registry-username $(az acr credential show --name azuretest2containerregistry --query "username" -o tsv) --registry-password $(az acr credential show --name azuretest2containerregistry --query "passwords[0].value" -o tsv) --dns-name-label mycontainerpublic --ports 80
```

---

## 5️⃣ Création du compte de stockage et du conteneur Blob

### 🖥️ Via l'interface Azure

1. Allez sur **Comptes de stockage**
2. Cliquez sur **Créer**
3. Remplissez :
   - Groupe de ressources : `azure_test_resource_group`
   - Nom du compte : `mystorageaccountXXXXXX` (remplacez `XXXXXX` par un nombre aléatoire)
   - Région : `UK South`
   - Performance : `Standard`
   - Redondance : `Stockage localement redondant (LRS)`
4. Cliquez sur **Créer**
5. Une fois créé, allez dans le compte et créez un **conteneur blob** nommé `nginx-logs`

### ⌨️ Via Azure CLI

```powershell
az storage account create --name mystorageaccountXXXXXX --resource-group azure_test_resource_group --location uksouth --sku Standard_LRS
az storage container create --account-name mystorageaccountXXXXXX --name nginx-logs
```

---

## 6️⃣ Vérification du statut de Nginx et stockage des logs

### ⌨️ Script PowerShell

```powershell
$response = curl -s "http://$publicIP"
$nginxStatus = if ($response -match "nginx") { "nginx est actif" } else { "nginx n'est pas actif" }
Write-Host "Statut de nginx : $nginxStatus" | Out-File -FilePath "nginx_status_log.txt" -Append

az storage blob upload --account-name mystorageaccountXXXXXX --container-name nginx-logs --file "nginx_status_log.txt" --name "nginx_status_log.txt"
```

---

## 7️⃣ Suppression automatique du conteneur

### ⌨️ Via Azure CLI

```powershell
az container delete --resource-group azure_test_resource_group --name my-container-instance --yes
```

