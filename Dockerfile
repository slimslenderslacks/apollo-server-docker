# syntax = docker/dockerfile:1.4
FROM nixos/nix:latest AS builder

WORKDIR /tmp/build
RUN mkdir /tmp/nix-store-closure

RUN \
    --mount=type=cache,target=/nix,from=nixos/nix:latest,source=/nix \
    --mount=type=cache,target=/root/.cache \
    --mount=type=bind,target=/tmp/build \
    <<EOF
  nix \
    --extra-experimental-features "nix-command flakes" \
    --extra-substituters "http://host.docker.internal?priority=10" \
    --option filter-syscalls false \
    --show-trace \
    --log-format bar-with-logs \
    build . --out-link /tmp/output/result
  cp -R $(nix-store -qR /tmp/output/result) /tmp/nix-store-closure
  cd /tmp/output
  nix \
    --extra-experimental-features "nix-command flakes" \
    run github:tiiuae/sbomnix#sbomnix -- /tmp/output/result/bin/entrypoint
EOF

FROM scratch

WORKDIR /app

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/output/ /app/
COPY --from=builder /tmp/output/sbom.spdx.json .
ENTRYPOINT ["/app/result/bin/entrypoint"]
