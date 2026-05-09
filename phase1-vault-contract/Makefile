.PHONY: start configure test negative cutover cleanup

start:
	./scripts/00-start.sh

configure:
	./scripts/01-configure-vault.sh

test:
	./scripts/02-test-success.sh
	./scripts/03-test-negative.sh

negative:
	./scripts/03-test-negative.sh

cutover:
	./scripts/04-test-cutover.sh

cleanup:
	./scripts/99-cleanup.sh
