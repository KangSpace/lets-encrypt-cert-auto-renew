#!/bin/sh
# dependence: dnsget , curl
# namesilo domain operate API script
# return: 1 or 0; 1:SUCCESS ,0:FAIL
#set -ex

USAGE="Usage: $0 --key xxx --domain example.com --hostname xxx [OPTIONS] []
  --key                 set namesilo API key
  --domain              set namesilo domain. e.g.: example.com
  --hostname            set hostname . e.g.: a is hostname in a.example.com
  --check-dns-txt       check DNS TXT record
  --check-dns-txt-wait  check DNS TXT record until checked DNS TXT record,request once every 15 seconds for 15 minutes
  --set-dns-txt         set DNS TXT record
  --del-dns-txt         delete DNS TXT record
  --txt                 DNS TXT value
  --rrid                DNS Record id
  --help                help
  e.g.:
  	./namesilo-service.sh --key xxx --domain example.com --hostname xxx --txt txtxxx --check-dns-txt
  	./namesilo-service.sh --key xxx --domain example.com --hostname xxx --txt txtxxx --set-dns-txt
"
showUsage(){
	echo "$USAGE"
	exit 0
}
#VERSION:1
#TYPE:xml
#key:$NAMESILO_KEY
GetNamesiloAPIUrl(){
# $1 OPERATION
	echo "https://www.namesilo.com/api/$1?version=1&type=xml&key=$NAMESILO_KEY"
}
RequestNamesiloAPI(){
# $1: OPERATION
# $2: param
	if [[ "$1" = "dnsAddRecord" ]]; then
		NAMESILO_API_URL=$(GetNamesiloAPIUrl $1)"&$2"
	fi

	if [[ "$1" = "dnsDeleteRecord" ]]; then
		NAMESILO_API_URL=$(GetNamesiloAPIUrl $1)"&$2"
	fi
	resp=`curl -s $NAMESILO_API_URL`
	echo $resp|tr \\n ' '
}
CheckDnsTxtRecord(){
  isCheckedRecord=`dnsget -t TXT $HOSTNAME.$DOMAIN | grep $DNS_TXT_VAL |wc -l`
	if [[ $isCheckedRecord -gt 0 ]]; then
		echo 1
  else
    echo 0
	fi
}
STARTTIME=0
export STARTTIME
CheckDnsTxtRecordWait(){
	if [[ "$STARTTIME" = 0 ]]; then
		STARTTIME=`date +%s`
	fi
  isCheckedRecord=$(CheckDnsTxtRecord)
	if [[ $isCheckedRecord = 1 ]]; then
		echo 1
		exit 0
	fi
	now=`date +%s`
	echo "STARTTIME:$STARTTIME"
	if [[ $(($now - $STARTTIME)) -lt 3600 ]]; then
		sleep 5s
		CheckDnsTxtRecordWait
	fi
}
#return rrid
SetDNSTxtRecord(){
	resp=$(RequestNamesiloAPI "dnsAddRecord" "domain=$DOMAIN&rrtype=TXT&rrhost=$HOSTNAME&rrvalue=$DNS_TXT_VAL&rrttl=$TTL")
	#complie xml,return rrid
	resp=`echo $resp | grep -oPm1 "(?<=<record_id>)[^<]" `
	if [[ ${#resp} -gt 0 ]];then
		echo $resp
	fi
	exit 0
}

#return 1
DelDNSTxtRecord(){
	resp=$(RequestNamesiloAPI "dnsDeleteRecord" "domain=$DOMAIN&rrid=$RRID")
	resp=`echo $resp | grep -oPm1 "(?<=<code>)\d*(?=<)"`
	if [[ $resp = 300 ]];then
		echo 1
	fi
	exit 0
}
#NAMESILO_KEY=""
#DOMAIN=""
#HOSTNAME=""
#DNS_TXT_VAL=""
#IS_CHECK_DNS_TXT
#IS_CHECK_DNS_TXT_WAIT
#IS_SET_DNS_TXT
#RRID DNS Record id
TTL=3601
if [[ $# = 0 ]]; then
	showUsage
fi
while [ -n "$1" ]
do
        case "$1" in
        --key) NAMESILO_KEY=$2;shift 2;;
				--domain) DOMAIN=$2;shift 2;;
				--hostname) HOSTNAME=$2;shift 2;;
        --check-dns-txt) IS_CHECK_DNS_TXT=1; shift 1;;
        --check-dns-txt-wait) IS_CHECK_DNS_TXT_WAIT=1; shift 1;;
        --set-dns-txt) IS_SET_DNS_TXT=1; shift 1;;
				--del-dns-txt) IS_DEL_DNS_TXT=1; shift 1;;
				--txt) DNS_TXT_VAL=$2; shift 2;;
				--rrid) RRID=$2; shift 2;;
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
