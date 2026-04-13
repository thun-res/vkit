# 构建命令参考

本文档按实际脚本行为整理 VKit 的可用命令。请优先区分两种模式：

1. 根目录 `make ...`
2. `source vkit-setup.sh` 后的 shell 函数

很多误用都来自把这两套入口混在一起使用。

## 目录

- [两种使用方式](#两种使用方式)
- [Makefile 命令（根目录 make）](#makefile-命令根目录-make)
- [Shell 函数命令（source 后使用）](#shell-函数命令source-后使用)
- [单项目构建命令](#单项目构建命令)
- [批量构建命令](#批量构建命令)
- [build 统一入口](#build-统一入口)
- [清理命令](#清理命令)
- [静态分析命令](#静态分析命令)
- [仓库管理命令](#仓库管理命令)
- [部署命令](#部署命令)
- [调试命令](#调试命令)

---

## 两种使用方式

### 方式一：Makefile 模式

适合：

- 首次上手
- CI
- 在仓库根目录做完整导入、构建、清理、打包

示例：

```bash
make import dev
make install
make deploy
make
```

### 方式二：Shell 函数模式

适合：

- 频繁进入单个项目目录调试
- 查看 cfg 中给某个项目附加了什么参数
- 分层构建和局部重编

示例：

```bash
source vkit-setup.sh
cd middleware/vlink-msgs
mmm
```

> 重要：`source` 之后不会出现名为 `import` 或 `deploy` 的 shell 函数。

---

## Makefile 命令（根目录 make）

根目录 `Makefile` 是对 `vkit-setup.sh` 的薄封装。更自然的分类方式不是先列命令，而是先按“工作流场景”来记。

### 场景 1：第一次拉起工作区

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

### 场景 2：日常同步与重建

```bash
make pull
make install
```

### 场景 3：打包部署

```bash
make deploy
make deploy_sdk
```

如果你想直接构建并打包：

```bash
make
```

### 场景 4：清理重建

```bash
make clean
make rclean
make dclean
make aclean
```

### 场景 5：再看命令对照表

| 命令 | 说明 |
|------|------|
| `make` | 等价于 `make install` 后再 `make deploy` |
| `make install` | 构建配置文件中注册的全部层 |
| `make import dev` | 导入 `repos/dev/` |
| `make import full` | 导入 `repos/full/` |
| `make import_dev` | `make import dev` 的固定简写 |
| `make import_full` | `make import full` 的固定简写 |
| `make pull` | 更新工作区中的仓库 |
| `make clean` | 对当前平台执行 `mm_all clean` |
| `make rclean` | 更激进地清理当前平台构建和打包目录，并重置 prebuilt |
| `make dclean` | 清空当前平台的 `prebuilt/`、`prebuilt-ext/`、`build/`、`packup/` |
| `make aclean` | 清空顶层 `build/`、`prebuilt/`、`prebuilt-ext/`、`packup/` 所有平台内容 |
| `make deploy` | 生成运行时包 |
| `make deploy_sdk` | 生成 SDK 包 |

### `make import ...` 的正确理解

正确写法是：

```bash
make import dev
make import full
```

这里的 `dev` 和 `full` 不是 shell 中单独存在的命令，而是 `make` 传给 `import` 目标的第二个参数。实际会展开为：

```bash
./vkit-setup.sh import dev
./vkit-setup.sh import full
```

### 并行构建

```bash
make -j8 install
```

根目录 `Makefile` 会把 `-j8` 解析为 `VKIT_BUILD_CPU_CORE=8`，再传给 VKit 内部构建流程。

### 什么时候切到 `source` 模式

当你已经进入某个具体项目目录，想做下面这些事时，就该切到 `source vkit-setup.sh`：

- 反复调试单个项目
- 使用 `mmm` 自动带 cfg 参数构建
- 使用 `llcfg` 查看当前项目配置

---

## Shell 函数命令（source 后使用）

执行：

```bash
source vkit-setup.sh
```

之后你可以使用这些 shell 函数：

- `mm`
- `mmm`
- `llcfg`
- `mm_thirdparty`
- `mm_vendor`
- `mm_middleware`
- `mm_app`
- `mm_all`
- `mmc`
- `mmmc`
- `build`
- `rdb`

---

## 单项目构建命令

### `mm [args]`

构建当前目录项目。

```bash
cd app/my-tool
mm
```

也可以附加额外 CMake 参数：

```bash
mm -DMY_OPTION=ON
```

清理当前项目：

```bash
mm clean
mm dclean
```

`mm` 的探测顺序如下：

1. `CMakeLists.txt`
2. `cmake/CMakeLists.txt`
3. `build.sh`
4. `Makefile`

这意味着一个项目不一定必须是 CMake，但如果是 CMake，VKit 的集成体验最好。

### `mmm [args]`

与 `mm` 类似，但会自动从对应 `cfg` 文件中读取当前项目那一行后面的附加参数。

```bash
cd middleware/my-service
mmm
```

如果你已经在 `config/<platform>/middleware.cfg` 里写了：

```text
middleware/my-service; -DMY_SERVICE_WITH_LOG=ON
```

那么 `mmm` 会自动把这部分参数带进去。

### `llcfg`

查看当前目录项目在 cfg 中匹配到的参数：

```bash
cd middleware/my-service
llcfg
```

这对于排查“为什么 `mmm` 和 `mm` 构建行为不同”非常有用。

---

## 批量构建命令

### `mm_thirdparty [args]`

读取 `thirdparty.cfg`，顺序构建其中注册的所有项目。

### `mm_vendor [args]`

读取 `vendor.cfg`。

### `mm_middleware [args]`

读取 `middleware.cfg`。

如果设置了：

```bash
export VKIT_MIDDLEWARE_RELWITHDEBINFO=1
```

则这一层会自动追加 `-DCMAKE_BUILD_TYPE=RelWithDebInfo`。

### `mm_app [args]`

读取 `app.cfg`。

如果设置了：

```bash
export VKIT_APP_RELWITHDEBINFO=1
```

则这一层会自动追加 `-DCMAKE_BUILD_TYPE=RelWithDebInfo`。

### `mm_all [args]`

按固定顺序执行：

```text
thirdparty -> vendor -> middleware -> app
```

示例：

```bash
mm_all
mm_all clean
```

---

## build 统一入口

`build` 是 `source` 模式下对分层构建和打包的统一封装。

```bash
build thirdparty
build 3rd
build vendor
build ven
build middleware
build mid
build app
build deploy
build deploy_sdk
build sdk
```

其中最实用的是：

```bash
build deploy
build deploy_sdk
```

因为在 `source` 模式下，这才是最接近“部署命令”的正式入口。

---

## 清理命令

| 命令 | 作用范围 | 说明 |
|------|---------|------|
| `mm clean` | 当前项目 | 删除当前项目构建目录 |
| `mm dclean` | 当前项目 | 删除当前项目构建目录，并尝试执行卸载目标 |
| `make clean` / `./vkit-setup.sh clean` | 当前平台已注册项目 | 等价于 `mm_all clean` |
| `make rclean` / `./vkit-setup.sh rclean` | 当前平台 | 删除当前平台 `build/` 和 `packup/` 内容，并重置 `prebuilt/`、`prebuilt-ext/` |
| `make dclean` / `./vkit-setup.sh dclean` | 当前平台 | 清空当前平台 `prebuilt/`、`prebuilt-ext/`、`build/`、`packup/` |
| `make aclean` / `./vkit-setup.sh aclean` | 全工作区 | 清空顶层所有平台的 `build/`、`prebuilt/`、`prebuilt-ext/`、`packup/` |

> 不要把这些命令简单理解为一条线性的“强弱排序”。`mm dclean` 是单项目范围，而 `make clean` 是整层范围，它们的关注点不同。

---

## 静态分析命令

### `mmc [fix]`

在当前项目上启用 `clang-tidy`：

```bash
cd middleware/my-service
mmc
mmc fix
```

### `mmmc [fix]`

与 `mmc` 类似，但会自动附加 cfg 中的构建参数。

---

## 仓库管理命令

### 导入仓库

根目录推荐：

```bash
make import dev
make import full
```

脚本入口：

```bash
./vkit-setup.sh import dev
./vkit-setup.sh import full
./vkit-setup.sh import my-variant
```

### 更新仓库

```bash
make pull
# 或
./vkit-setup.sh pull
```

### 需要特别记住的事实

- `import` 不是 `source` 模式下的 shell 函数
- `pull` 也不是 `source` 模式下的 shell 函数
- 导入仓库只负责把源码放进工作区，不等于自动加入构建

---

## 部署命令

### 根目录模式

```bash
make deploy
make deploy_sdk
```

### `source` 模式

```bash
build deploy
build deploy_sdk
```

### 直接脚本模式

```bash
./vkit-setup.sh deploy
./vkit-setup.sh deploy_sdk
```

---

## 调试命令

### `rdb [args]`

`rdb` 主要用于为特定目标平台启动调试器并补充库搜索路径。

当前脚本里：

- `qnx-aarch64` 使用 `ntoaarch64-gdb`
- `qnx-x86_64` 使用 `ntox86_64-gdb`
- 其他非 Linux 目标使用 `gdb`

如果你做的是普通 Linux 本机构建，通常直接使用系统 `gdb` 即可。
