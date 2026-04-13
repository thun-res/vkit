# 部署与打包

本文档介绍 VKit 如何把构建产物整理为运行时包和 SDK 包，以及如何把你自己的部署文件注入到最终包中。

## 目录

- [部署系统概述](#部署系统概述)
- [运行时包](#运行时包)
- [SDK 包](#sdk-包)
- [部署脚本详解](#部署脚本详解)
- [QNX Fileset](#qnx-fileset)
- [使用部署包](#使用部署包)
- [自定义部署](#自定义部署)

---

## 部署系统概述

VKit 的部署入口有三种：

```bash
make deploy
make deploy_sdk
```

```bash
./vkit-setup.sh deploy
./vkit-setup.sh deploy_sdk
```

```bash
source vkit-setup.sh
build deploy
build deploy_sdk
```

部署过程的核心工作是：

1. 把平台相关附加文件复制到 `prebuilt/<platform>/`
2. 为 QNX 生成 `vkit.build`
3. 组装打包暂存目录 `packup/<platform>/`
4. 输出最终归档包到顶层 `packup/`

部署脚本位于：

```text
deploy/
├── vkit-deploy.sh
├── functions/
│   ├── do_copy.sh
│   ├── do_fileset.sh
│   └── do_packup.sh
└── <platform>/
```

---

## 运行时包

### 生成命令

```bash
make deploy
```

### 输出文件名

```text
packup/vkit-<VKIT_DEVICE_PLATFORM>-runtime.tgz
```

例如：

```text
packup/vkit-linux-x86_64-runtime.tgz
packup/vkit-qnx-aarch64-mydevice-runtime.tgz
```

### 归档内容结构

运行时包真正展开后的根目录是：

```text
vkit-<VKIT_DEVICE_PLATFORM>-runtime/
├── bin/
├── lib/
├── etc/
├── data/
└── vkit-runtime-setup.sh
```

这里要特别注意：

- 运行时包根目录不是 `target/`
- `vkit-runtime-setup.sh` 位于运行时包根目录
- `bin/`、`lib/`、`etc/` 等目录也直接位于运行时包根目录

### 会被排除的内容

运行时包会过滤掉典型开发文件，例如：

- `include/`
- `share/`
- `lib/cmake/`
- `lib/pkgconfig/`
- `*.a`
- `*.la`
- `*.cmake`
- `*.pc`

因此运行时包的目标是“可运行”，不是“可二次开发”。

---

## SDK 包

### 生成命令

```bash
make deploy_sdk
```

### 输出文件名

```text
packup/vkit-<VKIT_DEVICE_PLATFORM>-sdk.tgz
```

### 归档内容结构

SDK 包展开后的根目录是：

```text
vkit-<VKIT_DEVICE_PLATFORM>-sdk/
├── cmake/
├── host/<host-platform>/
├── target/
└── vkit-sdk-setup.sh
```

其中：

- `cmake/`：SDK 侧使用的 CMake 工具链文件
- `host/`：宿主平台工具
- `target/`：目标平台产物
- `vkit-sdk-setup.sh`：SDK 环境脚本

与运行时包相比，SDK 包是面向二次开发者的完整交付物。

---

## 部署脚本详解

### `do_copy.sh`

这一步会把部署附加文件合并进 `prebuilt/`：

1. 复制 `deploy/<device-platform>/` 或 `deploy/<platform>/` 下的文件到 `prebuilt/<device-platform>/`
2. 如果 `setup/<device-platform>/` 存在，则复制其内容到 `prebuilt/<device-platform>/etc/`
3. 对部分平台补充运行时依赖

当前脚本里的平台补充逻辑包括：

- QNX：补充部分系统共享库
- Android：补充 `libc++_shared.so`

### `do_fileset.sh`

仅在 QNX 平台生效，用于生成：

```text
prebuilt/<platform>/vkit.build
```

这个文件用于后续 QNX 镜像集成。

### `do_packup.sh`

这是最终归档步骤，主要完成：

1. 生成 `vkit-runtime-setup.sh`
2. 生成 `vkit-sdk-setup.sh`
3. 把目标文件整理到 `packup/<platform>/target/`
4. 把 SDK 文件整理到 `packup/<platform>/`
5. 输出 `.tgz`

---

## QNX Fileset

当 `VKIT_PLATFORM` 为：

- `qnx-aarch64`
- `qnx-x86_64`

时，部署阶段会额外生成 `vkit.build`。

它只会收录适合 QNX 镜像的文件，例如：

- `bin/`
- `sbin/`
- `lib64/`
- `etc/`
- `scripts/`

并自动跳过头文件、静态库、CMake 元数据等开发文件。

---

## 使用部署包

### 使用运行时包

```bash
tar xzf packup/vkit-linux-x86_64-runtime.tgz
cd vkit-linux-x86_64-runtime
source vkit-runtime-setup.sh
./bin/my-service
```

请注意这里的正确路径是：

```bash
source vkit-runtime-setup.sh
```

不是旧文档中那种：

```bash
source target/vkit-runtime-setup.sh
```

运行时环境脚本会处理：

- `PATH`
- `LD_LIBRARY_PATH`
- `VLINK_TMP_DIR`
- `VLINK_LOG_DIR`
- `VLINK_LOCK_DIR`

### 使用 SDK 包

```bash
tar xzf packup/vkit-linux-x86_64-sdk.tgz
cd vkit-linux-x86_64-sdk
source vkit-sdk-setup.sh
```

之后你可以在自己的项目中使用 SDK 提供的工具链：

```bash
cmake -S /path/to/your-project \
      -B build \
      -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE \
      -DCMAKE_INSTALL_PREFIX=$VKIT_PREBUILT_DIR
cmake --build build
```

---

## 自定义部署

### 追加平台部署文件

如果你希望某些文件在 `deploy` 时自动进入最终产物，可以放到：

```text
deploy/<platform>/
```

或者更具体的设备目录：

```text
deploy/<platform>-<device>/
```

这些文件会被复制到：

```text
prebuilt/<VKIT_DEVICE_PLATFORM>/
```

例如：

```text
deploy/linux-x86_64/
├── etc/
│   └── my-service.yaml
└── scripts/
    └── startup.sh
```

最终它们会出现在：

- `prebuilt/linux-x86_64/etc/my-service.yaml`
- `prebuilt/linux-x86_64/scripts/startup.sh`

### 追加 setup 文件

如果你希望某些文件进入目标产物的 `etc/` 目录，可以放到：

```text
setup/<VKIT_DEVICE_PLATFORM>/
```

这一步没有平台回退逻辑，路径要直接对应当前 `VKIT_DEVICE_PLATFORM`。

例如：

```text
setup/linux-x86_64/
└── my-defaults.env
```

部署时会复制到：

```text
prebuilt/linux-x86_64/etc/my-defaults.env
```

### 运行时二次初始化

如果目标产物中存在：

```text
etc/oem-runtime-setup.sh
```

那么运行时包被 `source` 时会自动额外执行它。适合放 OEM 特定初始化逻辑。

### 控制打包输出

```bash
export VKIT_PACKUP_RUNTIME=1
export VKIT_PACKUP_SDK=0
./vkit-setup.sh deploy
```

或者：

```bash
export VKIT_PACKUP_SDK=1
./vkit-setup.sh deploy_sdk
```

### 控制是否剥离符号

如果你希望安装阶段进行 strip：

```bash
export VKIT_STRIP=1
source vkit-setup.sh
mm_all
build deploy
```

如果你希望保留符号：

```bash
unset VKIT_STRIP
source vkit-setup.sh
mm_all
build deploy
```

> 当前脚本只有在 `VKIT_STRIP=1` 时才会执行 `cmake --install --strip`。未设置时不会强制 strip。
