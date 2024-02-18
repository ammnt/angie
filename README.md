# Angie with HTTP/3 and QUIC support🚀

The Docker image is ready to use:<br>
<code>docker pull ghcr.io/ammnt/angie:http3</code><br>
or<br>
<code>docker pull ammnt/angie:http3</code>

# Description:

- Based on latest version of Alpine Linux - low size (~5 MB);
- QuicTLS with kTLS module:<br>
https://github.com/quictls/openssl
- HTTP/3 + QUIC native support;
- HTTP/2 with ALPN support;
- TLS 1.3 and 0-RTT support;
- TLS 1.2 and TCP Fast Open (TFO) support;
- Built using hardening GCC flags;
- NJS support;
- PCRE with JIT compilation;
- zlib library latest version;
- Rootless master process - unprivileged container;
- Async I/O threads module;
- Removed unnecessary modules;
- Added OCI labels and annotations;
- No excess ENTRYPOINT in the image;
- Slimmed version by Docker Slim tool;
- Prioritize ChaCha cipher patch and anonymous signature - removed "Server" header ("banner"):<br>
https://github.com/ammnt/angie/blob/http3/Dockerfile

# Note:

Feel free to <a href="https://github.com/ammnt/angie/issues/new">contact me</a> with more security improvements🙋
