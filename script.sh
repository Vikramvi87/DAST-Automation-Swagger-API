#! /bin/bash
apiKeyId='xxxxxxxxxxxxxxxxx'
apiKeySecret='xxxxxxxxxxxxxxxxx'
appId='xxxxxxxxxxxxxxxxx'
appscanPresenceId='xxxxxxxxxxxxxxxxx'
urlTarget='https://abcd.com'
jsonPath='/swagger/v3/swagger.json'

cd TrafficRecorder/
# Start proxy server in port 8383 
node app.js &
sleep 10
# Start a proxy in port 55555
curl -H 'Accept: application/json' 'http://localhost:8383/automation/StartProxy/55555'
sleep 10
# Get the swagger json file from API target
curl -X GET "$urlTarget$jsonPath" --output targetswagger.json
# Convert the swagger json file to a Postman Collection file
openapi2postmanv2 -s targetswagger.json -o output.json
# Set proxy to 55555 port
export http_proxy=http://localhost:55555/ && export https_proxy=http://localhost:55555/
# Execute the collection
newman run output.json --env-var baseUrl="$urlTarget" --insecure
# Stop proxy
curl -H 'Accept: application/json' 'http://localhost:8383/automation/StopProxy/55555'
sleep 10
# Reset the proxy
export http_proxy= && export https_proxy=
# Get the manual explorer file from Server Proxy
curl -X GET "http://localhost:8383/automation/Traffic/55555" -H  "accept: application/json" --output dast.config
# Kill Server Proxy
pkill -9 node

# Authenticate in ASoC
asocToken=$(curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d '{"KeyId":"'"${apiKeyId}"'","KeySecret":"'"${apiKeySecret}"'"}' 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' | grep -oP '(?<="Token":")[^"]*')
# Upload the manual explorer file
dastFileId=$(curl -X 'POST' 'https://cloud.appscan.com/api/v2/FileUpload' -H 'accept: application/json' -H "Authorization: Bearer $asocToken" -H 'Content-Type: multipart/form-data' -F 'fileToUpload=@dast.config;type=application/xml' | grep -oP '(?<="FileId":")[^"]*')
date=$(date '+%m-%d-%Y')
# Start the scan
scanId=$(curl -s -X 'POST' 'https://cloud.appscan.com/api/v2/Scans/DynamicAnalyzerWithFiles' -H 'accept: application/json' -H "Authorization: Bearer $asocToken" -H 'Content-Type: application/json' -d  '{"StartingUrl":"'"$urlTarget"'","TestOnly":true,"ExploreItems":[{"FileId":"'"$dastFileId"'","MultiStep": false}],"LoginUser":"","LoginPassword":"","TestPolicy":"Default.policy","ExtraField":"","ScanType":"Staging","PresenceId":"'"$appscanPresenceId"'","IncludeVerifiedDomains":false,"HttpAuthUserName":"","HttpAuthPassword":"","HttpAuthDomain":"","TestOptimizationLevel":"Fastest","LoginSequenceFileId":"","ThreadNum":10,"ConnectionTimeout":null,"UseAutomaticTimeout":true,"MaxRequestsIn":null,"MaxRequestsTimeFrame":null,"ScanName":"'"DAST $date $urlTarget"'","EnableMailNotification":false,"Locale":"en","AppId":"'"$appId"'","Execute":true,"Personal":false,"ClientType":"user-site","Comment":null,"FullyAutomatic":false,"RecurrenceRule":null,"RecurrenceStartDate":null}' | jq -r '. | {Id} | join(" ")')

# Loop waiting the scan finish
for x in $(seq 1 1000)
  do
    scanStatus=$(curl -s -X 'GET' "https://cloud.appscan.com/api/v2/Scans/$scanId" -H 'accept: application/json' -H "Authorization: Bearer $asocToken" | jq -r '.LatestExecution | {Status} | join(" ")')
    echo $scanStatus
    if [ "$scanStatus" == "Ready" ]
      then break
    elif [ "$scanStatus" == "Failed" ]
      then
        echo "Scan Failed. Check ASOC logs"
        exit 1
    fi
    sleep 60
  done

# Request a report generation
reportId=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $asocToken" -d '{"Configuration":{"Summary":true,"Details":true,"Discussion":true,"Overview":true,"TableOfContent":true,"Articles":true,"History":true,"Coverage":true,"MinimizeDetails":true,"ReportFileType":"HTML","Title":"","Notes":"","Locale":"en"},"OdataFilter":"","ApplyPolicies":"None"}' "https://cloud.appscan.com/api/v2/Reports/Security/Scan/$scanId" | grep -oP '(?<="Id":")[^"]*')

# Loop to get report file.
for x in {1..30}
  do
    curl -s -X GET --header 'Accept: text/xml' --header "Authorization: Bearer $asocToken" "https://cloud.appscan.com/api/v2/Reports/Download/$reportId" > DAST_report.html
    if [[ -s DAST_report.html ]] 
  then
      break
  fi
  sleep 1
done
