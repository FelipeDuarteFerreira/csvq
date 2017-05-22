BINARY=csvq
VERSION=$(shell git describe --tags --always)

SOURCEDIR=.
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')

LDFLAGS := -ldflags="-X main.version=$(VERSION)"

DIST_DIRS := find * -type d -exec

.DEFAULT_GOAL: $(BINARY)

$(BINARY): $(SOURCES)
	go build $(LDFLAGS) -o $(BINARY)

.PHONY: deps
deps: glide
	glide install

.PHONY: install
install:
	go install $(LDFLAGS)

.PHONY: glide
glide:
ifeq ($(shell command -v glide 2>/dev/null),)
	curl https://glide.sh/get | sh
endif

.PHONY: test
test:
	go test -cover `glide novendor`

.PHONY: test-all-cov
test-all-cov:
	echo "" > coverage.txt
	for d in `go list ./... | grep -v vendor`; do \
		go test -coverprofile=profile.out -covermode=atomic $$d; \
		if [ -f profile.out ]; then \
			cat profile.out >> coverage.txt; \
			rm profile.out; \
		fi; \
	done

.PHONY: clean
clean:
	if [ -f $(BINARY) ]; then rm $(BINARY); fi

.PHONY: gox
gox:
ifeq ($(shell command -v gox 2>/dev/null),)
	go get github.com/mitchellh/gox
endif

.PHONY: build-all
build-all: gox
	gox -output="dist/{{.OS}}-{{.Arch}}/{{.Dir}}"

.PHONY: dist
dist:
	cd dist && \
	$(DIST_DIRS) cp ../LICENSE {} \; && \
	$(DIST_DIRS) cp ../README.md {} \; && \
	$(DIST_DIRS) tar -zcf ${BINARY}-${VERSION}-{}.tar.gz {} \; && \
	$(DIST_DIRS) zip -r ${BINARY}-${VERSION}-{}.zip {} \; && \
	cd ..

.PHONY: release
release:
ifeq ($(shell git describe --tags 2>/dev/null),)
	$(error HEAD commit is not tagged)
else
	git push origin $(VERSION)
endif
