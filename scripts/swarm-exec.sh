#!/bin/bash
# https://stackoverflow.com/questions/39362363/execute-a-command-within-docker-swarm-service
#
set -e

exec_task=$1
exec_instance=$2

strindex() {
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

parse_node() {
  read title
  id_start=0
  name_start=`strindex "$title" NAME`
  image_start=`strindex "$title" IMAGE`
  node_start=`strindex "$title" NODE`
  dstate_start=`strindex "$title" DESIRED`
  id_length=name_start
  name_length=`expr $image_start - $name_start`
  node_length=`expr $dstate_start - $node_start`

  read line
  id=${line:$id_start:$id_length}
  name=${line:$name_start:$name_length}
  name=$(echo $name)
  node=${line:$node_start:$node_length}
  echo $name.$id
  echo $node
}

if true; then
   read fn
   docker_fullname=$fn
   read nn
   docker_node=$nn
fi < <( docker service ps -f name="${exec_task}_${exec_instance}" --no-trunc -f desired-state=running "${exec_task}_${exec_instance}" | parse_node )

echo "Executing in $docker_node $docker_fullname"

shift 2

docker exec -ti $docker_fullname $@
