#########################################################
## Delphix Masking Parameter Initialization ...

#$DMIP="3.14.126.196"                                  # DM Hostname or IP
$DMIP="13.90.196.157"
$DMUSER="admin"                                        #
$DMPASS="Admin-12"                                     #
$DMURL="http://${DMIP}/masking/api"                    # http or https
$BaseURL="http://${DMIP}/masking/api"                    # http or https

#
# Application Variables ...
#
$nl = [Environment]::NewLine
$CONTENT_TYPE = "application/json"
$COOKIE = "cookies.txt"
$DELAYTIMESEC=10             # check status interval
$ignore="No"                 # Ignore Exiting when hitting an API Error 
$DT=Get-Date -Format s