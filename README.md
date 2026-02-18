# nginx-otel module builder

Build pipeline for generating `ngx_otel_module.so` and `.deb` packages for specific nginx + OS + architecture combinations.

## How it works

A multi-stage Dockerfile builds the [nginxinc/nginx-otel](https://github.com/nginxinc/nginx-otel) module from source against a pinned nginx version. Build targets are defined in `manifest.yaml` and a GitHub Actions workflow fans out a matrix build across all targets and architectures.

## manifest.yaml

Add or modify entries to build for different combinations:

```yaml
targets:
  - os: ubuntu
    os_version: "24.04"
    nginx_version: "1.24.0"
    otel_version: "0.1.2"
    architectures:
      - amd64
      - arm64
```

## Local build

```sh
docker buildx build \
  --platform linux/amd64 \
  --build-arg BASE_IMAGE=ubuntu:24.04 \
  --build-arg NGINX_VERSION=1.24.0 \
  --build-arg NGINX_OTEL_TAG=v0.1.2 \
  --output type=local,dest=dist/ \
  .
```

Artifacts (`ngx_otel_module.so` and `nginx-mod-otel.deb`) will be written to `dist/`.

## Install

Download the `.deb` for your architecture from the [latest release](https://github.com/base-14/nginx-otel-build/releases/latest) and install with apt:

```sh
# arm64
curl -LO https://github.com/base-14/nginx-otel-build/releases/download/v0.1.1/ubuntu24.04-nginx1.24.0-arm64.deb
sudo apt install ./ubuntu24.04-nginx1.24.0-arm64.deb

# amd64
curl -LO https://github.com/base-14/nginx-otel-build/releases/download/v0.1.1/ubuntu24.04-nginx1.24.0-amd64.deb
sudo apt install ./ubuntu24.04-nginx1.24.0-amd64.deb
```

This will resolve and install dependencies (`nginx`, `libc-ares2`, `libre2`, `libssl`) automatically and enable the module.

## Releasing

Push a tag to create a release with downloadable artifacts:

```sh
git tag v0.1.1
git push --tags
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
