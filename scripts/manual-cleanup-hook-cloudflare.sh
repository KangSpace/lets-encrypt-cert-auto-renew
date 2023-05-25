#!/bin/sh
# dependence: cloudflare-service.sh
# cloudflare domain clean up validated DNS TXT script
#domain|host|id\n
#set -x
basePath="$basePath"
cloudflareServicePath="$basePath/scripts/cloudflare-service.sh"

DOMAIN_TEMP_LOCAL_FILE='DOMAIN_TEMP_LOCAL_FILE'
#config cloudflare zone identifier(must)
CLOUDFLARE_ZONE_IDENTIFIER=
#config cloudflare auth(must)
CLOUDFLARE_AUTH=

#open tempfile delete DNS TXT record
cat < $DOMAIN_TEMP_LOCAL_FILE | while read line
do
    echo "$line"
    IFS='|' arr=($line)
    echo "${arr[0]}"
    echo "${arr[1]}"
    echo "${arr[2]}"
    sh "$cloudflareServicePath" --key "$CLOUDFLARE_ZONE_IDENTIFIER"  --auth "$CLOUDFLARE_AUTH" --domain "${arr[0]}" --hostname  "${arr[1]}" --id  "${arr[1]}" --del-dns-txt
done
#delete tempfile
rm -f $DOMAIN_TEMP_LOCAL_FILE
