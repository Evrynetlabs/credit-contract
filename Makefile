.PHONY: lint
.PHONY: test
.PHONY: test-coverage

lint:
	yarn run lint

test: 
	yarn run test

test-coverage:
	yarn run test-coverage