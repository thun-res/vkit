# 环境变量参考

本文档只保留对用户真正有帮助的变量，并按“什么时候生效”来说明。

最重要的区分是：

- `source vkit-setup.sh` 时导出的变量
- 运行时包或 SDK 包被 `source` 时导出的变量

## 目录

- [核心路径变量](#核心路径变量)
- [平台与设备变量](#平台与设备变量)
- [构建控制变量](#构建控制变量)
- [VLink 相关变量](#vlink-相关变量)
- [CMake 变量](#cmake-变量)
- [工具变量](#工具变量)
- [用户可设置的变量](#用户可设置的变量)

---

## 核心路径变量

下面这些变量在 `source vkit-setup.sh` 后自动可用：

| 变量 | 说明 |
|------|------|
| `VKIT_ROOT_DIR` | VKit 根目录 |
| `VKIT_HOST_TOOL_DIR` | 宿主工具目录，通常是 `tools/<host-platform>` |
| `VKIT_BUILD_DIR` | 当前 `VKIT_DEVICE_PLATFORM` 的构建目录 |
| `VKIT_PREBUILT_DIR` | 当前 `VKIT_DEVICE_PLATFORM` 的主安装目录 |
| `VKIT_PREBUILT_EXT_DIR` | 当前 `VKIT_DEVICE_PLATFORM` 的扩展安装目录 |
| `VKIT_PACKUP_DIR` | 当前 `VKIT_DEVICE_PLATFORM` 的打包暂存目录 |
| `VKIT_SETUP_DIR` | `setup/<VKIT_DEVICE_PLATFORM>` |
| `VKIT_ETC_DIR` | `prebuilt/<VKIT_DEVICE_PLATFORM>/etc` |
| `VKIT_CODE_COMPLETE_DIR` | 代码补全脚本目录 |
| `VKIT_PLATFORM_CONFIG_DIR` | 实际生效的配置目录 |
| `VKIT_PLATFORM_DEPLOY_DIR` | 实际生效的部署目录 |

### 路径选择规则

其中有两个路径特别重要：

#### `VKIT_PLATFORM_CONFIG_DIR`

优先查找：

```text
config/<VKIT_DEVICE_PLATFORM>/
```

找不到时回退到：

```text
config/<VKIT_PLATFORM>/
```

#### `VKIT_PLATFORM_DEPLOY_DIR`

优先查找：

```text
deploy/<VKIT_DEVICE_PLATFORM>/
```

找不到时回退到：

```text
deploy/<VKIT_PLATFORM>/
```

---

## 平台与设备变量

| 变量 | 说明 |
|------|------|
| `VKIT_HOST_PLATFORM` | 宿主平台 |
| `VKIT_PLATFORM` | 当前目标平台 |
| `VKIT_DEVICE` | 可选的设备变体名 |
| `VKIT_DEVICE_PLATFORM` | 平台与设备组合名 |

### 自动检测规则

如果没有显式设置 `VKIT_PLATFORM`，当前脚本按下面顺序判断：

| 条件 | 结果 |
|------|------|
| 同时存在 `QNX_TARGET` 和 `QNX_HOST` | `qnx-aarch64` |
| 存在 `ANDROID_NDK` | `android-aarch64` |
| 存在 `CROSS_COMPILE_PREFIX` | `linux-aarch64` |
| 以上都没有 | 宿主平台 |

### 使用示例

```bash
export VKIT_PLATFORM=linux-aarch64
export VKIT_DEVICE=mydevice
source vkit-setup.sh
```

此时：

- `VKIT_PLATFORM=linux-aarch64`
- `VKIT_DEVICE_PLATFORM=linux-aarch64-mydevice`

---

## 构建控制变量

这些变量应在 `source vkit-setup.sh` 之前设置：

| 变量 | 当前行为 |
|------|---------|
| `VKIT_DEBUG` | 用户可自定义的调试标记，具体是否消费取决于项目自身 |
| `VKIT_STRIP` | 只有当值为 `1` 时，CMake 安装阶段才会执行 `--strip` |
| `VKIT_DISABLE_CCACHE` | 用户可用于约束构建环境，具体是否消费取决于工具链或项目 |
| `VKIT_BUILD_CPU_CORE` | 控制并行构建线程数，默认自动检测 |
| `VKIT_MIDDLEWARE_RELWITHDEBINFO` | 设为 `1` 时，中间件层追加 `RelWithDebInfo` |
| `VKIT_APP_RELWITHDEBINFO` | 设为 `1` 时，应用层追加 `RelWithDebInfo` |
| `VKIT_PACKUP_RUNTIME` | 默认为 `1` |
| `VKIT_PACKUP_SDK` | 默认为 `0` |

### 关于 `VKIT_STRIP`

旧文档里经常把它写成“默认值为 1”，这在当前脚本实现中并不准确。

当前实际规则是：

- `VKIT_STRIP=1` 时执行 `cmake --install --strip`
- 未设置或非 `1` 时执行普通 `cmake --install`

### 关于 `VKIT_BUILD_CPU_CORE`

如果你不设置，VKit 会自动估算一个并行数。

你也可以手动覆盖：

```bash
export VKIT_BUILD_CPU_CORE=4
source vkit-setup.sh
```

---

## VLink 相关变量

这一组变量需要分两类理解。

### 在 `source vkit-setup.sh` 时可能导出的变量

| 变量 | 说明 |
|------|------|
| `VKIT_PROTO_DIR` | 协议目录 |
| `VLINK_URL_REMAP` | 设备相关 URL 重映射文件 |
| `VLINK_SCHEMA_PLUGIN` | 当前脚本会在检测到 `vlink-msgs` 时设为 `vlink-msgs` |

#### `VKIT_PROTO_DIR` 的查找顺序

当前脚本会依次尝试：

1. `middleware/vlink-msgs/proto`
2. `app/vlink-msgs/proto`
3. `prebuilt/<platform>/etc/vlink-msgs/proto`

#### `VLINK_URL_REMAP` 的查找条件

只有设置了 `VKIT_DEVICE` 后，脚本才会去查找：

- `middleware/vlink-msgs/etc/url_remap_<device>.json`
- `app/vlink-msgs/etc/url_remap_<device>.json`
- `prebuilt/<platform>/etc/vlink-msgs/url_remap_<device>.json`

### 在运行时包或 SDK 环境中导出的变量

当你 `source vkit-runtime-setup.sh` 或 `source vkit-sdk-setup.sh` 时，还会涉及：

| 变量 | 默认值 |
|------|------|
| `VLINK_TMP_DIR` | `$VKIT_PREBUILT_DIR/data` |
| `VLINK_LOG_DIR` | `$VKIT_PREBUILT_DIR/data/vlink-log` |
| `VLINK_LOCK_DIR` | `$VKIT_PREBUILT_DIR/data/vlink-lock` |

这些目录会在环境脚本中自动创建。

---

## CMake 变量

VKit 会自动准备这些核心 CMake 变量：

| 变量 | 说明 |
|------|------|
| `CMAKE_TOOLCHAIN_FILE` | `cmake/toolchain.cmake` |
| `CMAKE_INSTALL_PREFIX` | 当前 `VKIT_PREBUILT_DIR` |
| `CMAKE_GENERATOR` | 如果环境里能找到 `ninja`，通常会设置为 `Ninja` |

这也是为什么大多数项目只要遵循正常的 CMake `install(...)` 约定，就能直接融入 VKit。

---

## 工具变量

| 变量 | 说明 |
|------|------|
| `VKIT_VCS_TOOL` | 优先为 `ripvcs`，否则回退为 `vcs` |
| `CCACHE_COMPRESS` | 当前脚本默认设为 `1` |
| `CCACHE_MAXSIZE` | 当前脚本默认设为 `10G` |

---

## 用户可设置的变量

下面这些是用户最常直接设置的变量。

### 平台和设备

```bash
export VKIT_PLATFORM=linux-aarch64
export VKIT_DEVICE=mydevice
source vkit-setup.sh
```

### Android

```bash
export ANDROID_NDK=/path/to/android-ndk
source vkit-setup.sh
```

### QNX

```bash
export QNX_HOST=/path/to/qnx/host
export QNX_TARGET=/path/to/qnx/target
source vkit-setup.sh
```

通常更常见的做法是先执行 QNX 官方环境脚本，再 `source vkit-setup.sh`。

### Linux aarch64

```bash
export CROSS_COMPILE_PREFIX=aarch64-linux-gnu-
export SYSROOT=/path/to/sysroot
source vkit-setup.sh
```

### 构建控制

```bash
export VKIT_BUILD_CPU_CORE=8
export VKIT_MIDDLEWARE_RELWITHDEBINFO=1
export VKIT_APP_RELWITHDEBINFO=1
export VKIT_STRIP=1
source vkit-setup.sh
```
