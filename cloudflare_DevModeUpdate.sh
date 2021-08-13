#!/bin/bash

auth_email=""                                      # The email used to login 'https://dash.cloudflare.com'
auth_method="global"                               # Set to "global" for Global API Keys
auth_key=""                                        # Your API Token or Global API Key
zone_identifier=""                                 # Can be found in the "Overview" tab of your domain
record_name=""                                     # Which record you want to be synced




###########################################
## Check Development Mode
###########################################


devmod=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/settings/development_mode" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json")


current_value=$(echo "$devmod" | grep -Po '(?<="value":")[^"]*' | head -1)
time_remaining=$(echo "$devmod" | grep -Po '(?<="time_remaining":)[[:digit:]]*' | head -1)


###########################################
## Check state and time remaining
###########################################

if [[ ($current_value -eq "on" ) && $time_remaining -gt 3600 ]]; then
  echo "Developer Mode is still On, time remaining: $time_remaining"
  exit 0
fi



######################################################
## Update Development Mode and purge all cached files
######################################################



updated_value=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/settings/development_mode" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json" \
     --data '{"value":"on"}')
purge=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/purge_cache" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}')

devmod=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/settings/development_mode" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json")


current_value=$(echo "$devmod" | grep -Po '(?<="value":")[^"]*' | head -1)
time_remaining=$(echo "$devmod" | grep -Po '(?<="time_remaining":)[[:digit:]]*' | head -1)
purge_allfiles=$(echo "$devmod" | grep -Po '(?<="success":)[[:alpha:]]*' | head -1)

case *"\"success\":false"* in
   "$updated_value") 
   echo "$updated_value" 
   exit 1
   ;;
   "$purge") 
   echo "$purge"
   exit 1
   ;;
   *)
   echo "Developer Mode changed to: $current_value, cached files purged success : $purge_allfiles, time remaining: $time_remaining"
   exit 0
   ;;
esac



