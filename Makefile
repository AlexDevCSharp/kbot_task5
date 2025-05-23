APP := kbot
NAMESPACE := alexdevcsharp
REGISTRY = quay.io/${NAMESPACE}
VERSION := $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

TARGETOS ?= linux
TARGETARCH ?= amd64
PLATFORM ?= ${TARGETOS}/${TARGETARCH}
IMAGE_TAG := ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

PLATFORMS := linux/amd64 linux/arm64

.PHONY: all format get lint test build build-linux build-arm build-windows \
        linux arm docker-build docker-push docker-test clean


format:
	gofmt -s -w ./

get:
	go get

lint:
	golint

test:
	go test -v ./...


build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}"

build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o kbot -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}"

build-arm:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -o kbot -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}"

build-windows:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -v -o kbot.exe -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}"


linux:
	docker buildx build \
		--platform linux/amd64 \
		--build-arg TARGETOS=linux \
		--build-arg TARGETARCH=amd64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:linux-amd64 .

arm:
	docker buildx build \
		--platform linux/arm64 \
		--build-arg TARGETOS=linux \
		--build-arg TARGETARCH=arm64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:linux-arm64 .


docker-build:
	docker buildx build \
		--platform ${PLATFORMS} \
		--build-arg TARGETOS=linux \
		--build-arg TARGETARCH=amd64 \
		--tag ${REGISTRY}/${APP}:multi \
		--push .

docker-push:
	docker push ${REGISTRY}/${APP}:multi

docker-test-linux-arm:
	docker buildx build \
		--target test \
		--platform linux/arm64 \
		--tag ${REGISTRY}/${APP}:test-linux-arm64 \
		--load .
	docker run --rm ${REGISTRY}/${APP}:test-linux-arm64


clean:
	rm -f kbot kbot.exe
	-docker rmi ${IMAGE_TAG} || true
	-docker rmi ${REGISTRY}/${APP}:linux-amd64 || true
	-docker rmi ${REGISTRY}/${APP}:linux-arm64 || true
	-docker rmi ${REGISTRY}/${APP}:multi || true
	-docker rmi ${REGISTRY}/${APP}:test-linux-arm64 || true
