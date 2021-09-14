all: lint

# Running ansible-lint in a docker file
# -p for parsable output
# -q for quieter output
lint:
	docker run -h toolset -it quay.io/ansible/toolset ansible-lint -p -q $(files) 

.PHONY: lint