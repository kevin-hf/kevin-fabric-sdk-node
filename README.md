[TOC]

## 从零到壹构建基于fabric-sdk-node的项目开发实战

一个Node.js示例应用程序，用于演示 **fabric-client** 和 **fabric-ca-client**  Node.js SDK API

### 先决条件和安装设置:

- **Ubuntu 16.04**
- **Vim、[Git Client](https://git-scm.com/downloads) **
- [Docker](https://www.docker.com/products/overview) - v17.03+
- [Docker Compose](https://docs.docker.com/compose/overview/) - v1.8+
- **Golang** v1.10+
- **Node.js** v8.4.0+

#### 安装 vim、git

```shell
$ sudo apt install vim
$ sudo apt install git
```

#### 安装docker

**需要Docker版本17.03.0-ce 或更高版本。**

```shell
$ docker version 
$ sudo apt install docker.io
```

安装完成后执行版本查询命令

```shell
$ sudo docker version
```

![docker版本](./img/docker.png)

#### 安装docker-compose

**docker-compose 1.8 或更高版本是必需的。**

我们目前无法一次性轻松管理多个容器。 为了解决这个问题，需要**docker-compose** 。

```shell
$ docker-compose version 
$ sudo apt install docker-compose
```

安装完成后查询：

```shell
$ docker-compose version 
```

![docker-compose版本](./img/docker_compose.png)

将当前用户添加到 docker 组

```shell
$ sudo usermod -aG docker kevin
```

添加成功后**必须注销/退出并重新登录**(如果使用的是远程连接工具，退出终端重新连接即可)

#### 安装Golang

**需要版本 1.10.x 或更高。**如果您使用的是 Hyperledger Fabric 1.1.x 版本，那么 Golang 版本在 1.9.x 以上

```shell
 $ go version 
 $ wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
```

> 下载受网络环境影响，如果您本地有相应的 tar.gz 包，则使用下面的命令直接解压到指定的路径下即可。

使用 tar 命令将下载后的压缩包文件解压到指定的 /usr/local/ 路径下

```shell
$ sudo tar -zxvf go1.10.3.linux-amd64.tar.gz -C /usr/local/
```

设置GOPATH & GOROOT环境变量, 通过 `go env` 查看GOPATH路径

```shell
$ sudo vim /etc/profile
```

> 如果只想让当前登录用户使用Golang， 其它用户不能使用， 则编辑当前用户$HOME目录下的   .bashrc 或  .profile 文件， 在该文件中添加相应的环境变量即可。

在profile文件最后添加如下内容:

```shell
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH
```

使用 source 命令，使刚刚添加的配置信息生效：

```shell
$ source /etc/profile
```

通过 go version命令验证是否成功：

```shell
$ go version
```

![Go版本](./img/go_version.png)

#### 安装 Node

**安装nvm**

```shell
$ sudo apt update
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.10/install.sh | bash

$ export NVM_DIR="$HOME/.nvm"
$ [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
```

**安装Node**

```shell
$ nvm install v8.11.1
```

安装完成终端输出如下信息：

![node-npm-version](./img/node-npm-version.png)

也可以使用命令查看相关的版本信息：

- 检查Node版本

  ```shell
  $ node -v
  ```

  输出:   `v8.11.1`

- 检查npm版本

  ```shell
  $ npm -v
  ```

  输出:   `5.6.0`



### 配置网络环境

使用 `git` 命令克隆 `kevin-fabric-sdk-node` 目录到当前登录用户的 $HOME 路径

```shell
$ cd ~
$ git clone https://github.com/kevin-hf/kevin-fabric-sdk-node.git
```

修改 `artifacts`  文件夹的所属关系为当前用户

```shell
$ cd kevin-fabric-sdk-node
$ sudo chown -R kevin:kevin ./artifacts
```

> 提示： kevin 为安装 Ubuntu 16.04 系统时创建的用户

进入 `artifacts` 目录

```shell
$ cd artifacts
```

为了构建区块链网络，使用 `docker` 构建处理不同角色的虚拟计算机。 在这里我们将尽可能保持简单。如果确定您的系统中已经存在相关的所需容器，或可以使用其它方式获取，则无需执行如下命令。否则请将 `fixtures` 目录下的 `pull_images.sh` 文件添加可执行权限后直接执行。

#### 下载Docker images

```shell
$ chmod 777 ./pull_images.sh
$ ./pull_images.sh 
```

> 提示：`pull_images.sh` 文件是下载 Fabric 环境所需容器的一个可执行脚本，下载过程需要一段时间（视网速情况而定），请耐心等待。
>
> 另：请确定您的系统支持虚拟技术。

下载完成后终端输出如下：

![docker-images-Download](./img/docker_images.png)



#### 配置 docker-compose.yaml

首先，我们需要进入项目的 `artifacts` 目录下

```shell
$ cd $HOME/kevin-fabric-sdk-node/artifacts
```

##### 创建 base.yaml 文件并编辑

```shell
$ vim base.yaml
```

`base.yaml` 文件完整内容如下：

```yaml
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

version: '2'
services:
  peer-base:
    image: hyperledger/fabric-peer
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      # the following setting starts chaincode containers on the same
      # bridge network as the peers
      # https://docs.docker.com/compose/networking/
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=artifacts_default
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_GOSSIP_USELEADERELECTION=true
      - CORE_PEER_GOSSIP_ORGLEADER=false
      # The following setting skips the gossip handshake since we are
      # are not doing mutual TLS
      - CORE_PEER_GOSSIP_SKIPHANDSHAKE=true
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto/peer/msp
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/crypto/peer/tls/server.key
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/crypto/peer/tls/server.crt
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto/peer/tls/ca.crt
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    volumes:
        - /var/run/:/host/var/run/
```

可以看到，我们在 `base.yaml`  文件中主要指定了 peer 容器相关的一些公共的环境参数，后继我们需要使用到。

##### 创建 docker-compose.yaml 文件并编辑

```shell
$ vim docker-compose.yaml 
```

`docker-compose.yaml` 文件完整内容如下：

```yaml
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
version: '2'

services:

  ca.org1.kevin.kongyixueyuan.com:
    image: hyperledger/fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-org1
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.kevin.kongyixueyuan.com-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/b22dd4d00a7bab82e84a904a33377fc82ba3695d32685f0ea64749b546361df9_sk
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.kevin.kongyixueyuan.com-cert.pem
      - FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/b22dd4d00a7bab82e84a904a33377fc82ba3695d32685f0ea64749b546361df9_sk
    ports:
      - "7054:7054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ./channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/ca/:/etc/hyperledger/fabric-ca-server-config
    container_name: ca_peerOrg1

  ca.org2.kevin.kongyixueyuan.com:
    image: hyperledger/fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-org2
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org2.kevin.kongyixueyuan.com-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/c4e1c8a8f5eb0c01df14cf2b635c656e0f7884c178dbc71d45c19f8ae3018340_sk
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org2.kevin.kongyixueyuan.com-cert.pem
      - FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/c4e1c8a8f5eb0c01df14cf2b635c656e0f7884c178dbc71d45c19f8ae3018340_sk
    ports:
      - "8054:7054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ./channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/ca/:/etc/hyperledger/fabric-ca-server-config
    container_name: ca_peerOrg2

  orderer.kevin.kongyixueyuan.com:
    container_name: orderer.kevin.kongyixueyuan.com
    image: hyperledger/fabric-orderer
    environment:
      - ORDERER_GENERAL_LOGLEVEL=debug
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/etc/hyperledger/configtx/genesis.block
      - ORDERER_GENERAL_LOCALMSPID=kevin.kongyixueyuan.com
      - ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/crypto/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/etc/hyperledger/crypto/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/etc/hyperledger/crypto/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/etc/hyperledger/crypto/orderer/tls/ca.crt, /etc/hyperledger/crypto/peerOrg1/tls/ca.crt, /etc/hyperledger/crypto/peerOrg2/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/orderers
    command: orderer
    ports:
      - 7050:7050
    volumes:
        - ./channel:/etc/hyperledger/configtx
        - ./channel/crypto-config/ordererOrganizations/kevin.kongyixueyuan.com/orderers/orderer.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/orderer
        - ./channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer0.org1.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peerOrg1
        - ./channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer0.org2.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peerOrg2

  peer0.org1.kevin.kongyixueyuan.com:
    container_name: peer0.org1.kevin.kongyixueyuan.com
    extends:
      file:   base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer0.org1.kevin.kongyixueyuan.com
      - CORE_PEER_LOCALMSPID=org1.kevin.kongyixueyuan.com
      - CORE_PEER_ADDRESS=peer0.org1.kevin.kongyixueyuan.com:7051
    ports:
      - 7051:7051
      - 7053:7053
    volumes:
        - ./channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer0.org1.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peer
    depends_on:
      - orderer.kevin.kongyixueyuan.com

  peer1.org1.kevin.kongyixueyuan.com:
    container_name: peer1.org1.kevin.kongyixueyuan.com
    extends:
      file:   base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer1.org1.kevin.kongyixueyuan.com
      - CORE_PEER_LOCALMSPID=org1.kevin.kongyixueyuan.com
      - CORE_PEER_ADDRESS=peer1.org1.kevin.kongyixueyuan.com:7051
    ports:
      - 7056:7051
      - 7058:7053
    volumes:
        - ./channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer1.org1.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peer
    depends_on:
      - orderer.kevin.kongyixueyuan.com

  peer0.org2.kevin.kongyixueyuan.com:
    container_name: peer0.org2.kevin.kongyixueyuan.com
    extends:
      file:   base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer0.org2.kevin.kongyixueyuan.com
      - CORE_PEER_LOCALMSPID=org2.kevin.kongyixueyuan.com
      - CORE_PEER_ADDRESS=peer0.org2.kevin.kongyixueyuan.com:7051
    ports:
      - 8051:7051
      - 8053:7053
    volumes:
        - ./channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer0.org2.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peer
    depends_on:
      - orderer.kevin.kongyixueyuan.com

  peer1.org2.kevin.kongyixueyuan.com:
    container_name: peer1.org2.kevin.kongyixueyuan.com
    extends:
      file:   base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer1.org2.kevin.kongyixueyuan.com
      - CORE_PEER_LOCALMSPID=org2.kevin.kongyixueyuan.com
      - CORE_PEER_ADDRESS=peer1.org2.kevin.kongyixueyuan.com:7051
    ports:
      - 8056:7051
      - 8058:7053
    volumes:
        - ./channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer1.org2.kevin.kongyixueyuan.com/:/etc/hyperledger/crypto/peer
    depends_on:
      - orderer.kevin.kongyixueyuan.com
```

完成上面的相关配置后，我们将具有以下 `docker` 容器配置的本地网络环境：

- 2个CA节点.
- 一个SOLO Orderer节点
- 4个Peer节点（每个 Org 有2个peer节点）

#### Artifacts

- Crypto材料已使用Hyperledger Fabric中的**cryptogen**工具生成，并安装到所有对等端，orderering节点和CA容器。有关加密工具的更多详细信息，请[点击此处](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#crypto-generator)。
- Orderer创世块（genesis.block）和通道配置事务（mychannel.tx）已使用Hyperledger Fabric中的**configtxgen**工具预生成，并放置在 `artifacts` 文件夹中。有关 `configtxgen` 工具的更多详细信息，请 [访问此处](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#configuration-transaction-generator)。

#### 测试网络环境

为了检查网络是否正常工作，我们可以使用 `docker-compose` 命令同时启动或停止所有容器。 进入`artifacts`文件夹，运行启动或停止的相关命令。

- 启动网络

  ```shell
  $ cd $HOME/kevin-fabric-sdk-node/artifacts
  $ docker-compose up -d
  ```

- 查看docker的活动容器

  ```shell
  $ docker ps
  ```

  ![docker-ps](./img/docker-ps.png)

- 关闭网络

  ```shell
  $ docker-compose down
  ```

  > 注意：使用停止网络的命令时，如果没有指定对应的 yaml 文件所在路径，那么，该命令必须在 `docker-compose.yaml` 或 `docker-compose.yml` 文件所在目录下执行。

### 编写链码

对于一个完整的应用而言，操作账本状态是通过链码来实现的，所以我们必须编写链码来实现对账本状态的操作

- 在此，我们不去考虑多么复杂的业务，只是实现一个简单的转账及余额查询的功能
- 另外，链代码可以使用不同的语言来编写实现，我们在示例中使用 `Golang` 
- 其它语言，如： `node`、`java` 等语言如何编写链代码在此我们不讨论

在使用 `Golang` 编写链码之前，我们需要创建存放链代码文件的目录，然后创建链代码文件并编辑：

```shell
$ cd $HOME/kevin-fabric-sdk-node/artifacts
$ mkdir -p src/github.com/example_cc
$ cd src/github.com/example_cc
$ vim example_cc.go
```

`example_cc.go` 文件完整内容如下：

```go
/*
Copyright IBM Corp. 2016 All Rights Reserved.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
		 http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package main

import (
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var logger = shim.NewLogger("example_cc0")

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response  {
	logger.Info("########### example_cc0 Init ###########")

	_, args := stub.GetFunctionAndParameters()
	var A, B string    // Entities
	var Aval, Bval int // Asset holdings
	var err error

	// Initialize the chaincode
	A = args[0]
	Aval, err = strconv.Atoi(args[1])
	if err != nil {
		return shim.Error("Expecting integer value for asset holding")
	}
	B = args[2]
	Bval, err = strconv.Atoi(args[3])
	if err != nil {
		return shim.Error("Expecting integer value for asset holding")
	}
	logger.Info("Aval = %d, Bval = %d\n", Aval, Bval)

	// Write the state to the ledger
	err = stub.PutState(A, []byte(strconv.Itoa(Aval)))
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(B, []byte(strconv.Itoa(Bval)))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### example_cc0 Invoke ###########")

	function, args := stub.GetFunctionAndParameters()
	
	if function == "delete" {
		// Deletes an entity from its state
		return t.delete(stub, args)
	}

	if function == "query" {
		// queries an entity state
		return t.query(stub, args)
	}
	if function == "move" {
		// Deletes an entity from its state
		return t.move(stub, args)
	}

	logger.Errorf("Unknown action, check the first argument, must be one of 'delete', 'query', or 'move'. But got: %v", args[0])
	return shim.Error(fmt.Sprintf("Unknown action, check the first argument, must be one of 'delete', 'query', or 'move'. But got: %v", args[0]))
}

func (t *SimpleChaincode) move(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// must be an invoke
	var A, B string    // Entities
	var Aval, Bval int // Asset holdings
	var X int          // Transaction value
	var err error

	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 4, function followed by 2 names and 1 value")
	}

	A = args[0]
	B = args[1]

	// Get the state from the ledger
	// TODO: will be nice to have a GetAllState call to ledger
	Avalbytes, err := stub.GetState(A)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if Avalbytes == nil {
		return shim.Error("Entity not found")
	}
	Aval, _ = strconv.Atoi(string(Avalbytes))

	Bvalbytes, err := stub.GetState(B)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if Bvalbytes == nil {
		return shim.Error("Entity not found")
	}
	Bval, _ = strconv.Atoi(string(Bvalbytes))

	// Perform the execution
	X, err = strconv.Atoi(args[2])
	if err != nil {
		return shim.Error("Invalid transaction amount, expecting a integer value")
	}
	Aval = Aval - X
	Bval = Bval + X
	logger.Infof("Aval = %d, Bval = %d\n", Aval, Bval)

	// Write the state back to the ledger
	err = stub.PutState(A, []byte(strconv.Itoa(Aval)))
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(B, []byte(strconv.Itoa(Bval)))
	if err != nil {
		return shim.Error(err.Error())
	}

        return shim.Success(nil);
}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	A := args[0]

	// Delete the key from the state in ledger
	err := stub.DelState(A)
	if err != nil {
		return shim.Error("Failed to delete state")
	}

	return shim.Success(nil)
}

// Query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var A string // Entities
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}

	A = args[0]

	// Get the state from the ledger
	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	jsonResp := "{\"Name\":\"" + A + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
	logger.Infof("Query Response:%s\n", jsonResp)
	return shim.Success(Avalbytes)
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		logger.Errorf("Error starting Simple chaincode: %s", err)
	}
}
```

###设置应用环境

####config.json

返回至项目根目录下

```shell
$ cd $HOME/kevin-fabric-sdk-node
```

创建 `config.json` 文件，指定应用相关的信息

```shell
$ vim config.json
```

`config.json` 文件内容如下：

```json
{
   "host":"localhost",
   "port":"4000",
   "jwt_expiretime": "36000",
   "channelName":"kevinkongyixueyuan",
   "CC_SRC_PATH":"../artifacts",
   "eventWaitTime":"30000",
   "admins":[
      {
         "username":"admin",
         "secret":"adminpw"
      }
   ]
}
```

####package.json

创建 `package.json` 文件，指定应用依赖信息

```shell
$ vim package.json
```

`package.json` 文件内容如下：

```json
{
  "name": "kevin-fabric-sdk-node",
  "version": "1.0.0",
  "description": "A balance-transfer example node program to demonstrate using node.js SDK APIs",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "keywords": [
    "fabric-client sample app",
    "balance-transfer node sample",
    "v1.0 fabric nodesdk sample"
  ],
  "engines": {
    "node": ">=8.9.4 <9.0",
    "npm": ">=5.6.0 <6.0"
  },
  "license": "Apache-2.0",
  "dependencies": {
    "body-parser": "^1.17.1",
    "cookie-parser": "^1.4.3",
    "cors": "^2.8.3",
    "express": "^4.15.2",
    "express-bearer-token": "^2.1.0",
    "express-jwt": "^5.1.0",
    "express-session": "^1.15.2",
    "fabric-ca-client": "~1.2.0",
    "fabric-client": "~1.2.0",
    "fs-extra": "^2.0.0",
    "jsonwebtoken": "^7.3.0",
    "log4js": "^0.6.38"
  }
}
```

####config.js

创建 `config.js` 文件，指定网络配置相关信息

```shell
$ vim config.js
```

`config.js` 文件内容如下：

```js
var util = require('util');
var path = require('path');
var hfc = require('fabric-client');

var file = 'network-config%s.yaml';

var env = process.env.TARGET_NETWORK;
if (env)
	file = util.format(file, '-' + env);
else
	file = util.format(file, '');
// indicate to the application where the setup file is located so it able
// to have the hfc load it to initalize the fabric client instance
hfc.setConfigSetting('network-connection-profile-path',path.join(__dirname, 'artifacts' ,file));
hfc.setConfigSetting('Org1-connection-profile-path',path.join(__dirname, 'artifacts', 'org1.yaml'));
hfc.setConfigSetting('Org2-connection-profile-path',path.join(__dirname, 'artifacts', 'org2.yaml'));
// some other settings the application might need to know
hfc.addConfigFile(path.join(__dirname, 'config.json'));
```



### 创建配置 fabric-sdk-node

#### network-config.yaml

进入项目的 `artifacts` 目录中，创建 `network-config.yaml` 文件并编辑

```shell
$ cd $HOME/kevin-fabric-sdk-node/artifacts/
$ vim network-config.yaml
```

`network-config.yaml` 文件完整内容如下：

```json
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: "kevin-fabric-sdk-node"

#
# Any properties with an "x-" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the "x-type" property with the "hlfv1" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: "hlfv1"

#
# Describe what the target network is/does.
#
description: "Balance Transfer Network"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: "1.0"

#
# The client section will be added on a per org basis see org1.yaml and org2.yaml
#
#client:

#
# [Optional]. But most apps would have this section so that channel objects can be constructed
# based on the content below. If an app is creating channels, then it likely will not need this
# section.
#
channels:
  # name of the channel
  kevinkongyixueyuan:
    # Required. list of orderers designated by the application to use for transactions on this
    # channel. This list can be a result of access control ("org1" can only access "ordererA"), or
    # operational decisions to share loads from applications among the orderers.  The values must
    # be "names" of orgs defined under "organizations/peers"
    orderers:
      - orderer.kevin.kongyixueyuan.com

    # Required. list of peers from participating orgs
    peers:
      peer0.org1.kevin.kongyixueyuan.com:
        # [Optional]. will this peer be sent transaction proposals for endorsement? The peer must
        # have the chaincode installed. The app can also use this property to decide which peers
        # to send the chaincode install request. Default: true
        endorsingPeer: true

        # [Optional]. will this peer be sent query proposals? The peer must have the chaincode
        # installed. The app can also use this property to decide which peers to send the
        # chaincode install request. Default: true
        chaincodeQuery: true

        # [Optional]. will this peer be sent query proposals that do not require chaincodes, like
        # queryBlock(), queryTransaction(), etc. Default: true
        ledgerQuery: true

        # [Optional]. will this peer be the target of the SDK's listener registration? All peers can
        # produce events but the app typically only needs to connect to one to listen to events.
        # Default: true
        eventSource: true

      peer1.org1.kevin.kongyixueyuan.com:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: false

      peer0.org2.kevin.kongyixueyuan.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true

      peer1.org2.kevin.kongyixueyuan.com:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: false

    # [Optional]. what chaincodes are expected to exist on this channel? The application can use
    # this information to validate that the target peers are in the expected state by comparing
    # this list with the query results of getInstalledChaincodes() and getInstantiatedChaincodes()
    chaincodes:
      # the format follows the "cannonical name" of chaincodes by fabric code
      - mycc:v0

#
# list of participating organizations in this network
#
organizations:
  Org1:
    mspid: org1.kevin.kongyixueyuan.com

    peers:
      - peer0.org1.kevin.kongyixueyuan.com
      - peer1.org1.kevin.kongyixueyuan.com

    # [Optional]. Certificate Authorities issue certificates for identification purposes in a Fabric based
    # network. Typically certificates provisioning is done in a separate process outside of the
    # runtime network. Fabric-CA is a special certificate authority that provides a REST APIs for
    # dynamic certificate management (enroll, revoke, re-enroll). The following section is only for
    # Fabric-CA servers.
    certificateAuthorities:
      - ca-org1

    # [Optional]. If the application is going to make requests that are reserved to organization
    # administrators, including creating/updating channels, installing/instantiating chaincodes, it
    # must have access to the admin identity represented by the private key and signing certificate.
    # Both properties can be the PEM string or local path to the PEM file. Note that this is mainly for
    # convenience in development mode, production systems should not expose sensitive information
    # this way. The SDK should allow applications to set the org admin identity via APIs, and only use
    # this route as an alternative when it exists.
    adminPrivateKey:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/users/Admin@org1.kevin.kongyixueyuan.com/msp/keystore/3a497246b8b16356e0a4e2df8d77e3327c5934494f488ddaa625d6bdbdff2cf7_sk
    signedCert:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/users/Admin@org1.kevin.kongyixueyuan.com/msp/signcerts/Admin@org1.kevin.kongyixueyuan.com-cert.pem

  # the profile will contain public information about organizations other than the one it belongs to.
  # These are necessary information to make transaction lifecycles work, including MSP IDs and
  # peers with a public URL to send transaction proposals. The file will not contain private
  # information reserved for members of the organization, such as admin key and certificate,
  # fabric-ca registrar enroll ID and secret, etc.
  Org2:
    mspid: org2.kevin.kongyixueyuan.com
    peers:
      - peer0.org2.kevin.kongyixueyuan.com
      - peer1.org2.kevin.kongyixueyuan.com
    certificateAuthorities:
      - ca-org2
    adminPrivateKey:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/users/Admin@org2.kevin.kongyixueyuan.com/msp/keystore/76d11fc03c74296a12d1e0075b1ea17332ee2a07f97617cb6104e1f5aa377953_sk
    signedCert:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/users/Admin@org2.kevin.kongyixueyuan.com/msp/signcerts/Admin@org2.kevin.kongyixueyuan.com-cert.pem

#
# List of orderers to send transaction and channel create/update requests to. For the time
# being only one orderer is needed. If more than one is defined, which one get used by the
# SDK is implementation specific. Consult each SDK's documentation for its handling of orderers.
#
orderers:
  orderer.kevin.kongyixueyuan.com:
    url: grpcs://localhost:7050

    # these are standard properties defined by the gRPC library
    # they will be passed in as-is to gRPC client constructor
    grpcOptions:
      ssl-target-name-override: orderer.kevin.kongyixueyuan.com

    tlsCACerts:
      path: artifacts/channel/crypto-config/ordererOrganizations/kevin.kongyixueyuan.com/orderers/orderer.kevin.kongyixueyuan.com/tls/ca.crt

#
# List of peers to send various requests to, including endorsement, query
# and event listener registration.
#
peers:
  peer0.org1.kevin.kongyixueyuan.com:
    # this URL is used to send endorsement and query requests
    url: grpcs://localhost:7051

    grpcOptions:
      ssl-target-name-override: peer0.org1.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer0.org1.kevin.kongyixueyuan.com/tls/ca.crt

  peer1.org1.kevin.kongyixueyuan.com:
    url: grpcs://localhost:7056
    grpcOptions:
      ssl-target-name-override: peer1.org1.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer1.org1.kevin.kongyixueyuan.com/tls/ca.crt

  peer0.org2.kevin.kongyixueyuan.com:
    url: grpcs://localhost:8051
    grpcOptions:
      ssl-target-name-override: peer0.org2.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer0.org2.kevin.kongyixueyuan.com/tls/ca.crt

  peer1.org2.kevin.kongyixueyuan.com:
    url: grpcs://localhost:8056
    eventUrl: grpcs://localhost:8058
    grpcOptions:
      ssl-target-name-override: peer1.org2.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer1.org2.kevin.kongyixueyuan.com/tls/ca.crt

#
# Fabric-CA is a special kind of Certificate Authority provided by Hyperledger Fabric which allows
# certificate management to be done via REST APIs. Application may choose to use a standard
# Certificate Authority instead of Fabric-CA, in which case this section would not be specified.
#
certificateAuthorities:
  ca-org1:
    url: https://localhost:7054
    # the properties specified under this object are passed to the 'http' client verbatim when
    # making the request to the Fabric-CA server
    httpOptions:
      verify: false
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/ca/ca.org1.kevin.kongyixueyuan.com-cert.pem

    # Fabric-CA supports dynamic user enrollment via REST APIs. A "root" user, a.k.a registrar, is
    # needed to enroll and invoke new users.
    registrar:
      - enrollId: admin
        enrollSecret: adminpw
    # [Optional] The optional name of the CA.
    caName: ca-org1

  ca-org2:
    url: https://localhost:8054
    httpOptions:
      verify: false
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/ca/ca.org2.kevin.kongyixueyuan.com-cert.pem
    registrar:
      - enrollId: admin
        enrollSecret: adminpw
    # [Optional] The optional name of the CA.
    caName: ca-org2
```

#### 网络配置注意事项

您可以通过直接编辑network-config.yaml文件或为备用目标网络提供其他文件来更改配置参数。该应用程序使用可选的环境变量“TARGET_NETWORK”来控制要使用的配置文件。例如，如果您在Amazon Web Services EC2上部署了目标网络，则可以添加文件“network-config-aws.yaml”，并将“TARGET_NETWORK”环境设置为“aws”。该应用程序将获取“network-config-aws.yaml”文件中的设置。

#### IP地址和PORT信息

如果您选择通过为对等方和订购者硬编码IP地址和PORT信息来自定义docker-compose yaml文件，那么您还必须将相同的值添加到network-config.yaml文件中。需要调整url和eventUrl设置以匹配docker-compose yaml文件。

```json
peer1.org1.kevin.kongyixueyuan.com:
  url: grpcs://x.x.x.x:7056
  eventUrl: grpcs://x.x.x.x:7058
```

#### network-config-aws.yaml

```shell
$ vim network-config-aws.yaml
```

`network-config-aws.yaml` 文件完整内容如下：

```json
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: "kevin-fabric-sdk-node"

#
# Any properties with an "x-" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the "x-type" property with the "hlfv1" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: "hlfv1"

#
# Describe what the target network is/does.
#
description: "Balance Transfer Network"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: "1.0"

#
# The client section will be added on a per org basis see org1.yaml and org2.yaml
#
#client:

#
# [Optional]. But most apps would have this section so that channel objects can be constructed
# based on the content below. If an app is creating channels, then it likely will not need this
# section.
#
channels:
  # name of the channel
  kevinkongyixueyuan:
    # Required. list of orderers designated by the application to use for transactions on this
    # channel. This list can be a result of access control ("org1" can only access "ordererA"), or
    # operational decisions to share loads from applications among the orderers.  The values must
    # be "names" of orgs defined under "organizations/peers"
    orderers:
      - orderer.kevin.kongyixueyuan.com

    # Required. list of peers from participating orgs
    peers:
      peer0.org1.kevin.kongyixueyuan.com:
        # [Optional]. will this peer be sent transaction proposals for endorsement? The peer must
        # have the chaincode installed. The app can also use this property to decide which peers
        # to send the chaincode install request. Default: true
        endorsingPeer: true

        # [Optional]. will this peer be sent query proposals? The peer must have the chaincode
        # installed. The app can also use this property to decide which peers to send the
        # chaincode install request. Default: true
        chaincodeQuery: true

        # [Optional]. will this peer be sent query proposals that do not require chaincodes, like
        # queryBlock(), queryTransaction(), etc. Default: true
        ledgerQuery: true

        # [Optional]. will this peer be the target of the SDK's listener registration? All peers can
        # produce events but the app typically only needs to connect to one to listen to events.
        # Default: true
        eventSource: true

      peer1.org1.kevin.kongyixueyuan.com:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: false

      peer0.org2.kevin.kongyixueyuan.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true

      peer1.org2.kevin.kongyixueyuan.com:
        endorsingPeer: false
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: false

    # [Optional]. what chaincodes are expected to exist on this channel? The application can use
    # this information to validate that the target peers are in the expected state by comparing
    # this list with the query results of getInstalledChaincodes() and getInstantiatedChaincodes()
    chaincodes:
      # the format follows the "cannonical name" of chaincodes by fabric code
      - mycc:v0

#
# list of participating organizations in this network
#
organizations:
  Org1:
    mspid: org1.kevin.kongyixueyuan.com

    peers:
      - peer0.org1.kevin.kongyixueyuan.com
      - peer1.org1.kevin.kongyixueyuan.com

    # [Optional]. Certificate Authorities issue certificates for identification purposes in a Fabric based
    # network. Typically certificates provisioning is done in a separate process outside of the
    # runtime network. Fabric-CA is a special certificate authority that provides a REST APIs for
    # dynamic certificate management (enroll, revoke, re-enroll). The following section is only for
    # Fabric-CA servers.
    certificateAuthorities:
      - ca-org1

    # [Optional]. If the application is going to make requests that are reserved to organization
    # administrators, including creating/updating channels, installing/instantiating chaincodes, it
    # must have access to the admin identity represented by the private key and signing certificate.
    # Both properties can be the PEM string or local path to the PEM file. Note that this is mainly for
    # convenience in development mode, production systems should not expose sensitive information
    # this way. The SDK should allow applications to set the org admin identity via APIs, and only use
    # this route as an alternative when it exists.
    adminPrivateKey:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/users/Admin@org1.kevin.kongyixueyuan.com/msp/keystore/3a497246b8b16356e0a4e2df8d77e3327c5934494f488ddaa625d6bdbdff2cf7_sk
    signedCert:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/users/Admin@org1.kevin.kongyixueyuan.com/msp/signcerts/Admin@org1.kevin.kongyixueyuan.com-cert.pem

  # the profile will contain public information about organizations other than the one it belongs to.
  # These are necessary information to make transaction lifecycles work, including MSP IDs and
  # peers with a public URL to send transaction proposals. The file will not contain private
  # information reserved for members of the organization, such as admin key and certificate,
  # fabric-ca registrar enroll ID and secret, etc.
  Org2:
    mspid: org2.kevin.kongyixueyuan.com
    peers:
      - peer0.org2.kevin.kongyixueyuan.com
      - peer1.org2.kevin.kongyixueyuan.com
    certificateAuthorities:
      - ca-org2
    adminPrivateKey:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/users/Admin@org2.kevin.kongyixueyuan.com/msp/keystore/76d11fc03c74296a12d1e0075b1ea17332ee2a07f97617cb6104e1f5aa377953_sk
    signedCert:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/users/Admin@org2.kevin.kongyixueyuan.com/msp/signcerts/Admin@org2.kevin.kongyixueyuan.com-cert.pem

#
# List of orderers to send transaction and channel create/update requests to. For the time
# being only one orderer is needed. If more than one is defined, which one get used by the
# SDK is implementation specific. Consult each SDK's documentation for its handling of orderers.
#
orderers:
  orderer.kevin.kongyixueyuan.com:
    url: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:7050

    # these are standard properties defined by the gRPC library
    # they will be passed in as-is to gRPC client constructor
    grpcOptions:
      ssl-target-name-override: orderer.kevin.kongyixueyuan.com

    tlsCACerts:
      path: artifacts/channel/crypto-config/ordererOrganizations/kevin.kongyixueyuan.com/orderers/orderer.kevin.kongyixueyuan.com/tls/ca.crt

#
# List of peers to send various requests to, including endorsement, query
# and event listener registration.
#
peers:
  peer0.org1.kevin.kongyixueyuan.com:
    # this URL is used to send endorsement and query requests
    url: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:7051

    grpcOptions:
      ssl-target-name-override: peer0.org1.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer0.org1.kevin.kongyixueyuan.com/tls/ca.crt

  peer1.org1.kevin.kongyixueyuan.com:
    url: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:7056
    eventUrl: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:7058
    grpcOptions:
      ssl-target-name-override: peer1.org1.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/peers/peer1.org1.kevin.kongyixueyuan.com/tls/ca.crt

  peer0.org2.kevin.kongyixueyuan.com:
    url: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:8051
    grpcOptions:
      ssl-target-name-override: peer0.org2.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer0.org2.kevin.kongyixueyuan.com/tls/ca.crt

  peer1.org2.kevin.kongyixueyuan.com:
    url: grpcs://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:8056
    grpcOptions:
      ssl-target-name-override: peer1.org2.kevin.kongyixueyuan.com
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/peers/peer1.org2.kevin.kongyixueyuan.com/tls/ca.crt

#
# Fabric-CA is a special kind of Certificate Authority provided by Hyperledger Fabric which allows
# certificate management to be done via REST APIs. Application may choose to use a standard
# Certificate Authority instead of Fabric-CA, in which case this section would not be specified.
#
certificateAuthorities:
  ca-org1:
    url: https://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:7054
    # the properties specified under this object are passed to the 'http' client verbatim when
    # making the request to the Fabric-CA server
    httpOptions:
      verify: false
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org1.kevin.kongyixueyuan.com/ca/ca.org1.kevin.kongyixueyuan.com-cert.pem

    # Fabric-CA supports dynamic user enrollment via REST APIs. A "root" user, a.k.a registrar, is
    # needed to enroll and invoke new users.
    registrar:
      - enrollId: admin
        enrollSecret: adminpw
    # [Optional] The optional name of the CA.
    caName: ca-org1

  ca-org2:
    url: https://ec2-13-59-99-140.us-east-2.compute.amazonaws.com:8054
    httpOptions:
      verify: false
    tlsCACerts:
      path: artifacts/channel/crypto-config/peerOrganizations/org2.kevin.kongyixueyuan.com/ca/ca.org2.kevin.kongyixueyuan.com-cert.pem
    registrar:
      - enrollId: admin
        enrollSecret: adminpw
    # [Optional] The optional name of the CA.
    caName: ca-org2
```



####org1.yaml

```shell
$ vim org1.yaml
```

`org1.yaml` 文件完整内容如下：

```yaml
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: "kevin-fabric-sdk-node-org1"

#
# Any properties with an "x-" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the "x-type" property with the "hlfv1" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: "hlfv1"

#
# Describe what the target network is/does.
#
description: "Balance Transfer Network - client definition for Org1"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: "1.0"

#
# The client section is SDK-specific. The sample below is for the node.js SDK
#
client:
  # Which organization does this application instance belong to? The value must be the name of an org
  # defined under "organizations"
  organization: Org1

  # Some SDKs support pluggable KV stores, the properties under "credentialStore"
  # are implementation specific
  credentialStore:
    # [Optional]. Specific to FileKeyValueStore.js or similar implementations in other SDKs. Can be others
    # if using an alternative impl. For instance, CouchDBKeyValueStore.js would require an object
    # here for properties like url, db name, etc.
    path: "./fabric-client-kv-org1"

    # [Optional]. Specific to the CryptoSuite implementation. Software-based implementations like
    # CryptoSuite_ECDSA_AES.js in node SDK requires a key store. PKCS#11 based implementations does
    # not.
    cryptoStore:
      # Specific to the underlying KeyValueStore that backs the crypto key store.
      path: "/tmp/fabric-client-kv-org1"

    # [Optional]. Specific to Composer environment
    wallet: wallet-name
```



####org2.yaml

```shell
$ vim org2.yaml
```

`org1.yaml` 文件完整内容如下：

```yaml
---
#
# The network connection profile provides client applications the information about the target
# blockchain network that are necessary for the applications to interact with it. These are all
# knowledge that must be acquired from out-of-band sources. This file provides such a source.
#
name: "kevin-fabric-sdk-node-org2"

#
# Any properties with an "x-" prefix will be treated as application-specific, exactly like how naming
# in HTTP headers or swagger properties work. The SDK will simply ignore these fields and leave
# them for the applications to process. This is a mechanism for different components of an application
# to exchange information that are not part of the standard schema described below. In particular,
# the "x-type" property with the "hlfv1" value example below is used by Hyperledger Composer to
# determine the type of Fabric networks (v0.6 vs. v1.0) it needs to work with.
#
x-type: "hlfv1"

#
# Describe what the target network is/does.
#
description: "Balance Transfer Network - client definition for Org2"

#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: "1.0"

#
# The client section is SDK-specific. The sample below is for the node.js SDK
#
client:
  # Which organization does this application instance belong to? The value must be the name of an org
  # defined under "organizations"
  organization: Org2

  # Some SDKs support pluggable KV stores, the properties under "credentialStore"
  # are implementation specific
  credentialStore:
    # [Optional]. Specific to FileKeyValueStore.js or similar implementations in other SDKs. Can be others
    # if using an alternative impl. For instance, CouchDBKeyValueStore.js would require an object
    # here for properties like url, db name, etc.
    path: "./fabric-client-kv-org2"

    # [Optional]. Specific to the CryptoSuite implementation. Software-based implementations like
    # CryptoSuite_ECDSA_AES.js in node SDK requires a key store. PKCS#11 based implementations does
    # not.
    cryptoStore:
      # Specific to the underlying KeyValueStore that backs the crypto key store.
      path: "/tmp/fabric-client-kv-org2"

    # [Optional]. Specific to Composer environment
    wallet: wallet-name
```



### 使用 fabric-sdk-node

在项目根目录下创建一个 `app` 的文件夹，做为所有的 JS 代码文件的存放目录，具体文件如下:

- helper.js
- create-channel.js
- join-channel.js
- install-chaincode.js
- instantiate-chaincode.js
- invoke-transaction.js
- query.js

创建 `app` 目录并进入该目录：

```shell
$ cd $HOME/kevin-fabric-sdk-node/
$ mkdir app && cd app
```

#### helper.js

`helper.js` 是应用最重要的主文件，提供了核心对象的实现。

创建 `helper.js` 文件并编辑：

```shell
$ vim helper.js
```

`helper.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an 'AS IS' BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('Helper');
logger.setLevel('DEBUG');

var path = require('path');
var util = require('util');
var copService = require('fabric-ca-client');

var hfc = require('fabric-client');
hfc.setLogger(logger);
var ORGS = hfc.getConfigSetting('network-config');

var clients = {};
var channels = {};
var caClients = {};

var sleep = async function (sleep_time_ms) {
	return new Promise(resolve => setTimeout(resolve, sleep_time_ms));
}

async function getClientForOrg (userorg, username) {
	logger.debug('getClientForOrg - ****** START %s %s', userorg, username)
	// get a fabric client loaded with a connection profile for this org
	let config = '-connection-profile-path';

	// build a client context and load it with a connection profile
	// lets only load the network settings and save the client for later
	let client = hfc.loadFromConfig(hfc.getConfigSetting('network'+config));

	// This will load a connection profile over the top of the current one one
	// since the first one did not have a client section and the following one does
	// nothing will actually be replaced.
	// This will also set an admin identity because the organization defined in the
	// client section has one defined
	client.loadFromConfig(hfc.getConfigSetting(userorg+config));

	// this will create both the state store and the crypto store based
	// on the settings in the client section of the connection profile
	await client.initCredentialStores();

	// The getUserContext call tries to get the user from persistence.
	// If the user has been saved to persistence then that means the user has
	// been registered and enrolled. If the user is found in persistence
	// the call will then assign the user to the client object.
	if(username) {
		let user = await client.getUserContext(username, true);
		if(!user) {
			throw new Error(util.format('User was not found :', username));
		} else {
			logger.debug('User %s was found to be registered and enrolled', username);
		}
	}
	logger.debug('getClientForOrg - ****** END %s %s \n\n', userorg, username)

	return client;
}

var getRegisteredUser = async function(username, userOrg, isJson) {
	try {
		var client = await getClientForOrg(userOrg);
		logger.debug('Successfully initialized the credential stores');
			// client can now act as an agent for organization Org1
			// first check to see if the user is already enrolled
		var user = await client.getUserContext(username, true);
		if (user && user.isEnrolled()) {
			logger.info('Successfully loaded member from persistence');
		} else {
			// user was not enrolled, so we will need an admin user object to register
			logger.info('User %s was not enrolled, so we will need an admin user object to register',username);
			var admins = hfc.getConfigSetting('admins');
			let adminUserObj = await client.setUserContext({username: admins[0].username, password: admins[0].secret});
			let caClient = client.getCertificateAuthority();
			let secret = await caClient.register({
				enrollmentID: username,
				affiliation: userOrg.toLowerCase() + '.department1'
			}, adminUserObj);
			logger.debug('Successfully got the secret for user %s',username);
			user = await client.setUserContext({username:username, password:secret});
			logger.debug('Successfully enrolled username %s  and setUserContext on the client object', username);
		}
		if(user && user.isEnrolled) {
			if (isJson && isJson === true) {
				var response = {
					success: true,
					secret: user._enrollmentSecret,
					message: username + ' enrolled Successfully',
				};
				return response;
			}
		} else {
			throw new Error('User was not enrolled ');
		}
	} catch(error) {
		logger.error('Failed to get registered user: %s with error: %s', username, error.toString());
		return 'failed '+error.toString();
	}

};


var setupChaincodeDeploy = function() {
	process.env.GOPATH = path.join(__dirname, hfc.getConfigSetting('CC_SRC_PATH'));
};

var getLogger = function(moduleName) {
	var logger = log4js.getLogger(moduleName);
	logger.setLevel('DEBUG');
	return logger;
};

exports.getClientForOrg = getClientForOrg;
exports.getLogger = getLogger;
exports.setupChaincodeDeploy = setupChaincodeDeploy;
exports.getRegisteredUser = getRegisteredUser;
```

#### create-channel.js

`create-channel.js` 文件主要实现根据指定的通道交易配置文件创建指定的应用通道。

创建 `create-channel.js` 文件并编辑：

```shell
$ vim create-channel.js
```

`create-channel.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an 'AS IS' BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var util = require('util');
var fs = require('fs');
var path = require('path');

var helper = require('./helper.js');
var logger = helper.getLogger('Create-Channel');
//Attempt to send a request to the orderer with the sendTransaction method
var createChannel = async function(channelName, channelConfigPath, username, orgName) {
	logger.debug('\n====== Creating Channel \'' + channelName + '\' ======\n');
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(orgName);
		logger.debug('Successfully got the fabric client for the organization "%s"', orgName);

		// read in the envelope for the channel config raw bytes
		var envelope = fs.readFileSync(path.join(__dirname, channelConfigPath));
		// extract the channel config bytes from the envelope to be signed
		var channelConfig = client.extractChannelConfig(envelope);

		//Acting as a client in the given organization provided with "orgName" param
		// sign the channel config bytes as "endorsement", this is required by
		// the orderer's channel creation policy
		// this will use the admin identity assigned to the client when the connection profile was loaded
		let signature = client.signChannelConfig(channelConfig);

		let request = {
			config: channelConfig,
			signatures: [signature],
			name: channelName,
			txId: client.newTransactionID(true) // get an admin based transactionID
		};

		// send to orderer
		var response = await client.createChannel(request)
		logger.debug(' response ::%j', response);
		if (response && response.status === 'SUCCESS') {
			logger.debug('Successfully created the channel.');
			let response = {
				success: true,
				message: 'Channel \'' + channelName + '\' created Successfully'
			};
			return response;
		} else {
			logger.error('\n!!!!!!!!! Failed to create the channel \'' + channelName +
				'\' !!!!!!!!!\n\n');
			throw new Error('Failed to create the channel \'' + channelName + '\'');
		}
	} catch (err) {
		logger.error('Failed to initialize the channel: ' + err.stack ? err.stack :	err);
		throw new Error('Failed to initialize the channel: ' + err.toString());
	}
};

exports.createChannel = createChannel;
```

#### join-channel.js

`join-channel.js` 文件主要实现将指定的peers加入至指定的通道中。

创建 `join-channel.js` 文件并编辑：

```shell
$ vim join-channel.js
```

`join-channel.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an 'AS IS' BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var util = require('util');
var path = require('path');
var fs = require('fs');

var helper = require('./helper.js');
var logger = helper.getLogger('Join-Channel');

/*
 * Have an organization join a channel
 */
var joinChannel = async function(channel_name, peers, username, org_name) {
	logger.debug('\n\n============ Join Channel start ============\n')
	var error_message = null;
	var all_eventhubs = [];
	try {
		logger.info('Calling peers in organization "%s" to join the channel', org_name);

		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channel_name);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channel_name);
			logger.error(message);
			throw new Error(message);
		}

		// next step is to get the genesis_block from the orderer,
		// the starting point for the channel that we want to join
		let request = {
			txId : 	client.newTransactionID(true) //get an admin based transactionID
		};
		let genesis_block = await channel.getGenesisBlock(request);

		// tell each peer to join and wait 10 seconds
		// for the channel to be created on each peer
		var promises = [];
		promises.push(new Promise(resolve => setTimeout(resolve, 10000)));

		let join_request = {
			targets: peers, //using the peer names which only is allowed when a connection profile is loaded
			txId: client.newTransactionID(true), //get an admin based transactionID
			block: genesis_block
		};
		let join_promise = channel.joinChannel(join_request);
		promises.push(join_promise);
		let results = await Promise.all(promises);
		logger.debug(util.format('Join Channel R E S P O N S E : %j', results));

		// lets check the results of sending to the peers which is
		// last in the results array
		let peers_results = results.pop();
		// then each peer results
		for(let i in peers_results) {
			let peer_result = peers_results[i];
			if(peer_result.response && peer_result.response.status == 200) {
				logger.info('Successfully joined peer to the channel %s',channel_name);
			} else {
				let message = util.format('Failed to joined peer to the channel %s',channel_name);
				error_message = message;
				logger.error(message);
			}
		}
	} catch(error) {
		logger.error('Failed to join channel due to error: ' + error.stack ? error.stack : error);
		error_message = error.toString();
	}

	// need to shutdown open event streams
	all_eventhubs.forEach((eh) => {
		eh.disconnect();
	});

	if (!error_message) {
		let message = util.format(
			'Successfully joined peers in organization %s to the channel:%s',
			org_name, channel_name);
		logger.info(message);
		// build a response to send back to the REST caller
		let response = {
			success: true,
			message: message
		};
		return response;
	} else {
		let message = util.format('Failed to join all peers to channel. cause:%s',error_message);
		logger.error(message);
		throw new Error(message);
	}
};
exports.joinChannel = joinChannel;
```

#### install-chaincode.js

`install-chaincode.js` 文件主要实现对链码的安装。

创建 `install-chaincode.js` 文件并编辑：

```shell
$ vim install-chaincode.js
```

`install-chaincode.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var path = require('path');
var fs = require('fs');
var util = require('util');
var config = require('../config.json');
var helper = require('./helper.js');
var logger = helper.getLogger('install-chaincode');
var tx_id = null;

var installChaincode = async function(peers, chaincodeName, chaincodePath,
	chaincodeVersion, chaincodeType, username, org_name) {
	logger.debug('\n\n============ Install chaincode on organizations ============\n');
	helper.setupChaincodeDeploy();
	let error_message = null;
	try {
		logger.info('Calling peers in organization "%s" to join the channel', org_name);

		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);

		tx_id = client.newTransactionID(true); //get an admin transactionID
		var request = {
			targets: peers,
			chaincodePath: chaincodePath,
			chaincodeId: chaincodeName,
			chaincodeVersion: chaincodeVersion,
			chaincodeType: chaincodeType
		};
		let results = await client.installChaincode(request);
		// the returned object has both the endorsement results
		// and the actual proposal, the proposal will be needed
		// later when we send a transaction to the orederer
		var proposalResponses = results[0];
		var proposal = results[1];

		// lets have a look at the responses to see if they are
		// all good, if good they will also include signatures
		// required to be committed
		var all_good = true;
		for (var i in proposalResponses) {
			let one_good = false;
			if (proposalResponses && proposalResponses[i].response &&
				proposalResponses[i].response.status === 200) {
				one_good = true;
				logger.info('install proposal was good');
			} else {
				logger.error('install proposal was bad %j',proposalResponses.toJSON());
			}
			all_good = all_good & one_good;
		}
		if (all_good) {
			logger.info('Successfully sent install Proposal and received ProposalResponse');
		} else {
			error_message = 'Failed to send install Proposal or receive valid response. Response null or status is not 200'
			logger.error(error_message);
		}
	} catch(error) {
		logger.error('Failed to install due to error: ' + error.stack ? error.stack : error);
		error_message = error.toString();
	}

	if (!error_message) {
		let message = util.format('Successfully install chaincode');
		logger.info(message);
		// build a response to send back to the REST caller
		let response = {
			success: true,
			message: message
		};
		return response;
	} else {
		let message = util.format('Failed to install due to:%s',error_message);
		logger.error(message);
		throw new Error(message);
	}
};
exports.installChaincode = installChaincode;
```

#### instantiate-chaincode.js

`instantiate-chaincode.js` 文件主要完成对链码的实例化。

创建 `instantiate-chaincode.js` 文件并编辑：

```shell
$ vim instantiate-chaincode.js
```

`instantiate-chaincode.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var path = require('path');
var fs = require('fs');
var util = require('util');
var hfc = require('fabric-client');
var helper = require('./helper.js');
var logger = helper.getLogger('instantiate-chaincode');

var instantiateChaincode = async function(peers, channelName, chaincodeName, chaincodeVersion, functionName, chaincodeType, args, username, org_name) {
	logger.debug('\n\n============ Instantiate chaincode on channel ' + channelName +
		' ============\n');
	var error_message = null;

	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}
		var tx_id = client.newTransactionID(true); // Get an admin based transactionID
		                                       // An admin based transactionID will
		                                       // indicate that admin identity should
		                                       // be used to sign the proposal request.
		// will need the transaction ID string for the event registration later
		var deployId = tx_id.getTransactionID();

		// send proposal to endorser
		var request = {
			targets : peers,
			chaincodeId: chaincodeName,
			chaincodeType: chaincodeType,
			chaincodeVersion: chaincodeVersion,
			args: args,
			txId: tx_id
		};

		if (functionName)
			request.fcn = functionName;

		let results = await channel.sendInstantiateProposal(request, 60000); //instantiate takes much longer

		// the returned object has both the endorsement results
		// and the actual proposal, the proposal will be needed
		// later when we send a transaction to the orderer
		var proposalResponses = results[0];
		var proposal = results[1];

		// lets have a look at the responses to see if they are
		// all good, if good they will also include signatures
		// required to be committed
		var all_good = true;
		for (var i in proposalResponses) {
			let one_good = false;
			if (proposalResponses && proposalResponses[i].response &&
				proposalResponses[i].response.status === 200) {
				one_good = true;
				logger.info('instantiate proposal was good');
			} else {
				logger.error('instantiate proposal was bad');
			}
			all_good = all_good & one_good;
		}

		if (all_good) {
			logger.info(util.format(
				'Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s", metadata - "%s", endorsement signature: %s',
				proposalResponses[0].response.status, proposalResponses[0].response.message,
				proposalResponses[0].response.payload, proposalResponses[0].endorsement.signature));

			// wait for the channel-based event hub to tell us that the
			// instantiate transaction was committed on the peer
			var promises = [];
			let event_hubs = channel.getChannelEventHubsForOrg();
			logger.debug('found %s eventhubs for this organization %s',event_hubs.length, org_name);
			event_hubs.forEach((eh) => {
				let instantiateEventPromise = new Promise((resolve, reject) => {
					logger.debug('instantiateEventPromise - setting up event');
					let event_timeout = setTimeout(() => {
						let message = 'REQUEST_TIMEOUT:' + eh.getPeerAddr();
						logger.error(message);
						eh.disconnect();
					}, 60000);
					eh.registerTxEvent(deployId, (tx, code, block_num) => {
						logger.info('The chaincode instantiate transaction has been committed on peer %s',eh.getPeerAddr());
						logger.info('Transaction %s has status of %s in blocl %s', tx, code, block_num);
						clearTimeout(event_timeout);

						if (code !== 'VALID') {
							let message = until.format('The chaincode instantiate transaction was invalid, code:%s',code);
							logger.error(message);
							reject(new Error(message));
						} else {
							let message = 'The chaincode instantiate transaction was valid.';
							logger.info(message);
							resolve(message);
						}
					}, (err) => {
						clearTimeout(event_timeout);
						logger.error(err);
						reject(err);
					},
						// the default for 'unregister' is true for transaction listeners
						// so no real need to set here, however for 'disconnect'
						// the default is false as most event hubs are long running
						// in this use case we are using it only once
						{unregister: true, disconnect: true}
					);
					eh.connect();
				});
				promises.push(instantiateEventPromise);
			});

			var orderer_request = {
				txId: tx_id, // must include the transaction id so that the outbound
				             // transaction to the orderer will be signed by the admin
							 // id as was the proposal above, notice that transactionID
							 // generated above was based on the admin id not the current
							 // user assigned to the 'client' instance.
				proposalResponses: proposalResponses,
				proposal: proposal
			};
			var sendPromise = channel.sendTransaction(orderer_request);
			// put the send to the orderer last so that the events get registered and
			// are ready for the orderering and committing
			promises.push(sendPromise);
			let results = await Promise.all(promises);
			logger.debug(util.format('------->>> R E S P O N S E : %j', results));
			let response = results.pop(); //  orderer results are last in the results
			if (response.status === 'SUCCESS') {
				logger.info('Successfully sent transaction to the orderer.');
			} else {
				error_message = util.format('Failed to order the transaction. Error code: %s',response.status);
				logger.debug(error_message);
			}

			// now see what each of the event hubs reported
			for(let i in results) {
				let event_hub_result = results[i];
				let event_hub = event_hubs[i];
				logger.debug('Event results for event hub :%s',event_hub.getPeerAddr());
				if(typeof event_hub_result === 'string') {
					logger.debug(event_hub_result);
				} else {
					if(!error_message) error_message = event_hub_result.toString();
					logger.debug(event_hub_result.toString());
				}
			}
		} else {
			error_message = util.format('Failed to send Proposal and receive all good ProposalResponse');
			logger.debug(error_message);
		}
	} catch (error) {
		logger.error('Failed to send instantiate due to error: ' + error.stack ? error.stack : error);
		error_message = error.toString();
	}

	if (!error_message) {
		let message = util.format(
			'Successfully instantiate chaingcode in organization %s to the channel \'%s\'',
			org_name, channelName);
		logger.info(message);
		// build a response to send back to the REST caller
		let response = {
			success: true,
			message: message
		};
		return response;
	} else {
		let message = util.format('Failed to instantiate. cause:%s',error_message);
		logger.error(message);
		throw new Error(message);
	}
};
exports.instantiateChaincode = instantiateChaincode;
```

#### invoke-transaction.js

`invoke-transaction.js` 主要完成事务操作，通过调用指定链码实现对账本状态的操作。

创建 `invoke-transaction.js` 文件并编辑：

```shell
$ vim invoke-transaction.js
```

`invoke-transaction.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var path = require('path');
var fs = require('fs');
var util = require('util');
var hfc = require('fabric-client');
var helper = require('./helper.js');
var logger = helper.getLogger('invoke-chaincode');

var invokeChaincode = async function(peerNames, channelName, chaincodeName, fcn, args, username, org_name) {
	logger.debug(util.format('\n============ invoke transaction on channel %s ============\n', channelName));
	var error_message = null;
	var tx_id_string = null;
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}
		var tx_id = client.newTransactionID();
		// will need the transaction ID string for the event registration later
		tx_id_string = tx_id.getTransactionID();

		// send proposal to endorser
		var request = {
			targets: peerNames,
			chaincodeId: chaincodeName,
			fcn: fcn,
			args: args,
			chainId: channelName,
			txId: tx_id
		};

		let results = await channel.sendTransactionProposal(request);

		// the returned object has both the endorsement results
		// and the actual proposal, the proposal will be needed
		// later when we send a transaction to the orderer
		var proposalResponses = results[0];
		var proposal = results[1];

		// lets have a look at the responses to see if they are
		// all good, if good they will also include signatures
		// required to be committed
		var all_good = true;
		for (var i in proposalResponses) {
			let one_good = false;
			if (proposalResponses && proposalResponses[i].response &&
				proposalResponses[i].response.status === 200) {
				one_good = true;
				logger.info('invoke chaincode proposal was good');
			} else {
				logger.error('invoke chaincode proposal was bad');
			}
			all_good = all_good & one_good;
		}

		if (all_good) {
			logger.info(util.format(
				'Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s", metadata - "%s", endorsement signature: %s',
				proposalResponses[0].response.status, proposalResponses[0].response.message,
				proposalResponses[0].response.payload, proposalResponses[0].endorsement.signature));

			// wait for the channel-based event hub to tell us
			// that the commit was good or bad on each peer in our organization
			var promises = [];
			let event_hubs = channel.getChannelEventHubsForOrg();
			event_hubs.forEach((eh) => {
				logger.debug('invokeEventPromise - setting up event');
				let invokeEventPromise = new Promise((resolve, reject) => {
					let event_timeout = setTimeout(() => {
						let message = 'REQUEST_TIMEOUT:' + eh.getPeerAddr();
						logger.error(message);
						eh.disconnect();
					}, 3000);
					eh.registerTxEvent(tx_id_string, (tx, code, block_num) => {
						logger.info('The chaincode invoke chaincode transaction has been committed on peer %s',eh.getPeerAddr());
						logger.info('Transaction %s has status of %s in blocl %s', tx, code, block_num);
						clearTimeout(event_timeout);

						if (code !== 'VALID') {
							let message = util.format('The invoke chaincode transaction was invalid, code:%s',code);
							logger.error(message);
							reject(new Error(message));
						} else {
							let message = 'The invoke chaincode transaction was valid.';
							logger.info(message);
							resolve(message);
						}
					}, (err) => {
						clearTimeout(event_timeout);
						logger.error(err);
						reject(err);
					},
						// the default for 'unregister' is true for transaction listeners
						// so no real need to set here, however for 'disconnect'
						// the default is false as most event hubs are long running
						// in this use case we are using it only once
						{unregister: true, disconnect: true}
					);
					eh.connect();
				});
				promises.push(invokeEventPromise);
			});

			var orderer_request = {
				txId: tx_id,
				proposalResponses: proposalResponses,
				proposal: proposal
			};
			var sendPromise = channel.sendTransaction(orderer_request);
			// put the send to the orderer last so that the events get registered and
			// are ready for the orderering and committing
			promises.push(sendPromise);
			let results = await Promise.all(promises);
			logger.debug(util.format('------->>> R E S P O N S E : %j', results));
			let response = results.pop(); //  orderer results are last in the results
			if (response.status === 'SUCCESS') {
				logger.info('Successfully sent transaction to the orderer.');
			} else {
				error_message = util.format('Failed to order the transaction. Error code: %s',response.status);
				logger.debug(error_message);
			}

			// now see what each of the event hubs reported
			for(let i in results) {
				let event_hub_result = results[i];
				let event_hub = event_hubs[i];
				logger.debug('Event results for event hub :%s',event_hub.getPeerAddr());
				if(typeof event_hub_result === 'string') {
					logger.debug(event_hub_result);
				} else {
					if(!error_message) error_message = event_hub_result.toString();
					logger.debug(event_hub_result.toString());
				}
			}
		} else {
			error_message = util.format('Failed to send Proposal and receive all good ProposalResponse');
			logger.debug(error_message);
		}
	} catch (error) {
		logger.error('Failed to invoke due to error: ' + error.stack ? error.stack : error);
		error_message = error.toString();
	}

	if (!error_message) {
		let message = util.format(
			'Successfully invoked the chaincode %s to the channel \'%s\' for transaction ID: %s',
			org_name, channelName, tx_id_string);
		logger.info(message);

		return tx_id_string;
	} else {
		let message = util.format('Failed to invoke chaincode. cause:%s',error_message);
		logger.error(message);
		throw new Error(message);
	}
};

exports.invokeChaincode = invokeChaincode;
```

#### query.js

`query.js` 文件中的代码主要完成相关的查询实现，具体功能如下：

- 查询链码信息
- 根据块号查询块信息
- 根据事务ID查询事务信息
- 根据hash获取区块信息
- 查询已安装、实例化的链码信息
- 查询通道信息等功能

创建 `query.js` 文件并编辑：

```shell
$ vim query.js
```

`query.js` 文件完整内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var path = require('path');
var fs = require('fs');
var util = require('util');
var hfc = require('fabric-client');
var helper = require('./helper.js');
var logger = helper.getLogger('Query');

var queryChaincode = async function(peer, channelName, chaincodeName, args, fcn, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}

		// send query
		var request = {
			targets : [peer], //queryByChaincode allows for multiple targets
			chaincodeId: chaincodeName,
			fcn: fcn,
			args: args
		};
		let response_payloads = await channel.queryByChaincode(request);
		if (response_payloads) {
			for (let i = 0; i < response_payloads.length; i++) {
				logger.info(args[0]+' now has ' + response_payloads[i].toString('utf8') +
					' after the move');
			}
			return args[0]+' now has ' + response_payloads[0].toString('utf8') +
				' after the move';
		} else {
			logger.error('response_payloads is null');
			return 'response_payloads is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
var getBlockByNumber = async function(peer, channelName, blockNumber, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}

		let response_payload = await channel.queryBlock(parseInt(blockNumber, peer));
		if (response_payload) {
			logger.debug(response_payload);
			return response_payload;
		} else {
			logger.error('response_payload is null');
			return 'response_payload is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
var getTransactionByID = async function(peer, channelName, trxnID, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}

		let response_payload = await channel.queryTransaction(trxnID, peer);
		if (response_payload) {
			logger.debug(response_payload);
			return response_payload;
		} else {
			logger.error('response_payload is null');
			return 'response_payload is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
var getBlockByHash = async function(peer, channelName, hash, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}

		let response_payload = await channel.queryBlockByHash(Buffer.from(hash), peer);
		if (response_payload) {
			logger.debug(response_payload);
			return response_payload;
		} else {
			logger.error('response_payload is null');
			return 'response_payload is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
var getChainInfo = async function(peer, channelName, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
		}

		let response_payload = await channel.queryInfo(peer);
		if (response_payload) {
			logger.debug(response_payload);
			return response_payload;
		} else {
			logger.error('response_payload is null');
			return 'response_payload is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
//getInstalledChaincodes
var getInstalledChaincodes = async function(peer, channelName, type, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);

		let response = null
		if (type === 'installed') {
			response = await client.queryInstalledChaincodes(peer, true); //use the admin identity
		} else {
			var channel = client.getChannel(channelName);
			if(!channel) {
				let message = util.format('Channel %s was not defined in the connection profile', channelName);
				logger.error(message);
				throw new Error(message);
			}
			response = await channel.queryInstantiatedChaincodes(peer, true); //use the admin identity
		}
		if (response) {
			if (type === 'installed') {
				logger.debug('<<< Installed Chaincodes >>>');
			} else {
				logger.debug('<<< Instantiated Chaincodes >>>');
			}
			var details = [];
			for (let i = 0; i < response.chaincodes.length; i++) {
				logger.debug('name: ' + response.chaincodes[i].name + ', version: ' +
					response.chaincodes[i].version + ', path: ' + response.chaincodes[i].path
				);
				details.push('name: ' + response.chaincodes[i].name + ', version: ' +
					response.chaincodes[i].version + ', path: ' + response.chaincodes[i].path
				);
			}
			return details;
		} else {
			logger.error('response is null');
			return 'response is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};
var getChannels = async function(peer, username, org_name) {
	try {
		// first setup the client for this org
		var client = await helper.getClientForOrg(org_name, username);
		logger.debug('Successfully got the fabric client for the organization "%s"', org_name);

		let response = await client.queryChannels(peer);
		if (response) {
			logger.debug('<<< channels >>>');
			var channelNames = [];
			for (let i = 0; i < response.channels.length; i++) {
				channelNames.push('channel id: ' + response.channels[i].channel_id);
			}
			logger.debug(channelNames);
			return response;
		} else {
			logger.error('response_payloads is null');
			return 'response_payloads is null';
		}
	} catch(error) {
		logger.error('Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};

exports.queryChaincode = queryChaincode;
exports.getBlockByNumber = getBlockByNumber;
exports.getTransactionByID = getTransactionByID;
exports.getBlockByHash = getBlockByHash;
exports.getChainInfo = getChainInfo;
exports.getInstalledChaincodes = getInstalledChaincodes;
exports.getChannels = getChannels;
```

####app.js

应用启动主文件，加载相关配置并进行初始化，通过编写的相应函数发出调用请求。

返回至项目根目录下

```shell
$ cd $HOME/kevin-fabric-sdk-node
```

创建并编辑应用主文件：

```shell
$ vim app.js
```

`app.js` 文件内容如下：

```js
/**
 * Copyright 2017 IBM All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an 'AS IS' BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('SampleWebApp');
var express = require('express');
var session = require('express-session');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var http = require('http');
var util = require('util');
var app = express();
var expressJWT = require('express-jwt');
var jwt = require('jsonwebtoken');
var bearerToken = require('express-bearer-token');
var cors = require('cors');

require('./config.js');
var hfc = require('fabric-client');

var helper = require('./app/helper.js');
var createChannel = require('./app/create-channel.js');
var join = require('./app/join-channel.js');
var install = require('./app/install-chaincode.js');
var instantiate = require('./app/instantiate-chaincode.js');
var invoke = require('./app/invoke-transaction.js');
var query = require('./app/query.js');
var host = process.env.HOST || hfc.getConfigSetting('host');
var port = process.env.PORT || hfc.getConfigSetting('port');
///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// SET CONFIGURATONS ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
app.options('*', cors());
app.use(cors());
//support parsing of application/json type post data
app.use(bodyParser.json());
//support parsing of application/x-www-form-urlencoded post data
app.use(bodyParser.urlencoded({
	extended: false
}));
// set secret variable
app.set('secret', 'thisismysecret');
app.use(expressJWT({
	secret: 'thisismysecret'
}).unless({
	path: ['/users']
}));
app.use(bearerToken());
app.use(function(req, res, next) {
	logger.debug(' ------>>>>>> new request for %s',req.originalUrl);
	if (req.originalUrl.indexOf('/users') >= 0) {
		return next();
	}

	var token = req.token;
	jwt.verify(token, app.get('secret'), function(err, decoded) {
		if (err) {
			res.send({
				success: false,
				message: 'Failed to authenticate token. Make sure to include the ' +
					'token returned from /users call in the authorization header ' +
					' as a Bearer token'
			});
			return;
		} else {
			// add the decoded user name and org name to the request object
			// for the downstream code to use
			req.username = decoded.username;
			req.orgname = decoded.orgName;
			logger.debug(util.format('Decoded from JWT token: username - %s, orgname - %s', decoded.username, decoded.orgName));
			return next();
		}
	});
});

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function() {});
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************',host,port);
server.timeout = 240000;

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	};
	return response;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////// REST ENDPOINTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Register and enroll user
app.post('/users', async function(req, res) {
	var username = req.body.username;
	var orgName = req.body.orgName;
	logger.debug('End point : /users');
	logger.debug('User name : ' + username);
	logger.debug('Org name  : ' + orgName);
	if (!username) {
		res.json(getErrorMessage('\'username\''));
		return;
	}
	if (!orgName) {
		res.json(getErrorMessage('\'orgName\''));
		return;
	}
	var token = jwt.sign({
		exp: Math.floor(Date.now() / 1000) + parseInt(hfc.getConfigSetting('jwt_expiretime')),
		username: username,
		orgName: orgName
	}, app.get('secret'));
	let response = await helper.getRegisteredUser(username, orgName, true);
	logger.debug('-- returned from registering the username %s for organization %s',username,orgName);
	if (response && typeof response !== 'string') {
		logger.debug('Successfully registered the username %s for organization %s',username,orgName);
		response.token = token;
		res.json(response);
	} else {
		logger.debug('Failed to register the username %s for organization %s with::%s',username,orgName,response);
		res.json({success: false, message: response});
	}

});
// Create Channel
app.post('/channels', async function(req, res) {
	logger.info('<<<<<<<<<<<<<<<<< C R E A T E  C H A N N E L >>>>>>>>>>>>>>>>>');
	logger.debug('End point : /channels');
	var channelName = req.body.channelName;
	var channelConfigPath = req.body.channelConfigPath;
	logger.debug('Channel name : ' + channelName);
	logger.debug('channelConfigPath : ' + channelConfigPath); //../artifacts/channel/mychannel.tx
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!channelConfigPath) {
		res.json(getErrorMessage('\'channelConfigPath\''));
		return;
	}

	let message = await createChannel.createChannel(channelName, channelConfigPath, req.username, req.orgname);
	res.send(message);
});
// Join Channel
app.post('/channels/:channelName/peers', async function(req, res) {
	logger.info('<<<<<<<<<<<<<<<<< J O I N  C H A N N E L >>>>>>>>>>>>>>>>>');
	var channelName = req.params.channelName;
	var peers = req.body.peers;
	logger.debug('channelName : ' + channelName);
	logger.debug('peers : ' + peers);
	logger.debug('username :' + req.username);
	logger.debug('orgname:' + req.orgname);

	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!peers || peers.length == 0) {
		res.json(getErrorMessage('\'peers\''));
		return;
	}

	let message =  await join.joinChannel(channelName, peers, req.username, req.orgname);
	res.send(message);
});
// Install chaincode on target peers
app.post('/chaincodes', async function(req, res) {
	logger.debug('==================== INSTALL CHAINCODE ==================');
	var peers = req.body.peers;
	var chaincodeName = req.body.chaincodeName;
	var chaincodePath = req.body.chaincodePath;
	var chaincodeVersion = req.body.chaincodeVersion;
	var chaincodeType = req.body.chaincodeType;
	logger.debug('peers : ' + peers); // target peers list
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('chaincodePath  : ' + chaincodePath);
	logger.debug('chaincodeVersion  : ' + chaincodeVersion);
	logger.debug('chaincodeType  : ' + chaincodeType);
	if (!peers || peers.length == 0) {
		res.json(getErrorMessage('\'peers\''));
		return;
	}
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!chaincodePath) {
		res.json(getErrorMessage('\'chaincodePath\''));
		return;
	}
	if (!chaincodeVersion) {
		res.json(getErrorMessage('\'chaincodeVersion\''));
		return;
	}
	if (!chaincodeType) {
		res.json(getErrorMessage('\'chaincodeType\''));
		return;
	}
	let message = await install.installChaincode(peers, chaincodeName, chaincodePath, chaincodeVersion, chaincodeType, req.username, req.orgname)
	res.send(message);});
// Instantiate chaincode on target peers
app.post('/channels/:channelName/chaincodes', async function(req, res) {
	logger.debug('==================== INSTANTIATE CHAINCODE ==================');
	var peers = req.body.peers;
	var chaincodeName = req.body.chaincodeName;
	var chaincodeVersion = req.body.chaincodeVersion;
	var channelName = req.params.channelName;
	var chaincodeType = req.body.chaincodeType;
	var fcn = req.body.fcn;
	var args = req.body.args;
	logger.debug('peers  : ' + peers);
	logger.debug('channelName  : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('chaincodeVersion  : ' + chaincodeVersion);
	logger.debug('chaincodeType  : ' + chaincodeType);
	logger.debug('fcn  : ' + fcn);
	logger.debug('args  : ' + args);
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!chaincodeVersion) {
		res.json(getErrorMessage('\'chaincodeVersion\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!chaincodeType) {
		res.json(getErrorMessage('\'chaincodeType\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	let message = await instantiate.instantiateChaincode(peers, channelName, chaincodeName, chaincodeVersion, chaincodeType, fcn, args, req.username, req.orgname);
	res.send(message);
});
// Invoke transaction on chaincode on target peers
app.post('/channels/:channelName/chaincodes/:chaincodeName', async function(req, res) {
	logger.debug('==================== INVOKE ON CHAINCODE ==================');
	var peers = req.body.peers;
	var chaincodeName = req.params.chaincodeName;
	var channelName = req.params.channelName;
	var fcn = req.body.fcn;
	var args = req.body.args;
	logger.debug('channelName  : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('fcn  : ' + fcn);
	logger.debug('args  : ' + args);
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!fcn) {
		res.json(getErrorMessage('\'fcn\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, fcn, args, req.username, req.orgname);
	res.send(message);
});
// Query on chaincode on target peers
app.get('/channels/:channelName/chaincodes/:chaincodeName', async function(req, res) {
	logger.debug('==================== QUERY BY CHAINCODE ==================');
	var channelName = req.params.channelName;
	var chaincodeName = req.params.chaincodeName;
	let args = req.query.args;
	let fcn = req.query.fcn;
	let peer = req.query.peer;

	logger.debug('channelName : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('fcn : ' + fcn);
	logger.debug('args : ' + args);

	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!fcn) {
		res.json(getErrorMessage('\'fcn\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}
	args = args.replace(/'/g, '"');
	args = JSON.parse(args);
	logger.debug(args);

	let message = await query.queryChaincode(peer, channelName, chaincodeName, args, fcn, req.username, req.orgname);
	res.send(message);
});
//  Query Get Block by BlockNumber
app.get('/channels/:channelName/blocks/:blockId', async function(req, res) {
	logger.debug('==================== GET BLOCK BY NUMBER ==================');
	let blockId = req.params.blockId;
	let peer = req.query.peer;
	logger.debug('channelName : ' + req.params.channelName);
	logger.debug('BlockID : ' + blockId);
	logger.debug('Peer : ' + peer);
	if (!blockId) {
		res.json(getErrorMessage('\'blockId\''));
		return;
	}

	let message = await query.getBlockByNumber(peer, req.params.channelName, blockId, req.username, req.orgname);
	res.send(message);
});
// Query Get Transaction by Transaction ID
app.get('/channels/:channelName/transactions/:trxnId', async function(req, res) {
	logger.debug('================ GET TRANSACTION BY TRANSACTION_ID ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let trxnId = req.params.trxnId;
	let peer = req.query.peer;
	if (!trxnId) {
		res.json(getErrorMessage('\'trxnId\''));
		return;
	}

	let message = await query.getTransactionByID(peer, req.params.channelName, trxnId, req.username, req.orgname);
	res.send(message);
});
// Query Get Block by Hash
app.get('/channels/:channelName/blocks', async function(req, res) {
	logger.debug('================ GET BLOCK BY HASH ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let hash = req.query.hash;
	let peer = req.query.peer;
	if (!hash) {
		res.json(getErrorMessage('\'hash\''));
		return;
	}

	let message = await query.getBlockByHash(peer, req.params.channelName, hash, req.username, req.orgname);
	res.send(message);
});
//Query for Channel Information
app.get('/channels/:channelName', async function(req, res) {
	logger.debug('================ GET CHANNEL INFORMATION ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let peer = req.query.peer;

	let message = await query.getChainInfo(peer, req.params.channelName, req.username, req.orgname);
	res.send(message);
});
//Query for Channel instantiated chaincodes
app.get('/channels/:channelName/chaincodes', async function(req, res) {
	logger.debug('================ GET INSTANTIATED CHAINCODES ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let peer = req.query.peer;

	let message = await query.getInstalledChaincodes(peer, req.params.channelName, 'instantiated', req.username, req.orgname);
	res.send(message);
});
// Query to fetch all Installed/instantiated chaincodes
app.get('/chaincodes', async function(req, res) {
	var peer = req.query.peer;
	var installType = req.query.type;
	logger.debug('================ GET INSTALLED CHAINCODES ======================');

	let message = await query.getInstalledChaincodes(peer, null, 'installed', req.username, req.orgname)
	res.send(message);
});
// Query to fetch channels
app.get('/channels', async function(req, res) {
	logger.debug('================ GET CHANNELS ======================');
	logger.debug('peer: ' + req.query.peer);
	var peer = req.query.peer;
	if (!peer) {
		res.json(getErrorMessage('\'peer\''));
		return;
	}

	let message = await query.getChannels(peer, req.username, req.orgname);
	res.send(message);
});
```



### 运行示例程序

一切就绪，现在可以开始测试我们的应用程序了。

#### 终端窗口 1

- 进入项目根目录：

  ```shell
  $ cd $HOME/kevin-fabric-sdk-node
  ```

- 使用 docker-compose 命令启动网络

  ```shell
  $ docker-compose -f artifacts/docker-compose.yaml up
  ```

#### 终端窗口 2

- 进入项目根目录，安装 `gulp`：

  ```shell
  $ cd $HOME/kevin-fabric-sdk-node
  $ npm install -g gulp
  ```

- 安装 `fabric-client` 与 `fabric-ca-client` 模块

  ```shell
  $ npm install
  ```

  执行成功如下信息：

  ![npm-install-ok](./img/npm-install-ok.png)

- 启动 node app 指定 PORT 为 4000

  ```shell
  $ PORT=4000 node app
  ```


  启动成功如下图所示：

  ![node app](./img/node-app.png)

#### 终端窗口 3

- 执行 REST APIs 参见 <a href="#restapis">REST APIs 调用请求</a>

### <a name="restapis">REST APIs 调用请求</a>

#### 登录请求

在终端窗口3中执行：

```shell
$ cd $HOME/kevin-fabric-sdk-node
```

- 在 **Org1** 组织中注册并登记一个新的用户:

```shell
$ curl -s -X POST \
	http://localhost:4000/users \
	-H "content-type: application/x-www-form-urlencoded" \
	-d 'username=Jim&orgName=Org1'
```

> 如果出现502错误，那么使用 `unset http_proxy` 取消/关闭代理即可。

**终端输出如下响应信息:**

```shell
{
  "success": true,
  "secret": "RaxhMgevgJcm",
  "message": "Jim enrolled Successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NDIwNTA5MTYsInVzZXJuYW1lIjoiSmltIiwib3JnTmFtZSI6Ik9yZzEiLCJpYXQiOjE1NDIwMTQ5MTZ9.Lw23sTb5JjyCpcf6mep-NjvoOFaPfA60VbkRGRwtqXU"
}
```

**注意：**响应信息包含成功/失败的状态，**注册密钥**和**JSON Web令牌（JWT）**，它是后续请求的请求标头中的所必需字符串

#### 创建通道请求

```shell
$ curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"kevinkongyixueyuan",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
```

**请注意**，Header **授权**必须包含`POST /users`通话中返回的 **JWT**

执行成功终端输出如下响应信息：

```shell
{
	"success":true,
	"message":"Channel 'kevinkongyixueyuan' created Successfully"
}
```

#### 加入通道请求

```shell
$ curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/peers \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"]
}'
```

执行成功终端输出如下响应信息：

```shell
{
	"success":true,
	"message":"Successfully joined peers in organization Org1 to the channel:kevinkongyixueyuan"
}
```

#### 安装链码

```shell
$ curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeType": "golang",
	"chaincodeVersion":"v0"
}'
```

> **注意：** 当使用node.js链*代码时，*必须将*chaincodeType*设置为**node**，并且必须将*chaincodePath*设置为node.js chaincode的位置。也加入了$PWD
>
> ```shell
> 如下:
> $ curl -s -X POST \
> http://localhost:4000/chaincodes \
> -H "authorization: Bearer <put JSON Web Token here>" \
> -H "content-type: application/json" \
> -d '{
> "peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"],
> "chaincodeName":"mycc",
> "chaincodePath":"$PWD/artifacts/src/github.com/example_cc/node",
> "chaincodeType": "node",
> "chaincodeVersion":"v0"
> }'
> ```

执行成功终端输出如下响应信息：

```shell
{
	"success":true,
	"message":"Successfully install chaincode"
}
```



#### 实例化链码

```shell
$ curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/chaincodes \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json" \
  -d '{
    "peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"],
	"chaincodeName":"mycc",
	"chaincodeVersion":"v0",
	"chaincodeType": "golang",
	"args":["a","100","b","200"]
}'
```

执行成功终端输出如下：

```shell
{
	"success":true,
	"message":"Successfully instantiate chaingcode in organization Org1 to the channel 'kevinkongyixueyuan'"
}
```

#### 调用链码请求

```shell
$ curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/chaincodes/mycc \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"],
	"fcn":"move",
	"args":["a","b","10"]
}'
```

**注意：** 当使用node.js链代码时，必须将*chaincodeType*设置为**node**

执行成功终端中输出响应的**事务ID**

```shell
c499c8b010f0af518384730f9d01b6e106ea084ec6794751f9235e897afefd09
```

**注意：**请保存响应信息的事务ID，在后续查询事务中会使用到此字符串。

#### 查询链码

```shell
$ curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/chaincodes/mycc?peer=peer0.org1.kevin.kongyixueyuan.com&fcn=query&args=%5B%22a%22%5D" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

执行成功终端中输出如下响应信息：

```shell
a now has 90 after the move
```

#### 根据块号查询块

```shell
$ curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/blocks/1?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

#### 根据 TransactionID 查询事务

```shell
$ curl -s -X GET http://localhost:4000/channels/kevinkongyixueyuan/transactions/$TRX_ID?peer=peer0.org1.kevin.kongyixueyuan.com \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"
```

**注意**：事务ID来自于之前的事务调用

#### 查询 ChainInfo

```shell
$ curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

执行成功终端中输出如下响应信息：

```json
{"height":{"low":3,"high":0,"unsigned":true},"currentBlockHash":{"buffer":{"type":"Buffer","data":[8,3,18,32,90,58,37,82,74,234,234,178,22,93,187,246,79,177,37,66,84,226,156,100,61,35,120,220,166,146,193,20,143,34,221,57,26,32,137,149,94,253,17,79,72,43,212,158,153,70,25,218,146,32,22,125,198,104,249,102,21,157,183,90,12,28,111,246,17,66]},"offset":4,"markedOffset":-1,"limit":36,"littleEndian":true,"noAssert":false},"previousBlockHash":{"buffer":{"type":"Buffer","data":[8,3,18,32,90,58,37,82,74,234,234,178,22,93,187,246,79,177,37,66,84,226,156,100,61,35,120,220,166,146,193,20,143,34,221,57,26,32,137,149,94,253,17,79,72,43,212,158,153,70,25,218,146,32,22,125,198,104,249,102,21,157,183,90,12,28,111,246,17,66]},"offset":38,"markedOffset":-1,"limit":70,"littleEndian":true,"noAssert":false}}
```

#### 查询已安装的链代码

```shell
$ curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

执行成功终端中输出如下响应信息：

```json
["name: mycc, version: v0, path: github.com/example_cc"]
```

#### 查询实例化链代码

```shell
$ curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/chaincodes?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

执行成功终端中输出如下响应信息：

```json
["name: mycc, version: v0, path: github.com/example_cc"]
```

#### 查询通道

```shell
$ curl -s -X GET \
  "http://localhost:4000/channels?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer <put JSON Web Token here>" \
  -H "content-type: application/json"  
```

执行成功终端中输出如下响应信息：

```json
{"channels":[{"channel_id":"kevinkongyixueyuan"}]}
```

#### 发现IP地址

要检索某个网络实体的IP地址，请使用如下命令：

```shell
# this will return the IP Address for peer0
$ docker inspect peer0 | grep IPAddress
```

### 关闭并清理网络

创建清理网络的脚本文件：

```shell
$ cd $HOME/kevin-fabric-sdk-node
$ vim shutdownnetwork.sh
```

文件中添加如下内容：

```shell
echo "shutdown fabric-network"
echo
docker-compose -f artifacts/docker-compose.yaml down
echo

echo "docker rm -f $(docker ps -aq)"
echo
docker rm -f $(docker ps -aq)
echo

echo "docker rmi -f $(docker images | grep dev | awk '{print $3}')"
echo
docker rmi -f $(docker images | grep dev | awk '{print $3}')
echo

echo "Delete current dir org-kv"
echo
rm -rf fabric-client-kv-org[1-2]
echo

echo "Delete tmp dir org-kv"
echo
rm -rf /tmp/fabric-client-kv-org[1-2]
echo

echo "shutdown and clear OK"
```

添加可执行权限并执行：

```shell
$ chmod 777 ./shutdownnetwork.sh
$ ./shutdownnetwork.sh
```



### 自动化测试

之前的方式，需要我们每次都要输入命令，这样操作的话比较麻烦，所以现在我们对其进行简化，没有必要每次都输入一长串的命令来执行，而是将命令写在指定的脚本文件中，以后直接执行该脚本文件即可，此方式大大简化了测试步骤，提高效率。

#### 终端窗口 1

进入项目根目录：

```shell
$ cd $HOME/kevin-fabric-sdk-node
```

安装 `gulp`：

```shell
$ npm install -g gulp
```
#####创建 `runApp.sh` 文件并编辑

```shell
$ vim runApp.sh
```

 `runApp.sh` 脚本文件具体作用如下：

- 在本地计算机上启动通过配置指定的网络环境
- 安装 `fabric-client` 和 `fabric-ca-client` 节点模块
- 并在PORT 4000上启动应用程序

`runApp.sh` 文件完整内容如下：

```shell
#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

function dkcl(){
        CONTAINER_IDS=$(docker ps -aq)
	echo
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "========== No containers available for deletion =========="
        else
                docker rm -f $CONTAINER_IDS
        fi
	echo
}

function dkrm(){
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
	echo
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
		echo "========== No images available for deletion ==========="
        else
                docker rmi -f $DOCKER_IMAGE_IDS
        fi
	echo
}

function restartNetwork() {
	echo

        #teardown the network and clean the containers and intermediate images
	cd artifacts
	docker-compose down
	dkcl
	dkrm

	#Cleanup the material
	rm -rf /tmp/hfc-test-kvs_peerOrg* $HOME/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*

	#Start the network
	docker-compose up -d
	cd -
	echo
}

function installNodeModules() {
	echo
	if [ -d node_modules ]; then
		echo "============== node modules installed already ============="
	else
		echo "============== Installing node modules ============="
		npm install
	fi
	echo
}


restartNetwork

installNodeModules

PORT=4000 node app

```

#####添加可执行权限并执行 `runApp.sh` 脚本：

```shell
$ chmod 777 ./runApp.sh
$ ./runApp.sh
```



#### 终端窗口 2

为了使 shell 脚本能够正确解析JSON，您必须安装 `jq`，详情请 [参见此处](https://stedolan.github.io/jq/)

**安装jq**

```shell
$ sudo apt update
$ sudo apt install -y jq
```

进入项目根目录中：

```shell
$ cd $HOME/kevin-fabric-sdk-node
```

#####创建并编辑 `testAPIs.sh` 脚本文件

```shell
$ vim testAPIs.sh
```

`testAPIs.sh` 脚本文件的主要作用如下：

- 创建用户
- 创建通道
- 安装链码
- 实例化链码
- 调用链码
- 调用链码查询
- 执行其它查询

`testAPIs.sh` 文件完整内容如下：

```shell
#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./testAPIs.sh -l golang|node"
  echo "    -l <language> - chaincode language (defaults to \"golang\")"
}
# Language defaults to "golang"
LANGUAGE="golang"

# Parse commandline args
while getopts "h?l:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
  esac
done

##set chaincode path
function setChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_SRC_PATH="github.com/example_cc"
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/example_cc/node"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

setChaincodePath

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=Org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=Org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo
echo
echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"kevinkongyixueyuan",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo
sleep 5
echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"]
}'
echo
echo

echo "POST request Join channel on Org2"
echo
curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org2.kevin.kongyixueyuan.com","peer1.org2.kevin.kongyixueyuan.com"]
}'
echo
echo

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.kevin.kongyixueyuan.com\",\"peer1.org1.kevin.kongyixueyuan.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.kevin.kongyixueyuan.com\",\"peer1.org2.kevin.kongyixueyuan.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST instantiate chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"mycc\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST invoke chaincode on peers of Org1"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/kevinkongyixueyuan/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.kevin.kongyixueyuan.com","peer1.org1.kevin.kongyixueyuan.com"],
	"fcn":"move",
	"args":["a","b","10"]
}')
echo "Transaction ID is $TRX_ID"
echo
echo

echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/chaincodes/mycc?peer=peer0.org1.kevin.kongyixueyuan.com&fcn=query&args=%5B%22a%22%5D" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Block by blockNumber"
echo
curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/blocks/1?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Transaction by TransactionID"
echo
curl -s -X GET http://localhost:4000/channels/kevinkongyixueyuan/transactions/$TRX_ID?peer=peer0.org1.kevin.kongyixueyuan.com \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

############################################################################
### TODO: What to pass to fetch the Block information
############################################################################
#echo "GET query Block by Hash"
#echo
#hash=????
#curl -s -X GET \
#  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
#  -H "authorization: Bearer $ORG1_TOKEN" \
#  -H "cache-control: no-cache" \
#  -H "content-type: application/json" \
#  -H "x-access-token: $ORG1_TOKEN"
#echo
#echo

echo "GET query ChainInfo"
echo
curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Installed chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Instantiated chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/channels/kevinkongyixueyuan/chaincodes?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Channels"
echo
curl -s -X GET \
  "http://localhost:4000/channels?peer=peer0.org1.kevin.kongyixueyuan.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
```

应用程序在终端1中启动之后，接下来，我们通过执行 **testAPIs.sh** 脚本来测试API ：

#####添加可执行权限并执行 `testAPIs.sh` 脚本：

```shell
$ chmod 777 ./testAPIs.sh
$ ./testAPIs.sh
```

### 关闭并清理网络

创建清理网络的脚本文件：

```shell
$ cd $HOME/kevin-fabric-sdk-node
$ vim stopAPP.sh
```

文件中添加如下内容：

```shell
echo "shutdown fabric-network"
echo
docker-compose -f artifacts/docker-compose.yaml down
echo

echo "docker rm -f $(docker ps -aq)"
echo
docker rm -f $(docker ps -aq)
echo

echo "docker rmi -f $(docker images | grep dev | awk '{print $3}')"
echo
docker rmi -f $(docker images | grep dev | awk '{print $3}')
echo

echo "Delete current dir org-kv"
echo
rm -rf fabric-client-kv-org[1-2]
echo

echo "Delete tmp dir org-kv"
echo
rm -rf /tmp/fabric-client-kv-org[1-2]
echo

echo "shutdown and clear OK"
```

添加可执行权限并执行：

```shell
$ chmod 777 ./stopAPP.sh
$ ./stopAPP.sh
```





[![Creative Commons License](https://camo.githubusercontent.com/005cfe27b7c4520ac0d6b607d6a7e33f5ad4eb6e/68747470733a2f2f692e6372656174697665636f6d6d6f6e732e6f72672f6c2f62792f342e302f38387833312e706e67)](http://creativecommons.org/licenses/by/4.0/)
This work is licensed under a [Creative Commons Attribution 4.0 International License](http://creativecommons.org/licenses/by/4.0/).

###参考资料

- [Hyperledger 官网](https://www.hyperledger.org/)

- [Hyperledger Fabric 在线文档](https://hyperledger-fabric.readthedocs.io/en/latest//)

- [Hyperledger Fabric-SDK-Node](https://github.com/hyperledger/fabric-sdk-node)

- [Node SDK documentation](https://fabric-sdk-node.github.io/)

- [fabric-samples balance-transfer](https://github.com/hyperledger/fabric-samples/tree/release/balance-transfer)




