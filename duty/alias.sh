#!/bin/bash

BUILDER="docker.quncrm.com/maiscrm/omnisocials-frontend-builder"
#运行docker-grunt时应该在本地项目目录/omnisocials-frontend/src下运行
#这样${pwd}挂在到容器内的/srv/omnisocials-frontend/src下，运行grunt才能找到node_modules
function docker_alias() {
  docker run -it --rm \
      --network omnisocials_default \
      -v $(pwd):$1 -w $1 \
      ${@:2}
}

# JavaScript
alias docker-node="docker_alias /srv/omnisocials-frontend/src $BUILDER node"
alias docker-npm="docker_alias /srv/omnisocials-frontend/src $BUILDER npm"
alias docker-grunt="docker_alias /srv/omnisocials-frontend/src $BUILDER grunt"

# PHP
alias docker-php="docker_alias /srv/omnisocials-frontend/src $BUILDER php"