#!/usr/bin/python
# aliyundnssign.py
 
import sys
import urllib
import hmac
import base64
from hashlib import sha1

#  A-Z,a-z,0-9 - ,_,.,~ no encode
# https://help.aliyun.com/document_detail/29747.html?spm=a2c4g.11186623.2.15.7d012b314gTRhj
def encodeURL(str):
    return urllib.quote(str).replace("%7E","~").replace("/","%2F")

def hashCode(s):
    s = s.decode("utf-8")
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF
    return abs(((h + 0x80000000) & 0xFFFFFFFF) - 0x80000000)

# arr hash sort 
def hashSort(arr):
    return arr.sort(key=hashCode)

def sign(key,url):
    hmacKey = key
    url = url
    returnUrl = ""
    #split url by ?
    tempUrls = url.split("?")
    uri = tempUrls[0]
    params = tempUrls[1]
    paramMap = {}
    for p in params.split("&"):
        ps = p.split("=")
        paramMap[ps[0]]= encodeURL(ps[1])
    #sort 
    for p in sorted(paramMap.items(), key=lambda paramMap: paramMap[0]):
        returnUrl+=p[0]+"="+paramMap[p[0]]+"&"
    #for p in paramMap.keys():
    #    returnUrl+=p+"="+paramMap[p]+"&"
    if len(returnUrl) > 0:
        returnUrl = returnUrl[0:len(returnUrl)-1]
    # StringToSign= HTTPMethod + "&" + percentEncode("/") + "&" + percentEncode(CanonicalizedQueryString)
    stringToSign = "GET&%2F&"+encodeURL(returnUrl)
    # BASE64 sha1 sign 
    h = hmac.new(key=hmacKey,msg=stringToSign,digestmod=sha1) 
    signature = encodeURL(base64.b64encode(h.digest()))
    returnUrl = uri+"?" + returnUrl + "&Signature=" + signature
    return returnUrl

if __name__ == '__main__':
    sign(sys.argv[1],sys.argv[2])

