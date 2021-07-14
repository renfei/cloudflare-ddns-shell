[English](./README.md) | [简体中文](./README_ZH.md)

![Cloudflare](./document/image/cf-logo.jpg)

注：Cloudflare®图形商标版权归 Cloudflare, Inc. 所有。

# Cloudflare 动态DNS
基于 CloudFlare API v4 的 动态 DNS Shell 脚本。

## 参数说明

选中的参数为必传参数：

- [x] -key：Cloudflare API Authorization Key，接口Token，申请地址：[https://dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
- [x] -zone：域，例如：renfei.net
- [ ] -zone_id：在 Cloudflare 上域名的唯一ID
- [ ] -type：域名记录类型，例如：A记录
- [ ] -rec_id：域名记录唯一ID
- [x] -name：二级域名例如：www
- [ ] -content：请求体内容
- [ ] -ttl：解析记录存活时间，1为自动
- [ ] -proxied：是否启用 CloudFlare 代理


## 示例

域名：test2.renfei.net，先到 Cloudflare 添加域名A记录解析，手动执行一次：

```bash
bash /path/to/cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name test2
```
![Example](./document/image/example.png)

### 通过 Linux cron 定时任务执行

```bash
crontab -e
0 */1 * * * ? /path/to/cloudflare_ddns.sh -key 404613183ab3971a2118ae5bf03d63e032f9e -zone renfei.net -name test2 >> /path/to/cloudflare_ddns.log
```