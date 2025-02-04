Voici dessous les étapes pour parvenir aux mêmes résultat qu'avec le script powershell (elles contiennent les même noms de données que dans le script) :

1. **Créer un groupe de ressources :**

   - Allez sur le portail Azure.
   - Naviguez vers "Groupes de ressources" et cliquez sur "Créer".
   - Entrez le nom du groupe de ressources (par exemple, `az_test_resource_group`) et sélectionnez la région (par exemple, `UK South`).
   - Cliquez sur "Vérifier + créer" puis sur "Créer".

2. **Créer une machine virtuelle :**

   - Dans le portail Azure, naviguez vers "Machines virtuelles" et cliquez sur "Créer".
   - Sélectionnez "Machine virtuelle Azure".
   - Remplissez les détails :
     - Groupe de ressources : `az_test_resource_group`
     - Nom de la machine virtuelle : `MyVM1`
     - Région : `UK South`
     - Image : Sélectionnez `Ubuntu 20.04 LTS`
     - Compte administrateur : Nom d'utilisateur : `azureuser`
     - Type d'authentification : Clé publique SSH
     - Clé publique SSH : Générez ou fournissez votre clé SSH
   - Cliquez sur "Vérifier + créer" puis sur "Créer".

3. **Créer un compte de stockage :**

   - Dans le portail Azure, naviguez vers "Comptes de stockage" et cliquez sur "Créer".
   - Remplissez les détails :
     - Groupe de ressources : `az_test_resource_group`
     - Nom du compte de stockage : `test1storaccXXXX` (remplacez `XXXX` par un nombre aléatoire pour maximiser les chances d'éviter un conflit avec un nom déjà existant)
     - Région : `UK South`
     - Performance : Standard
     - Réplication : Stockage localement redondant (LRS)
   - Cliquez sur "Vérifier + créer" puis sur "Créer".

4. **Créer un conteneur :**

   - Allez dans le compte de stockage nouvellement créé.
   - Naviguez vers "Conteneurs" sous "Stockage de données".
   - Cliquez sur "+ Conteneur" et entrez le nom `test1container`.
   - Cliquez sur "Créer".

5. **Télécharger un blob :**

   - Dans le compte de stockage, naviguez vers le conteneur `test1container`.
   - Cliquez sur "Télécharger" et sélectionnez le fichier `C:\Users\alyxi\package-lock.json`.
   - Entrez le nom du blob `package_example_file.json`.
   - Cliquez sur "Télécharger".

6. **Lister les blobs dans le conteneur :**

   - Dans le conteneur, vous devriez voir le blob téléchargé `package_example_file.json`.

7. **Définir les permissions du conteneur :**

   - Dans le conteneur, cliquez sur "Changer le niveau d'accès".
   - Sélectionnez "Blob (accès en lecture anonyme pour les blobs uniquement)".
   - Cliquez sur "OK".

8. **Supprimer les ressources :**

   - Pour nettoyer les ressources créées, allez dans le portail Azure.
   - Naviguez vers "Groupes de ressources".
   - Sélectionnez `az_test_resource_group`.
   - Cliquez sur "Supprimer le groupe de ressources" et confirmez la suppression.
