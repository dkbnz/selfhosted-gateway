# Self-hosted Gateway

**Jump to [Getting Started](#getting-started)**

This project automates the provisioning of a **Reverse Proxy-over-VPN (RPoVPN)** using WireGuard, Caddy and NGINX. It provides a self-hosted alternative to Cloudflare Tunnels, Tailscale Funnel or ngrok and is suitable for exposing services defined in a `docker-compose` file. There's no code or APIs, just a generic NGINX config and a short bash script. It automatically provisions TLS certs with Caddy's Automatic HTTPS feature via Let's Encrypt.

## Benefits

1. **RPoVPN is a common strategy for remotely accessing applications self-hosted at home. It solves problems such as:**
  - Self-hosting behind double-NAT or via an ISP that does CGNAT (Starlink, Mobile Internet).
  - Inability to portforward on your local network due to insufficient access.
  - Having a dynamically allocated IP that may change frequently.

2. **Using RPoVPN is ideal for self-hosting from both a network security and privacy perspective:**
  - Prevents the need to expose your home public IP address to the world.
  - Utilises the advanced network isolation capabilities of Docker (via Linux network namespaces) to isolate your self-hosted services from your home network and your other docker self-hosted services.
  - Built on open-source technologies (WireGuard, Caddy and NGINX).

## Getting Started

### Prerequisites

- Ability to create an `A` record for a domain name.
- A Linux host to act as the `gateway`, typically a cloud VPS (Hetzner, Digital Ocean, etc..) with the following requirements:
  - Open ports 80/443 (http(s)).
  - UDP port range listed `/proc/sys/net/ipv4/ip_local_port_range` exposed to the internet.
  - `docker` installed.
  - SSH access to the `gateway`.
- Server with one or more services defined in a `docker-compose.yml` that you would like to expose to the internet.
- A local machine to run the commands on. This may also be the server where the exposed services will run.
  - `docker`, `git` & `make` installed on the local machine.

### Steps

1. Point `*.mydomain.com` (DNS A Record) to the IPv4 & IPv6 address of your VPS Gateway host.

2. Clone the repo, build the images and initialize the `gateway`:
```console
foo@local:~$ git clone ... && cd selfhosted-gateway
foo@local:~/selfhosted-gateway$ export GATEWAY=root@123.456.789.101
foo@local:~/selfhosted-gateway$ make build
foo@local:~/selfhosted-gateway$ make gateway
```

3. Generate a `link` and the required `docker-compose.yml` snippet:
```console
foo@local:~/selfhosted-gateway$ make link GATEWAY=root@123.456.789.101 FQDN=nginx.mydomain.com EXPOSE=nginx:80
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.mydomain.com
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 123.456.789.101:49185
    cap_add:
      - NET_ADMIN
```

4. Add the generated snippet to your `docker-compose.yml` file:
```yaml
version: '3.9'
services:
  nginx:
    image: nginx:latest
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: nginx.mydomain.com
      EXPOSE: nginx:80
      GATEWAY_CLIENT_WG_PRIVKEY: 4M7Ap0euzTxq7gTA/WIYIt3nU+i2FvHUc9eYTFQ2CGI=
      GATEWAY_LINK_WG_PUBKEY: Wipd6Pv7ttmII4/Oj82I5tmGZwuw6ucsE3G+hwsMR08=
      GATEWAY_ENDPOINT: 123.456.789.101:49185
    cap_add:
      - NET_ADMIN
```

5. Run `docker compose up -d`. This will established the `link` to the `gateway` and negotiate a TLS-certificate via Let's Encrypt. After ~1 minute, your service should be securely accessible via `https://nginx.mydomain.com/`

You may repeat steps 3-5 for as many services as you would like to expose using the same gateway.

## Extra

### Roadmap

- Completely automate initialisation of gateway using Ansible.
  - Create separate host user and generate ssh key for link creation.
- Allow `make link ...` to return the snippet if the link already exists.
- Automate the creation of the link using docker labels and a continuously running service.

### Architecture

<!-- TODO: Add a network diagram -->

```shell
├── ...
└── src
    ├── client-link  # WireGuard instance for the client. Also handles SSL termination with Caddy
    │   └── ...
    ├── create-link  # CLI script for establishing a link.
    │   └── ...
    ├── gateway      # NGINX reverse proxy to distribute requests to each gateway-link instance.
    │   └── ...
    └── gateway-link # WireGuard instance for the gateway.
        └── ...
```

### Terminology
- `Link` - A dedicated WireGuard tunnel between a local container (client) and the remote container running on the Gateway through which Reverse Proxy traffic is routed. A link is comprised of 2 pieces, the local or client link and the gateway or remote link.

### Show all links running on a Gateway
```
$ docker ps
```

### Limitations

- Currently only IPv4 is supported

### FAQ

- How is this better than setting up nginx and WireGuard myself on a VPS?

The goal of this project is to self-hosting more accessible and reproducible. This selfhosted-gateway leverages a "ZeroTrust" network architecture (see diagram above). Each "Link" provides a dedicated WireGuard tunnel that is isolated from other containers and the underlying. This isolation is provided by Docker Compose's creation of a private Docker network for each compose file (project).

- Can I still access the service from my local network?

You will need to expose ports in your Docker host as you would traditionally, but this is no longer necessary:
```
ports:
 - 80:80
 - 443:443
```
