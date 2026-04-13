# 快速开始指南

本文档面向第一次接触 VKit 的用户，目标是用最短路径让你完成下面几件事：

1. 理解 VKit 的两种入口方式
2. 正确导入当前工作区
3. 完成第一次构建和打包
4. 避免最常见的命令误用

如果你后续还要把自己的项目接入到 VKit，请继续阅读：

- [仓库管理](repository-management.md)
- [配置系统说明](configuration.md)
- [自建项目教程](create-project.md)

## 目录

- [系统要求](#系统要求)
- [安装 VKit](#安装-vkit)
- [初始化环境](#初始化环境)
- [导入仓库](#导入仓库)
- [首次构建](#首次构建)
- [验证构建结果](#验证构建结果)
- [常见问题](#常见问题)

---

## 系统要求

### Linux / macOS

- Bash
- Git
- 可用的 C/C++ 编译器
- 建议至少 20GB 可用磁盘空间

> VKit 自带常用宿主构建工具，因此一般不需要用户再单独安装 CMake、Ninja 等工具。

### Windows

- Visual Studio 2019+ 或等效 MSVC 工具链
- Git for Windows

### 交叉编译额外要求

| 目标平台 | 额外要求 |
|---------|---------|
| Android | 设置 `ANDROID_NDK` |
| QNX | 设置 `QNX_HOST` 和 `QNX_TARGET` |
| Linux aarch64 | 设置 `CROSS_COMPILE_PREFIX`，或在目标架构机器上原生构建 |

---

## 安装 VKit

### 步骤 1：克隆仓库

```bash
git clone https://github.com/thun-res/vkit.git
cd vkit
```

### 步骤 2：确认仓库骨架

初始仓库通常至少包含这些目录和文件：

```text
vkit/
├── cmake/
├── config/
├── deploy/
├── doc/
├── repos/
├── tools/
├── vkit-setup.sh
├── vkit-setup.bat
└── Makefile
```

其中：

- `repos/` 管理要导入哪些 Git 仓库
- `config/` 管理各层项目的构建清单和参数
- `deploy/` 管理打包与部署

---

## 初始化环境

VKit 有两种正式入口：

1. 根目录 `make ...`
2. `source vkit-setup.sh` 后使用 `mm` / `mmm`

### 方式一：根目录 `make`，推荐首次使用

这部分更适合按“你现在想做什么”来理解，而不是先把命令表全部背下来。

### 场景 1：第一次先拉一个轻量工作区

```bash
make import dev
make install
```

适合先确认：

- 工作区能正常导入
- 环境已经配置正确
- 基础构建链路可用

### 场景 2：第一次直接拉完整工作区

```bash
make import full
make install
make deploy
```

适合你已经明确要使用完整内置中间件。

### 场景 3：已有工作区，只做同步和重建

```bash
make pull
make install
```

### 场景 4：一条命令构建并打包

```bash
make
```

它等价于：

```bash
make install
make deploy
```

### 场景 5：清理或补充打包

```bash
make deploy_sdk
make clean
make rclean
make dclean
make -j8 install
```

### 方式二：`source` 模式，推荐日常开发

当你需要频繁进入某个项目目录、单独构建、查看 cfg 参数时，使用 `source` 模式更方便。

```bash
source vkit-setup.sh
```

执行后，脚本会输出一个环境横幅和可用命令列表。典型形式如下：

```text
Setup VKIT build environment...
##########################################################################
# Platform: linux-x86_64
# Device:
# Date: 2026-04-13  12:00:00
##########################################################################

Note: You can run the following command:
      mmm
      mm
      mm_thirdparty
      mm_vendor
      mm_middleware
      mm_app
      mm_all
```

进入该模式后，常用命令是：

```bash
mm
mmm
llcfg
mm_thirdparty
mm_vendor
mm_middleware
mm_app
mm_all
build deploy
build deploy_sdk
```

### 平台选择规则

如果你没有手动设置 `VKIT_PLATFORM`，脚本会按下面顺序自动判定：

1. 检测到 `QNX_TARGET` 和 `QNX_HOST` 时，使用 `qnx-aarch64`
2. 检测到 `ANDROID_NDK` 时，使用 `android-aarch64`
3. 检测到 `CROSS_COMPILE_PREFIX` 时，使用 `linux-aarch64`
4. 否则使用当前宿主平台

你也可以显式覆盖：

```bash
export VKIT_PLATFORM=linux-aarch64
source vkit-setup.sh
```

### 设备变体

如果你有设备差异化配置，可以设置：

```bash
export VKIT_DEVICE=mydevice
source vkit-setup.sh
```

此时：

- `VKIT_DEVICE_PLATFORM` 会变成 `linux-x86_64-mydevice`
- VKit 会优先查找 `config/linux-x86_64-mydevice/`
- 部署目录也会优先查找 `deploy/linux-x86_64-mydevice/`

### Windows

```cmd
vkit-setup.bat
```

---

## 导入仓库

VKit 的工作区不是靠手工逐个 `git clone` 拼起来的，而是由 `repos/<variant>/` 下的 `.repos` 清单统一导入。

### 开发变体 `dev`

```bash
make import dev
# 或
./vkit-setup.sh import dev
```

当前仓库中，`dev` 的重点是：

- 导入 `setup/`
- 导入 `prebuilt/` 和 `prebuilt-ext/`
- 导入 `thirdparty/`
- 导入 `middleware/vlink-msgs`

它更适合先把最小可用工作区拉起来。

### 完整变体 `full`

```bash
make import full
# 或
./vkit-setup.sh import full
```

与 `dev` 相比，`full` 额外导入：

- `middleware/vlink`

也就是说，当前内置中间件项目只有两个：

- `middleware/vlink`
- `middleware/vlink-msgs`

`vendor` 和 `app` 目录当前默认可以是空的，用户按需自行扩展。

### 更新导入的仓库

```bash
make pull
# 或
./vkit-setup.sh pull
```

---

## 首次构建

### 推荐路径：直接从根目录构建

```bash
make install
```

### 如果已经 `source`，可使用按层命令

```bash
mm_all
```

如果你只是想先验证内置中间件是否正常，也可以只构建中间件层：

```bash
mm_middleware
```

### 构建单个项目

进入项目目录后可以使用：

```bash
cd middleware/vlink-msgs
mm
```

如果这个项目已经在 cfg 文件中注册，且你希望自动带上 cfg 中写好的 CMake 参数，则用：

```bash
mmm
```

### 打包

```bash
make deploy
```

如果你已经在 `source` 模式下，也可以用：

```bash
build deploy
```

生成的包会出现在 `packup/` 目录，例如：

- `packup/vkit-linux-x86_64-runtime.tgz`
- `packup/vkit-linux-x86_64-sdk.tgz`

---

## 验证构建结果

构建安装产物默认位于：

```bash
prebuilt/<VKIT_DEVICE_PLATFORM>/
```

例如：

```bash
ls prebuilt/linux-x86_64
```

通常你会看到这些目录：

- `bin/`
- `lib/`
- `include/`
- `etc/`
- `data/`
- `share/`

这些目录的含义分别是：

- `bin/`：可执行文件
- `lib/`：动态库、静态库及部分 CMake 元数据
- `include/`：头文件
- `etc/`：配置文件
- `data/`：运行时数据
- `share/`：辅助资源

---

## 常见问题

### Q: 为什么 `source vkit-setup.sh` 后没有出现我想象中的变量表？

因为当前脚本的实际行为是输出横幅和命令提示，而不是打印一整套环境变量表。真正的环境变量已经被导出到当前 shell，可通过 `echo $VKIT_PLATFORM` 之类的方式查看。

### Q: 为什么 `source` 之后不能直接输入 `import` 或 `deploy`？

因为当前脚本并不会向 shell 注入名为 `import` 或 `deploy` 的函数。

正确写法是：

```bash
make import dev
make import full
./vkit-setup.sh import dev
./vkit-setup.sh import full
make deploy
./vkit-setup.sh deploy
build deploy
```

### Q: `./vkit-setup.sh` 和 `source vkit-setup.sh` 有什么区别？

- `./vkit-setup.sh ...`：执行脚本命令，适合 `import`、`pull`、`install`、`deploy`
- `source vkit-setup.sh`：把环境变量和 shell 函数加载到当前终端，适合开发期反复执行 `mm` / `mmm`

如果你要使用 `mm`、`mmm`、`llcfg`，必须用 `source`。

### Q: 构建失败后该怎么清理？

```bash
# 清理当前项目
cd middleware/vlink-msgs
mm clean

# 清理整个工作区的已配置项目构建目录
make clean

# 更激进地清理当前平台的 build / packup，并重置 prebuilt
make rclean

# 彻底清空当前平台的 prebuilt / prebuilt-ext / build / packup
make dclean
```

### Q: 如何查看当前项目在 cfg 中到底写了什么参数？

```bash
cd middleware/vlink-msgs
llcfg
```

### Q: 如何把我自己的仓库导入进来？

这一步请看：

- [仓库管理](repository-management.md)
- [自建项目教程](create-project.md)

因为“导入仓库”和“能否被构建”是两件不同的事：

1. 先通过 `.repos` 把源代码放到工作区
2. 再通过 `config/<platform>/*.cfg` 把项目注册进构建层
