#######################################################################
# Filename: agile_mssql_tables.ps1
# Version: v2.0
# Date: 2020-08-14
# Last Updated: 2020-08-14 Bitt...
# Author: Alan Bitterman
#
# Description: Demo script for masking SQL Server Database 
#              using the newer Delphix Masking APIs
#
# Arguments:
#
#. .\agile_mssql_tables.ps1 
#      [meta_data_file]		        # 1 XML Path/Element Name, Domain Name and Algorithm mapping file
#         [connection_str_file]   	# 2 Connection String file plus Database XML Meta Data ...
#            [YES, NO]              # 3 Run Masking Job: YES or NO
#
#
# Default Arguments Usage: 
#   Modify the param values later in the code ...
#     param (
#       [String]$M_SOURCE="algo_EDW_6.0.txt",	# Source Meta Data File 
#       [String]$M_CONN_STR="conn_mssql_jdbc.txt",   # Connection String File 
#       [String]$M_RUN_JOB="YES"
#    )
#
# . .\agile_mssql_tables.ps1 
#
#
# Command Line Arguments Usage:  
# . .\agile_mssql_tables.ps1 mssql_mask.txt conn.txt YES
#
# 
# Sample Meta Data File ...
#
#                 [xmlpath],[domain_name],[algorithm_name],[isProfileWritable],[date_format]
#                                                           Auto=true           dd-MMM-yy
#                                                           User=false          yyyy-MM-dd
#
#/path_to_xml/elementName,FIRST_NAME,FirstNameLookup,Auto
#/path_to_xml/elementName,LAST_NAME,LastNameLookup,Auto
#/path_to_xml/elementName,CITY,USCitiesLookup,User
#
# Note: 5th value is for date format for respective date algorithms ...
#/path_to_xml/elementName,DOB,DateShiftDiscrete,User,dd-MMM-yy
#
# Sample Connection String File ...
## Note: connNo MUST BE 1, profileSetName not required 
#
#=== begin of file === 
#[
#{
#  "connNo": 1,
#  "databaseType": "EXTENDED",
#  "environmentId": 14,
#  "jdbc": "jdbc:sqlserver://104.43.217.180:1433;database=XMLTesting;authenticationScheme=NTLM;integratedSecurity=true;",
#  "password": "Azure12345678",
#  "jdbcDriverId": 16,
#  "username": "AzureUser",
#  ...
#  ... Includes Database Meta Data for the XML Data ...
#  ...
#  "dbName": "XMLTesting",
#  "schemaName": "dbo",
#  "tblName": "dTest",
#  "colName": "xmldata",
#  "colType": "xml",
#  "condition": "id=1",
#}
#]
#=== end of file ===
#
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#    [String]$M_SOURCE="test_algorithms_sdk.txt",	# Source Meta Data File 

param (
    [String]$M_SOURCE="tables.txt",	     # Source Meta Data File 
    [String]$M_CONN_STR="conn_mssql_tables.txt",   # Connection String File plus Database XML Data 
    [String]$M_RUN_JOB="YES"
)

#
# Debug ...
#
#set -x 

#########################################################
## Parameter Initialization ...

try {
    ###. ("C:\temp\ver6.0\masking_engine_conf.ps1")
    . .\masking_engine_conf.ps1
} catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}

echo "Command Line Args: $M_SOURCE ...$M_CONN_STR ... $M_RUN_JOB"

$M_APP="tables_app" 		# Masking Application Name ...
$M_ENV="tables_env"			# Transient Masking Environment Name ...

##DT=`date '+%Y%m%d%H%M%S'`
$date = Get-Date  #-format "yyyyMMdd"
$DT = $date.ToString("yyyyMMddHHmmss")

$rnd = (Get-Random -Maximum 100)
$M_RULE_SET="RS_${DT}_${rnd}"           #
$M_MASK_NAME="Mask_${DT}_${rnd}"        #
$M_CONN="Conn_${DT}_${rnd}"         	# Transient Masking Connetor Name ...

$ALGONAME="Algo_${DT}_${rnd}"

#########################################################
##        NO CHANGES REQUIED BELOW THIS LINE           ##
#########################################################

echo "Source: ${M_SOURCE}"
echo "Application: ${M_APP}"
echo "Environment: ${M_ENV}"
echo "Connection String File: ${M_CONN_STR}"
echo "Connector: ${M_CONN}"
echo "Rule Set Name: ${M_RULE_SET}"
echo "Masking Job Name: ${M_MASK_NAME}"
echo "Run Masking Job: ${M_RUN_JOB}"

#########################################################
## Data Pre-Processing ...
#########################################################

#########################################################
## Authetication ...

echo "Authenticating on ${DMURL}"
#$json = "{ ""username"": """+${DMUSER}+""", ""password"": """+${DMPASS}+"""}"
$json = @"
{ 
   \"username\": \"${DMUSER}\", 
   \"password\": \"${DMPASS}\"
}
"@

$json = $json.replace('\','')
##$json = $json.replace('\','').replace("`n","")   ##.replace("`r","")
#echo "json: ${json}"

$results = (Invoke-RestMethod -Method POST -URI "${BaseURL}/login" -body "${json}" -ContentType: "${CONTENT_TYPE}")
$KEY=$results.Authorization
#echo "Token: $KEY" 
if (!$KEY) {
   echo "Invalid Token: $results"
   echo "Exiting ..."
   exit 1; 
   cd ..\tables

} else {
   echo "Authentication Successfull Token: ${KEY} "
}


#########################################################
## System Information ...

echo "Gathering System Information ..."
$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/system-information" -ContentType: "${CONTENT_TYPE}")
$VERSION=$results.version
echo "Masking Platform Version: ${VERSION} "

#
# Add any version verification code here ...
#

#########################################################
## Application and Environment have API changes ...

#########################################################
## Get Application ...

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/applications" -ContentType: "${CONTENT_TYPE}")
##DEBUG##echo $results
$b = $results.responseList | where { $_.applicationName -eq "${M_APP}"} | Select-Object
$c = $b.applicationName
$APPID = $b.applicationId

if ("$c" -ne "${M_APP}") {
   $json = @"
{
    \"applicationName\": \"${M_APP}\"
}
"@
   $json = $json.replace('\','')
   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/applications" -body "${json}" -ContentType: "${CONTENT_TYPE}")
   echo "Creating ${M_APP} Application: $results"
   $M_APP = $results.applicationName
   $APPID = $results.applicationId
}

echo "Application Name: ${M_APP}"
echo "Application Id: ${APPID}"

#########################################################
## Get Environment ...

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/environments" -ContentType: "${CONTENT_TYPE}")
##DEBUG##echo $results

$b = $results.responseList | where { $_.applicationId -eq "${APPID}" -and $_.environmentName -eq "${M_ENV}"} | Select-Object
$c = $b.environmentName
$ENVID = $b.environmentId

if ("$c" -ne "${M_ENV}") {
   $json = @"
{
    \"environmentName\": \"${M_ENV}\", \"applicationId\": \"${APPID}\", \"purpose\": \"MASK\"
}
"@

   $json = $json.replace('\','')
   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/environments" -body "${json}" -ContentType: "${CONTENT_TYPE}")
   echo "Creating ${M_ENV} Environment: $results"
   $ENVID = $results.environmentId
}

echo "Environment Name: ${M_ENV}"
echo "Environment Id: ${ENVID}"


#########################################################
## Get Environment Connectors ...

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/database-connectors" -ContentType: "${CONTENT_TYPE}")
##DEBUG##echo $results

$b = $results.responseList | where { $_.environmentId -eq "${ENVID}"} | Select-Object
$DELDB = $b.databaseConnectorId
echo "Delete Conn Ids: ${DELDB}"

if ("${DELDB}" -ne "") {
   foreach ($TMPID in ${DELDB}) {
      #Write-Output "Array Value: |$TMPID|"
      $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method DELETE -URI "${BaseURL}/database-connectors/${TMPID}" -ContentType: "${CONTENT_TYPE}")
      #echo "results: $results"
      echo "Removing previous connection id ${TMPID}"
   }
}

#########################################################
## Create Connection String ...

echo "Processing Connection String ..."

$o = Get-Content -Raw -Path $M_CONN_STR | ConvertFrom-Json
#$o

$j=1
#CONN0=`echo "${CONN}" | jq --raw-output ".[] | select (.connNo == ${j})"`
##echo "$CONN0" | jq -r "."

#########################################################
## Process Provided Connectors ...

$CNAME="${M_CONN}${j}"

$USR=$o.username
$PWD=$o.password
#
# If Password is Encrypted, put Decrypt code here ...
#

$DBT=$o.databaseType
$DBHOST=$o.host
$PORT=$o.port
$SCHEMA=$o.schemaName
$SID=$o.sid
$JDBC=$o.jdbc
$DBNAME=$o.databaseName
$INSTANCE=$o.instanceName


$DRIVERID=$o.jdbcDriverId
$tblName=$o.tblName
$colName=$o.colName
$colType=$o.colType
$condition=$o.condition
$CONN_STR=""      # For Reporting Purposes ONLY ...

#
# Supported Databases ...
#
if ("${DBT}" -eq "MSSQL" -or "${DBT}" -eq "EXTENDED")  {
   #########################################################
   ## Create MSSQL Connector ...

if ("${JDBC}" -ne "") {  
  $json = @"
 { 
     \"connectorName\": \"${CNAME}\", 
     \"databaseType\": \"${DBT}\", 
     \"environmentId\": ${ENVID}, 
     \"jdbc\": \"${JDBC}\",
     \"password\": \"${PWD}\", 
     \"username\": \"${USR}\", 
     \"schemaName\" : \"${SCHEMA}\" 
 }
"@

} else {  

   $json = @"
 { 
     \"connectorName\": \"${CNAME}\", 
     \"databaseType\": \"${DBT}\", 
     \"environmentId\": ${ENVID}, 
     \"host\": \"${DBHOST}\", 
     \"password\": \"${PWD}\", 
     \"port\": ${PORT}, 
     \"databaseName\": \"${DBNAME}\", 
     \"instance\": \"\",
     \"username\": \"${USR}\", 
     \"schemaName\" : \"${SCHEMA}\" 
 }
"@

}

if ("${DBT}" -eq "EXTENDED") {

  $json = @"
{
  \"connectorName\": \"${CNAME}\",
  \"databaseType\": \"${DBT}\",
  \"environmentId\": ${ENVID},
  \"jdbc\": \"${JDBC}\",
  \"password\": \"${PWD}\",
  \"jdbcDriverId\": ${DRIVERID},
  \"username\": \"${USR}\"
}
"@


}
  
   $json = $json.replace('\','')
   echo "JSON: $json"

   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/database-connectors" -body "${json}" -ContentType: "${CONTENT_TYPE}")
   echo "Creating DB Connector:"   # $results"
   $results
   $DBID = $results.databaseConnectorId
   echo "Database Connector Id: ${DBID}"
   $CONN_STR="${DBT} ${DBHOST}:${PORT}:${SID}"

} else {
   #
   # Not Supported Yet ...
   #
   echo "Error: Database ${DBT} Not Yet supported in this script, exiting ..."
   exit 1
}
####echo "DEBUG: ${CONN_STR} "

#########################################################
## Test Connector ...
   
$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/database-connectors/${DBID}/test" -body "${json}" -ContentType: "${CONTENT_TYPE}")
echo "Testing DB Connector: $results"
$CONN_RESULTS = $results.response
if ( "${CONN_RESULTS}" -ne "Connection Succeeded") {
   echo "Error: Connection ${CNAME} not valid for ${DBID} ... ${CONN_RESULTS}"
   echo "Please verify parameters and try again, exiting ..."
   exit 1
}


#
# Have a valid database connect, let's proceed ...
#

#######################################################################
## Get list of tables from connector ...

$tbl_arr = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/database-connectors/${DBID}/fetch" -ContentType: "${CONTENT_TYPE}")
##DEBUG##echo $tbl_arr

foreach ($a1 in $tbl_arr) {
   Write-Output "Array Value: |$a1|"
}
Write-Output "Index: " $tbl_arr[0]

#########################################################
## Define Rule Set ...

$json = @"
   { \"rulesetName\": \"${M_RULE_SET}${j}\", \"databaseConnectorId\": ${DBID} }
"@

$json = $json.replace('\','')
echo "JSON: $json"

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/database-rulesets" -body "${json}" -ContentType: "${CONTENT_TYPE}")
#echo "Creating Ruleset $results"
$RSID=$results.databaseRulesetId
echo "Rule Set Id: ${RSID}"


#
# Loop thru Tables and add to Rule Set ...
#
$i = 0
$tbl_meta_arr = @{}    # Use Hash/Associative Array ...
foreach ($tbname in $tbl_arr) {
   #Write-Output "Array Value: |$tbname|"
   ###STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"tableName\": \"${tbname}\", \"rulesetId\": ${RSID} }" "${DMURL}/table-metadata"`
   $json = @"
   { \"tableName\": \"${tbname}\", \"rulesetId\": ${RSID} }
"@
   $json = $json.replace('\','')
   echo "JSON: $json"
   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/table-metadata" -body "${json}" -ContentType: "${CONTENT_TYPE}")
   echo "Ruleset Table: $results"
   $TBL_META_ID = $results.tableMetadataId
   echo "TBL_META_ID: $TBL_META_ID"
   $tbl_meta_arr.$tbname = $TBL_META_ID
   #same as above#   $tbl_meta_arr["$tbname"] = $TBL_META_ID

   $i = $i + 1
}

#$tbl_meta_arr.GetEnumerator()  | Get-Member -MemberType Properties  
#foreach ($g in $tbl_meta_arr.Keys) {
# echo "key $g  ... value $($tbl_meta_arr.$g)"
#} 
#echo "test $($tbl_meta_arr.EMPLOYEES) "
#exit

#########################################################
## tableMetadataId Options ... customSQL, whereClause, havingClause, keyColumn

#if ( $condition -ne "" ) {
#   $json = @"
#{
#   \"tableName\": \"${tblName}\" 
#  ,\"rulesetId\": ${RSID} 
#  ,\"whereClause\": \"${condition}\" 
#}
#"@
#
#   $json = $json.replace('\','')
#   echo "JSON: $json"
#
#   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method PUT -URI "${BaseURL}/table-metadata/${TBL_META_ID}" -body "${json}" -ContentType: "${CONTENT_TYPE}")
#   echo "table-metadata-id results: $results"
#}


#########################################################
## Read Source Table.Column Algorithm File ...

$M_TBLS = import-csv “${M_SOURCE}” –header xf,f1,f2,f3,f4,f5 –delimiter ","

echo "Table(s) and Algorithms from ${M_SOURCE}: "
echo "${M_TBLS}"
$tbprev = ""
ForEach ($row in $M_TBLS) {
   $x = $($row.xf)
   $split = $x.split('.')
   $tbname = $split[0]
   $colname = $split[1]
   $a = $($row.f1)
   $b = $($row.f2)
   $c = $($row.f3)
   $d = $($row.f4)
   Write-host "$tbName | $colname | $x | $a | $b | $c | $d |"

   #$DOMAIN=$a
   #$ALG=$b
   #$VTMP4=$c
   #$DOB=$d

   $json = @"
   { \"tableName\": \"${tbname}\", \"rulesetId\": ${RSID} }
"@


   $TBL_META_ID = $($tbl_meta_arr.$tbname) 

   if ($tbname -ne $tbprev) {
      # captured table meta id earlier into a hash table/associative array 
      echo "TBL_META_ID: $TBL_META_ID"

      $ometa = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/column-metadata?table_metadata_id=${TBL_META_ID}&page_number=1" -ContentType: "${CONTENT_TYPE}")
      echo "Meta Status: $ometa.responseList"
   }
   $tbprev = $tbname

   # Get columnMetadataId ...
   $a1 = $ometa.responseList | where { $_.columnName -eq "${colname}" } | Select-Object
   $COL_META_ID = $a1.columnMetadataId  
   echo "Column Meta Id: ${COL_META_ID}"

   #########################################################
   ## Logic

   #
   # Have User Input and valid column meta data id ...
   #
   if ( "${b}" -ne "" -and "${COL_META_ID}" -ne "" ) {
      echo "Updating Domain and Algorithm for ${tbname}.${colname} with columnMetadataId=${COL_META_ID} ..."
        
      $VTMP4="true"
      if ( "${c}" -eq "User" ) {
          $VTMP4="false"
      }

       $json=@"
{
   \"domainName\": \"${a}\",
   \"algorithmName\": \"${b}\", 
   \"isProfilerWritable\": ${VTMP4} 
}
"@

      if ( "${b}" -eq "DOB" ) {
         $json=@"
{
   \"domainName\": \"${a}\",
   \"algorithmName\": \"${b}\", 
   \"isProfilerWritable\": ${VTMP4},        
   \"dateFormat\": \"${d}\"
}
"@
      }

      $json = $json.replace('\','')
      echo "json: $json"

      #
      # Update (PUT) column-metadata, i.e. add domain and algorithm ...
      #
      $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method PUT -URI "${BaseURL}/column-metadata/${COL_META_ID}" -body "${json}" -ContentType: "${CONTENT_TYPE}")
      echo "results: $results"
      # {"errorMessage":"Missing required field 'dateFormat'"}

   }   	  # end if $b "" ...



}         # end foreach ...

########################################################
## Create Masking Job ...

echo "---------------------------------------------------"
echo "Creating Masking Job ${M_MASK_NAME} ..."
$json=@"
{ 
   \"jobName\": \"${M_MASK_NAME}\", 
   \"rulesetId\": ${RSID}, 
   \"jobDescription\": \"Created File MaskingJob from API\", 
   \"feedbackSize\": 50000, 
   \"minMemory\": 2048,
   \"maxMemory\": 2048,
   \"onTheFlyMasking\": false, 
   \"databaseMaskingOptions\": { 
     \"batchUpdate\": true, 
     \"commitSize\": 10000 
   } 
}
"@


$json = $json.replace('\','')
echo "JSON: $json"

$results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/masking-jobs" -body "${json}" -ContentType: "${CONTENT_TYPE}")
echo "results: $results"
$JOBID = $results.maskingJobId
echo "job_id: ${JOBID}"

$JOBSTATUS = ""

#########################################################
## Execute Masking Job ...

if ( "${M_RUN_JOB}" -eq "YES" ) {

   echo "=================================================================="
   echo "Running Masking JobID ${JOBID} ..."
   $json = @"
{ \"jobId\": ${JOBID} }
"@

   $json = $json.replace('\','')
   echo "JSON: $json"

   $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method POST -URI "${BaseURL}/executions" -body "${json}" -ContentType: "${CONTENT_TYPE}")
   $EXID = $results.executionId
   echo "Execution Id: ${EXID}"

   #########################################################
   ## Monitor Job Status ...

   $JOBSTATUS = $results.status    
   echo "JobStatus: ${JOBSTATUS}"
   sleep 1
   while ( "${JOBSTATUS}" -eq "RUNNING" ) {
      $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method GET -URI "${BaseURL}/executions/${EXID}" -ContentType: "${CONTENT_TYPE}")
      #echo "results: $results"
      $JOBSTATUS = $results.status   
      echo "${JOBSTATUS}" 
      #printf "."
      sleep ${DELAYTIMESEC}   
   }
   echo " "

   if ( "${JOBSTATUS}" -ne "SUCCEEDED" ) {
      echo "Job Error: $results.error"
   } else {
      echo "Masking Job Completed: $JOBSTATUS"
   }

   echo "Please Verify Masked Table Data: ${M_SOURCE}"

#   if ( "${JOBSTATUS}" -eq "SUCCEEDED" ) {
#      echo "Clean Up ..."
#      $results = (Invoke-RestMethod -Headers @{ "Authorization" = $KEY } -Method DELETE -URI "${BaseURL}/database-connectors/${DBID}" -ContentType: "${CONTENT_TYPE}") 
#      echo "results: $results"
#   }
}	# end if ${M_RUN_JOB}

#####################################################
## Data Post-Processing ...

############## E O F ####################################
echo "Done."
exit