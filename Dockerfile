FROM quay.io/projectquay/golang:1.21 AS test
WORKDIR /app
COPY . .
RUN go test -v ./...

FROM quay.io/projectquay/golang:1.21 AS builder
WORKDIR /go/src/app
COPY . .
# Используем переменные окружения для кросс-компиляции
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=dev"

FROM alpine:latest AS certs
RUN apk --no-cache add ca-certificates

FROM scratch
WORKDIR /
COPY --from=builder /go/src/app/kbot .
# Только если это Linux-образ (не Windows)
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["./kbot"]
