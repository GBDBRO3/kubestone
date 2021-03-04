# Build the manager binary
FROM golang:1.12.5 as builder

WORKDIR /workspace

# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

# Copy the go source
COPY api/ api/
COPY controllers/ controllers/
COPY pkg/ pkg/
COPY hack/ hack/
COPY Makefile Makefile
COPY main.go main.go

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on make manager

# Create final image
FROM alpine:3.13.2
RUN apk update && apk upgrade && \
addgroup -S kubestone && adduser -S kubestone -G kubestone && \
mkdir /kubestone && \
chown -R kubestone:kubestone /kubestone && \
chmod -R g=u /kubestone
WORKDIR /
COPY --from=builder /workspace/bin/manager .
USER 1001
ENTRYPOINT ["/manager"]
