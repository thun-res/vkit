# 自建项目教程

本文档重点讲两件事：

1. 如何把你自己的项目接入到 VKit
2. 如何一步一步让它能够被导入、被配置、被构建、被打包

本文不再展开介绍具体第三方库本身，而是聚焦用户最关心的流程：自定义项目如何落地。

## 目录

- [理解 VKit 项目结构](#理解-vkit-项目结构)
- [教程一：创建本地基础库项目](#教程一创建本地基础库项目)
- [教程二：创建中间件组件](#教程二创建中间件组件)
- [教程三：创建应用程序](#教程三创建应用程序)
- [教程四：导入已有 Git 项目](#教程四导入已有-git-项目)
- [进阶：多平台支持](#进阶多平台支持)
- [进阶：自定义构建脚本](#进阶自定义构建脚本)
- [完整示例项目](#完整示例项目)

---

## 理解 VKit 项目结构

VKit 把项目分为四层：

```text
thirdparty/
vendor/
middleware/
app/
```

但对最终用户来说，真正要理解的是两件事：

### 1. 项目代码放在哪里

你可以选择：

- 本地直接放目录
- 通过 `.repos` 从 Git 仓库导入

### 2. 项目如何进入构建

无论代码从哪里来，最终都必须写入：

```text
config/<platform>/thirdparty.cfg
config/<platform>/vendor.cfg
config/<platform>/middleware.cfg
config/<platform>/app.cfg
```

只要你能把这两步理顺，VKit 就能接住你的项目。

---

## 教程一：创建本地基础库项目

这一节用一个最小公共库项目说明 VKit 的接入方法。这个套路既可以放在 `thirdparty/`，也可以放在 `middleware/` 或 `vendor/`。

### 场景

创建一个本地公共库：

```text
middleware/my-base-lib
```

### 步骤 1：创建目录

```bash
mkdir -p middleware/my-base-lib/include/my_base_lib
mkdir -p middleware/my-base-lib/src
```

### 步骤 2：编写头文件和源码

`middleware/my-base-lib/include/my_base_lib/hello.h`

```cpp
#pragma once

#include <string>

std::string my_base_lib_hello();
```

`middleware/my-base-lib/src/hello.cpp`

```cpp
#include "my_base_lib/hello.h"

std::string my_base_lib_hello() {
    return "hello from my-base-lib";
}
```

### 步骤 3：编写 `CMakeLists.txt`

`middleware/my-base-lib/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.16)
project(my-base-lib VERSION 1.0.0 LANGUAGES CXX)

add_library(my-base-lib src/hello.cpp)

target_include_directories(my-base-lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_compile_features(my-base-lib PUBLIC cxx_std_17)

install(TARGETS my-base-lib
    EXPORT my-base-libTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/ DESTINATION include)

install(EXPORT my-base-libTargets
    FILE my-base-libTargets.cmake
    NAMESPACE my_base_lib::
    DESTINATION lib/cmake/my-base-lib
)
```

### 步骤 4：注册到 cfg

编辑：

```text
config/linux-x86_64/middleware.cfg
```

加入：

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-base-lib;
```

### 步骤 5：构建验证

```bash
source vkit-setup.sh
cd middleware/my-base-lib
mmm
```

### 步骤 6：检查安装结果

```bash
ls $VKIT_PREBUILT_DIR/lib
ls $VKIT_PREBUILT_DIR/include/my_base_lib
```

如果这一步通过，说明你已经掌握了“本地项目接入 VKit”的最小闭环。

---

## 教程二：创建中间件组件

接下来创建一个真正的中间件服务：

```text
middleware/my-service
```

### 步骤 1：创建目录

```bash
mkdir -p middleware/my-service/src
mkdir -p middleware/my-service/etc
```

### 步骤 2：编写源码

`middleware/my-service/src/main.cpp`

```cpp
#include <iostream>

int main() {
    std::cout << "my-service started" << std::endl;
    return 0;
}
```

### 步骤 3：编写 `CMakeLists.txt`

`middleware/my-service/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.16)
project(my-service VERSION 1.0.0 LANGUAGES CXX)

add_executable(my-service src/main.cpp)
target_compile_features(my-service PRIVATE cxx_std_17)

install(TARGETS my-service
    RUNTIME DESTINATION bin
)

install(FILES etc/my-service.yaml
    DESTINATION etc/my-service
    OPTIONAL
)
```

### 步骤 4：准备默认配置

`middleware/my-service/etc/my-service.yaml`

```yaml
service_name: my-service
log_level: info
```

### 步骤 5：把项目加入构建层

编辑：

```text
config/linux-x86_64/middleware.cfg
```

写成：

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-base-lib;
middleware/my-service;
```

如果你的服务依赖 `my-base-lib`，就必须把它排在后面。

### 步骤 6：构建

```bash
source vkit-setup.sh
cd middleware/my-service
mmm
```

或者整层构建：

```bash
mm_middleware
```

### 步骤 7：运行

```bash
$VKIT_PREBUILT_DIR/bin/my-service
```

---

## 教程三：创建应用程序

应用层接入方式与中间件层完全一致，只是目录和 cfg 文件不同。

### 场景

创建：

```text
app/my-tool
```

### 步骤 1：创建目录和源码

```bash
mkdir -p app/my-tool/src
```

`app/my-tool/src/main.cpp`

```cpp
#include <iostream>

int main() {
    std::cout << "my-tool running" << std::endl;
    return 0;
}
```

### 步骤 2：编写 `CMakeLists.txt`

`app/my-tool/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.16)
project(my-tool VERSION 1.0.0 LANGUAGES CXX)

add_executable(my-tool src/main.cpp)
target_compile_features(my-tool PRIVATE cxx_std_17)

install(TARGETS my-tool
    RUNTIME DESTINATION bin
)
```

### 步骤 3：注册到应用层配置

编辑：

```text
config/linux-x86_64/app.cfg
```

加入：

```text
app/my-tool;
```

### 步骤 4：构建和验证

```bash
source vkit-setup.sh
cd app/my-tool
mmm
```

或者：

```bash
mm_app
```

构建成功后：

```bash
$VKIT_PREBUILT_DIR/bin/my-tool
```

---

## 教程四：导入已有 Git 项目

这一节解决用户最容易缺失的一步：如何把已有远程仓库真正接进 VKit。

### 场景

假设你已经有一个远程 Git 仓库：

```text
git@github.com:myorg/my-service.git
```

希望它进入：

```text
middleware/my-service
```

### 步骤 1：选择导入变体

如果你只是扩展现有完整工作区，可以直接修改：

```text
repos/full/middleware.repos
```

如果你不想影响默认 `full`，建议复制出一个新变体：

```bash
cp -r repos/full repos/my-workspace
```

### 步骤 2：在 `.repos` 中增加条目

编辑：

```text
repos/my-workspace/middleware.repos
```

加入：

```yaml
repositories:
  middleware/vlink:
    type: git
    url: https://github.com/thun-res/vlink.git
    version: master
  middleware/vlink-msgs:
    type: git
    url: https://github.com/thun-res/vlink-msgs.git
    version: master
  middleware/my-service:
    type: git
    url: git@github.com:myorg/my-service.git
    version: main
```

### 步骤 3：执行导入

```bash
make import my-workspace
```

或者：

```bash
./vkit-setup.sh import my-workspace
```

### 步骤 4：确认源码已经到位

```bash
ls middleware/my-service
```

### 步骤 5：把它加入 cfg

编辑：

```text
config/linux-x86_64/middleware.cfg
```

加入：

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-service;
```

### 步骤 6：构建

```bash
source vkit-setup.sh
cd middleware/my-service
mmm
```

### 步骤 7：打包验证

```bash
make deploy
```

然后检查：

```bash
tar tzf packup/vkit-linux-x86_64-runtime.tgz | grep my-service
```

### 应用项目的导入方法

如果你导入的是应用项目，规则完全一样，只需把路径改到：

```text
app/my-tool
```

并把仓库条目放进：

```text
repos/<variant>/app.repos
```

构建注册放进：

```text
config/<platform>/app.cfg
```

---

## 进阶：多平台支持

如果你的项目需要在多个平台构建，最直接的方法不是在 CMake 里硬编码所有差异，而是：

1. 让项目本身保持通用
2. 把平台差异尽量写进不同平台的 cfg

例如：

```text
config/linux-x86_64/app.cfg
app/my-tool; -DMY_TOOL_BACKEND=epoll
```

```text
config/qnx-aarch64/app.cfg
app/my-tool; -DMY_TOOL_BACKEND=qnx
```

如果某个项目只属于特定设备，可以再用：

```bash
export VKIT_DEVICE=mydevice
```

并提供：

```text
config/linux-x86_64-mydevice/
```

---

## 进阶：自定义构建脚本

VKit 优先支持 CMake，但也兼容：

- `build.sh`
- `Makefile`

如果项目不是标准 CMake，可以提供：

```text
build.sh
```

最小示例：

```bash
#!/usr/bin/env bash
set -e

mkdir -p "$VKIT_PREBUILT_DIR/bin"
g++ -O2 src/main.cpp -o "$VKIT_PREBUILT_DIR/bin/my-tool"
```

只要你的脚本最终把产物安装到：

- `$VKIT_PREBUILT_DIR`
- 或 `$VKIT_PREBUILT_EXT_DIR`

VKit 的后续打包流程就能接住它。

但如果没有特别原因，仍然建议优先使用 CMake，因为这样：

- `mm`
- `mmm`
- `cmake --install`
- `deploy`

这条链路最完整、最稳定。

---

## 完整示例项目

你可以把“自建项目接入”简单记成下面这张检查清单：

### 本地项目接入

1. 在 `middleware/` 或 `app/` 下创建目录
2. 写好 `CMakeLists.txt`
3. 确保有 `install(...)`
4. 在 `config/<platform>/*.cfg` 中注册路径
5. `source vkit-setup.sh`
6. 进入目录执行 `mmm`
7. 检查 `$VKIT_PREBUILT_DIR`
8. 执行 `make deploy`

### 远程仓库导入接入

1. 选定 `repos/<variant>/`
2. 在对应 `.repos` 文件中增加 Git 条目
3. 执行 `make import <variant>`
4. 确认源码已落到目标目录
5. 在 `config/<platform>/*.cfg` 中注册
6. `source vkit-setup.sh`
7. 使用 `mmm` 或分层命令构建
8. 执行打包验证

如果你已经能独立完成上面两套流程，就已经掌握了 VKit 对自定义项目的核心使用方式。
