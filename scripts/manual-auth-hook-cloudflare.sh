#!/bin/sh
# dependence: cloudflare-service.sh
# auto detect basePath
basePath="$basePath"
# cloudflare domain validate script
# location of cloudflare-service script
servicePath="$basePath/scripts/cloudflare-service.sh"

// TODO xxxxxx

# Need add DNS TXT domain
CREATE_DOMAIN='_acme-challenge'
DOMAIN_TEMP_LOCAL_FILE='$basePath/DOMAIN_TEMP_LOCAL_FILE'
#CERTBOT_DOMAIN：正在验证的域
#CERTBOT_VALIDATION：验证字符串（仅限HTTP-01和DNS-01）
#1. Check domain DNS TXT record is exist,1:exist 0:not exist
#example.org
#config cloudflare CLOUDFLARE_ZONE_IDENTIFIER
CLOUDFLARE_ZONE_IDENTIFIER=""
IS_EXIST=`sh $servicePath --key $CLOUDFLARE_ZONE_IDENTIFIER --domain $CERTBOT_DOMAIN --hostname $CREATE_DOMAIN --txt $CERTBOT_VALIDATION --check-dns-txt`
if [[ $IS_EXIST = 1 ]]; then
	exit 0
fi
#2. Set domain DNS TXT record 1:SUCCESS 0:FAIL
IS_SUCCESSED=`sh $servicePath --key $CLOUDFLARE_ZONE_IDENTIFIER --domain $CERTBOT_DOMAIN --hostname $CREATE_DOMAIN --txt $CERTBOT_VALIDATION --set-dns-txt`
#if fail return
if [[ ${#IS_SUCCESSED} = 0 ]];then
	exit 1
fi
#3. Save DNS TXT temp file to local domain|host|rrid\n
`$CERTBOT_DOMAIN|$CREATE_DOMAIN|$IS_SUCCESSED\n`>>$DOMAIN_TEMP_LOCAL_FILE
#4. validate DNS TXT record 1:SUCCESS 0:FAIL
IS_SUCCESSED1=`sh $servicePath --key $CLOUDFLARE_ZONE_IDENTIFIER --domain $CERTBOT_DOMAIN --hostname $CREATE_DOMAIN --txt $CERTBOT_VALIDATION --check-dns-txt-wait`
if [[ $IS_SUCCESSED1 = 1 ]];then
	exit 0
fi
exit 1
