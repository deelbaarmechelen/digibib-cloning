#!/bin/bash
### 1. Get serial number & fog tag
###    from command line args: $1=tag $2=serial number
###    or from a query to fog server
###    or fallback to local query for serial number? sudo dmidecode -s system-serial-number
### 2. Query with serial numer
### -> found & same tag? -> Done
### -> found & not same tag? -> emit warning, possible duplicate serial number
### -> not found -> got to 3
### 3. Query with tag
### -> found & not same serial number -> emit warning, possible tag conflict
### -> not found -> got to 4
### 4. Create entry with tag & serial number
### -> success -> log success message and exit
### -> not succes -> log error message and exit

# inventory hostname
echo ""
#postdownpath=/images/postdownloadscripts/
postdownpath=/mnt/c/Users/Bernard/Documents/GitHub/digibib-cloning/fog/postdownloadscript/
echo "postdownpath=${postdownpath}"
echo "Running update inventory script";

inventory_host=https://inventory.test.klusbib.be
#token_file=${postdownpath}inventory.token
token_file=${postdownpath}inventory.token
jq_bin=${postdownpath}jq-linux64
inventory_token=$(cat "$token_file")
status_id_maintenance=1
unknown_model_id=30
unknown_model_name="Onbekend"
model_category_laptop=3
default_tag="dummy"
default_serial="0000"
default_model_id=${unknown_model_id}
default_model_name=${unknown_model_name}
default_model_category=${model_category_laptop}
echo "inventory_host=${inventory_host}"
echo "token_file=${token_file}"
echo "inventory_token=${inventory_token}"
echo "status_id_maintenance=${status_id_maintenance}"
echo "default_model_id"=${default_model_id}
echo "default_model_name"=${default_model_name}

# Functions
###########

failureCode() {
    local url=${1:-http://localhost:8080}
    local code=${2:-500}
    local status=$(curl --head --location --connect-timeout 5 --write-out %{http_code} --silent --output /dev/null ${url})
    [[ $status == ${code} ]] || [[ $status == 000 ]]
}

# failureCode http://httpbin.org/status/500 && echo need to restart

# get content and http code:
#URL="https://www.gitignore.io/api/nonexistentlanguage"

# Issues an http request and returns the body content and http response code
# $1: url
# $2: http response body variable name. If not set, body content is sent to stdout
# $3: http code variable name
# $4: http verb (GET, POST, PUT, PATCH or DELETE)
# $5: bearer token
httpRequest() {
    # Passing args to bash functions: see also https://www.linuxjournal.com/content/return-values-bash-functions
    local __url=${1:-http://localhost:8080}
    local __httpbodyvar=$2
    local __httpresponsecodevar=$3
    local __httpverb=${4:-GET}
    local __token=${5}
    local __body=${6:-''}
    #local __urlparam="${7// /%20}"
    local __urlparam="${7}"

    echo "__url"=${__url}
    echo "__httpbodyvar"=${__httpbodyvar}
    echo "__httpresponsecodevar"=${__httpresponsecodevar}
    echo "__token"=${__token}
    echo "__body"=${__body}
    echo "__urlparam"=${__urlparam}

    local __response=''
    # FIXME: enabling -k option on curl due to ssl certificate issue on inventory calls
    if [[ -n $__body ]]; then
      set -x # enable echo of command
      __response=$(curl -k --url $__url -X $__httpverb -H 'Content-Type: application/json' -H 'accept: application/json' -H "Authorization: Bearer ${__token}" -d "${__body}" -s -w "\n%{http_code}"  )
      set +x # turn off echo of command
    else
      if [[ -n $__urlparam ]]; then
        set -x # enable echo of command
        __response=$(curl -k -G -X $__httpverb -H 'Content-Type: application/json' -H "Authorization: Bearer ${__token}" --data-urlencode "$__urlparam" -s -w "\n%{http_code}" $__url)
        set +x # turn off echo of command
      else
        set -x # enable echo of command
        __response=$(curl -k -X $__httpverb -H 'Content-Type: application/json' -H "Authorization: Bearer ${__token}" -s -w "\n%{http_code}" $__url)
        set +x # turn off echo of command
      fi
    fi
    local __http_code=$(tail -n1 <<< "$__response")  # get the last line
    local __content=$(sed '$ d' <<< "$__response")   # get all but the last line which contains the status code ('$' marks last line, 'd' marks deletion)

    if [[ "$__httpbodyvar" ]]; then
        __content=$(echo $__content | sed "s/'/'\"'\"'/g")
        eval $__httpbodyvar=$(echo "'$__content'")
    else
        echo "$__content"
    fi
    if [[ "$__httpresponsecodevar" ]]; then
        eval $__httpresponsecodevar="'$__http_code'"
    fi
}

# create inventory entry
# $1: asset tag
# $2: serial number
# $3: model id
# $4: status id
# $5: bearer token
createInventoryEntry() {
### 4. Create entry with tag & serial number
### -> success -> log success message and exit
### -> not succes -> log error message and exit
  local __assettag=$1
  local __serial=$2
  local __model=$3
  local __status=$4
  local __token=${5}
  httpRequest ${inventory_host}/api/v1/hardware content http_code "POST" $__token "{\"asset_tag\": \"$__assettag\", \"serial\": \"$__serial\", \"model_id\": \"$__model\", \"status_id\": $__status}"
  echo $content
  echo $http_code
}

getInventoryModelId() {
  local __modelnameforquery=${1}
  local __token=${2}
  local __result_var=${3}
  local __model_id=${4:-$default_model_id}
  local __model_name=' '

  #local __url=${inventory_host}/api/v1/models?limit=50\&offset=0\&search=${__modelnameforquery// /%20}
  local __url=${inventory_host}/api/v1/models
  #echo "__url"=${__url}
  #echo "__token"=${__token}
  #echo "__modelnameforquery"=${__modelnameforquery}
  #echo "__result_var"=${__result_var}

  httpRequest $__url content http_code GET $inventory_token '' "search=$__modelnameforquery"
  echo $content
  echo $http_code

  if [[ $http_code -eq 200 ]]; then 
    echo "query succeeded, check number of results"
    rowcount=$(echo $content | $jq_bin '.total')
    if [[ $rowcount -eq 0 ]]; then 
      ### -> model not found -> create it
      echo "Model entry '$__modelnameforquery' not found -> creating..."
      createInventoryModel "$__modelnameforquery" $default_model_category "${inventory_token}" $__result_var
      return
    fi 
    if [[ $rowcount -gt 0 ]]; then
      ### check for exact match
      for ((i=0; i<$rowcount; i++)); do 
        __model_name=$(echo $content | $jq_bin ".rows[$i].name")
        echo "__model_name"=${__model_name:1: -1}
        echo "__modelnameforquery"=${__modelnameforquery}
        if [[ "${__model_name:1: -1}" == "$__modelnameforquery" ]]; then 
          echo "model names are equal"
          __model_id=$(echo $content | $jq_bin ".rows[$i].id")
          eval $__result_var="'$__model_id'"
          return
        fi
      done
      # create model
      echo "Model entry '$__modelnameforquery' not found -> creating..."
      createInventoryModel "$__modelnameforquery" $default_model_category "${inventory_token}" $__result_var
      return
    fi 
  else
    echo "Query on models failed with http code $http_code (url=$__url)"
    echo "You may want to check host is running and token is correctly set"
    echo "Cannot proceed, exiting..."
    exit 1
  fi
}

createInventoryModel() {
  local __model_name=${1}
  local __category_id=${2:-$default_category_id}
  local __token=${3}
  local __result_var=${4}
  local __model_id=$default_model_id
  local __content=
  local __http_code=

  echo "__model_name"=${__model_name}
  echo "__category_id"=${__category_id}
  echo "__token"=${__token}
  echo "__result_var"=${__result_var}

  ### -> model not found -> create it
  httpRequest ${inventory_host}/api/v1/models content http_code "POST" $__token "{\"name\": \"$__model_name\", \"category_id\": \"$__category_id\"}"
  echo $content
  echo $http_code
  local __status=$(echo $content | $jq_bin ".status")
  echo "__status"=${__status}

  if [[ "${__status:1: -1}" == "success" ]]; then 
    echo "model $__model_name created"
    __model_id=$(echo $content | $jq_bin ".payload.id")
    echo "__model_id=$__model_id"
  fi
  eval $__result_var="'$__model_id'"
}

########
# Main #
########

### 1. Get serial number & fog tag
###    from command line args: $1=tag $2=serial number
tag=${1:-$default_tag}
serial=${2:-$default_serial}
model_name=${3:-$default_model_name}
model_id=${4:-$default_model_id}

###    or from a query to fog server
# to be completed
###  Lookup model id
#modelnameforquery="Makita Boorhamer"

getInventoryModelId "$model_name" "${inventory_token}" model_id
echo "model_id"=${model_id}
###    or fallback to local query for serial number? sudo dmidecode -s system-serial-number
# to be completed

### 2. Query with serial numer
echo "Query with serial number"
serialforquery=${serial// /%20} #replace spaces by '%20'
serialforquery=${serialforquery//&/%26} #replace & by '%26'
serialforquery=${serialforquery//&/%26} #replace & by '%26'
url=${inventory_host}/api/v1/hardware/byserial/${serialforquery}
httpRequest $url content http_code GET $inventory_token
echo "content=$content"
echo "httpcode=$http_code"

if [[ $http_code -eq 200 ]]; then 
  echo "query succeeded, check number of results"
  rowcount=$(echo $content | $jq_bin '.total')
  if [[ $rowcount -eq 0 ]]; then 
    ### -> serial not found -> got to 3
    echo "Serial number is not found in inventory"

    ### 3. Query with tag
    echo "Query with tag"
    httpRequest ${inventory_host}/api/v1/hardware/bytag/${tag} content http_code GET $inventory_token
    echo "content=$content"
    echo "httpcode=$http_code"
    
    ### -> found & not same serial number -> emit warning, possible tag conflict
    ### -> not found -> got to 4
    createInventoryEntry ${tag} ${serial} $model_id $status_id_maintenance $inventory_token
    if [[ $http_code -eq 200 ]]; then
      status=$(echo $content | $jq_bin '.status')
      message=$(echo $content | $jq_bin '.messages')
      if [[ $status = '"success"' ]]; then
        echo "Inventory entry successfully created for tag ${tag} (message=${message})"
      else
        echo "Unable to create inventory entry, server responded with staus ${status} and message ${message}"
      fi
    else
      echo "Creation of inventory entry failed with http response code ${http_code}. Check server logs for more details"
    fi
  fi
  if [[ $rowcount -eq 1 ]]; then
    ### -> serial found
    echo "Found 1 result, checking tag"
    currenttag=$(echo $content | $jq_bin '.rows[0].asset_tag')
    if [[ $currenttag = "\"$tag\"" ]]; then
      ### -> serial found & same tag? -> Done
      echo "Tag already correctly set in inventory -> nothing to do"
      exit 0
    else
      ### -> found & not same tag? -> emit warning, possible duplicate serial number
      echo "Serial number already assigned to another tag -> automatic inventory update not possible"
      echo "You may want to validate no serial duplicate exists"
      echo "Cannot proceed, exiting..."
      exit 1
    fi
  fi 
  if [[ $rowcount -gt 1 ]]; then
    echo "Found more than 1 entry with serial number $serial -> automatic inventory update not possible"
    echo "Cannot proceed, exiting..."
    exit 1
  fi 
  exit 0
else
  echo "Query on serial number failed with http code $http_code (url=$url)"
  echo "You may want to check host is running and token is correctly set"
  echo "Cannot proceed, exiting..."
  exit 1
fi

### 4. Create entry with tag & serial number
### -> success -> log success message and exit
### -> not succes -> log error message and exit
