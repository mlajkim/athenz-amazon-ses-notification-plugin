.PHONY: all deploy

all: deploy

deploy:
	@./hack/deploy.sh

check:
	@./hack/check-jar-in-athenz-zms.sh