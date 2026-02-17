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

Download the `.deb` from the [GitHub Releases](../../releases) page and install with apt:

```sh
sudo apt install ./nginx-mod-otel-ubuntu24.04-nginx1.24.0.deb
```

This will resolve and install dependencies (`nginx`, `libc-ares2`, `libre2-11`, `libssl3t64`) automatically and enable the module.

## Releasing

Push a tag to create a release with downloadable artifacts:

```sh
git tag v0.1.2
git push --tags
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
