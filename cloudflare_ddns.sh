#!/bin/sh
#
# CloudFlare Dynamic DNS
# https://github.com/renfei/cloudflare-ddns-shell
#
# Updates CloudFlare records with the current public IP address
#
# Takes the same basic arguments as A/CNAME updates in the CloudFlare v4 API
# https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record
#
# Use with cron jobs etc.
#
# e.g.
#
# manually run:
# cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name extra
#
# cronjob entry to run every 5 minutes:
# */5 * * * * /path/to/cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name extra >> /path/to/cloudflare_ddns.log
#
# will both set the type A DNS record for extra.renfei.net to the current public IP address for user test@renfei.net with the provided API key
#
# #############################################################
#
# CloudFlare 动态 DNS
# https://github.com/renfei/cloudflare-ddns-shell
#
# 使用当前公共 IP 地址更新 CloudFlare 记录
#
# 采用与 CloudFlare v4 API 中的 A/CNAME 更新相同的基本参数
# https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record
#
# 与 cron 作业等一起使用。
#
# 例如
#
# 手动运行：
# cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name extra
#
# cronjob 定时任务每 5 分钟运行一次：
# */5 * * * * /path/to/cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name extra >> /path/to/cloudflare_ddns.log
#
# 使用提供的 API 密钥将 extra.renfei.net 的 DNS A记录设置为当前公网 IP 地址

echo "CloudFlare Dynamic DNS Start"
echo "Datetime: "$(date)
echo "=========="
key=
zone=
zone_id=
type=A
rec_id=
name=
content=
ttl=1
proxied=false

while [ "$1" != "" ]; do
    case $1 in
        -key )     shift
                   key=$1
                   ;;
        -zone )    shift
                   zone=$1
                   ;;
        -zone_id ) shift
                   zone_id=$1
                   ;;
        -type )    shift
                   type=$1
                   ;;
        -rec_id )  shift
                   rec_id=$1
                   ;;
        -name )    shift
                   name=$1
                   ;;
        -content ) shift
                   content=$1
                   ;;
        -ttl )     shift
                   ttl=$1
                   ;;
        -proxied ) shift
                   proxied=$1
                   ;;
        * )        echo "unknown parameter $1"
                   exit 1
    esac
    shift
done

if [ "$content" = "" ]
then
    content=`curl -s http://ip.renfei.net | awk -F ':"' '{print $NF}' | awk -F '"}' '{print $1}'`
    if [ "$content" = "" ]
    then
        date
        echo "No IP address to set record value with. 没有可用于设置记录值的 IP 地址。"
        exit 1
    fi
    if [[ $content =~ ":" ]]
    then
        content=`curl -s http://ipv4.renfei.net | awk -F ':"' '{print $NF}' | awk -F '"}' '{print $1}'`
        if [ "$content" = "" ]
        then
            date
            echo "No IP address to set record value with. 没有可用于设置记录值的 IP 地址。"
            exit 1
        fi
    fi
fi
echo "IP Addr: "$content
echo "=========="
if [ "$name" = "" ]
then
    echo "You must provide the name of the record you wish to change. 您必须提供要更改的记录的名称。"
    exit 1
fi

if [ "$zone" = "" ]
then
    echo "You must provide the domain you wish to change. 您必须提供要更改的域名。"
    exit 1
fi

if [ "$name" = "$zone" ]
then
    hostname="$name"
else
    hostname="$name.$zone"
fi

if [ "$key" = "" ]
then
    echo "You must provide your user API token. 您必须提供您的用户 API 令牌。"
    exit 1
fi

# Get the zone id for the entry we're trying to change if it's not provided
if [ "$zone_id" = "" ]
then
    echo "GET: https://api.cloudflare.com/client/v4/zones?name=$zone"
    zone_response_json=`curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone" -H "X-Auth-Email: $email" -H "Authorization: Bearer $key" -H "Content-Type: application/json"`
    # echo "zone_response_json: "$zone_response_json
    echo "=========="
    zone_id=`echo $zone_response_json | sed -E "s/.+\"result\":\[\{\"id\":\"([a-f0-9]+)\"[^\}]+$zone.+/\1/g"`
    if [ "$zone_id" = "" ]
    then
        echo "Cloudflare DNS Zone id could not be found, please make sure it exists. 在 Cloudflare 中找不到 DNS Zone ID，请确保它存在。"
        exit 1
    fi
fi

# Get the record id for the entry we're trying to change if it's not provided
if [ "$rec_id" = "" ]
then
    echo "GET: https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$hostname"
    rec_response_json=`curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$hostname" -H "Authorization: Bearer $key" -H "Content-Type: application/json"`
    # echo "rec_response_json: "$rec_response_json
    echo "=========="
    rec_id=`echo $rec_response_json | sed -E "s/.+\"result\":\[\{\"id\":\"([a-f0-9]+)\"[^\}]+\$hostname\",\"type\":\"$type\"[^\}]+.+/\1/g"`
    if [ "$rec_id" = "" ]
    then
        echo "Cloudflare DNS Record id could not be found, please make sure it exists. 在 Cloudflare 中找不到 DNS 记录，请确保它存在。"
        exit 1
    fi
fi

# Update the DNS record
echo "PUT: https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$rec_id"
update_response=`curl -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$rec_id" -H "Authorization: Bearer $key" -H "Content-Type: application/json" --data "{\"id\":\"$rec_id\",\"type\":\"$type\",\"name\":\"$hostname\",\"content\":\"$content\",\"ttl\":$ttl,\"proxied\":$proxied}"`
# echo "update_response: "$update_response
echo "=========="
success_val=`echo $update_response | sed -E "s/.+\"success\":(true|false).+/\1/g"`
if [ "$success_val" = "true" ]
then
    echo "Record Updated. 记录更新成功。"
else
    echo "Record update failed. 记录更新失败。"
    exit 1
fi