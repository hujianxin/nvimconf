.PHONY: install-hooks

install-hooks:
	ln -sf $(PWD)/scripts/pre-commit .git/hooks/pre-commit
