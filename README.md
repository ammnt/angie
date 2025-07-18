# Distroless Angie with HTTP/3 and QUIC support🚀

[![Build and push image📦](https://github.com/ammnt/angie/actions/workflows/build.yml/badge.svg)](https://github.com/ammnt/angie/actions/workflows/build.yml)
![version](https://img.shields.io/badge/version-1.10.1-blue)
[![GitHub issues open](https://img.shields.io/github/issues/ammnt/angie.svg)](https://github.com/ammnt/angie/issues)
![GitHub Maintained](https://img.shields.io/badge/open%20source-yes-orange)
![GitHub Maintained](https://img.shields.io/badge/maintained-yes-yellow)

The Docker image is ready to use:<br>
<code>ghcr.io/ammnt/angie:latest</code><br>
or<br>
<code>docker.io/ammnt/angie:latest</code><br>
or with Docker Compose deployment:
```
services:
  angie:
    image: docker.io/ammnt/angie:latest
    user: "101:101"
    read_only: true
    privileged: false
    tmpfs:
     - /tmp:mode=1700,size=1G,noexec,nosuid,nodev,uid=101,gid=101
    cap_drop:
     - all
    container_name: angie
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-angie
      - seccomp:./angie-seccomp.json
    volumes:
      - "./conf:/etc/angie:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
...
```

# Description:

- Base image: Alpine Linux (only ~5 MB);
- Hardened image (secure, minimal and production-ready) - recommended to use in Rootless mode:<br>
https://docs.docker.com/engine/security/rootless/
- Runtime on scratch image - with zero bloat;
- Multi-stage building with statically linked binary;
- OpenSSL with HTTP/3 and QUIC support:<br>
https://github.com/openssl/openssl
- HTTP/2 with ALPN support;
- TLS 1.3 and 0-RTT support;
- TLS 1.2 and TCP Fast Open (TFO) support;
- Built using hardening GCC flags;
- NJS and Brotli support;
- PCRE with JIT compilation;
- zlib-ng library latest version;
- Rootless master process (unprivileged container);
- Async I/O threads module;
- "Distroless" image - reduced attack surface (removed SHELL, UNIX tools, package manager etc);
- Removed unnecessary modules;
- Added OCI labels and annotations;
- No excess ENTRYPOINT in the image;
- Slimmed version by Docker Slim tool;
- Image efficiency score 100% according to Dive utility;
- Scanned by vulnerability scanners: GitHub CodeQL, Docker Scout, Snyk, Grype, Dockle and Syft;
- Prioritize ChaCha cipher patch and anonymous signature - removed "Server" header ("banner"):<br>
https://github.com/ammnt/angie/blob/main/Dockerfile

# Note:

Feel free to <a href="https://github.com/ammnt/angie/issues/new">contact me</a> with more improvements 🙋
