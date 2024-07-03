#!/bin/bash

#You can start this script at startup by adding to crontab
DOMAIN="maindomain.com" # The domain name to update DNS for
INTERVAL=1              # Interval (in minutes) to check and update DNS
TIME="Modified: $(date +"%Y-%m-%d %H:%M")"

## PLOI Crendentials
PLOI_SERVER_ID=""
PLOI_API_KEY=""

## CloudFlare Credentials
CF_API_KEY=""
CF_ZONE_ID=""

# Function to update DNS for a given host
update_dns() {
  local name=$(echo "$1" | jq -r '.name')
  local id=$(echo "$1" | jq -r '.id')
  local dns_ip=$(echo "$1" | jq -r '.content') # Current DNS IP address
  local proxied=$(echo "$1" | jq -r '.proxied')
  local public_ip=$(dig @resolver4.opendns.com myip.opendns.com +short) # Public IP address

  ## --------------- CLOUDFLARE API CALL ------------------ ##
  if [ "$public_ip" != "$dns_ip" ]; then # If public IP and DNS IP are different
    # Define the JSON to patch
    cf_data="{\"content\": \"$public_ip\",  \"proxied\": $proxied,  \"type\": \"A\",  \"comment\": \"$TIME\",  \"id\": \"$id\",  \"ttl\": 1}"
    # Send the PATCH request using curl
    curl --request PATCH \
      --url https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$id \
      --header "Content-Type: application/json" \
      --header "Authorization: Bearer $CF_API_KEY" \
      --data "$cf_data"
    ## --------------- ////////////////// ------------------ ##

    ## --------------- PLOI API CALL ------------------ ##
    if [ "$name" = "$DOMAIN" ]; then
      # Define the JSON data for the update
      ploi_data="{\"name\":\"sirio-a\", \"ip\":\"$public_ip\", \"ssh_port\": 22}"
      # Send the PATCH request using curl
      curl -X PATCH "https://ploi.io/api/servers/$PLOI_SERVER_ID" \
        -H "Authorization: Bearer $PLOI_API_KEY" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --data "$ploi_data"
    fi
    ## --------------- //////////// ------------------ ##
  fi
}

# Main loop to update DNS for all hosts
while true; do
  filter=("@" "*") # Array of subdomains to filter from CloudFlare

  # Append the DOMAIN to each value in the filter array
  for ((i = 0; i < ${#filter[@]}; i++)); do
    if [[ ${filter[$i]} == "@" ]]; then
      filter[$i]=$DOMAIN
    else
      filter[$i]="${filter[$i]}.$DOMAIN"
    fi
  done

  # Convert the array to a jq-readable format
  jq_filter=$(printf '"%s",' "${filter[@]}" | sed 's/,$//')

  # CURL to CloudFlare to get DNS Record ID
  json_response=$(curl --request GET \
    --url "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $CF_API_KEY")
  # Parse the JSON response and store names, IDs, and IPs
  cf_dns=$(echo "$json_response" | jq --argjson names "[$jq_filter]" '.result[] | select(.name as $n | $names | index($n) ) | select(.type == "A")')

  # Iterate over the filtered results and pass each element to the function
  echo "$cf_dns" | jq -c '.' | while IFS= read -r element; do
    update_dns "$element"
  done
  sleep $(($INTERVAL * 60)) # Sleep for the specified interval (converted to seconds)
done
