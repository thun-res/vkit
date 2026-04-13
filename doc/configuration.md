# 配置系统说明

VKit 使用 `config/<platform>/` 下的 `.cfg` 文件决定：

1. 哪些项目需要参与构建
2. 它们属于哪个构建层
3. 构建时需要附加哪些 CMake 参数

如果 `.repos` 决定的是“代码从哪里来”，那么 `.cfg` 决定的就是“这些代码如何加入 VKit 的构建流水线”。

## 目录

- [配置文件位置](#配置文件位置)
- [配置文件类型](#配置文件类型)
- [配置文件语法详解](#配置文件语法详解)
- [ENABLE_INSTALL_PREFIX_EXT 机制](#enable_install_prefix_ext-机制)
- [如何添加新组件到配置](#如何添加新组件到配置)
- [构建顺序与依赖](#构建顺序与依赖)
- [多平台配置策略](#多平台配置策略)
- [配置示例合集](#配置示例合集)

---

## 配置文件位置

所有平台配置位于：

```text
config/<platform>/
```

例如：

```text
config/linux-x86_64/
├── thirdparty.cfg
├── vendor.cfg
├── middleware.cfg
└── app.cfg
```

如果设置了设备变体：

```bash
export VKIT_DEVICE=mydevice
```

那么 VKit 会优先查找：

```text
config/<platform>-mydevice/
```

如果不存在，再回退到：

```text
config/<platform>/
```

---

## 配置文件类型

| 文件 | 对应命令 | 作用 |
|------|---------|------|
| `thirdparty.cfg` | `mm_thirdparty` | 第三方层项目列表 |
| `vendor.cfg` | `mm_vendor` | Vendor 层项目列表 |
| `middleware.cfg` | `mm_middleware` | 中间件层项目列表 |
| `app.cfg` | `mm_app` | 应用层项目列表 |

`mm_all` 会固定按下面顺序执行：

```text
thirdparty -> vendor -> middleware -> app
```

---

## 配置文件语法详解

### 基本格式

每个条目本质上是一行：

```text
<项目相对路径>; <附加参数>
```

例如：

```text
middleware/my-service;
```

或者：

```text
app/my-tool; -DMY_TOOL_WITH_CLI=ON
```

### 语法规则

| 规则 | 说明 |
|------|------|
| 路径使用工作区相对路径 | 例如 `middleware/my-service` |
| 分号 `;` 为主分隔符 | 前面是项目路径，后面是附加参数 |
| 允许使用 `\` 续行 | 便于书写多参数 |
| `#`、`//` 开头的行会被忽略 | 适合整行注释 |
| 空行会被忽略 | 便于分组整理 |

### 多参数写法

```text
middleware/my-service; \
    -DMY_SERVICE_WITH_LOG=ON \
    -DMY_SERVICE_WITH_TEST=OFF
```

### 注释与临时关闭

```text
# middleware/my-service;
// app/my-tool;
```

### 如果目录不存在会怎样

如果 `cfg` 里写了某个项目，但工作区里暂时没有这个目录，VKit 当前实现会跳过它，而不是直接把整层构建中断。

这对“某些项目只在部分工作区存在”的场景很有帮助，但也意味着你需要自己留意是否漏导入了源码。

---

## ENABLE_INSTALL_PREFIX_EXT 机制

VKit 有两个安装根：

| 安装位置 | 典型目录 | 用途 |
|---------|---------|------|
| 主安装目录 | `prebuilt/<platform>/` | 默认安装位置，面向运行和交付 |
| 扩展安装目录 | `prebuilt-ext/<platform>/` | 面向开发时依赖或扩展产物 |

如果某个项目需要安装到扩展目录，可以在 cfg 中加：

```text
thirdparty/my-dev-only-lib; -DENABLE_INSTALL_PREFIX_EXT=ON
```

这个机制通常用于：

- 只在开发阶段需要的依赖
- 不希望进入最终运行时包的扩展内容
- 希望和主运行时产物分开的辅助组件

如果你不需要这套分离策略，直接不设置即可。

---

## 如何添加新组件到配置

这是最常见也是最重要的日常操作。

### 步骤 1：先决定项目属于哪个层

| 层 | 典型用途 |
|----|---------|
| `thirdparty` | 通用外部依赖 |
| `vendor` | 硬件厂商或 OEM 组件 |
| `middleware` | 服务、框架、中间层能力 |
| `app` | 最终应用程序 |

### 步骤 2：确保项目目录已经在工作区中

你可以通过两种方式完成这一步：

1. 直接把目录放到工作区，例如 `app/my-tool/`
2. 通过 `.repos` 导入，例如导入到 `middleware/my-service/`

### 步骤 3：编辑对应 cfg

例如把一个新中间件加入：

```text
config/linux-x86_64/middleware.cfg
```

写成：

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-service;
```

如果项目需要额外参数：

```text
middleware/my-service; \
    -DMY_SERVICE_WITH_MONITOR=ON \
    -DMY_SERVICE_USE_LOCAL_CACHE=OFF
```

### 步骤 4：验证参数是否匹配

```bash
source vkit-setup.sh
cd middleware/my-service
llcfg
```

### 步骤 5：构建验证

```bash
mmm
```

或者整层验证：

```bash
mm_middleware
```

---

## 构建顺序与依赖

### 层间顺序是固定的

VKit 的大顺序永远是：

```text
thirdparty -> vendor -> middleware -> app
```

所以：

- `app` 可以依赖前面所有层
- `middleware` 可以依赖 `thirdparty` 和 `vendor`
- `thirdparty` 内部如果有依赖，也只能靠文件中顺序来表达

### 同一 cfg 内的顺序也很重要

在同一个 cfg 中，条目从上到下依次构建。

如果 `middleware/my-service` 依赖 `middleware/my-base-lib`，就应该写成：

```text
middleware/my-base-lib;
middleware/my-service;
```

### 当前仓库的默认中间件顺序

当前 `middleware.cfg` 的核心内置项目是：

```text
middleware/vlink;
middleware/vlink-msgs;
```

如果你的项目要依赖它们，应把自己的条目写在后面。

---

## 多平台配置策略

### 同一个项目在不同平台有不同参数

这是最常见的写法。

例如：

```text
config/linux-x86_64/app.cfg
app/my-tool; -DMY_TOOL_USE_EPOLL=ON
```

```text
config/qnx-aarch64/app.cfg
app/my-tool; -DMY_TOOL_USE_QNX_API=ON
```

### 某个平台暂时不构建

最简单的做法就是：

- 不在该平台的 cfg 中写这一项

或者临时注释掉：

```text
# app/my-tool;
```

### 设备变体配置

如果同一平台下还有设备差异，可以新建：

```text
config/linux-x86_64-mydevice/
```

这样在：

```bash
export VKIT_DEVICE=mydevice
```

后，VKit 会优先读取该目录。

---

## 配置示例合集

### 示例 1：最简单的项目

```text
app/my-tool;
```

### 示例 2：带附加 CMake 参数

```text
middleware/my-service; \
    -DMY_SERVICE_WITH_LOG=ON \
    -DMY_SERVICE_WITH_TEST=OFF
```

### 示例 3：安装到 `prebuilt-ext`

```text
thirdparty/my-dev-only-lib; \
    -DENABLE_INSTALL_PREFIX_EXT=ON
```

### 示例 4：同层顺序表达依赖

```text
middleware/my-base-lib;
middleware/my-service;
```

### 示例 5：应用层示例

```text
app/my-cli;
app/my-daemon; -DMY_DAEMON_WITH_MONITOR=ON
```

### 示例 6：当前内置中间件基础写法

```text
middleware/vlink;
middleware/vlink-msgs;
middleware/my-service;
```

如果你只记住一件事，请记住这句：

> `.repos` 决定代码在不在，`.cfg` 决定 VKit 会不会构建它。`
