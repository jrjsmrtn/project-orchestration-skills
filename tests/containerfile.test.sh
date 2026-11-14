#!/usr/bin/env bash
# usage: tests-containerfile.sh "RUNNER SCRIPT"
K=$1; fails=0; D=$(printf 'a%.0s' $(seq 64))
t(){ name=$1; want=$2; pat=$3; shift 3; out=$("$@" 2>&1); rc=$?; res=PASS; [ $rc -eq $want ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"; [ "$res" = PASS ] || { fails=$((fails+1)); echo "$out" | grep -E '^(FAIL|info)' | head -5 | sed 's/^/      /'; }; }
T=$(mktemp -d); cd "$T"; git init -q -b main; mkdir -p .github/workflows
cf(){ cat > Dockerfile; }
good(){ cf <<Y
FROM node:22-slim@sha256:$D AS build
RUN apt-get update && apt-get install -y --no-install-recommends make && rm -rf /var/lib/apt/lists/*
RUN set -eux; \\
    curl -fsSL -o /tmp/x.tgz https://example.com/x.tgz; \\
    echo "abc  /tmp/x.tgz" | sha256sum -c -
FROM cgr.dev/chainguard/node:latest@sha256:$D AS runtime
COPY --from=build /app /app
USER 65532
CMD ["node","/app"]
Y
}
good; printf '.git\n.env\n.env.*\nCLAUDE.local.md\n' > .dockerignore
printf 'pre-push:\n  commands:\n    lint:\n      run: hadolint Dockerfile\n' > lefthook.yml
printf 'fail-on-severity: "high"\n' > .grype.yaml
printf 'jobs:\n  s:\n    steps:\n      - run: grype oci-archive:img.tar\n' > .github/workflows/scan.yml
printf 'updates:\n  - package-ecosystem: "docker"\n    directory: "/"\n' > .github/dependabot.yml
t "good" 0 'ok    Dockerfile: base pinned' $K
t "explicit file argument" 0 '!FAIL' $K Dockerfile
good; sed -i.b 's/^FROM node:22-slim@sha256:[a]*/FROM node:22-slim/' Dockerfile; t "mutable tag" 1 'FROM node:22-slim is not pinned' $K
good; sed -i.b 's/^FROM node:22-slim@sha256:[a]* AS build/FROM node AS build/' Dockerfile; t "no tag at all" 1 'FROM node is not pinned' $K
good; sed -i.b 's/^FROM node:22-slim@sha256:[a]*/FROM node:22-slim@sha256:abc123/' Dockerfile; t "short digest" 1 'not 64 hex' $K
cf <<Y
FROM \${BASE} AS build
USER 65532
Y
t "variable base with no ARG" 1 'no default in a global ARG' $K
cf <<Y
ARG BASE=node:22-slim@sha256:$D
FROM \${BASE} AS build
USER 65532
Y
t "variable base with a pinned ARG default" 0 '!FAIL' $K
cf <<Y
ARG BASE="node:22-slim"
FROM \$BASE AS build
USER 65532
Y
t '$BASE form with an UNPINNED ARG default' 1 'FROM node:22-slim is not pinned' $K
cf <<Y
ARG BASE
FROM \${BASE} AS build
USER 65532
Y
t "ARG with no default" 1 'no default in a global ARG' $K
cf <<Y
FROM \${BASE} AS build
ARG BASE=node:22-slim@sha256:$D
USER 65532
Y
t "an ARG declared after the FROM does not count" 1 'no default in a global ARG' $K
cf <<Y
ARG V=22-slim
ARG DIG=sha256:$D
ARG IMG="node:\${V}@\${DIG}"
FROM \${IMG} AS build
USER 65532
Y
t "an ARG default that names other ARGs is expanded (pinned)" 0 'ok    Dockerfile: base pinned' $K
cf <<Y
ARG V=22-slim
ARG IMG="node:\${V}"
FROM \${IMG} AS build
USER 65532
Y
t "...and the expanded unpinned image is reported by name" 1 'FROM node:22-slim is not pinned' $K
good; sed -i.b 's/^FROM node:22-slim@sha256:[a]* AS build/FROM --platform=$BUILDPLATFORM node:22-slim AS build/' Dockerfile; t "--platform flag then an unpinned image" 1 'FROM node:22-slim is not pinned' $K
good; printf 'FROM scratch\nCOPY a /a\nUSER 1000\n' > Dockerfile; t "FROM scratch needs no digest" 0 '!FAIL' $K
good; sed -i.b 's/FROM cgr.dev\/chainguard\/node:latest@sha256:[a]* AS runtime/FROM build AS runtime/' Dockerfile; t "FROM an earlier stage is fine" 0 '!FAIL' $K
good; sed -i.b 's/^USER 65532/# no user/' Dockerfile; t "no USER" 1 'no USER, or ends as root' $K
good; sed -i.b 's/^USER 65532/USER root/' Dockerfile; t "USER root" 1 'no USER, or ends as root' $K
good; sed -i.b 's/^USER 65532/USER 0:0/' Dockerfile; t "USER 0:0" 1 'ends as root' $K
good; sed -i.b 's/^USER 65532/# root-ok: the entrypoint drops to postgres via gosu (ADR-0007)\nUSER root/' Dockerfile; t "declared root exception is reported, not failed" 0 'info  Dockerfile: final stage runs as root, declared acceptable' $K
good; sed -i.b 's/^USER 65532/USER root\nUSER 65532/' Dockerfile; t "last USER wins" 0 '!FAIL' $K
good; python3 - <<'PY'
s=open("Dockerfile").read(); s=s.replace("USER 65532\n","").replace("FROM node:22-slim","USER root\nFROM node:22-slim",1)
s=s.replace("RUN apt-get update","USER root\nRUN apt-get update",1)
open("Dockerfile","w").write(s)
PY
t "a root USER in an earlier stage does not excuse the final stage" 1 'no USER, or ends as root' $K
good; printf 'RUN curl -fsSL https://example.com/i.sh | sh\n' >> Dockerfile; t "curl | sh" 1 'pipes a download into a shell' $K
good; printf 'RUN wget -qO- https://example.com/i.sh | bash -s -- -y\n' >> Dockerfile; t "wget | bash" 1 'pipes a download into a shell' $K
good; printf 'RUN curl -fsSL https://example.com/i.sh | sudo sh\n' >> Dockerfile; t "curl | sudo sh" 1 'pipes a download' $K
good; printf 'RUN sh -c "$(curl -fsSL https://example.com/i.sh)"\n' >> Dockerfile; t 'sh -c "$(curl ...)"' 1 'pipes a download' $K
good; printf 'RUN curl -fsSL -o /tmp/x https://example.com/x && chmod +x /tmp/x\n' >> Dockerfile; t "download with no checksum" 1 'no checksum or signature check' $K
good; printf '# unverified-ok: fixture data, not executed\nRUN curl -fsSL -o /tmp/x https://example.com/x\n' >> Dockerfile; t "waived unverified download" 0 'info  .*waived' $K
good; printf 'RUN curl -fsSL -o /tmp/x https://example.com/x \\\n && echo "abc  /tmp/x" | sha256sum -c -\n' >> Dockerfile; t "checksum on a continuation line counts" 0 '!FAIL' $K
good; printf 'RUN curl -fsSL -o /tmp/x.asc https://example.com/x.asc && gpg --verify /tmp/x.asc /tmp/x\n' >> Dockerfile; t "gpg --verify counts" 0 '!FAIL' $K
good; printf 'RUN apt-get update && apt-get install -y curl\n' >> Dockerfile; t "apt-get install without --no-install-recommends" 1 'without --no-install-recommends' $K
good; printf '# a comment mentioning curl | sh in prose\nRUN echo ok\n' >> Dockerfile; t "a comment about curl | sh is not a hit" 0 '!FAIL' $K
good; printf 'RUN echo a \\\n  # inner comment\n  && curl -fsSL https://example.com/i.sh | sh\n' >> Dockerfile; t "continuation with an inner comment still scanned" 1 'pipes a download' $K
rm -f Dockerfile*; t "no Containerfile -> 2" 2 'nothing was checked' $K
good; rm .dockerignore; t "no .dockerignore" 1 'no .dockerignore' $K; printf '.git\n' > .dockerignore; t ".dockerignore without .env" 1 'no .dockerignore' $K; printf '.git\n.env\n' > .containerignore; rm .dockerignore; t ".containerignore accepted" 0 '!FAIL' $K; rm .containerignore; printf '.git\n.env\n' > .dockerignore
rm lefthook.yml; t "hadolint not wired" 1 'hadolint appears in no' $K; printf 'x: hadolint\n' > .github/workflows/lint.yml; t "hadolint in CI counts" 0 '!hadolint appears' $K; rm .github/workflows/lint.yml; printf 'pre-push:\n  commands:\n    lint:\n      run: hadolint Dockerfile\n' > lefthook.yml
rm .grype.yaml; t "no .grype.yaml" 1 '.grype.yaml is missing' $K; printf 'fail-on-severity: "high"\n' > .grype.yaml
rm .github/workflows/scan.yml; t "grype not in CI" 1 'grype appears in no CI' $K; printf 'jobs:\n  s:\n    steps:\n      - run: grype oci-archive:img.tar\n' > .github/workflows/scan.yml
printf 'updates:\n  - package-ecosystem: "npm"\n' > .github/dependabot.yml; t "dependabot without docker" 1 'no docker ecosystem' $K; rm .github/dependabot.yml; t "no dependabot.yml: not required here" 0 '!dependabot' $K
mkdir -p build; cp Dockerfile build/Containerfile.prod; t "second file under build/ is checked too" 0 'build/Containerfile.prod' $K; sed -i.b 's/^USER 65532/USER root/' build/Containerfile.prod; t "...and fails on its own" 1 'build/Containerfile.prod: the final stage' $K
cd /; rm -rf "$T"; echo "failures: $fails"; exit $fails
