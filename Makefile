.PHONY: dependencies clean lint fmt syntax-check

all: dependencies

# clean removes and re-initializes the directories that have their contents
# ignored by git. This will force a re-installation of the requirements, roles,
# etc.
clean:
	rm -rf my-logs
	mkdir my-logs
	touch my-logs/.empty-file
	rm -rf ansible_collections
	rm -rf roles

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

# syntax-check statically checks the syntax for all the playbooks in playbooks
# directory
syntax-check:
	for f in $$(ls ./playbooks); do \
		if ! [ -d ./playbooks/$$f ]; \
		then \
			./scripts/syntax-check.sh ./playbooks/$$f || exit 1; \
		fi \
	done
