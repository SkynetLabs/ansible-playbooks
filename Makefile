.PHONY: lint fmt

all: dependencies

dependencies:
	pip install yamllint

# yamlfix is a helper tool that will fix common yaml errors. If we can enable it
# that would help ensure code standards but we need tests first to ensure the
# updates don't break things. Until then we need to address the lint errors
# manually.
#
# https://lyz-code.github.io/yamlfix/
#	pip install yamlfix
#fmt:
#	yamlfix .

# https://yamllint.readthedocs.io/
lint:
	yamllint --no-warnings .
