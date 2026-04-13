# 交叉编译指南

本文档只关注用户真正需要掌握的内容：

1. 如何选择目标平台
2. 不同平台在 VKit 中如何触发
3. 如何用最少步骤完成跨平台构建

不再展开介绍 `cmake/` 和工具目录内部实现细节。

## 目录

- [交叉编译概述](#交叉编译概述)
- [工具链系统](#工具链系统)
- [Linux aarch64 交叉编译](#linux-aarch64-交叉编译)
- [Android 交叉编译](#android-交叉编译)
- [QNX 交叉编译](#qnx-交叉编译)
- [macOS 编译](#macos-编译)
- [Windows 编译](#windows-编译)
- [自定义工具链](#自定义工具链)

---

## 交叉编译概述

VKit 的跨平台流程可以简化理解为：

```text
设置平台相关环境变量
-> source vkit-setup.sh
-> VKit 选择目标平台和工具链
-> mm / mmm / mm_all / make install
```

你只需要关心两类平台：

- 宿主平台：你当前正在执行构建命令的机器
- 目标平台：最终产物要运行的平台

### `VKIT_PLATFORM` 自动选择规则

如果你没有手动设置 `VKIT_PLATFORM`，当前脚本会按下面顺序判断：

1. 有 `QNX_TARGET` 和 `QNX_HOST` 时，使用 `qnx-aarch64`
2. 有 `ANDROID_NDK` 时，使用 `android-aarch64`
3. 有 `CROSS_COMPILE_PREFIX` 时，使用 `linux-aarch64`
4. 否则使用宿主平台

如果你希望明确指定，就直接设置：

```bash
export VKIT_PLATFORM=linux-aarch64
source vkit-setup.sh
```

---

## 工具链系统

从用户视角理解，VKit 已经替你完成了下面几件事：

- 设定 `CMAKE_TOOLCHAIN_FILE`
- 设定安装前缀
- 设定构建输出目录
- 选择宿主工具

因此实际操作中，用户只需要做好两件事：

1. 提前准备好目标平台所需环境变量
2. 使用 `source vkit-setup.sh` 或根目录 `make`

---

## Linux aarch64 交叉编译

### 典型场景

在 x86_64 Linux 主机上，交叉构建 Linux aarch64 目标。

### 常用写法

```bash
export CROSS_COMPILE_PREFIX=aarch64-linux-gnu-
export VKIT_PLATFORM=linux-aarch64
source vkit-setup.sh
mm_all
```

如果你不显式设置 `VKIT_PLATFORM`，只设置了 `CROSS_COMPILE_PREFIX`，当前脚本也会自动落到：

```text
linux-aarch64
```

### 如果有 sysroot

```bash
export SYSROOT=/path/to/sysroot
source vkit-setup.sh
```

---

## Android 交叉编译

### 前提

设置 `ANDROID_NDK`：

```bash
export ANDROID_NDK=/path/to/android-ndk
```

### 基本流程

```bash
source vkit-setup.sh
mm_all
```

如果只设置了 `ANDROID_NDK`，脚本默认会落到：

```text
android-aarch64
```

如果你要切换到其他 Android 目标，例如：

```bash
export VKIT_PLATFORM=android-x86_64
source vkit-setup.sh
mm_all
```

### 打包注意事项

当前部署脚本会为 Android 目标额外补充：

- `libc++_shared.so`

因此建议 Android 目标构建完成后使用 `make deploy` 做最终校验。

---

## QNX 交叉编译

### 前提

先加载 QNX 环境：

```bash
source /path/to/qnxsdp-env.sh
```

这一步通常会提供：

- `QNX_HOST`
- `QNX_TARGET`

### 基本流程

```bash
source vkit-setup.sh
mm_all
```

如果你没有手动覆盖 `VKIT_PLATFORM`，当前脚本在检测到 `QNX_HOST` 和 `QNX_TARGET` 后会默认选择：

```text
qnx-aarch64
```

### QNX 额外产物

QNX 部署时会自动生成：

```text
prebuilt/<platform>/vkit.build
```

它可用于后续系统镜像集成。

---

## macOS 编译

在 macOS 上通常是原生构建，不属于典型“交叉”场景，但使用方式一致。

### Apple Silicon

```bash
source vkit-setup.sh
mm_all
```

通常会自动识别为：

```text
darwin-arm64
```

### Intel Mac

同样执行：

```bash
source vkit-setup.sh
mm_all
```

通常会自动识别为：

```text
darwin-x86_64
```

---

## Windows 编译

### 前提

建议在已加载 MSVC 环境的终端中执行。

### 基本流程

```cmd
vkit-setup.bat
mm_all
```

如果你主要在 Windows 上做整仓构建，也可以优先使用根目录 `Makefile` 的等价入口或批处理入口，但从当前仓库内容看，最核心的仍然是先把构建环境初始化好。

---

## 自定义工具链

如果某个平台需要额外的外部环境脚本，VKit 支持在 `source vkit-setup.sh <name>` 时尝试加载以下位置之一：

```text
vkit-toolchains/<name>/<name>_setup.sh
~/vkit-toolchains/<name>/<name>_setup.sh
/opt/vkit-toolchains/<name>/<name>_setup.sh
/opt/<name>/<name>_setup.sh
```

例如：

```bash
source vkit-setup.sh qnx-aarch64
```

这时脚本会尝试查找：

```text
qnx-aarch64_setup.sh
```

这种机制适合：

- 把公司内部工具链初始化逻辑单独放到外部脚本
- 不把特定平台的敏感环境细节写死在仓库里

如果你没有这种需求，直接使用前面几节的标准流程即可。
