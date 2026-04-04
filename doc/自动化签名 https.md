# 自动化签名 https



# ✅ 第1步：安装 Nginx

```
sudo apt update
sudo apt install nginx -y
```

------

# ✅ 第2步：启动

```
sudo systemctl enable nginx
sudo systemctl start nginx
```

------

# ✅ 第3步：配置反代

```
sudo nano /etc/nginx/sites-available/api
```

写入👇

```
server {
    listen 80;
    server_name api.etedrop.com;

    location / {
        proxy_pass http://127.0.0.1:40321;
    }
}
```

启用：

```
sudo ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

------

# ✅ 第4步：安装 HTTPS（最关键）

```
sudo apt install certbot python3-certbot-nginx -y
```

------

# ❗ Cloudflare 先关代理（灰云）

👉 在 Cloudflare：

```
api → DNS only
```

------

# ✅ 第5步：申请证书

```
sudo certbot --nginx -d api.etedrop.com
```

选择：

```
2 → 强制 HTTPS
```

------

# 🎉 完成

访问：

```
https://api.etedrop.com
```

------

# ☁️ 第6步：开启 Cloudflare

```
api → 🟠 Proxied
SSL → Full (strict)
```

------

# 🔄 自动续期（已经自带）

```
systemctl list-timers | grep certbot
```

------

# ⚠️ Nginx 必须反代 WebSocket（否则 `wss://…/api/share` 失败）

浏览器里页面是 **HTTPS**，信令会用 **`wss://api.etedrop.com/api/share`**。若 Nginx 只做普通 `proxy_pass`、不传 **Upgrade**，WebSocket 握手会失败（控制台：`WebSocket connection to 'wss://…' failed`）。

在 **`http { … }` 顶层**（与 `server` 同级）加一次 `map`（整份配置里只加一次即可）：

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
```

在 **`listen 443 ssl` 的 `server`** 里，把原来的 `location /` 换成（或合并进同一段）：

```nginx
location / {
    proxy_pass http://127.0.0.1:40321;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;
}
```

然后：

```
sudo nginx -t && sudo systemctl reload nginx
```

说明：`/api/share`、`/api/connect` 与 Nest 里 `ws` 的 `upgrade` 监听一致，路径不用在 Nginx里再拆；长连接可把 `proxy_read_timeout` 设大（例如 24h）。

------

# ☁️ Cloudflare Proxy（橙云）与 WebRTC

| 问题 | 说明 |
|------|------|
| **Proxy 开不开？** | 可以开。**SSL/TLS** 选 **Full (strict)**，源站已是合法证书。 |
| **WSS 受影响吗？** | Cloudflare **支持** WebSocket 透传；先修好上面 Nginx 的 `Upgrade`，再谈 CF。 |
| **WebRTC 媒体（UDP）** | 音视频/DataChannel 走 **P2P/STUN/TURN**，不经过 Nginx HTTP；橙云主要影响 **域名解析到你机器的方式**，一般 **不会** 单独“关掉” WebRTC。若遇极端 NAT，靠的是 **TURN**，与橙云无必然冲突。 |
| **排查顺序** | 1）本机 `curl` / 浏览器先确认 **WSS 已通**（Nginx + Upgrade）→ 2）再开橙云测一遍。 |

若仍异常：Cloudflare **Network** 里确认 **WebSockets** 为开启；可先 **DNS only（灰云）** 对比，确认是 CF 还是源站配置问题。