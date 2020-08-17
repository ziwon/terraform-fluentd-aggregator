include .envrc
export

define docker-env
$(foreach val, $(shell docker-machine env $1 | sed -e '/^#/d' -e 's/"//g'), $(eval $(val)))
endef

define get-node-ip
$(shell docker-machine ip $1)
endef

PHONY: node-gen-cert
node-gen-cert: # Generate SSL certification: # make node-gen-cert
	./scripts/gen-cert.sh

PHONY: node-add-cert
node-add-cert: # Add certification into the local machine: # make node-add-cert
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./certs/ca/ca-cert.pem

node-env:
	$(call docker-env, $(SWARM_MASTER))

PHONY: node-up
node-up: node-env # Bootstrap swarm nodes: # make node-up
	./scripts/swarm-up.sh

PHONY: node-down
node-down: node-env # Terminate swarm nodes: # make node-down
	docker-machine ls --format '{{.Name}}' | xargs -I {} docker-machine rm -f -y {} 2>/dev/null

PHONY: node-cleanup
node-cleanup: node-env # Clean up the docker volume: # make node-cleanup
	for node in $$(docker node ls --format '{{.Hostname}}'); do \
		echo "Cleaning up $$node volume"; \
		if [[ ! -z $$node ]]; then \
			eval $$(docker-machine env $$node); \
			docker-machine ssh $$node sh -c "docker volume prune > /dev/null 2>&1"; \
			sleep 1; \
			yes | docker volume prune; \
		fi \
	done

PHONY: node-list
node-list: node-env # Show node list: # make node-list
	docker node ls -q | xargs docker node inspect \
		-f '{{ .ID }} [{{ .Description.Hostname }}]: {{ range $$k, $$v := .Spec.Labels }}{{ $$k }}={{ $$v }} {{end}}'

#PHONY: node-br-net
#node-br-net: node-env # Create a bridge network: # make node-br-net
	#docker network create \
		#--config-only \
		#--driver=bridge \
		#--ipam-driver=default \
		#--subnet=172.20.1.0/24 \
		#--ip-range=172.20.1.0/24 \
		#--gateway=172.20.1.254 \
		#config_overnet
	#docker network create \
		#-d bridge --attachable \
		#--scope swarm \
		#--config-from \
		#config_overnet \
		#overnet

PHONY: node-ip
node-ip: node-env # Show the address of node: # make node-ip
	docker node inspect self --format '{{ .Status.Addr  }}'

PHONY: stack-start
stack-start: node-env # Start the stack onto swarm: # make stack-start
	docker stack deploy -c docker-compose.yml $(STACK_NAME)

PHONY: stack-service
stack-service: node-env # List stack services: # make stack-service
	watch docker stack services $(STACK_NAME)

PHONY: stack-ps
stack-ps: node-env # List stack process: # make stack-ps
	watch docker stack ps --no-trunc $(STACK_NAME)

PHONY: stack-viz
stack-viz: # Visualize the swarm stack: # make stack-viz
	open http://$(call get-node-ip, $(SWARM_MASTER))/viz

PHONY: stack-exec
ifeq (stack-exec,$(firstword $(MAKECMDGOALS)))
 SERVICE:=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
 $(eval $(SERVICE):;@:)
endif
stack-exec: # Get executed the given command into container: # make stack-exec sh
	./scripts/swarm-exec.sh $(STACK_NAME) $(SERVICE)

PHONY: stack-logs
ifeq (stack-logs,$(firstword $(MAKECMDGOALS)))
 SERVICE:=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
 $(eval $(SERVICE):;@:)
endif
stack-logs: node-env # Show logs from the service: # make stack-logs elasticsearch
	docker service logs -f $(STACK_NAME)_$(SERVICE)

PHONY: stack-stop
stack-stop: node-env # Remove the stack from swarm: # make stack-stop
	docker stack rm $(STACK_NAME);

PHONY: stack-reload
stack-reload: # Reload the stack from swarm: # make stack-reload
	make stack-stop && make node-cleanup && make stack-start
