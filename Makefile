.PHONY: fmt fmt-ci install-dev lint test

fmt:
	black . $(ARGS)

fmt-ci:
	black --check .

install-dev:
	pip3 install --user -r requirements_dev.txt

lint:
	flake8 .

test:
	pytest -s -vv .
