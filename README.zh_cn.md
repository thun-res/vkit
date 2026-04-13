# VKit - 集成化跨平台构建与包管理系统

<p align="center">
  <strong>统一的多平台 C/C++ 项目构建编排与 SDK 部署系统</strong>
</p>

<p align="center">
  <em>类似于 vcpkg 和 Conan，但设计为面向 VLink 中间件生态的完整集成化构建系统</em>
</p>

---

## 概述

VKit 是一个集成化的跨平台构建工具，管理 C/C++ 软件项目的完整生命周期：从**仓库管理**和**依赖构建**，经过**交叉编译**和**中间件集成**，到**打包和 SDK 部署**。

与独立包管理器（vcpkg、Conan）不同，VKit 提供：

- **统一环境配置** - 一条命令配置完整构建环境
- **分层构建系统** - 有序构建流水线：thirdparty → vendor → middleware → app
- **预置宿主工具** - 内置 cmake、ninja、protoc、flatc 等构建工具
- **多平台交叉编译** - 开箱即用的 9 种平台配置
- **仓库编排管理** - 将多个 git 仓库作为统一工作空间管理，并支持用户自定义导入变体
- **SDK 与运行时打包** - 生成可分发的归档包和初始化脚本

![架构总览](doc/images/architecture-overview.png)

## 支持的平台

| 平台 | 架构 | 配置 ID |
|------|------|---------|
| **Linux** | x86_64 | `linux-x86_64` |
| **Linux** | aarch64 | `linux-aarch64` |
| **macOS** | arm64 (Apple Silicon) | `darwin-arm64` |
| **macOS** | x86_64 (Intel) | `darwin-x86_64` |
| **Android** | aarch64 | `android-aarch64` |
| **Android** | x86_64 | `android-x86_64` |
| **QNX** | aarch64 | `qnx-aarch64` |
| **QNX** | x86_64 | `qnx-x86_64` |
| **Windows** | x86_64 | `win32-x86_64` |

![平台支持矩阵](doc/images/platform-support.png)

## 快速开始

### 1. 克隆 VKit

```bash
git clone https://github.com/thun-res/vkit.git
cd vkit
```

### 2. 先把根目录 `Makefile` 当成“整仓入口”

如果你现在站在仓库根目录，想做的是“导入整个工作区、整仓构建、整仓清理、整仓打包”，那最自然的入口就是根目录 `Makefile`。

这里不要按散命令记，按场景记会更顺。

**首次拉起完整工作区：**

```bash
make import full
make install
make deploy
```

**首次先拉一个轻量工作区：**

```bash
make import dev
make install
```

**已有工作区，只做同步和重建：**

```bash
make pull
make install
```

**想一条命令构建并打包：**

```bash
make
```

它等价于：

```bash
make install
make deploy
```

其他常用补充命令：

```bash
make deploy_sdk
make clean
make rclean
make dclean
make -j8 install
```

打包结果会出现在 `packup/` 目录，例如：

- `packup/vkit-linux-x86_64-runtime.tgz`
- `packup/vkit-linux-x86_64-sdk.tgz`

### 3. 日常开发再切到 `source` 模式

当你需要 `mm`、`mmm`、按层构建时，再进入 VKit 环境。

**Linux / macOS：**

```bash
source vkit-setup.sh
```

**Windows：**

```cmd
vkit-setup.bat
```

进入环境后，主要命令是：

```bash
mm
mmm
mm_all
mm_thirdparty
mm_middleware
mm_app
```

这里要特别注意：

- `source` 之后并不会得到一个叫 `import` 的 VKit 命令
- `source` 之后也不会得到一个叫 `deploy` 的 VKit 命令
- 导入和部署请使用 `make import ...`、`./vkit-setup.sh import ...`、`make deploy`、`./vkit-setup.sh deploy` 或 `build deploy`

## 构建命令一览

| 命令 | 说明 |
|------|------|
| `mm` | 构建当前目录项目 |
| `mmm` | 带 cfg 文件配置参数构建项目 |
| `mm_thirdparty` | 构建所有第三方库 |
| `mm_vendor` | 构建所有 vendor 组件 |
| `mm_middleware` | 构建所有中间件模块 |
| `mm_app` | 构建所有应用程序 |
| `mm_all` | 完整构建（按顺序构建所有层）|
| `mmc` | 使用 clang-tidy 静态分析构建 |
| `make clean` | 在仓库根目录清理构建产物 |
| `make rclean` | 更激进地清理构建和打包目录 |
| `make deploy` | 在仓库根目录打运行时包 |
| `make deploy_sdk` | 打 SDK 包 |
| `make import dev` / `make import full` | 在仓库根目录导入不同清单 |
| `make pull` | 更新已导入仓库 |

## 构建流程

![构建流程](doc/images/build-workflow.png)

## 目录结构

![目录结构](doc/images/directory-structure.png)

**版本控制中：**
```
vkit/
├── cmake/              # CMake 工具链系统
├── config/             # 平台构建配置 (*.cfg)
├── deploy/             # 部署与打包脚本
├── doc/                # 文档
├── repos/              # 仓库清单文件 (dev/full)
├── tools/              # 预置宿主工具 (cmake, ninja, protoc...)
├── vkit-setup.sh       # 主设置脚本 (Linux/macOS)
├── vkit-setup.bat      # 主设置脚本 (Windows)
└── Makefile            # 快捷构建入口
```

**运行时生成目录（不在 Git 中）：**
```
vkit/
├── setup/              # 引导文件
├── thirdparty/         # 第三方源代码
├── middleware/         # VLink 与用户中间件源代码
├── vendor/             # Vendor 组件
├── app/                # 用户应用程序
├── build/<platform>/   # CMake 构建缓存
├── prebuilt/<platform>/# 安装产物 (bin/, lib/, include/)
├── prebuilt-ext/       # 外部预编译产物
└── packup/             # 分发包 (.tgz)
```

## 构建层级

VKit 将项目组织为四个有序构建层：

| 层级 | 目录 | 说明 |
|------|------|------|
| **1. thirdparty** | `thirdparty/` | 外部依赖（按需接入，不需要逐个展开理解） |
| **2. vendor** | `vendor/` | OEM/厂商组件（按需接入） |
| **3. middleware** | `middleware/` | 当前内置为 `vlink`、`vlink-msgs`，同时支持用户自定义中间件 |
| **4. app** | `app/` | 用户自建或导入的应用项目 |

每个层的组件在 `config/<platform>/*.cfg` 文件中定义。用户可以自由向任何层添加自己的项目。

## VLink 集成

VKit 是 **VLink** 中间件生态系统的官方构建系统：

- **vlink** - 核心中间件通信框架
- **vlink-msgs** - 协议消息定义（Protobuf/FlatBuffers）

这是当前内置的两个中间件项目。其他中间件项目由用户自行添加。

## 打包输出

VKit 生成两种分发包：

- **运行时包** (`vkit-{VKIT_DEVICE_PLATFORM}-runtime.tgz`) - 仅包含可执行文件和共享库
- **SDK 包** (`vkit-{VKIT_DEVICE_PLATFORM}-sdk.tgz`) - 完整 SDK，含工具、头文件和库

其中 `{VKIT_DEVICE_PLATFORM}` 是平台和可选设备变体的组合（如 `linux-x86_64`、`qnx-aarch64-mydevice`）。

## 详细文档

- [快速开始指南](doc/getting-started.md) - 环境配置与首次构建
- [构建命令参考](doc/build-commands.md) - 所有可用命令详解
- [配置系统说明](doc/configuration.md) - 如何编写平台配置文件
- [自建项目教程](doc/create-project.md) - 本地新建项目、导入已有仓库、注册到 cfg 的完整教程
- [交叉编译指南](doc/cross-compilation.md) - 面向不同平台的构建
- [部署与打包](doc/deployment.md) - 创建可分发包
- [仓库管理](doc/repository-management.md) - 如何导入自己的仓库、创建自定义变体并接入工作区
- [环境变量参考](doc/environment-variables.md) - 完整变量参考

## 根目录 `Makefile` 用法

把根目录 `Makefile` 简单理解成一句话就够了：

> 它是“整个工作区”的统一入口，不是“当前项目目录”的局部入口。

按场景分类会更自然。

### 1. 首次拉起

完整工作区：

```bash
make import full
make install
make deploy
```

轻量工作区：

```bash
make import dev
make install
```

### 2. 日常同步

```bash
make pull
make install
```

### 3. 打包部署

```bash
make deploy
make deploy_sdk
```

如果你想直接“构建并打包”：

```bash
make
```

### 4. 清理重建

```bash
make clean
make rclean
make dclean
make aclean
```

### 5. 三个你真正需要记住的细节

- `make` 等价于先 `install` 再 `deploy`
- `make import full` 实际会调用 `./vkit-setup.sh import full`
- `make -j8 install` 会把并行度传给 VKit

### 6. 什么时候切到 `source`

当你已经进入某个具体项目目录，想做这些事情时，就不要继续把根目录 `Makefile` 当主入口了：

- 用 `mmm` 自动带 cfg 参数构建
- 用 `llcfg` 看当前项目配置
- 只调试单个项目而不是整仓

## 许可证

Copyright (C) 2026 by Thun Lu. All rights reserved.
