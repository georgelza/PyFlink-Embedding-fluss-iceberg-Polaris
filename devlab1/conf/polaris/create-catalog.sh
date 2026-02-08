#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

set -e

apk add --no-cache jq

polaris_host=${1:-"polaris"}
polaris_realm=${2:-"POLARIS"}
catalog_name=${3:-"icebergcat"}

echo
echo create-catalog Params
echo "Polaris Host:             $polaris_host"
echo "Catalog Name:             $catalog_name"
echo "Realm:                    $polaris_realm"
echo "Properties:               $PROPERTIES"
echo "Storage Location:         $STORAGE_LOCATION"
echo "Storage config:           $STORAGE_CONFIG_INFO"

if [ -z "$TOKEN" ]; then
    #  source /polaris/obtain-token.sh ${realm}
    echo "Token Null, fetching"
    source /polaris/obtain-token.sh $$POLARISHOST $$POLARIS_REALM $$CLIENT_ID $$CLIENT_SECRET;

fi

echo
echo "Obtained access token: $TOKEN"

STORAGE_TYPE="FILE"
if [ -z "${STORAGE_LOCATION}" ]; then
    echo "STORAGE_LOCATION is not set, using FILE storage type"
    STORAGE_LOCATION="file:///var/tmp/icebergcat/"

else
    echo "STORAGE_LOCATION is set to '$STORAGE_LOCATION'"

    if [[ "$STORAGE_LOCATION" == s3* ]]; then
        STORAGE_TYPE="S3"

    elif [[ "$STORAGE_LOCATION" == gs* ]]; then
        STORAGE_TYPE="GCS"
    
    else
        STORAGE_TYPE="AZURE"
    fi
    echo "Using StorageType: $STORAGE_TYPE"
fi


if [ -z "${STORAGE_CONFIG_INFO}" ]; then
    STORAGE_CONFIG_INFO="{\"storageType\": \"$STORAGE_TYPE\", \"allowedLocations\": [\"$STORAGE_LOCATION\"]}"

    if [[ "$STORAGE_TYPE" == "S3" ]]; then
        STORAGE_CONFIG_INFO=$(echo "$STORAGE_CONFIG_INFO" | jq --arg roleArn "$AWS_ROLE_ARN" '. + {roleArn: $roleArn}')

    
    elif [[ "$STORAGE_TYPE" == "AZURE" ]]; then
        STORAGE_CONFIG_INFO=$(echo "$STORAGE_CONFIG_INFO" | jq --arg tenantId "$AZURE_TENANT_ID" '. + {tenantId: $tenantId}')
    fi
fi


echo
echo 1. Creating a catalog named $catalog_name in realm $polaris_realm...

PAYLOAD='{
   "catalog": {
     "name": "'$catalog_name'",
     "type": "INTERNAL",
     "readOnly": false,
     "properties": '$PROPERTIES',
     "storageConfigInfo": '$STORAGE_CONFIG_INFO'
   }
 }'

echo
echo Payload:               $PAYLOAD

curl -X POST http://$polaris_host:8181/api/management/v1/catalogs \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Polaris-Realm: $polaris_realm" \
    -d "$PAYLOAD" | jq   

echo 
echo Created a catalog named $catalog in realm $polaris_realm...


echo 
echo 2. Assigning Extra grants...;
PAYLOAD='{
        "grant":{
            "type":"catalog", 
            "privilege": "CATALOG_MANAGE_CONTENT"
        }
}'
echo
echo Payload:               $PAYLOAD

curl -X PUT http://$polaris_host:8181/api/management/v1/catalogs/$catalog_name/catalog-roles/catalog_admin/grants \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Polaris-Realm: $polaris_realm" \
    -d "$PAYLOAD" | jq   

echo
echo Assigned CATALOG_MANAGE_CONTENT


echo
echo 3. Creating a data engineer role;
PAYLOAD='{
        "principalRole":{
            "name":"DataEngineer"
        }
}'
echo
echo Payload:               $PAYLOAD

curl -X POST http://$polaris_host:8181/api/management/v1/principal-roles \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Polaris-Realm: $polaris_realm" \
    -d "$PAYLOAD" | jq   

echo
echo Created a data engineer role


echo
echo 4. Connecting the roles;
PAYLOAD='{
        "catalogRole":{
            "name":"catalog_admin"
        }
}'
echo
echo Payload:               $PAYLOAD

curl -X PUT http://$polaris_host:8181/api/management/v1/principal-roles/DataEngineer/catalog-roles/$catalog_name \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Polaris-Realm: $polaris_realm" \
    -d "$PAYLOAD" | jq   

echo
echo Connected the roles


echo
echo 5. Assigning root the data engineer role
PAYLOAD='{
        "principalRole": {
            "name":"DataEngineer"
        }
}'
echo
echo Payload:               $PAYLOAD

curl -X PUT http://$polaris_host:8181/api/management/v1/principals/root/principal-roles \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Polaris-Realm: $polaris_realm" \
    -d "$PAYLOAD" | jq   

echo
echo Assigned root the data engineer role

echo
echo Done - create-catalog


# IF You wanted to pre create the warehouse with contained iceberg namespace
#
# echo
# echo 6. Create warehouse namespace in Polaris
# PAYLOAD='{
#     "namespace": ["warehouse"],
#     "properties": {}
# }'
# echo
# echo Payload:               $PAYLOAD

# curl -X POST "http://$polaris_host:8181/api/catalog/v1/$catalog_name/namespaces" \
#     -H "Authorization: Bearer $TOKEN" \
#     -H "Content-Type: application/json" \
#     -H "Polaris-Realm: $polaris_realm" \
#     -d "$PAYLOAD" | jq   


# echo
# echo 7. Create warehouse.iceberg namespace in Polaris
# PAYLOAD='{
#     "namespace": ["warehouse", "iceberg"],
#     "properties": {}
# }'
# echo
# echo Payload:               $PAYLOAD

# curl -X POST "http://$polaris_host:8181/api/catalog/v1/$catalog_name/namespaces" \
#     -H "Authorization: Bearer $TOKEN" \
#     -H "Content-Type: application/json" \
#     -H "Polaris-Realm: $polaris_realm" \
#     -d "$PAYLOAD" | jq   
