## hp prodesk 600 g3 mini pc
* intel i5-7500T cpu
* 8gb DDR4 RAM
* 256 GB SSD

## domains through [porkbun](https://porkbun.com/)
* `kicanter.dev` - personal website
* `git.kicanter.dev` - [forgejo](https://forgejo.org/) instance mirroring my github
* `kierancanter.dev` - redirect to above domain

## tools used
* [`caddy`](https://github.com/caddyserver/caddy) - Reverse proxy
* [`forgejo`](https://codeberg.org/forgejo/forgejo) - FOSS git host
* [`ddclient`](https://github.com/ddclient/ddclient) - Dynamic DNS
* [`fail2ban`](https://github.com/fail2ban/fail2ban) - Ban suspicious IPs
* [`docker`](https://github.com/docker) - Forgejo, Caddy, and ddclient containerization

## pre-deployment
1. port forward 80 (http), 443 (https), 22 (or custom port for direct ssh), and 2222 (alt ssh for forgejo ssh git interaction) via router config
1. lock in static LAN IP for server via router config (change from DHCP)
1. generate API keys in porkbun and enable API access for primary domain

## steps
1. start service `docker compose up -d`
1. set up Caddy's `Caddyfile`
1. set up Forgejo
  1. visit `http://<local-ip>:3000` to finish set up of instance (if first time)
1. set up `ddclient` for dynamic DNS updates
  1. place at `/etc/ddclient/ddclient.conf`
  1. replace API keys with actual keys
