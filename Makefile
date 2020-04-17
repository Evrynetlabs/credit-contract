.PHONY: lint
.PHONY: test
.PHONY: test-coverage

lint:
	yarn run solhint

test: 
	yarn run test

test-coverage:
	yarn run test-coverage