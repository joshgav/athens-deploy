# Athens Deploy

Scripts et al to deploy <https://github.com/gomods/athens> to Microsoft Azure.

1. Sign in and get your resource group. In this lab a group is provided for
   you; in your own environment you'll need to create one.

  ```bash
  az login
  az group list

  # to create your own group:
  # group_name=go-proxy-group
  # az group create --name ${group_name}
  ```

2. Create a Container Registry to hold your images. Get connection metadata for
   later use.

  ```bash
  registry_name=goproxy${RANDOM}registry
  group_name=from_above
  image_name=gomods/athens/proxy
  image_tag=latest

  az acr create \
      --name ${registry_name} --resource-group ${group_name} \
      --sku 'Standard' --admin-enabled 'true' --location westus2
  registry_prefix=$(az acr show \
      --name ${registry_name} --resource-group ${group_name} --output tsv --query 'loginServer')
  registry_password=$(az acr credential show \
      --name ${registry_name} --output tsv --query 'passwords[0].value')
  registry_username=$(az acr credential show \
      --name ${registry_name} --output tsv --query 'username')
  image_uri=${registry_prefix}/${image_name}:${image_tag}
  ```

3. Build and store an image in your registry.

  ```bash
  # variables set in previous step
  mkdir -p ./deps/athens
  git clone https://github.com/gomods/athens.git ./deps/athens
  dockerfile_relative_path=cmd/proxy/Dockerfile
  docker_context_path=deps/athens
  az acr build \
     --registry ${registry_name} \
     --resource-group ${group_name} \
     --file ${dockerfile_relative_path} \
     --image "${image_name}:${image_tag}" \
     --os 'Linux' \
     ${docker_context_path})
  ```

4. Create and configure a Web App.

  ```bash
  app_name=go-proxy-app
  plan_name=go-proxy-plan
  group_name=go-proxy-group

  az appservice plan create \
    --name ${plan_name} \
    --resource-group ${group_name} \
    --is-linux \
    --location westus2
  az webapp create \
    --name ${app_name} \
    --plan ${plan_name} \
    --resource-group ${group_name} \
    --deployment-container-image-name ${image_uri}
  az webapp config container set --name ${app_name} --resource-group ${group_name} \
    --docker-custom-image-name ${image_uri} \
    --docker-registry-server-url "https://${registry_prefix}" \
    --docker-registry-server-user ${registry_username} \
    --docker-registry-server-password ${registry_password}
  az webapp deployment container config --name ${app_name} --resource-group ${group_name} \
    --enable-cd 'true'
  az webapp log config --name ${app_name} --resource-group ${group_name} \
    --docker-container-logging filesystem \
    --level verbose
  az webapp config appsettings set --name ${app_name} --resource-group ${group_name} \
    --settings "WEBSITE_HTTPLOGGING_RETENTION_DAYS=7"
  ```


5. Setup a CosmosDB/MongoDB account, database, and collection, and get
   connection metadata for later use.

  ```bash
  cosmosdb_account_name=go-proxy-cosmosdb
  group_name=<from_above>
  db_name=athens
  coll_name=modules

  az cosmosdb create \
    --name ${cosmosdb_account_name} \
    --resource-group ${group_name} \
    --kind MongoDB
  az cosmosdb database create \
    --db-name $db_name --name ${cosmosdb_account_name} --resource-group-name ${group_name}
  az cosmosdb collection create \
	--collection-name $coll_name \
    --db-name $db_name --name ${cosmosdb_account_name} --resource-group-name ${group_name}
  mongo_url=$(az cosmosdb list-connection-strings \
    --name ${cosmosdb_account_name} --resource-group ${group_name} \
    --query "connectionStrings[0].connectionString" --output tsv)
```

6. Configure web app with Mongo connection strings.

  ```
  webapp_id=$(az webapp show --name ${app_name} --resource-group ${group_name} --output tsv --query id)
  url_suffix=azurewebsites.net
  olympus_endpoint=https://go-proxy-olympus-webapp.${url_suffix}
  az webapp config appsettings set --ids $webapp_id \
      --settings \
          "ATHENS_STORAGE_TYPE=mongo" \
          "ATHENS_MONGO_CONNECTION_STRING=${mongo_url}" \
          "OLYMPUS_GLOBAL_ENDPOINT=${olympus_endpoint}"
  ```

7. Try it!

* Browse <https://go-proxy-webapp.azurewebsites.net>
* Browse <https://go-proxy-webapp.azurewebsites.net/github.com/!azure/azure-sdk-for-go/@v/list>
* Browse <https://go-proxy-webapp.azurewebsites.net/github.com/!azure/azure-sdk-for-go/@v/v19.1.0.zip>
* In a terminal:

  ```bash
  git clone https://github.com/joshgav/go-sample
  cd go-sample
  GOPROXY=https://go-proxy-webapp.azurewebsites.net GO111MODULE=on go1.11rc1 get
  ```

This will update dependencies via the specified proxy and create `go.mod` and `go.sum` files.
