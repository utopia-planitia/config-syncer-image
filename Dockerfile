# config-syncer v0.13.2 and v0.14.0-rc.0 are incompatible with any Go version greater than 1.20.
# The reason might be that Go 1.21 changed the package initialization order.
FROM docker.io/library/golang:1.20.14-alpine

USER 0:0
WORKDIR /config-syncer

# renovate: datasource=github-tags depName=config-syncer/config-syncer
ENV CONFIG_SYNCER_VERSION=v0.13.2

RUN set -eux; \
    apk upgrade --no-cache; \
    apk add --no-cache bash git

RUN set -eux; \
    git clone "--branch=${CONFIG_SYNCER_VERSION:?}" --depth=1 https://github.com/config-syncer/config-syncer .

# TODO: Should we fix the critical vulnerability CVE-2022-1996 like this? 🙈
#RUN set -eux; \
#    go get github.com/emicklei/go-restful@v2.16.0; \
#    go mod vendor; \
#    git diff ':!vendor'

ARG TARGETOS TARGETARCH
RUN set -eux; \
    OS="${TARGETOS:?}" \
    ARCH="${TARGETARCH:?}" \
    VERSION="$(git describe --tags --always --dirty)" \
    git_branch="$(git rev-parse --abbrev-ref HEAD)" \
    git_tag="$(git describe --exact-match --abbrev=0 2>/dev/null || echo "")" \
    commit_hash="$(git rev-parse --verify HEAD)" \
    commit_timestamp="$(date --date="@$(git show -s --format=%ct)" --utc +%FT%T)" \
    version_strategy=tag \
    bash hack/build.sh; \
    /go/bin/kubed version | tee -a /dev/stderr | grep -Fq "${CONFIG_SYNCER_VERSION:?}"

FROM scratch
USER 65534:65534
ENTRYPOINT ["/kubed"]
COPY --from=0 /go/bin/kubed /kubed
