#!/bin/sh
# set crontab run every day,when time is about 85d ,renew
# echo $CERTBOT_VALIDATION
# echo $CERTBOT_DOMAIN
# echo $CERTBOT_TOKEN
set -x
basePath="/usr/docs"
baseScriptPath="$basePath/scripts"
#$baseScriptPath/
manualAuthHookScriptNamesilo="manual-auth-hook-namesilo.sh"
#$baseScriptPath/
manualCleanupHookScriptNamesilo="manual-cleanup-hook-namesilo.sh"
# deployHookNginx="$baseScriptPath/deploy-hook-nginx.sh"
#Default is aliyun
manualAuthHookScript="$baseScriptPath/manual-auth-hook-aliyundns.sh"
manualCleanupHookScript="$baseScriptPath/manual-cleanup-hook-aliyundns.sh"
deployHookNginx="$baseScriptPath/deploy-hook-nginx.sh"
certName=""
USAGE="Usage: $0 --base xxx --mahs xxx --mchs example.com --dh xxx [OPTIONS] []
  --base                 set base path,like '/usr/docs'
  --mahs                 set manualAuthHookScript, like 'manual-auth-hook-aliyundns.sh',should under base path
  --mchs                 set manualCleanupHookScript,like 'manual-cleanup-hook-aliyundns.sh',should under base path
  --dh                   set deployHook,like 'deploy-hook-nginx.sh',should under base path
  --aliyun               run aliyun config,this is default
  --namesilo             run namesilo config
  --cloudflare             run cloudflare config
  --cert-name            set cert-name that specified on the first time created
  --help                 help
  e.g.(defalut):
  	./$0 --base '/usr/docs' --mahs manual-auth-hook-aliyundns.sh --mchs manual-cleanup-hook-aliyundns.sh --dh deploy-hook-nginx.sh
"
showUsage(){
	echo "$USAGE"
	exit 0
}

# if [[ $# = 0 ]]; then
# 	showUsage
# fi
while [ -n "$1" ]
do
        case "$1" in
        --base) baseScriptPath=$2;shift 2;;
        --mahs) manualAuthHookScript="$baseScriptPath/$2";shift 2;;
				--mchs) manualCleanupHookScript="$baseScriptPath/$2";shift 2;;
				--dh) deployHookNginx="$baseScriptPath/$2";shift 2;;
				--namesilo) manualAuthHookScript=$manualAuthHookScriptNamesilo; manualCleanupHookScript=$manualCleanupHookScriptNamesilo ;shift 1;;
				--cert-name) certName=$2;shift 2;;
        --help) showUsage;;
        *) break ;;
        esac
done

# valid autorun flag,content is last run timestamp,e.g.: 1544351118
CERTBOT_AUTO_RUN_FLAG_FILE="$basePath/CERTBOT_AUTO_RUN_FLAG"
# check file exists
if [[ -f $CERTBOT_AUTO_RUN_FLAG_FILE ]];then
  certFlag=`cat $CERTBOT_AUTO_RUN_FLAG_FILE`
  lastRunTime="${certFlag//_1/}"
  now=`date +%s`
  succIdx=`expr index $certFlag _`
  if  [[ $succIdx = 0 ]] || [[ $certFlag =~ "_1" && $(($now - $lastRunTime)) -gt 6912000 ]]; then
    isNeedRun=1
  fi  
else
  isNeedRun=1
fi
if [[ $isNeedRun = 1 ]];then
  # config the cert-name , e.g.: example.com
  sh $basePath/certbot-auto renew --cert-name $certName --manual-auth-hook $manualAuthHookScript --manual-cleanup-hook $manualCleanupHookScript --deploy-hook $deployHookNginx
  if [[ $? = 0 ]];then
    echo `date +%s_1` > $CERTBOT_AUTO_RUN_FLAG_FILE
    #send email
    sh $baseScriptPath/sendmail_server_event.sh "CERT UPDATE SUCCESS"
  else
    echo `date +%s` > $CERTBOT_AUTO_RUN_FLAG_FILE
    #send email
    sh $baseScriptPath/sendmail_server_event.sh "CERT UPDATE FAIL"
  echo ""

  fi
fi
