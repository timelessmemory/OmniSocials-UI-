# 快速入门

## 安装 docker 环境

本地通过镜像安装 `docker`, `docker-machine` 和 `docker-compose`：

```
curl -sSL https://cdn.quncrm.com/docker.sh | sudo sh
```

## 本地添加 host(/etc/hosts)

```
127.0.0.1 wm.com
127.0.0.1 ajax.wm.com
192.168.161.58 docker.quncrm.com
```

## 删掉本地的nginx

```
sudo apt-get remove nginx
sudo apt-get autoremove
```

## Clone项目

```
git clone git@git.augmentum.com.cn:scrm/omnisocials.git
```

## 初始化项目

```bash
# 获取 develop 分支代码, 更新子模块, 初始化 local
./build.sh init

# 使用 docker 启动项目(php, mongo, redis, nginx)并在 omnisocials-frontend/src 下面执行 `grunt build`
./build.sh up
```

## 本地Mongodb数据迁移或者新建用户

### Mongodb数据迁移

```bash
mongodump -h 127.0.0.1 -o /tmp/mongodb
mongorestore --port 26017 -u admin -p Abc123__ /tmp/mongodb
```

### 创建用户 test@wm.com

```bash
DEFAULT_USER=test@wm.com ./build.sh create_default_user
```

## 添加快捷方式

添加 `[ -e <DIR>/omnisocials/alias.sh ] && source <DIR>/omnisocials/alias.sh` 到其中任意一个 (~/.bash_profile, ~/.zshrc, ~/.profile, or ~/.bashrc), 然后source这个文件。

例如，如果你添加到了 `~/.zshrc` 这个文件中，就运行 `source ~/.zshrc`。

之后你就可以使用 `docker` 镜像中暴露出来的 `docker-grunt`, `docker-php`, `docker-node`, `docker-npm` 命令来做代码的构建。

**DIR是你本地项目的路径**

## 访问项目

浏览器打开 http://wm.com

## 运行前端项目

```bash
docker-grunt
```

# 使用指南

## build.sh

### init

初始化项目

```bash
./build.sh init
```

执行以下步骤:

1. 目录 `omnisocials-frontend` 不存在则克隆 `http://git.augmentum.com.cn/scrm/omnisocials-frontend` 的 `develop` 分支的代码.

2. 目录 `omnisocials-backend` 不存在则克隆 `http://git.augmentum.com.cn/scrm/omnisocials-backend` 的 `develop` 分支的代码

3. 修复数据目录权限

4. 复制 `node_modules` 到 `omnisocials-frontend` 和 `omnisocials-backend` 的 `src` 目录中

5. 根据环境变量中的 `ENV` (默认是 `local`) 来执行

    ```bash
      php init --env=$ENV && ./yii module/init-dev && (cd .. && node updateModules.js) && grunt linkmodule
    ```

### start

重新启动 php-fpm, mongo, redis, nginx

```bash
./build.sh start
```

### stop

关闭 php-fpm, mongo, redis, nginx

```bash
./build.sh stop
```

### up

重新启动 php-fpm, mongo, redis, nginx, 并在 `omnisocials-frontend/src` 下执行一次 `grunt build`

```bash
./build.sh up
```

### create_default_user

创建用户

```bash
# 创建默认的用户 test@wm.com
DEFAULT_USER=test@wm.com ./build.sh create_default_user
```

### fix_dir

修复数据目录权限, 项目启动依赖于 `data/mongodb`, `data/redis`, `log/mongodb`, `log/redis` 为 `0777`, 如项目启动失败请尝试执行该命令.

```bash
./build.sh fix_dir
```

### ssh

进入开发模式(进入 docker 容器中, 类似进入一台 linux 系统), 在这个模式下你可以直接使用 `php`, `grunt`, `node`, `npm` 等命令, 此模式并不会暴露端口，如果需要额外权限需要通过参数开启。

```bash
./build.sh ssh

# 进入开发模式同时暴露 8081 端口到本机，之后可以通过本机的 8081 端口访问到容器内的 8081 端口
./build.sh ssh -p 8081:8081

```

## alias.sh

```
source ./alias.sh

docker-node -v
docker-npm -v
docker-grunt -v
docker-php -m
```

# FAQ

## 出现 `Cannot connect to the Docker daemon. Is the docker daemon running on this host?`

```bash
    sudo  echo "DOCKER_OPTS=\"\$DOCKER_OPTS --dns 114.114.114.114\"" | sudo tee -a /etc/default/docker
    sudo  echo "DOCKER_OPTS=\"\$DOCKER_OPTS --registry-mirror=https://ieao2zab.mirror.aliyuncs.com\"" | sudo tee -a /etc/default/docker
    sudo gpasswd -a ${USER} docker
    sudo service docker restart
    newgrp - docker
    ./build.sh init
    ./build.sh up
```

## 我怎么不能够 `debug php` 程序?

debug 需要开放 `php-fpm` 的 `9000` 端口. docker 并不会暴露容器中的端口到宿主机, 如需将 omnisocials-backend 的 9000 端口暴露出来请执行以下操作:

在 `docker-compose.yml` 的 `omnisocials-backend` 中加入 `ports: ["9001:9000"]`, 例:

```
  omnisocials-backend:
   ...省略部分代码
   ports:
    - 9001:9000
   links:
      - omnisocials-mongodb
      - omnisocials-redis
```

执行完毕后修改 debug 配置的端口为 `9001`

## 日志的路径在哪里, 怎么查看

- 服务日志:
    - omnisocials-mongodb: `log/mongodb`
    - omnisocials-redis: `log/reids`
    - omnisocials-nginx: `log/nginx`
    - omnisocials-backend: `omnisocials-backend/src/backend/runtime/logs`
    - omnisocials-frontend: `omnisocials-frontend/src/frontend/runtime/logs`
    
- docker 容器运行日志:
    -  docker logs -f omnisocials-mongodb
    -  docker logs -f omnisocials-redis
    -  docker logs -f omnisocials-nginx
    -  docker logs -f omnisocials-backend
    -  docker logs -f omnisocials-frontend


## 提示本地 `grunt` 找不到怎么办
    
```bash
    rm -rf omnisocials-backend/src/node_modules
    rm -rf omnisocials-frontend/src/node_modules
    ./build.sh init
    ./build.sh up
```

## 出错了通用型的解决办法

### 方法一： 更新至最新代码, 并重试

```
    # 关闭全部容器
    docker rm -f $(docker ps -aq)

    # 获取最新代码
    git pull
    
    # 初始化项目
    ./build.sh init
    
    # 启动项目
```

### 方法二: 重置项目
    
```bash
    # 删除
    sudo rm -rf omnisocials-backend omnisocials-frontend data log
    
    # 获取最新代码
    git pull
    
    # 初始化项目
    ./build.sh init
    
    # 启动项目
    ./build.sh up
```

## 我该如何在本地连接到我的数据库

### 方法一: 使用本地 mongo 客户端连接（如果连接失败可以尝试升级 mongo 至 `3.X` 或者使用方法二）

```bash
    # 连接 admin
    mongo admin --port 26017 -u admin -p Abc123__
    # 连接 wm
    mongo wm --port 26017 -u root -p root
```
        
### 方法二： 使用 docker 连接（需要在 `./build.sh up` 或 `./build.sh start` 执行成功后调用）

```bash
    # 连接 admin
    docker exec -it omnisocials-mongodb mongo admin -u admin -p Abc123__
    # 连接 wm
    docker exec -it omnisocials-mongodb mongo wm -u root -p root
```

## 出现错误 `cannot open xxx: Permission denied` 怎么解决

```bash
    sudo chown -R $(whoami):$(whoami) omnisocials-backend
    sudo chown -R $(whoami):$(whoami) omnisocials-frontend
```

## 出现错误 `Error starting userland proxy: listen tcp 0.0.0.0:XX: bind: address already in use`

出现这个错误请检查端口占用， 关闭占用程序，并重新 `./build.sh start` 如：

```bash
# nginx 占用 `80` 端口
sudo service nginx stop
```

## 使用 `docker-npm run h5dev` 怎么不能够通过 `8081` 端口访问

- 方法一（推荐）
    ```bash
        # 1. 进入开发模式并暴露 8081 端口， ssh 用法参照上面 ./build.sh ssh 使用部分
        ./build.sh ssh -p 8081:8081
    
        # 2. 进入容器中 /srv/omnisocials-frontend/src 目录
        cd omnisocials-frontend/src/
    
        npm run h5dev
    ```
- 方法二
    - 修改 `alias.sh` 中 `docker run -it --rm \` 改为 `docker run -it --rm -p 8080:8081 \`
    - `source ./alias.sh`
    - `docker-npm run h5dev`

## 前后台分离后我该怎么设置 `nginx` 使用 `ip` 在手机端去访问

前后台分离后都是绑定 80 端口然后通过不同的域名来分别访问 `omnisocials-backend` 和 `omnisocials-backend`， 暂不支持 ip 直接访问项目
解决办法: 在本机设置一个代理服务器， 然后手机连接代理，所有手机请求将经过本机转发并共享本机 `hosts` 配置

1. 设置本机代理

    ```bash
        sudo apt-get install polipo
    ```
2. 修改 `/etc/polipo/config` 为以下内容:

    ```bash
        logSyslog = true
        logFile = /var/log/polipo/polipo.log

        proxyAddress = "0.0.0.0"
        proxyPort = 8888

        dnsUseGethostbyname = yes
    ```
    
4. 重启 polipo `sudo service polipo restart`

5. 手机端设置代理服务器
    - http 代理设置：
        ```
            服务器: 你本机的ip 
            端口: 8888
        ```
    - 设置方法：
        - [代理服务器IPhone手机设置代理的方法](http://www.ccproxy.com/ru-he-wei-iphone-shou-ji-she-zhi-da-li.htm)
        - [代理服务器Android手机代理上网的设置方法](http://www.ccproxy.com/Android-shou-ji-dai-li-shang-wang.htm)
6. 修改本机的 hosts
    ```bash
        你本机的ip ajax.wm.com
        你本机的ip wm.com
    ```
7. 在手机上访问 `wm.com` 看是不是访问到你本机上

# 扩展模块迁移需要做的一些改动

1. 在webapp文件夹下做功能的，需要在渲染页面的头部注入`window.ajaxapiDomain=BACKEND_DOMAIN`，这样在页面中使用rest请求后台的时候，会去获取这个`ajaxapiDomain`来拼接请求的url，比如reservation模块，它在`renderPage`方法里在注入签名和trackerLog时也加上了这个`window.ajaxapiDomain`这样在js里就可以通过window.ajaxapiDomain来获取到当前环境的后台的domain

    ```php
    $js = "var options=$signPackage, page='$page';window.trackerLog=$logObj;window.ajaxapiDomain='" . BACKEND_DOMAIN . "';";
    $this->view->registerJs($js, View::POS_HEAD);
    ```

2. 在h5文件夹下做功能的，也就是使用vue做开发的，现在在主项目的h5文件夹里有一个config文件夹里面有一个`domain.js`文件，存放域名变量。在各个模块的`main.js`里需要引用该文件获取后台的domain，同时还需要允许跨域时带上cookies。例如member模块，它加了如下部分的代码

    ```js
    import {ajaxapiDomain} from '../../../static/h5/config/domain'

    Vue.http.options.root = `${ajaxapiDomain}/api`
    Vue.http.options.xhr = {withCredentials: true}
    ```

3. 在backend文件夹下做功能的，需要check项目中使用DOMAIN的地方，因为之前的DOMAIN都是统一的.现在前后端分离之后，后台有自己的domain，所以需要check使用DOMAIN地方，如果需要跳到前台去的，需要改成使用UrlUtil::getFrontendDomain()来获取前端的域名或者直接使用FRONTEND_DOMAIN常量来获取。例如很多模块有`channelMenu.php`这个文件，用来配置渠道菜单的，里面有的需要跳转到前台的，有的需要跳转到后台的，可以参考member模块的`channelMenu.php`文件.

4. 在开发者中心配置应用回调地址时，需要配置成后台的，而不是前台的

5. 在使用redirect进行跳转时，尽量使用绝对路径，而不是相对路径

