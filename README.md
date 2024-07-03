# CloudFlare Ploi Dynamic IP

This script updates the <b>DNS records</b> for a given domain hosted on <b>CloudFlare</b> and communicates with <b>Ploi's API</b>. It requires your system to have `curl`, `jq` and `dig` installed.


## Prerequisites and Setup
- Make sure to install `curl`, `jq` and `dig` tool in your system.
- Update the `PLOI_SERVER_ID` and `PLOI_API_KEY` with your <b>Ploi</b> server ID and API key respectively.
- Update `CF_API_KEY` and `CF_ZONE_ID` with your <b>Cloudflare</b> API key and Zone ID respectively.
- Set your domain in the `DOMAIN` variable.
- The `INTERVAL` value represents how often (in minutes) the script checks if your DNS needs an update.

## How it works
- The script first requests your current public IP address from the <b>OpenDNS</b> resolver.
- The script then fetches the existing DNS records for the given domain from <b>Cloudflare's API</b>.
- If the public IP differs from the IP in the A record, then the script sends an API request to <b>Cloudflare</b> to update the A record with the current public IP.
- If the DNS record name matches the domain, the script will also send an update request to <b>Ploi's API</b>.

## Filter
- The script has defined a filter to list the <b>CloudFlare</b> DNS Records `@`,`*`
- Set your custom <b>subdomains</b> here accordingly, the only one required is `@`
- If you want to add `test.domain.com` you only need to add `test` to the filter eg.
  `filter("@" "test")`

## Docker Containers
- The script also checks for running Docker containers with an environment variable `VIRTUAL_HOST`.
- If found, it will add the name of the container to the domain list for updating.

## Usage
- It is recommended to start this script at startup by adding it to the cron job for automatic updates.
- To add a cron job, open your cron tab with `crontab -e` and add the line `@reboot /path/to/dynamic-ip-full.sh &`.

`dynamic-ip.sh` Only changes ip in <b>CloudFlare</b>

`dynamic-ip-cf-pl.sh` Also changes ip in <b>Ploi</b>.

`dynamic-ip-full.sh`  Also scans for <b>docker containers</b>.

**Note**: Be sure to replace `/path/to/dynamic-ip-full.sh` with the actual path to your script.