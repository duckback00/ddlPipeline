
#########################################################
## Parameter Initialization ...

. .\masking_engine_conf.ps1
    
#Set-StrictMode -Version 1
Set-StrictMode -Off
#Set-PSDebug -Trace 2
 
echo "Authenticating on ${DMURL}"

$json = @"
{
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@

$json = $json.replace('\','')
echo "JSON: ${json}"

$results = (Invoke-RestMethod -Method POST -URI "${BaseURL}/login" -body "${json}" -ContentType: "${CONTENT_TYPE}")
$KEY=$results.Authorization
#echo "Token: $KEY" 
if (!$KEY) {
   echo "Invalid Token: $results"
   echo "Exiting ..."
   exit 1;
} else {
   echo "Authentication Successfull Token: ${KEY} "
}


#
# Domains ...
#
#$results = (curl.exe -sX GET -H "${CONTENT_TYPE}" -H "Authorization: ${KEY}" "${DMURL}/domains?page_number=1")
#echo $results
#$o = ConvertFrom-Json $results

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/domains?page_number=1" -ContentType: "${CONTENT_TYPE}")
# {"domainName":"ACCOUNT_TK","classification":"CUSTOMER","defaultAlgorithmCode":"NullValueLookup","defaultTokenizationCode":"AccountTK"}
$a = $results.responseList
Write-Host "Domains ..."
Write-Host "domainName                | defaultAlgorithmCode"
foreach ($b in $a) {
   $b.domainName.PadRight(25," ")+" | "+$b.defaultAlgorithmCode    #+ " | " + $b.
}


#
# Algorithms ...
#
#$results = (curl.exe -sX GET -H "${CONTENT_TYPE}" -H "Authorization: ${KEY}" "${DMURL}/algorithms?page_number=1")
#echo $results
#$o = ConvertFrom-Json $results

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/algorithms?page_number=1" -ContentType: "${CONTENT_TYPE}")
#{"algorithmName":"USCitiesLookup","algorithmType":"LOOKUP","description":"Top 300 US cities by population density.","algorithmExtension":{"latestKeyResetTime":"2019-10-09T13:24:00.670+0000"}}
$a = $o.responseList
Write-Host " "
Write-Host "Algorithms ..."
Write-Host "algorithmName             | algorithmType | description "
foreach ($b in $a) {
   $b.algorithmName.PadRight(25," ") + " | " + $b.algorithmType.PadRight(13," ") +" | " + $b.description
}

exit