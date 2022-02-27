GO_VERSION := $(shell cat .go-version)
PROJECT=github.com/{{.repoName}}/{{.application.Name}}
COMMIT = $(shell git log --pretty=format:'%H' -n 1)
VERSION    = $(shell git describe --tags --always)
BUILD_DATE = $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS   = -ldflags "\
 -X github.com/{{.organization}}/{{.repoName}}/{{.application.Name}}.Commit=$(COMMIT) \
 -X github.com/{{.organization}}/{{.repoName}}/{{.application.Name}}.Version=$(VERSION) \
 -X github.com/{{.organization}}/{{.repoName}}/{{.application.Name}}.BuildDate=$(BUILD_DATE) \
 -X github.com/{{.organization}}/{{.repoName}}/{{.application.Name}}.Compiler=$(GOLANG_VERSION)"

# Go
GO  = GOFLAGS=-mod=vendor go
GOBUILD  = CGO_ENABLED=0 $(GO) build $(LDFLAGS)



   
.DEFAULT_GOAL := dev

.PHONY: ci
ci: ## CI build
ci: dev diff

.PHONy: setup
setup:
	sh scripts/setup.sh
	git add .pre-commit-config.yaml
	pre-commit install

.PHONY: dev
dev: ## dev build
dev: clean install fmt lint test mod-tidy

.PHONY: clean
clean: ## remove files created during build pipeline
	$(call print-target)
	rm -rf dist
	rm -f coverage.*

.PHONY: install
install: ## go install tools
	$(call print-target)
	cd tools && go install $(shell cd tools && go list -f '{{ join .Imports " " }}' -tags=tools)

.PHONY: fmt
fmt: ## go fmt
	$(call print-target)
	go fmt ./...

.PHONY: lint
lint: ## golangci-lint
	$(call print-target)
	golangci-lint run

.PHONY: test
test: ## go test with race detector and code covarage
	$(call print-target)
	go test -race -covermode=atomic -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

.PHONY: mod-tidy
mod-tidy: ## go mod tidy
	$(call print-target)
	go mod tidy
	cd tools && go mod tidy

.PHONY: diff
diff: ## git diff
	$(call print-target)
	git diff --exit-code
	RES=$$(git status --porcelain) ; if [ -n "$$RES" ]; then echo $$RES && exit 1 ; fi

.PHONY: build
build: ## goreleaser --snapshot --skip-publish --rm-dist
build: install
	$(call print-target)
	goreleaser --snapshot --skip-publish --rm-dist

.PHONY: release
release: ## goreleaser --rm-dist
release: install
	$(call print-target)
	goreleaser --rm-dist

.PHONY: run
run: ## go run
	@go run -race $(PROJECT)/cmd/{{.applcation.name}}

.PHONY: go-clean
go-clean: ## go clean build, test and modules caches
	$(call print-target)
	go clean -r -i -cache -testcache -modcache

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

define print-target
    @printf "Executing target: \033[36m$@\033[0m\n"
endef