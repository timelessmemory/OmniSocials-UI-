#!/bin/bash -e

### VARIABLES

WORKSPACE=${WORKSPACE:-$(pwd)}
ENV=${ENV:-"local"}
GRUNT_INIT_TASK=${GRUNT_INIT_TASK:-"build"}
BUILDER_IMAGE="docker.quncrm.com/maiscrm/omnisocials-frontend-builder"
DEFAULT_USER=${DEFAULT_USER:-"xxxxxx@qq.com"}
FRONTEND_BRANCH=${FRONTEND_BRANCH:-"develop"}
BACKEND_BRANCH=${BACKEND_BRANCH:-"develop"}
LN_TO_SRV=${LN_TO_SRV:-"true"}

opts="init up start create_default_user dev"

### FUNCTIONS

ln_to_srv() {
  echo "=============================================="
  echo "link omnisocials-frontend and omnisocials-backend to /srv/ "
  echo "=============================================="
  sudo rm -rf /srv/omnisocials-frontend /srv/omnisocials-backend
  sudo ln -s $WORKSPACE/omnisocials-frontend /srv/
  sudo ln -s $WORKSPACE/omnisocials-backend /srv/
}

clone_code() {
  echo "=============================================="
  echo "clone project, FRONTEND_BRANCH: $FRONTEND_BRANCH BACKEND_BRANCH: $BACKEND_BRANCH"
  echo "=============================================="
  [ ! -e $WORKSPACE/omnisocials-frontend ] && git clone git@git.augmentum.com.cn:scrm/omnisocials-frontend.git -b $FRONTEND_BRANCH
  [ ! -e $WORKSPACE/omnisocials-backend ] && git clone git@git.augmentum.com.cn:scrm/omnisocials-backend.git -b $BACKEND_BRANCH
}

copy_node_modules() {
  echo "=============================================="
  echo "copy node_modules start, cost a little time.  "
  echo "=============================================="

  CONTAINER_ID=$(docker create $BUILDER_IMAGE)
  [ ! -e $WORKSPACE/omnisocials-frontend/src/node_modules ] && \
    docker cp $CONTAINER_ID:/app/src/node_modules $WORKSPACE/omnisocials-frontend/src/node_modules
  [ ! -e $WORKSPACE/omnisocials-backend/src/node_modules ] && \
    docker cp $CONTAINER_ID:/app/src/node_modules $WORKSPACE/omnisocials-backend/src/node_modules
  docker rm -f $CONTAINER_ID
  echo "copy node_modules done."
}

init_project_env() {
  echo "=============================================="
  echo "init project. env: $ENV                       "
  echo "=============================================="
  PROJECTS="omnisocials-backend omnisocials-frontend"

  for PROJECT in $PROJECTS; do
    echo "Init $PROJECT start."
    docker run --rm -v $WORKSPACE/$PROJECT:/srv/$PROJECT -v ~/.ssh:/root/.ssh -w /srv/$PROJECT/src $BUILDER_IMAGE \
      bash -c "php init --env=$ENV && ./yii module/init-dev && (cd .. && node updateModules.js) && grunt linkmodule"
    echo "Init $PROJECT done."
  done
}

build_frontend() {
  echo "=============================================="
  echo "build frontend                                "
  echo "=============================================="
  docker run -it --rm \
    -v $WORKSPACE/omnisocials-frontend/src:/srv/omnisocials-frontend/src \
    -w /srv/omnisocials-frontend/src $BUILDER_IMAGE \
    bash -c "grunt build"
}

check_init() {
  if [ ! -d "$WORKSPACE/omnisocials-frontend" ] || [ ! -d "$WORKSPACE/omnisocials-backend" ]; then
    echo "can't find omnisocials-frontend and omnisocials-backend, run './build.sh init'"
    init
  fi
}

start_server() {
  echo "=============================================="
  echo "start server                                  "
  echo "=============================================="
  check_init

  halt

  docker-compose pull
  docker-compose up -d --build
  echo "project start success, you can vist: http://wm.com"
}

create_default_user() {
  echo "create default user: $DEFAULT_USER, abc123_"
  docker exec omnisocials-backend \
    bash -c "./src/yii management/account/generate-by-email $DEFAULT_USER"
}

fix_dir() {
  echo "=============================================="
  echo "fix dir                                       "
  echo "=============================================="
  DIRS="log/redis data/redis log/mongodb data/mongodb log/worker"
  for DIR in $DIRS; do
    [ ! -e $WORKSPACE/$DIR ] && mkdir -p $WORKSPACE/$DIR
    echo "chmod $DIR to 777"
    sudo chmod -R 777 $WORKSPACE/$DIR
  done

  echo "=============================================="
  echo "chown -R $(id -u):$(id -g) $WORKSPACE/omnisocials-frontend $WORKSPACE/omnisocials-backend"
  echo "=============================================="
  sudo chown -R $(id -u):$(id -g) $WORKSPACE/omnisocials-frontend $WORKSPACE/omnisocials-backend
}

up() {
  start_server
  build_frontend
  echo "project start success"
}

halt() {
  echo "=============================================="
  echo "stop server                                   "
  echo "=============================================="
  
  echo "exit omnisocials-ssh"
  docker rm -f $(docker ps -a --format={{.Names}} | grep omnisocials-ssh) 2> /dev/null || true

  docker-compose down --remove-orphans
}

init() {
  echo "=============================================="
  echo "init project                                  "
  echo "=============================================="
  clone_code
  copy_node_modules
  init_project_env
  fix_dir
  [ -n $LN_TO_SRV ] && ln_to_srv
  echo "=========================================================="
  echo "init project success. you can run: ./build.sh up"
  echo "=========================================================="
}

ssh() {
  echo "=============================================="
  echo "Enter development mode  (${@:1})              "
  echo "=============================================="
  ip=`docker inspect --format '{{ .NetworkSettings.Networks.omnisocials_default.IPAddress }}'  omnisocials-webserver`
  docker run -it --rm \
    -v $WORKSPACE:/srv \
    -v ~/.ssh:/root/.ssh \
    --name omnisocials-ssh \
    ${@:1} \
    --add-host ajax.wm.com:$ip \
    --add-host wm.com:$ip \
    --network omnisocials_default \
    -w /srv $BUILDER_IMAGE \
    bash
}

usage() {
  echo "USAGE: $0" option key

  echo -e "\nOptions:"
  for opt in $opts; do
    echo "    ${opt}"
  done

  echo -e "\nKeys from config.yaml:"
  for key in $keys; do
    echo "    ${key}"
  done
  echo ""
  exit 1
}

#-------------------------------------------------------------------------------
case "$1" in
  init)
    init
    ;;
  build)
  build_frontend
  ;;
  up)
    up
    ;;
  start)
    start_server
    ;;
  stop)
    halt
    ;;
  create_default_user)
    create_default_user
    ;;
  fix_dir)
    fix_dir
    ;;
  ssh)
    ssh ${@:2}
    ;;
  ln_to_srv)
    ln_to_srv
    ;;
  check)
    check_init
    ;;
  *)
    usage
    ;;
esac
