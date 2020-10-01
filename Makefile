# SHELL := /bin/bash

RELEASE := sonarqube
NAMESPACE := sonarqube

CHART_NAME := oteemocharts/sonarqube
CHART_VERSION ?= 6.8.0

DEV_CLUSTER ?= p4-development
DEV_PROJECT ?= planet-4-151612
DEV_ZONE ?= us-central1-a

.DEFAULT_TARGET: status

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint
	@circleci config validate

init:
	helm init --client-only
	helm repo add oteemo https://oteemo.github.io/charts/
	helm repo update

deploy: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	-kubectl create namespace $(NAMESPACE)
	@helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)
	$(MAKE) history

destroy:
	helm delete --purge $(RELEASE)
	-kubectl delete namespace $(NAMESPACE)

history:
	helm history $(RELEASE) --max=5
