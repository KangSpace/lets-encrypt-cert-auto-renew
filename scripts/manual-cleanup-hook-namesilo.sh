#!/bin/sh
# dependence: namesilo-service.sh
# namesilo domain clean up valided DNS TXT script
#domain|host|rrid\n
#set -x
basePath="$basePath"
namesiloServicePath="$basePath/scripts/namesilo-service.sh"
DOMAIN_TEMP_LOCAL_FILE='DOMAIN_TEMP_LOCAL_FILE'

#config namesilo api key
NAMESILO_KEY=""
#open tempfile delete DNS TXT record
cat $DOMAIN_TEMP_LOCAL_FILE | while read line
do
    echo $line
    IFS='|' arr=($line)
    echo ${arr[0]}
    echo ${arr[1]}
    echo ${arr[2]}
    sh $namesiloServicePath --key $NAMESILO_KEY --domain ${arr[0]} --hostname  ${arr[1]} --rrid  ${arr[1]} --del-dns-txt
done
#delete tempfile
rm -f $DOMAIN_TEMP_LOCAL_FILE
