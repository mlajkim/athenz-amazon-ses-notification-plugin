.PHONY: all deploy

all: deploy

deploy:
	@./hack/deploy.sh

create-aws-ses-secret:
	@./hack/create-aws-ses-secret.sh

patch:
	@./hack/patch-zms.sh

check:
	@./hack/check-jar-in-athenz-zms.sh

test:
	@./hack/test-cause-athenz-notification.sh

help:
	@echo "Available commands:"
	@echo "  make deploy                - Build jar and deploy to current k8s cluster as config file"
	@echo "  make create-aws-ses-secret - Create Kubernetes secret for AWS SES SMTP credentials"
	@echo "  make patch                 - Modify ZMS deployment to use the jar created (idempotent)"
	@echo "  make check                 - Check if the jar is present in Athenz ZMS pod"
	@echo "  make test                  - Trigger a test notification to verify setup"
