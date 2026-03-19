.PHONY: build test integration-test run clean

NIM_FLAGS ?= --hints:off --warnings:off

build: together

together: src/together.nim
	nim c -o:together -d:release -d:withAudio src/together.nim

test:
	@files=$$(ls tests/test_*.nim 2>/dev/null); \
	if [ -z "$$files" ]; then \
		echo "No unit tests found in tests/test_*.nim"; \
		exit 0; \
	fi; \
	fail=0; \
	for f in $$files; do \
		echo "--- $$f ---"; \
		nim r $(NIM_FLAGS) "$$f" || fail=1; \
	done; \
	exit $$fail

integration-test:
	@files=$$(ls tests/integration_*.nim 2>/dev/null); \
	if [ -z "$$files" ]; then \
		echo "No integration tests found in tests/integration_*.nim"; \
		exit 0; \
	fi; \
	fail=0; \
	for f in $$files; do \
		echo "--- $$f ---"; \
		nim r $(NIM_FLAGS) "$$f" || fail=1; \
	done; \
	exit $$fail

run: build
	./together

clean:
	rm -f together
	rm -rf nimcache
