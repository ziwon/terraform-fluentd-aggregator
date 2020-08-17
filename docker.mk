GIT_VERSION := $(shell echo $(shell git describe --tags --always) | sed 's/^v//')
GIT_COMMIT := $(shell git log -1 --format='%H')

PHONY: docker-build
ifeq (docker-build,$(firstword $(MAKECMDGOALS)))
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif
docker-build: # Build docker image: # make docker-build
	docker build --force-rm -t $(APP_NAME) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		--build-arg GIT_VERSION=$(GIT_VERSION) \
		.
	docker tag $(APP_NAME):$(TAG) $(ECR_IMAGE_URL):$(TAG)

PHONY: docker-tag
	docker tag $(APP_NAME):$(TAG) $(ECR_IMAGE_URL):$(TAG)

PHONY: docker-history
docker-history: # Show the history of an image: # make docker-history
	docker history --human --format "{{.CreatedBy}}: {{.Size}}" $(APP_NAME)

PHONY: docker-commit
docker-commit: # Commit current container using killed tag: # make docker-commit
	docker commit $(shell docker inspect --format="{{.Id}}" $(PROJECT_NAME)-$(APP_NAME)) $(APP_NAME):killed

PHONY: docker-run
docker-run: # Run a command in a new container: # make docker-run
	docker run --rm -it --name $(PROJECT_NAME)-$(APP_NAME) \
		-p 24224:24224 \
		-p 24220:24220 \
		-p 24230:24230 \
		$(APP_NAME)

PHONY: docker-push
docker-push: # Push an image to Amazon ECR registry: # make docker-push
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_IMAGE_URL)
	docker push $(ECR_IMAGE_URL):$(TAG)
