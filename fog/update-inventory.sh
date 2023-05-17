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
inventory_host=https://inventory.test.klusbib.be
token_file=inventory.token
inventory_token=$(cat "$token_file")
status_id_maintenance=1
model_id_dell_latitude_5780=2

# Extra doc
# Curl request samples:
# https://reqbin.com/curl
# 
# curl -X POST https://reqbin.com/echo/post/json
#    -H 'Content-Type: application/json'
#    -d '{"login":"my_login","password":"my_password"}'
# curl https://reqbin.com/echo/get/json
#    -H "Accept: application/json"
#    -H "Authorization: Bearer {token}"
# 
# Parse json:
# https://stedolan.github.io/jq/
# e.g. echo {\"id\":4} | ./jq-linux64 '.'
# https://www.baeldung.com/linux/json-shell-parse-validate-print
# 
# https://stackoverflow.com/questions/2220301/how-to-evaluate-http-response-codes-from-bash-shell-script
# https://everything.curl.dev/usingcurl/verbose/writeout

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

    local __response=''
    if [[ -n $__body ]]; then
      #set -x # enable echo of command
      __response=$(curl --url $__url -X $__httpverb -H 'Content-Type: application/json' -H 'accept: application/json' -H "Authorization: Bearer ${__token}" -d "${__body}" -s -w "\n%{http_code}"  )
      #set +x # turn off echo of command
    else
      __response=$(curl -X $__httpverb -H 'Content-Type: application/json' -H "Authorization: Bearer ${__token}" -s -w "\n%{http_code}" $__url)
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

########
# Main #
########

### 1. Get serial number & fog tag
###    from command line args: $1=tag $2=serial number
tag=${1:-KB-000-20-123}
serial=${2:-'444 760 597'}

###    or from a query to fog server
# to be completed
###    or fallback to local query for serial number? sudo dmidecode -s system-serial-number
# to be completed

### 2. Query with serial numer
echo "Query with serial number"
serialforquery=${serial// /%20} #replace spaces by '%20'
url=${inventory_host}/api/v1/hardware/byserial/${serialforquery}
httpRequest $url content http_code
echo "content=$content"
echo "httpcode=$http_code"

if [[ $http_code -eq 200 ]]; then 
  echo "query succeeded, check number of results"
  rowcount=$(echo $content | ./jq-linux64 '.total')
  if [[ $rowcount -eq 0 ]]; then 
    ### -> serial not found -> got to 3
    echo "Serial number is not found in inventory"

    ### 3. Query with tag
    echo "Query with tag"
    httpRequest ${inventory_host}/api/v1/hardware/bytag/${tag} content http_code
    echo "content=$content"
    echo "httpcode=$http_code"
    
    ### -> found & not same serial number -> emit warning, possible tag conflict
    ### -> not found -> got to 4
    createInventoryEntry ${tag} ${serial} $model_id_dell_latitude_5780 $status_id_maintenance
    if [[ $http_code -eq 200 ]]; then
      status=$(echo $content | ./jq-linux64 '.status')
      message=$(echo $content | ./jq-linux64 '.messages')
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
    currenttag=$(echo $content | ./jq-linux64 '.rows[0].asset_tag')
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


echo "sandbox area"
#httpRequest https://inventory.test.klusbib.be/api/v1/hardware content http_code
#httpRequest https://inventory.test.klusbib.be/api/v1/hardware/byserial/444%20760%20597 content http_code
#https://snipe-it.readme.io/reference/hardware-by-asset-tag
httpRequest https://inventory.test.klusbib.be/api/v1/hardware/bytag/KB-000-20-123 content http_code
echo "content=$content"
echo "httpcode=$http_code"
json="$content"
echo "json=$json" 
echo $json | ./jq-linux64 '.'
echo $json | ./jq-linux64 '. | { status :.status}'
echo $json | ./jq-linux64 '. | { serial :.serial, asset_tag :.asset_tag}'

# not found?:
# content={"status":"error","messages":"Asset not found","payload":null}
# httpcode=200
# json={"status":"error","messages":"Asset not found","payload":null}
# {
#   "status": "error",
#   "messages": "Asset not found",
#   "payload": null
# }

httpRequest https://inventory.test.klusbib.be/api/v1/hardware/byserial/123 content http_code
#content=$(httpRequest https://www.google.be)
#httpRequest https://www.google.be content

echo "content=$content"
echo "httpcode=$http_code"
