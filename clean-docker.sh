#!/bin/bash
#Script para limpeza de imagens docker sem uso
#Altera o $path de acordo com o seu grupo dentro da registry

$path=/prod

docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
docker rmi $(docker images | grep "docker-registry.default.svc:5000/$path" | awk '{print $3}')
