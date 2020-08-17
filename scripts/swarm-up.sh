#!/bin/bash
#shellcheck disable=SC2046,SC2086,SC2006

set -e

# Local Docker Swarm for testing with 1 manager and 3 workers
MANAGERS=1
WORKERS=3

VBOX_MEMORY=${VBOX_MEMORY:-1024}
VBOX_CPUS=${VBOX_CPUS:-1}
VBOX_HOST_CIDR=${VBOX_HOST_CIDR:-"192.168.128.1/24"}

OVERLAY_SUBNET="172.20.0.0/16"

info() {
  tput setaf 4; echo "Info> $*" && tput sgr0
}

warn() {
  tput setaf 3; echo "Warn> $*" && tput sgr0
}

err() {
  tput setaf 1; echo "Error> $*" && tput sgr0
  exit 1
}

info "Creating Docker host machine for managers"
for i in $(seq 1 "${MANAGERS}"); do
  node=node-m$i
  docker-machine create -d virtualbox \
    --virtualbox-hostonly-cidr ${VBOX_HOST_CIDR} \
    --virtualbox-memory ${VBOX_MEMORY} \
    --virtualbox-cpu-count ${VBOX_CPUS} \
    $node

  echo "ifconfig eth1 192.168.128.10$i netmask 255.255.255.0 broadcast 192.168.128.255 up;" \
    | docker-machine ssh $node sudo tee /var/lib/boot2docker/bootsync.sh > /dev/null
  echo "sleep 5;" \
    | docker-machine ssh $node sudo tee -a /var/lib/boot2docker/bootsync.sh > /dev/null
  echo "kill \$(cat /var/run/udhcpc.eth1.pid)" \
    | docker-machine ssh $node sudo tee -a /var/lib/boot2docker/bootsync.sh > /dev/null

  info "Copying CA cert"
  docker-machine scp certs/ca/ca-cert.pem $node:~/ca.pem
  docker-machine ssh $node sudo mkdir -p /var/lib/boot2docker/certs/
  docker-machine ssh $node sudo mv ca.pem /var/lib/boot2docker/certs/

  info "Restarting $node"
  docker-machine stop $node
  docker-machine start $node
  docker-machine regenerate-certs $node -f
done


MANAGER_IP=$(docker-machine ip node-m1)

info "Creating Docker host machine for workers"
for i in $(seq 1 "${WORKERS}"); do
  node=node-w$i
  docker-machine create -d virtualbox \
    --virtualbox-hostonly-cidr ${VBOX_HOST_CIDR} \
    --virtualbox-memory ${VBOX_MEMORY} \
    --virtualbox-cpu-count ${VBOX_CPUS} \
    $node

  echo "ifconfig eth1 192.168.128.10$((i + 2)) netmask 255.255.255.0 broadcast 192.168.128.255 up" \
    | docker-machine ssh $node sudo tee /var/lib/boot2docker/bootsync.sh > /dev/null
  echo "sleep 5;" \
    | docker-machine ssh $node sudo tee -a /var/lib/boot2docker/bootsync.sh > /dev/null
  echo "kill \$(cat /var/run/udhcpc.eth1.pid)" \
    | docker-machine ssh $node sudo tee -a /var/lib/boot2docker/bootsync.sh > /dev/null

  info "Copying CA cert"
  docker-machine scp certs/ca/ca-cert.pem $node:~/ca.pem
  docker-machine ssh $node sudo mkdir -p /var/lib/boot2docker/certs/
  docker-machine ssh $node sudo mv ca.pem /var/lib/boot2docker/certs/

  info "Restarting $node"
  docker-machine stop $node
  docker-machine start $node
  docker-machine regenerate-certs $node -f
done

MANAGER_IP=$(docker-machine ip node-m1)

info "Initializing Swarm"
eval $(docker-machine env node-m1)
docker-machine ssh node-m1 docker swarm init --advertise-addr=$MANAGER_IP

MANAGER_TOKEN=$(docker swarm join-token -q manager)
WORKER_TOKEN=$(docker swarm join-token -q worker)

info "Join as managers"
for i in $(seq 2 "${MANAGERS}"); do
  node=node-m$i
  eval $(docker-machine env $node)
  docker-machine ssh $node docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377
done

info "Join as workers"
for i in $(seq 1 "${WORKERS}"); do
  node=node-w$i
  eval $(docker-machine env $node)
  docker-machine ssh $node docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
done

info "Creating overlay network"
eval $(docker-machine env node-m1)
docker network create --driver overlay --subnet=${OVERLAY_SUBNET} --attachable overnet

info "Adding labels for each node"
docker node update --label-add worker=01 node-w1
docker node update --label-add worker=02 node-w2
docker node update --label-add worker=03 node-w3

info "Update /etc/hosts in managers"
for i in $(seq "${MANAGERS}"); do
  node=node-m$i
  echo "192.168.128.101 docker.local" \
    | docker-machine ssh $node sudo tee -a /etc/hosts > /dev/null
done

info "Update /etc/hosts in workers"
for i in $(seq "${WORKERS}"); do
  node=node-w$i
  echo "192.168.128.101 docker.local" \
    | docker-machine ssh $node sudo tee -a /etc/hosts > /dev/null
done

info "Increasing the limits on mmap"
# https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
for i in $(seq "${WORKERS}"); do
  docker-machine ssh node-w${i} sudo sysctl -w vm.max_map_count=1048575
done

info ">> The Swarm Cluster is set up!"
