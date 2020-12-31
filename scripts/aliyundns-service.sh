#!/bin/sh
# dependence: dig , curl ,python (file: aliyundnssign.py)
# aliyundns domain operate API script
# return: 1 or 0; 1:SUCCESS ,0:FAIL
# set -ex 
# aliyun dns help api: https://help.aliyun.com/document_detail/29745.html?spm=a2c4g.11186623.4.4.798313b6cUjK9J
#		       https://help.aliyun.com/document_detail/29740.html?spm=a2c4g.11186623.2.14.798313b6cUjK9J
USAGE="Usage: $0 --key xxx --sec xxx --domain example.com --hostname xxx [OPTIONS] []
  --key                 set aliyundns AccessKey key
  --sec                 set aliyundns AccessSecret
  --domain              set aliyundns domain. e.g.: example.com
  --hostname            set hostname . e.g.: a is hostname in a.example.com
  --check-dns-txt       check DNS TXT record
  --check-dns-txt-wait  check DNS TXT record until checked DNS TXT record,request once every 15 seconds for 15 minutes
  --set-dns-txt         set DNS TXT record
  --del-dns-txt         delete DNS TXT record
  --txt                 DNS TXT value
  --rrid                DNS Record id
  --ttl									set ttl value
  --signtest						test alidns api url sign
  --testaliyunurl				test get alidns api url contains sign
  --help                help
  e.g.:
  	./$0 --key xxx --domain example.com --hostname xxx --txt txtxxx --check-dns-txt
  	./$0 --key xxx --domain example.com --hostname xxx --txt txtxxx --set-dns-txt
"
showUsage(){
	echo "$USAGE"
	exit 0
}

CURR_PATH=`dirname $0`
RUNNING_PATH=`pwd`

#Get AliYunDns Api Request Url , contain Signature
#key:$ALIYUNDNS_KEY
#https://help.aliyun.com/document_detail/29745.html?spm=a2c4g.11186623.2.17.17e87ebbfSiIDk
GetAliYunDNSAPIUrl(){
# $1 OPERATION
# $2 ORTHER PARAMS
	URL_="https://alidns.aliyuncs.com/?Action=$1&Format=XML&Version=2015-01-09&AccessKeyId=$ALIYUNDNS_KEY&SignatureMethod=HMAC-SHA1&SignatureVersion=1.0&Timestamp=$(GetTimestamp)&SignatureNonce=$(GetSignatureNonce)"
	if [ -n "$2" ];then
		URL_="$URL_&$2"
	fi 
	cd $CURR_PATH
	GetSignaturePy "$ALIYUNDNS_SEC&" "$URL_"
	cd $RUNNING_PATH
}

#Get formate timestamp
GetTimestamp(){
	echo -n `date -u "+%Y-%m-%dT%H:%M:%SZ"`
}

#Get SignatureNonce , value is timestamp
GetSignatureNonce(){
	current=`date "+%Y-%m-%d %H:%M:%S"`  
	echo `date -d "$current" +%s000` 
}

# URLEncode 
# + to %20,* to %2A
URLEncode() {
    local l=${#1}
    for (( i = 0 ; i < l ; i++ )); do
        local c=${1:i:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            ' ') printf "%20";; # +
            *) printf '%%%.2X' "'$c"
        esac
    done
}

URLDecode() {
    local data=${1//+/ }
    printf '%b' "${data//%/\x}"
}

#Get Signature URL by python
GetSignaturePy(){
# $1 HMAC key
# $2 URL
	echo -n $(python -c "import aliyundnssign; print aliyundnssign.sign(\"$1\",\"$2\")")
}

# NO COMPLETE FUNCTION
_GetSignature(){
# $1 URL
# return URL contain Signature
		if [ -n "$1" ];then
			tempUrlArr=(${1//\?/ })
			requestURI=${tempUrlArr[0]}
			tempParams=${tempUrlArr[1]}
			# split tempParams
			tempParamArr=(${tempParams//&/ })
			orderKeys=""
			#awk 'BEGIN{info = "this is a test";split(info,tA," ");for(k in tA){print k,tA[k];}}'
			declare -A paramMap=() 
			for temp_ in ${tempParamArr[@]}
			do
					kv=(${temp_//=/ })
					k=${kv[0]}
					orderKeys=$orderKeys$k,
					# encodeURI temp_
					v="$(URLEncode ${kv[1]})"
					paramMap["$k"]="$v"
			done
			URL_=$requestURI"?";
			# order by orderKeys
						#concat URL param
			for key in ${!paramMap[@]}
			do
		  		URL_="$URL_$key=${paramMap[$key]}&"
			done

			if [ -n $URL_ ];then
				URL_=`echo "$URL_" |sed 's/.$//'`
			fi
			# SIGN 
			# StringToSign= HTTPMethod + "&" + percentEncode("/") + "&" + percentEncode(CanonicalizedQueryString)
			StringToSign="GET&%2F&$(URLEncode $URL_)"
			SIGN_=`echo -n $StringToSign|openssl dgst -sha1 -binary -hmac $ALIYUNDNS_SEC"&"|openssl enc -base64`
			echo "$URL_&Signature=$(URLEncode $SIGN_)"
		fi
}

# GET Final AliYunDNSApi Request URL
RequestAliYunDNSAPI(){
# $1: OPERATION
# $2: param
	if [[ "$1" = "AddDomainRecord" ]]; then
		ALIYUNDNS_API_URL=$(GetAliYunDNSAPIUrl $1 $2)
	fi

	if [[ "$1" = "DeleteDomainRecord" ]]; then
		ALIYUNDNS_API_URL=$(GetAliYunDNSAPIUrl $1 $2)
	fi
	resp=`curl -s $ALIYUNDNS_API_URL`
	echo $resp|tr \\n ' '
}

#Check Dns Txt Record
CheckDnsTxtRecord(){
  # dnsget -t 
  isCheckedRecord=`dig TXT $HOSTNAME.$DOMAIN | grep $DNS_TXT_VAL |wc -l`
	if [[ $isCheckedRecord -gt 0 ]]; then
		echo 1
  else
    echo 0
	fi
}

STARTTIME=0
export STARTTIME
#Check Dns Txt Record sync
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

#Set DNS Record(AddDomainRecord)
#See https://help.aliyun.com/document_detail/29772.html?spm=a2c4g.11186623.6.639.3a881af8VmFvMR
#return rrid 
SetDNSTxtRecord(){
	# rrtype=TXT&rrhost=$HOSTNAME&rrvalue=$DNS_TXT_VAL&rrttl=$TTL
	resp=$(RequestAliYunDNSAPI "AddDomainRecord" "DomainName=$DOMAIN&RR=$HOSTNAME&Type=TXT&Value=$DNS_TXT_VAL&TTL=$TTL")
	#complie xml,return rrid
	resp=`echo $resp | grep -oPm1 "(?<=<RecordId>)[^<]" `
	if [[ ${#resp} -gt 0 ]];then
		echo $resp
	fi
	exit 0
}

#Delete DNS Record(DeleteDomainRecord)
#See https://help.aliyun.com/document_detail/29773.html?spm=a2c4g.11186623.6.640.2d212846KGI0uz
# domain=$DOMAIN&
#return 1
DelDNSTxtRecord(){
	resp=$(RequestAliYunDNSAPI "DeleteDomainRecord" "RecordId=$RRID")
	resp=`echo $resp | grep -oPm1 "(?<=<RecordId>)\d*(?=<)"`
	if [[ ${#resp} -gt 0 ]];then
		echo 1
	fi
	exit 0
}

#ALIYUNDNS_KEY=""
#ALIYUNDNS_SEC=""
#DOMAIN=""
#HOSTNAME=""
#DNS_TXT_VAL=""
#IS_CHECK_DNS_TXT
#IS_CHECK_DNS_TXT_WAIT
#IS_SET_DNS_TXT
#RRID DNS Record id
TTL=600
if [[ $# = 0 ]]; then
	showUsage
fi
while [ -n "$1" ]
do
        case "$1" in
        --key) ALIYUNDNS_KEY=$2;shift 2;;
        --sec) ALIYUNDNS_SEC=$2;shift 2;;
				--domain) DOMAIN=$2;shift 2;;
				--hostname) HOSTNAME=$2;shift 2;;
        --check-dns-txt) IS_CHECK_DNS_TXT=1; shift 1;;
        --check-dns-txt-wait) IS_CHECK_DNS_TXT_WAIT=1; shift 1;;
        --set-dns-txt) IS_SET_DNS_TXT=1; shift 1;;
				--del-dns-txt) IS_DEL_DNS_TXT=1; shift 1;;
				--txt) DNS_TXT_VAL=$2; shift 2;;
				--rrid) RRID=$2; shift 2;;
				--ttl) TTL=$2; shift 2;;
		--signtest) SIGN_TEST_URL=$2;shift 2;;
		--testaliyunurl) IS_TEST_GET_ALIUIN_URL=1; shift 1;;
        --help) showUsage;;
#				--) break ;;
        *) break ;;
        esac
done

if [ "$IS_TEST_GET_ALIUIN_URL" = 1 ]; then
    # get aliyundns url test
    GetAliYunDNSAPIUrl
    exit 0
fi

if [ -n  "$SIGN_TEST_URL" ]; then
    # sign test
    GetSignature "$SIGN_TEST_URL"
    exit 0
fi

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

