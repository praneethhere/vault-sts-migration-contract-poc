.PHONY: phase1-test phase1-cleanup phase2-e2e phase2-cleanup

phase1-test:
	cd phase1-vault-contract && $(MAKE) cleanup || true
	cd phase1-vault-contract && $(MAKE) start
	cd phase1-vault-contract && $(MAKE) configure
	cd phase1-vault-contract && $(MAKE) test

phase1-cleanup:
	cd phase1-vault-contract && $(MAKE) cleanup

phase2-e2e:
	./phase2-real-sts/scripts/90-run-real-sts-e2e.sh

phase2-cleanup:
	./phase2-real-sts/scripts/99-cleanup-real-sts.sh
