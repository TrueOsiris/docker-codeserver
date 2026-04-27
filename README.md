# docker-codeserver

docker codeserver with docker-cli and vim

<!-- TOC tocDepth:2..3 chapterDepth:2..6 -->

- [1. credits](#1-credits)
- [2. Application Setup](#2-application-setup)
  - [2.1. Setup differences with basic linuxserver/code-server image](#21-setup-differences-with-basic-linuxservercode-server-image)
  - [2.2. Hashed code-server password](#22-hashed-code-server-password)
- [3. Usage](#3-usage)
  - [3.1. docker-compose](#31-docker-compose)
  - [3.2. Source control](#32-source-control)
  - [3.3. code-marketplace](#33-code-marketplace)
- [4. Parameters](#4-parameters)
- [5. Firefox](#5-firefox)

<!-- /TOC -->
## 1. credits

 This is a fork of [linuxserver.io/code-server](https://docs.linuxserver.io/images/docker-code-server/).<br>
 It has docker cli and python3 built-in.

## 2. Application Setup

Access the webui at `http://<your-ip>:8443`.
For github integration, drop your ssh key in to `/config/.ssh`.

### 2.1. Setup differences with basic linuxserver/code-server image

- use PGID & PUID 0
- map volume /var/run/docker.sock:/var/run/docker.sock
- map your dockerfiles as a volume
- configure the Microsoft extensions gallery instead of the much more limited default one. 

### 2.2. Hashed code-server password

How to create the [hashed password](https://github.com/cdr/code-server/blob/master/docs/FAQ.md#can-i-store-my-password-hashed).

## 3. Usage

Here are some example snippets to help you get started creating a container.

### 3.1. docker-compose

```yaml
networks:
  dockerbridge:
    name: dockerbridge
    driver: bridge
    external: true      
      
      
services:
  codeserver:
    image: ghcr.io/trueosiris/codeserver:latest
    environment:
      PUID: 0
      PGID: 0
      TZ: Europe/Brussels
      DEFAULT_WORKSPACE: /config/workspace
      #EXTENSIONS_GALLERY: '{"serviceUrl":"http://codemarketplace:3001/vscode/gallery","itemUrl":"http://codemarketplace:3001/vscode/item","resourceUrlTemplate":"http://codemarketplace:3001/vscode/resource/{publisher}/{name}/{version}/{path}"}'
      EXTENSIONS_GALLERY: '{"serviceUrl":"https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl":"https://vscode.blob.core.windows.net/gallery/index","itemUrl":"https://marketplace.visualstudio.com/items"}'
    volumes:
      - type: bind
        source: ./codeserver/config
        target: /config
        bind:
          create_host_path: true
      - type: bind
        source: /var/run/docker.sock
        target: /var/run/docker.sock
    ports:
      - 8443:8443
    restart: unless-stopped
    networks:
      - dockerbridge
    # depends_on:
    #   codemarketplace:
    #     condition: service_healthy    
    logging:
      driver: "json-file"
      options:
        max-size: "1m"
        max-file: "1"
    healthcheck:
      test: curl -sSf http://localhost:8443/login || exit 1
      start_period: 1m
      interval: 30s
      timeout: 10s
      retries: 5       
```

### 3.2. Source control

To work with git, set git credentials via a terminal

```bash
git config --global user.name "username"
git config --global user.email "email address"
```

### 3.3. code-marketplace 

Optional: If you want to run your own limited extension library, use this and replace the EXTENSIONS_GALLERY env var.
``` yaml
  codemarketplace:
    image: ghcr.io/coder/code-marketplace:v2.4.1
    restart: unless-stopped
    environment:
      - PORT=3001
      - HOST=0.0.0.0
    volumes:
      - type: bind
        source: /mnt/user/docker_volumes/dev/codeserver/config/extensions
        target: /extensions
        bind:
          create_host_path: true
    command: ["--extensions-dir", "/extensions", "--address", "0.0.0.0:3001"]
    networks:
      - dockerbridge
    healthcheck:
      test: ["CMD-SHELL", "netstat -an | grep LISTEN | grep -q :3001 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
```

## 4. Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 8443` | web gui |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Etc/UTC` | specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). |
| `-e PASSWORD=password` | Optional web gui password, if `PASSWORD` or `HASHED_PASSWORD` is not provided, there will be no auth. |
| `-e HASHED_PASSWORD=` | Optional web gui password, overrides `PASSWORD`, instructions on how to create it is below. |
| `-e SUDO_PASSWORD=password` | If this optional variable is set, user will have sudo access in the code-server terminal with the specified password. |
| `-e SUDO_PASSWORD_HASH=` | Optionally set sudo password via hash (takes priority over `SUDO_PASSWORD` var). Format is `$type$salt$hashed`. |
| `-e PROXY_DOMAIN=code-server.my.domain` | If this optional variable is set, this domain will be proxied for subdomain proxying. See [Documentation](https://github.com/cdr/code-server/blob/master/docs/FAQ.md#sub-domains) |
| `-e DEFAULT_WORKSPACE=/config/workspace` | If this optional variable is set, code-server will open this directory by default |
| `-v /config` | Contains all relevant configuration files. |

## 5. Firefox

- To enable the rightclick menu, set dom.events.testing.asyncClipboard to True in `about:config`
