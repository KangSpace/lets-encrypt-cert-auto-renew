#!/bin/bash
# $1: Server Report Event Name
base_path='$basePath'
base_script_path='$basePath/scripts'
# config your email address which send the email
__FROM__=''
# config destination email address
__TO__=''
__SERVER_HOST__=`hostname`
__CONTENT__='Server Status Report:'
__HOST__="$__SERVER_HOST__"
__IP__=`/usr/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2}'`
#__IP__=`/usr/sbin/ifconfig eth0 | grep 'inet addr' | awk '{ print $2}' | awk -F: '{print $2}'`
__TIME__=`date`
__EVENT__='Server Restart'

if [ "$1" ]; then
  __EVENT__="$1"
fi

__MAIN_HTML__=`cat $base_script_path/mail_event_template.txt`
temp_file="$base_script_path/.temp_mail.txt"
cp -f $base_script_path/mail_event_template.txt $temp_file
# replace vars
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__FROM__/$__FROM__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__TO__/$__TO__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__SERVER_HOST__/$__SERVER_HOST__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__CONTENT__/$__CONTENT__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__HOST__/$__HOST__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__IP__/$__IP__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__TIME__/$__TIME__})
#__MAIN_HTML__=$(echo ${__MAIN_HTML__//__EVENT__/$__EVENT__})
sed -i "s/__FROM__/$__FROM__/g" $temp_file
sed -i "s/__TO__/$__TO__/g" $temp_file
sed -i "s/__SERVER_HOST__/$__SERVER_HOST__/g" $temp_file
sed -i "s/__CONTENT__/$__CONTENT__/g" $temp_file
sed -i "s/__HOST__/$__HOST__/g" $temp_file
sed -i "s/__IP__/$__IP__/g" $temp_file
sed -i "s/__TIME__/$__TIME__/g" $temp_file
sed -i "s/__EVENT__/$__EVENT__/g" $temp_file
cat $temp_file |/usr/sbin/sendmail -t
