#!/bin/sh
# dependence: dnsget , curl, jq(yum -y install jq | https://stedolan.github.io/jq/download/)
# cloudflare domain operate API script
# API: https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record
# return: 1 or 0; 1:SUCCESS ,0:FAIL
#set -ex
USAGE="Usage: $0 --zone-identifier xxx --token --domain example.com --hostname xxx [OPTIONS] []
  --zone-identifier                 set cloudflare Zone ID
  --token                 set cloudflare auth
  --domain              set cloudflare domain. e.g.: example.com
  --hostname            set hostname . e.g.: a is hostname in a.example.com
  --check-dns-txt       check DNS TXT record
  --check-dns-txt-wait  check DNS TXT record until checked DNS TXT record,request once every 15 seconds for 15 minutes
  --set-dns-txt         set DNS TXT record
  --del-dns-txt         delete DNS TXT record
  --txt                 DNS TXT value
  --id                DNS Record id
  --help                help
  e.g.:
  	./cloudflare-service.sh --zone-identifier xxx --token xxx --domain example.com --hostname xxx --txt txtxxx --check-dns-txt
  	./cloudflare-service.sh --zone-identifier xxx --token xxx --domain example.com --hostname xxx --txt txtxxx --set-dns-txt
"
showUsage(){
	echo "$USAGE"
	exit 0
}

#key:$CLOUDFLARE_ZONE_IDENTIFIER
RequestCloudflareAPI(){
# $1: OPERATION
# $2: param
	if [[ "$1" = "dnsAddRecord" ]]; then
		CLOUDFLARE_API_URL="curl -s --request POST https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_IDENTIFIER/dns_records --header 'Content-Type: application/json' --header 'Authorization: Bearer $CLOUDFLARE_TOKEN' --data '{\"type\":\"TXT\",\"comment\": \"_acme-challenge add\",\"content\": \"$DNS_TXT_VAL\",\"name\": \"_acme-challenge\",\"priority\": 1,\"proxied\": false,\"ttl\": $TTL}'"
	fi

	if [[ "$1" = "dnsDeleteRecord" ]]; then
    CLOUDFLARE_API_URL="curl -s --request DELETE https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_IDENTIFIER/dns_records/$ID --header 'Content-Type: application/json' --header 'Authorization: Bearer $CLOUDFLARE_TOKEN' "
	fi
#	printf "dns record request($1): curl: %s" "$CLOUDFLARE_API_URL"
	resp=$(echo "$CLOUDFLARE_API_URL" | sh)
#	printf "## %s" `$resp`
	echo "$resp"|tr \\n ' '
}

# CheckDnsTxtRecord
CheckDnsTxtRecord(){
  isCheckedRecord=$(dnsget -t TXT "$HOSTNAME".$DOMAIN | grep $DNS_TXT_VAL |wc -l)
	if [[ $isCheckedRecord -gt 0 ]]; then
		echo 1
  else
    echo 0
	fi
}

START_TIME=0
export START_TIME

CheckDnsTxtRecordWait(){
	if [[ "$START_TIME" = 0 ]]; then
		START_TIME=$(date +%s)
	fi
  isCheckedRecord=$(CheckDnsTxtRecord)
	if [[ $isCheckedRecord = 1 ]]; then
		echo 1
		exit 0
	fi
	now=$(date +%s)
	echo "START_TIME:$START_TIME"
	if [[ $(($now - $START_TIME)) -lt 3600 ]]; then
		sleep 5s
		CheckDnsTxtRecordWait
	fi
}
# return recordId
# echo '{"a":"123"}' |jq -c|jq '.a' => "123"
# echo '{"a":"123", "b":true}' |jq -c|jq '.b' => true
# echo '{"a":"123", "b":true, "c":{"c1":"c1"}}' |jq -c|jq '.c.c1' => "c1"
SetDNSTxtRecord(){
	resp=$(RequestCloudflareAPI "dnsAddRecord")
	printf "dns add record response: %s \n" "$resp"
	#complie json,return success
	resp=$(echo "$resp" | jq '.success')
	printf "## %s\n" "$resp"
	if [[ $($resp) ]];then
	  id=$(echo "$resp" | jq '.result.id')
	  printf "dns add record response: id: %s \n" "$id"
		echo "$id"
	fi
	exit 0
}

#return 1
DelDNSTxtRecord(){
	resp=$(RequestCloudflareAPI "dnsDeleteRecord")
	resp=$(echo "$resp" | jq '.success')
#  printf "##delete %s\n" "$resp"
  if [[ $($resp) ]];then
    printf "dns delete record response success: id: %s \n" "$ID"
    echo 1
  fi
	exit 0
}
#CLOUDFLARE_ZONE_IDENTIFIER=""
#CLOUDFLARE_TOKEN=""
#DOMAIN=""
#HOSTNAME=""
#DNS_TXT_VAL=""
#IS_CHECK_DNS_TXT
#IS_CHECK_DNS_TXT_WAIT
#IS_SET_DNS_TXT
#ID DNS Record id
TTL=61
if [[ $# = 0 ]]; then
	showUsage
fi
while [ -n "$1" ]
do
        case "$1" in
        --zone-identifier) CLOUDFLARE_ZONE_IDENTIFIER=$2;shift 2;;
        --token) CLOUDFLARE_TOKEN=$2;shift 2;;
				--domain) DOMAIN=$2;shift 2;;
				--hostname) HOSTNAME=$2;shift 2;;
        --check-dns-txt) IS_CHECK_DNS_TXT=1; shift 1;;
        --check-dns-txt-wait) IS_CHECK_DNS_TXT_WAIT=1; shift 1;;
        --set-dns-txt) IS_SET_DNS_TXT=1; shift 1;;
				--del-dns-txt) IS_DEL_DNS_TXT=1; shift 1;;
				--txt) DNS_TXT_VAL=$2; shift 2;;
				--id) ID=$2; shift 2;;
        --help) showUsage;;
#				--) break ;;
        *) break ;;
        esac
done

if [ "$IS_CHECK_DNS_TXT" = 1 ]; then
    # check DNS TXT record
    CheckDnsTxtRecord
    exit 0
fi
if [ "$IS_CHECK_DNS_TXT_WAIT" = 1 ]; then
    # check DNS TXT record until checked DNS TXT record,request once every 15 seconds for 15 minutes
    CheckDnsTxtRecordWait
    exit 0
fi
if [ "$IS_SET_DNS_TXT" = 1 ]; then
    echo $(SetDNSTxtRecord)
    exit 0
fi

if [ "$IS_DEL_DNS_TXT" = 1 ]; then
    echo $(DelDNSTxtRecord)
    exit 0
fi
set +x
