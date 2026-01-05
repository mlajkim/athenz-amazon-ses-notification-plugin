.PHONY: all deploy

all: deploy

deploy:
	@./hack/deploy.sh

patch:
	@./hack/patch-zms.sh

create-aws-ses-secret:
	@./hack/create-aws-ses-secret.sh

check:
	@./hack/check-jar-in-athenz-zms.sh