#!/bin/sh
# dependence: aliyundns-service.sh
# aliyundns domain clean up valided DNS TXT script
#domain|host|rrid\n
#set -x
basePath="$basePath"
aliyundnsServicePath="$basePath/scripts/aliyundns-service.sh"

DOMAIN_TEMP_LOCAL_FILE='DOMAIN_TEMP_LOCAL_FILE'
#config aliyun dns api key
ALIYUNDNS_KEY=""
#config aliyun dns api secret
ALIYUNDNS_SEC=""

#open tempfile delete DNS TXT record
cat $DOMAIN_TEMP_LOCAL_FILE | while read line
do
    echo $line
    IFS='|' arr=($line)
    echo ${arr[0]}
    echo ${arr[1]}
    echo ${arr[2]}
    sh $aliyundnsServicePath --key $ALIYUNDNS_KEY  --sec $ALIYUNDNS_SEC --domain ${arr[0]} --hostname  ${arr[1]} --rrid  ${arr[1]} --del-dns-txt
done
#delete tempfile
rm -f $DOMAIN_TEMP_LOCAL_FILE
