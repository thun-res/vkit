<h1 align="center">VKit</h1>

<p align="center"><strong>Cross-platform build &amp; release suite for the <a href="https://vlink.work">VLink</a> project</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.0.0-blue.svg" />
  <img src="https://img.shields.io/badge/build-CMake-orange.svg" />
  <img src="https://img.shields.io/badge/platform-Linux%20|%20QNX%20|%20Android%20|%20macOS%20|%20Windows-brightgreen.svg" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" /></a>
</p>

<p align="center">English · <a href="README.md">中文</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="LICENSE">License</a></p>

VKit weaves multi-repo source pulling, cross-platform CMake toolchain dispatch, layered component orchestration, incremental caching, target-side artifact assembly, and SDK / Runtime packaging into **a single end-to-end pipeline behind one command** — letting VLink and its dependencies build and ship across Linux / QNX / Android / macOS / Windows with **the same commands, directory layouts, and artifact shapes**.

<p align="center"><img src="tools/images/architecture.png" alt="VKit architecture" width="94%"></p>

---

## 📑 Contents

| # | Section | For |
| --- | --- | --- |
| 1 | [🤔 Why VKit](#1--why-vkit) | First read |
| 2 | [⚡ Quick Start (10 min)](#2--quick-start-10-min) | First build |
| 3 | [🧩 Core Concepts](#3--core-concepts) | Understand the model |
| 4 | [🛠️ Daily Workflow](#4-%EF%B8%8F-daily-workflow) | Day-to-day iteration |
| 5 | [🚢 Deploy &amp; Packaging](#5--deploy--packaging) | Shipping artifacts |
| 6 | [➕ Recipes](#6--recipes) | Task-oriented |
| 7 | [🔍 Debug &amp; Troubleshoot](#7--debug--troubleshoot) | Build failures |
| 8 | [🪟 Windows Specifics](#8--windows-specifics) | Windows users |
| 9 | [❓ FAQ](#9--faq) | Common questions |
| Appx. | [A Platform matrix](#appendix-a--platform-support-matrix) · [B Environment vars](#appendix-b--full-environment-variable-set) · [C Deploy details](#appendix-c--deploy-implementation-details) · [D Adding a platform](#appendix-d--adding-a-new-platform--architecture) | Reference |

---

## 1. 🤔 Why VKit

Reliably building one codebase across many operating systems × many architectures has never been something raw CMake can solve gracefully. VKit adds five layers of leverage on top of CMake:

| Axis | Pain | VKit's answer |
| --- | --- | --- |
| **Multi-platform** | Toolchain scripts scattered, install prefixes / search paths inconsistent | One `cmake/toolchain.cmake` dispatches every `<os>-<arch>` target; install prefix is auto-derived |
| **Multi-component** | Hard to maintain build order and CMake flags for dozens of components | `config/<platform>/{thirdparty,vendor,middleware,app}.cfg`: one component per line + flags |
| **Multi-device** | Multiple ECU configs on the same platform clash | `VKIT_DEVICE` overlay; artifacts and caches isolated by `<platform>-<device>`, parallel builds don't collide |
| **AOSP feel** | Iterating one component shouldn't require remembering build paths or long cmake commands | `mm` / `mmm`: `cd` into any component and build directly; cfg flags auto-injected |
| **Shipping** | Compile, strip, package, deploy scaffolding gets reinvented every time | `make` does "build → overlay deploy → QNX fileset → SDK / Runtime tarballs" in one command |

### 1.1 vs. Conan / Colcon / vcpkg

Adjacent tools each pick a different focus. VKit deliberately stays **close to CMake and oriented toward shipping**:

| Axis | **VKit** | Conan | Colcon (ROS 2) | vcpkg |
| --- | --- | --- | --- | --- |
| Runtime dependency | **Bash + CMake only** | Python ≥ 3.6 + Conan packages | Python 3 + a stack of `colcon-*` packages | C++ bootstrap; ports use CMake |
| CMake integration | **Native — components keep their own `CMakeLists.txt`** | Needs `conanfile.py/.txt` + `find_package` wrappers | Forces `ament_cmake` / custom macros | port files use the vcpkg DSL |
| Learning curve | **Know CMake → ready to go** | Must learn package-description DSL + profiles | Must learn ament/colcon conventions | Must learn portfile + triplets |
| Cross-compilation | **Built-in** for Linux / QNX / Android / macOS / Windows + device overlays | Profile + toolchain file, you wire it up | Mostly Linux ROS 2; toolchain is your own problem | Triplets cover desktop well; QNX/embedded is thin |
| Shipping artifacts | **One command produces runtime + SDK tarballs** (incl. QNX fileset, Android NDK compatibility) | Outputs Conan packages; shipping is a separate step | Outputs `install/`; no shipping packager | Outputs library trees; no shipping packager |
| Multi-repo source | `.repos` + `ripvcs/vcstool`, **4 serial layers** | Source-pull is not its job — script it yourself | Uses `vcs` for ROS workspaces | Doesn't manage upper-layer source |
| Device / ECU variants | **`VKIT_DEVICE` overlay**, multiple configs share one source tree | Profile-based; non-trivial cases need scripting | Not directly supported | Triplets express it, but with limited flexibility |

**In short:**

- **No Python runtime.** The whole workflow is Bash + CMake — smaller CI images, no venv pain on QNX / embedded boxes.
- **No new syntax to learn.** Components keep their original `CMakeLists.txt` — Colcon's `ament_cmake_xxx` wrappers, Conan's `conanfile`, vcpkg's portfiles are not needed. Your team's CMake knowledge transfers directly.
- **Shipping-first, not a package repo.** Conan / vcpkg solve "where do dependencies come from"; VKit solves "how do I build, package, and install VLink across 5 OSes × multiple devices in one command" — toolchain dispatch, cfg orchestration, overlays, stripping, fileset, dual-package tarball, all on one pipeline.
- **AOSP-style single-component iteration.** `mm` / `mmm` removes the need to remember build directories — something a package-manager-shaped tool never sets out to do.

> 💡 **Positioning**　VKit doesn't replace CMake, and doesn't compete with Conan / vcpkg on dependency management. It is a *workspace orchestrator* — one consistent build / deploy / packaging experience for multi-repo, multi-platform, multi-device middleware projects like VLink.

---

## 2. ⚡ Quick Start (10 min)

> Goal: build VLink from scratch and produce a deployable runtime tarball.

### 2.1 Host prerequisites

**Ubuntu 22.04** recommended (20.04 minimum; macOS / Windows / WSL2 all work).

```bash
sudo apt-get -y install \
    git git-lfs \
    autoconf automake tclsh \
    build-essential ninja-build ccache rsync \
    python3 \
    openjdk-17-jdk \
    doxygen graphviz \
    ccache
sudo pip install vcstool
```

| Tool | Source | Notes |
| --- | --- | --- |
| `cmake / ripvcs / protoc / flatc / fastddsgen` | **Vendored** in `tools/<host>/bin/` | Auto-prepended to `PATH`; no system install needed |
| `ninja / ccache / git / git-lfs` | System package manager | ccache speeds rebuilds 5–10× |
| `openjdk-17-jdk` | System package manager | `fastddsgen` is a Java program |
| Python ≥ 3.6 + `vcstool` | System + pip | Only used as a fallback when bundled `ripvcs` is unavailable |

### 2.2 Pull source

```bash
git clone <vkit-url> vkit && cd vkit

$EDITOR repos/full/*.repos

make import_full     # default — build vlink from scratch
# or
make import_dev      # developer set when you already have a vlink working tree
```

| Set | `middleware.repos` content | When to use |
| --- | --- | --- |
| **`full`** | `vmsgs` + `vlink` | **Build vlink from scratch (recommended)** |
| `dev` | `vmsgs` only | You already have `middleware/vlink/` locally (vlink developer) |

> Pull order is fixed: `setup → prebuilt(--shallow) → thirdparty(--shallow) → vendor → middleware → app`. Shallow pulls save disk.

### 2.3 Configure the target platform

Each platform needs only one extra step; everything else is auto-detected by `VKIT_PLATFORM=auto` (default):

```bash
# Linux x86_64 (host)        — nothing to do
# Linux aarch64 (cross)      — export CROSS_COMPILE_PREFIX=/opt/.../bin/aarch64-none-linux-gnu-
# QNX                        — source ~/.qnx/qnxsdp-env.sh
# Android                    — export ANDROID_NDK=/opt/android-ndk-r27
```

> 💡 Auto-detection only resolves to **aarch64** cross targets; `qnx-x86_64` / `android-x86_64` need `export VKIT_PLATFORM=...` explicitly. Full rules in [Appendix A](#appendix-a--platform-support-matrix).
> Windows `vkit-setup.bat` forces the host platform — see [§8](#8--windows-specifics).

### 2.4 One-command build

```bash
make                # build → deploy → produce runtime tarball
```

`make` ≡ `make install + make deploy`. Full entry points:

| Entry | Action |
| --- | --- |
| `make` | install + deploy (**default**, produces runtime tarball) |
| `make install` | Compile per cfg only |
| `make deploy` | Deploy + runtime tarball only |
| `make deploy_sdk` | Deploy + extra SDK tarball |
| `make clean` / `rclean` / `dclean` / `aclean` | Four cleanup tiers ([§4.4](#44-cleanup--cache)) |

### 2.5 Verify the artifact

```bash
ls packup/                                  # vkit-<platform>-runtime.tgz
tar tzf packup/vkit-*-runtime.tgz | head    # inspect tarball layout

# Host platform + import_full → can run in place
source vkit-setup.sh
vlink-info -v                                # version printed = success
```

> 💡 `vlink-info` is a vlink build artifact. It can be invoked directly on the host only when ① you used `make import_full` to pull the vlink source and ② the current target is the host platform. Cross-compiled artifacts must be deployed to the target device before running.

Expected layout:
```
packup/
├── linux-x86_64/
│   ├── cmake/    host/    target/
│   ├── vkit-sdk-setup.sh                    (inside the SDK package)
│   └── target/vkit-runtime-setup.sh         (inside the runtime package)
└── vkit-linux-x86_64-runtime.tgz            ← the artifact you ship to the target device
```

### 2.6 Next steps

| Goal | Jump to |
| --- | --- |
| Rebuild only what you changed | [§4.1 Single-component build](#41-single-component-build-mm--mmm) |
| Maintain multiple targets in parallel | [§3.2 Multi-platform sandbox](#32-multi-platform-sandbox) |
| Add your own library | [§6.1 Onboard a new component](#61-onboard-a-new-component-cmake-project) |
| Cross-compile an OEM image | [§6.4 OEM / Vendor customization](#64-oem--vendor-customization) |
| Build is failing | [§7 Debug &amp; Troubleshoot](#7--debug--troubleshoot) |

---

## 3. 🧩 Core Concepts

### 3.1 Glossary

| Term | Meaning |
| --- | --- |
| **Platform target** | The `<os>-<arch>` combination, e.g. `linux-aarch64`, `qnx-x86_64`; full list in [Appendix A](#appendix-a--platform-support-matrix) |
| **VKIT_PLATFORM** | Current platform target; with `auto`, it is derived from environment |
| **VKIT_DEVICE** | Sub-layer above the platform target, letting one platform host several ECU configs |
| **DEVICE_PLATFORM** | Derived: `<platform>` or `<platform>-<device>`; key for every artifact directory |
| **prebuilt** | Default destination of CMake `--install` = shipping artifacts (executables, `.so`, configs) |
| **prebuilt-private** | Link-only deps (boost, asio, …); not shipped; activated by `-DENABLE_INSTALL_PRIVATE=ON` |
| **cfg layer** | Four layers — `thirdparty` / `vendor` / `middleware` / `app` — built serially in this order |
| **overlay** | Target-rootfs overlay under `deploy/<platform>/`; merged into `prebuilt/` during `do_copy` |
| **fileset** | QNX `mkqnximage` input list (`vkit.build`); generated in `do_fileset` |
| **runtime package** | Minimal deployable artifact: includes / cmake / static libs stripped out |
| **SDK package** | Runtime + `cmake/` + `tools/` (host toolchain); for downstream development |

### 3.2 Multi-platform sandbox

`build/`, `prebuilt/`, `prebuilt-private/`, `packup/` are all keyed by `DEVICE_PLATFORM`. Multiple shells with different `VKIT_PLATFORM` values **build in parallel inside the same workspace** without interfering.

<p align="center"><img src="tools/images/multi-platform.png" alt="Multi-platform sandbox" width="100%"></p>

### 3.3 Build pipeline

Four cfg layers determine build order with no inversion:

<p align="center"><img src="tools/images/build-pipeline.png" alt="Build pipeline" width="100%"></p>

| Stage | Batch command | cfg | Output |
| --- | --- | --- | --- |
| ① thirdparty | `mm_thirdparty` | `thirdparty.cfg` | boost, protobuf, Fast-DDS … |
| ② vendor | `mm_vendor` | `vendor.cfg` | OEM / customer libs |
| ③ middleware | `mm_middleware` | `middleware.cfg` | `vmsgs`, `vlink` |
| ④ app | `mm_app` | `app.cfg` | top-level services / tools |

`mm_all` ≡ `make install` chains ① → ④; `make` further appends `make deploy`.

#### `.cfg` syntax

```cfg
# One component per line: <path-relative-to-vkit-root> ; <CMake flags…>
thirdparty/yaml-cpp;            \
    -DENABLE_INSTALL_PRIVATE=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF
```

- `\` continues a line; `#` / `;` / `//` start line comments; blank lines skipped
- Missing path → `Skip [<proj>]` (not an error) — that's why `import_dev` (no vlink) still builds
- Text after `;` is shell-expanded and appended to `mm`'s CMake flags

#### `.repos` syntax

`vcstool`-compatible YAML, split into 6 layers (`setup` / `prebuilt` / `thirdparty` / `vendor` / `middleware` / `app`); the layer determines the on-disk location:

```yaml
repositories:
  middleware/vlink:                  # path relative to vkit root
    type: git
    url: https://<token>@github.com/<org>/vlink.git
    version: master
```

### 3.4 Install prefixes &amp; VLink injection

<p align="center"><img src="tools/images/install-prefix.png" alt="Public/private install prefix" width="100%"></p>

| Prefix | Trigger | Holds | In `packup/`? |
| --- | --- | --- | --- |
| `prebuilt/<platform>/` | Default | Shipping executables, shared libs, `etc/`, `data/` | ✅ |
| `prebuilt-private/<platform>/` | cfg adds `-DENABLE_INSTALL_PRIVATE=ON` | Link-only deps: boost, asio, json, yaml-cpp, Fast-CDR, … | ❌ (a small whitelist of executables is promoted into `prebuilt/bin/` by `do_copy`) |

`cmake/toolchain.cmake` transparently adds `prebuilt-private` to `-I` / `-L` / `CMAKE_FIND_ROOT_PATH` / `pkgconfig` (Windows also `CMAKE_PREFIX_PATH`); **consumer components don't have to know**.

**VLink injection**　Done immediately after `source vkit-setup.sh`:

```sh
# Always injected:
VLINK_ROOT_DIR        = $VKIT_PREBUILT_DIR
VLINK_ETC_DIR         = $VKIT_ETC_DIR
VLINK_COMPLETIONS     = $VLINK_ETC_DIR/vlink/vlink-completions.sh

# Added only when middleware/vmsgs/schemas/ exists:
VLINK_PROTO_DIR / VLINK_FBS_DIR / VLINK_SCHEMA_PLUGIN
```

When building for the host, the script additionally prepends `prebuilt/<platform>/{bin,lib}` to `PATH` / `LD_LIBRARY_PATH` and sources command-completion.

---

## 4. 🛠️ Daily Workflow

### 4.1 Single-component build (`mm` / `mmm`)

AOSP-style — `cd` into any component and call directly:

```bash
source vkit-setup.sh                 # source once per new shell
cd middleware/vlink
mmm                                  # build with the cfg-defined flags (recommended)
mm '-DENABLE_VIEWER=ON'              # pass flags directly, ignoring cfg
mm clean                             # delete this component's build/
mm dclean                            # CMake projects also trigger __uninstall
```

<p align="center"><img src="tools/images/mm-flow.png" alt="Single-component build flow" width="100%"></p>

| Function | Behavior |
| --- | --- |
| `mm [args…]` | Single-component build; args go to `cmake -S/-B`; **does not** read cfg |
| `mmm [args…]` | Same as `mm`, but auto-merges the cfg-defined flags for the current component (recommended) |
| `mmc [fix]` / `mmmc [fix]` | + `clang-tidy`; `fix` applies fixes |
| `llcfg` | Inside a component dir, prints the cfg flags configured for it |
| `rdb [args…]` | Cross-platform GDB wrapper (QNX picks `nto<arch>-gdb`; no-op on Linux native) |

> ⚠️ **CMake cache stickiness**　`mm` re-runs `cmake -S -B` only when `CMakeCache.txt` is missing. Subsequent `-D…` flags will not override cached values — run `mm clean` before changing configure-time flags. Exception: when `--target …` is passed, configure is skipped and all args flow to `cmake --build`.

### 4.2 Batch &amp; full build

```bash
mm_thirdparty                        # build the thirdparty layer per cfg
mm_vendor / mm_middleware / mm_app   # build a specific layer
mm_all                               # all four layers in order (≡ make install)
build app                            # short alias for mm_app (POSIX only; also 3rd / ven / mid / sdk)
```

### 4.3 Command cheat sheet

| Entry | When |
| --- | --- |
| `make` | Produce runtime tarball (most common) |
| `make install` | Compile only, skip deploy |
| `make deploy` / `deploy_sdk` | Deploy stage; `deploy_sdk` adds the SDK tarball |
| `make import_dev` / `import_full` / `import <name>` | Multi-repo source pull |
| `make pull` | `ripvcs pull` on every existing repo (parallel) |
| `make clean` / `rclean` / `dclean` / `aclean` | See §4.4 |

### 4.4 Cleanup &amp; cache

<p align="center"><img src="tools/images/cleanup-levels.png" alt="Cleanup levels" width="100%"></p>

| Command | Scope | Action |
| --- | --- | --- |
| `make clean` | Current platform · all components | Remove each component's `build/` only |
| `make rclean` | Current platform | `build/` + `packup/` + platform tgz; for git-tracked `prebuilt*/`, restore via `git checkout` |
| `make dclean` | Current platform | `build/`, `prebuilt/`, `prebuilt-private/`, `packup/`, and the platform tgz |
| `make aclean` | **All platforms** | Top-level `build/`, `prebuilt/`, `prebuilt-private/`, `packup/` |

**ccache**　The toolchain configures 10 GiB + compression automatically; not enabled on Windows / QNX / clang-tidy paths. `VKIT_DISABLE_CCACHE=1` turns it off. Inspect with `ccache -s`.

---

## 5. 🚢 Deploy &amp; Packaging

`make deploy` chains three stages:

<p align="center"><img src="tools/images/deploy-flow.png" alt="Deploy pipeline" width="100%"></p>

| Stage | Role |
| --- | --- |
| **`do_copy`** | Apply `deploy/<platform>/` overlay; setup overlay → `etc/`; pull platform-specific runtime deps (QNX `libsqlite3 / libicu*`, Android `libc++_shared.so`); promote a few `prebuilt-private/bin/` whitelist executables into `prebuilt/bin/` |
| **`do_fileset`** | QNX only: scan `prebuilt/<platform>/`, filter via `vkit.ignore`, rewrite `lib → lib64`, emit a `mkqnximage`-style `prebuilt/<platform>/vkit.build` |
| **`do_packup`** | Sync to `packup/<DEVICE_PLATFORM>/{cmake,host,target}/`; generate `vkit-runtime-setup.sh` / `vkit-sdk-setup.sh`; produce `runtime.tgz` / `sdk.tgz` on demand |

> Implementation details (`fast-discovery-server` glob match, `engines-*` cleanup, `QHS_SDP220` permission format, …) are in [Appendix C](#appendix-c--deploy-implementation-details).

### 5.1 Runtime vs SDK dual artifacts

| Aspect | `vkit-<platform>-runtime.tgz` | `vkit-<platform>-sdk.tgz` |
| --- | --- | --- |
| Default produced | ✅ Controlled by `VKIT_PACKUP_RUNTIME=1` | ❌ Needs `make deploy_sdk` or `VKIT_PACKUP_SDK=1` |
| Holds | Shipping artifacts (executables + .so + configs) | All of runtime + `cmake/` + host toolchain |
| Setup script | `vkit-runtime-setup.sh` (injects `VLINK_*` + completions) | `vkit-sdk-setup.sh` (target env + host toolchain) |
| Use | Deploy to target device | Offline development / downstream builds |

Runtime strip rules (tar `--exclude` + `--exclude-from=deploy/vkit.ignore`):

```text
include/  share/  ssl/  usr/
lib/include  lib/python  lib/cmake  lib/pkgconfig
lib/src  lib/source  lib/sources  lib/test  lib/tests  lib/example  lib/examples
*.a  *.la  *.sym  *.o  *.in  *.cmake  *.pc
```

### 5.2 Custom strip via `vkit.ignore`

`deploy/vkit.ignore` is a list of shell globs consumed **twice**: by `do_fileset` (QNX image registration) and by `do_packup_runtime` (tar `--exclude-from`). When a new component carries `bin/` or `lib/` files that should not ship, append them here once and both artifacts pick it up.

---

## 6. ➕ Recipes

<p align="center"><img src="tools/images/onboarding.png" alt="Component onboarding" width="100%"></p>

### 6.1 Onboard a new component (CMake project)

**Two steps**:

```yaml
# Step 1: register in repos/<dev|full>/<layer>.repos
repositories:
  middleware/my-component:
    type: git
    url: <git-url>
    version: <branch-or-tag>
```

```cfg
# Step 2: add a line to config/<platform>/<layer>.cfg (for every target platform)
middleware/my-component;            \
    -DBUILD_SHARED_LIBS=ON          \
    -DMY_FEATURE=ON
```

```bash
make import_full          # pull
mm_middleware             # or `mmm` inside the component dir
```

> **Prerequisite**　The component must expose one of `CMakeLists.txt` (recommended) / `cmake/CMakeLists.txt` / `build.sh` / `Makefile`; `mm` resolves them in this priority. Windows additionally accepts `build.cmd` / `build.bat`.

### 6.2 Add a link-only dependency (header-only / static)

```cfg
# Used at link time, kept out of the runtime tarball
thirdparty/my-headers;              \
    -DENABLE_INSTALL_PRIVATE=ON     \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF
```

With `-DENABLE_INSTALL_PRIVATE=ON`, CMake installs the dep into `prebuilt-private/`. The toolchain auto-adds it to consumer search paths, and the runtime tarball will not include it.

### 6.3 Create a new device variant

```bash
# Override only what differs from the platform layer; missing entries fall back automatically
mkdir -p config/linux-aarch64-mydev
cp config/linux-aarch64/middleware.cfg config/linux-aarch64-mydev/
$EDITOR config/linux-aarch64-mydev/middleware.cfg

# Optional: device-specific deploy overlay and setup script
mkdir -p deploy/linux-aarch64-mydev/{bin,etc}
mkdir -p setup/linux-aarch64-mydev

# Activate (POSIX only; Windows does not parse VKIT_DEVICE)
export VKIT_DEVICE=mydev
export CROSS_COMPILE_PREFIX=...
make                      # → vkit-linux-aarch64-mydev-runtime.tgz
```

`build/`, `prebuilt/`, `prebuilt-private/`, `packup/` are all keyed by `DEVICE_PLATFORM` — fully isolated from the bare-platform layer.

### 6.4 OEM / Vendor customization

`vendor` is the second layer in the pipeline; the repo ships it empty by default. OEM libraries land here so they build after thirdparty and before middleware:

```yaml
# repos/full/vendor.repos
repositories:
  vendor/oem-acme:
    type: git
    url: <oem-git-url>
    version: master
```

```cfg
# config/<platform>/vendor.cfg
vendor/oem-acme; -DOEM_FEATURE=ON
```

Need to extend the runtime environment on the target? Drop `oem-runtime-setup.sh` into `setup/<DEVICE_PLATFORM>/`; the deployed `vkit-runtime-setup.sh` will source it automatically.

### 6.5 Integrate an external toolchain (OE / Yocto / vendor SDK / multi-device)

A toolchain script is one shell file, sourced by `source vkit-setup.sh <name>` *before* platform dispatch. It is used to:
- Inject vendor SDK paths (compiler, sysroot, third-party libs) into the environment
- Bind `VKIT_PLATFORM` + `VKIT_DEVICE` together so "one physical platform × multiple device configs" becomes addressable
- Hand the OE / Yocto-supplied CMake toolchain (`OE_CMAKE_TOOLCHAIN_FILE`) to vkit's dispatch chain

#### Recommended location

| User view | Path | Use case |
| --- | --- | --- |
| ⭐ **Preferred** | `~/vkit-toolchains/<name>/<name>_setup.sh` | **Recommended — does not pollute the repo (stays out of git history) and needs no root** |
| Team-shared | `<vkit>/vkit-toolchains/<name>/<name>_setup.sh` | Travels with the vkit workspace (already in `.gitignore`) |
| In-repo private | `<vkit>/toolchains/<name>/<name>_setup.sh` | **Will be tracked by git** — use only when you intend to ship it with the repo |
| Host-shared | `/opt/vkit-toolchains/<name>/<name>_setup.sh` | For multi-user machines; needs root to write |
| SDK-bundled | `/opt/<name>/<name>_setup.sh` | Entry script supplied by the vendor SDK |

> ⚠️ **Code search precedence**　`source vkit-setup.sh <name>` looks for `<name>_setup.sh` in the order below and **stops at the first hit**:<br>
> &nbsp;&nbsp;`<vkit>/toolchains/` → `<vkit>/vkit-toolchains/` → `~/vkit-toolchains/` → `/opt/vkit-toolchains/` → `/opt/<name>/`<br>
> So **if a same-named toolchain exists in the repo, it overrides your `~/vkit-toolchains/` copy**. For everyday work, drop scripts in `~/vkit-toolchains/` (the repo usually has no same-named entry); if you really need duplicates in multiple places, mind the precedence above.

#### Minimal template (OE / Yocto)

```bash
# ~/vkit-toolchains/myoe/myoe_setup.sh
export OE_CMAKE_TOOLCHAIN_FILE=/opt/myoe/cmake-toolchain.cmake
export SYSROOT=/opt/myoe/sysroot
export CC=$SYSROOT/usr/bin/aarch64-poky-linux-gcc
export CXX=$SYSROOT/usr/bin/aarch64-poky-linux-g++
export VKIT_PLATFORM=linux-aarch64        # use the Linux dispatch
```

```bash
source vkit-setup.sh myoe
make
```

> When `OE_CMAKE_TOOLCHAIN_FILE` is set, `cmake/<os>/*.toolchain.{aarch64,x86_64}.cmake` does an `include(${OE_CMAKE_TOOLCHAIN_FILE})` **first** — OE's toolchain wins, then vkit overlays its install prefixes and find paths.

#### Full template (vendor SDK + multi-device + stacked SDK helpers)

In real projects, vendors often ship a GCC, a sysroot, and several specialty SDKs (vision / comms / AI accelerators, …) at once. Below is a sanitized version of an actual structure:

```bash
# ~/vkit-toolchains/myecu/myecu_setup.sh
SHELL_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}) && pwd)

# === 1. Bind platform + device → derives VKIT_DEVICE_PLATFORM=linux-aarch64-myecu ===
export VKIT_PLATFORM="linux-aarch64"
export VKIT_DEVICE="myecu"

# === 2. Point at the SDK root (place it next to the script, or use an absolute path) ===
export SDK_PATH="$SHELL_DIR/myecu_sdk"
[ -d "$SDK_PATH" ] || { echo "SDK not found: $SDK_PATH"; return 1; }

# === 3. Compiler ===
export TOOLPATH="$SDK_PATH/aarch64-none-linux-gnu"
export CC="$TOOLPATH/bin/aarch64-none-linux-gnu-gcc"
export CXX="$TOOLPATH/bin/aarch64-none-linux-gnu-g++"
unset CFLAGS CXXFLAGS                     # avoid pollution from the outer env

# === 4. Vendor sysroot + CMake toolchain ===
export VENDOR_SYSROOT="$SDK_PATH/vendor-rootfs"
export OE_CMAKE_TOOLCHAIN_FILE="$SHELL_DIR/myecu_toolchain.cmake"

# === 5. Vendor-specific -isystem / -L / -Wl,-rpath-link chain ===
export MYECU_COMPILE_FLAGS="\
-isystem${VENDOR_SYSROOT}/usr/include \
-isystem${VENDOR_SYSROOT}/usr/include/aarch64-linux-gnu \
-L${VENDOR_SYSROOT}/usr/lib -Wl,-rpath-link,${VENDOR_SYSROOT}/usr/lib \
-L${VENDOR_SYSROOT}/usr/lib/aarch64-linux-gnu -Wl,-rpath-link,${VENDOR_SYSROOT}/usr/lib/aarch64-linux-gnu \
"

# === 6. Optional: stack additional SDK helpers (vision / comms / AI, etc.) ===
[ -f "$SHELL_DIR/extra_setup.sh" ] && . "$SHELL_DIR/extra_setup.sh" aarch64
```

The benefit of stacked helpers: split each independent SDK's environment injection into its own file and combine on demand. The helper only needs to be sourced at the end of the main script and merge its paths into `MYECU_COMPILE_FLAGS`.

#### Letting cmake/toolchain.cmake see the vendor sysroot

If the vendor sysroot ships pkg-config / headers / static libs, `OE_CMAKE_TOOLCHAIN_FILE` usually handles it. Otherwise, in `myecu_toolchain.cmake`:

```cmake
# myecu_toolchain.cmake
set(CMAKE_C_FLAGS_INIT "${CMAKE_C_FLAGS_INIT} $ENV{MYECU_COMPILE_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} $ENV{MYECU_COMPILE_FLAGS}")
list(APPEND CMAKE_FIND_ROOT_PATH "$ENV{VENDOR_SYSROOT}")
```

#### Use

```bash
source vkit-setup.sh myecu     # injects VKIT_PLATFORM=linux-aarch64 + VKIT_DEVICE=myecu
make import_full               # multiple devices share the same .repos
make                           # → packup/vkit-linux-aarch64-myecu-runtime.tgz
```

> Switching devices on the same host = sourcing a different toolchain script (in a fresh shell). Artifacts are isolated by `linux-aarch64-myecu`, leaving other devices' caches untouched.

> Adding a brand-new OS / architecture (not one of Linux / QNX / Android / macOS / Windows) → [Appendix D](#appendix-d--adding-a-new-platform--architecture).

---

## 7. 🔍 Debug &amp; Troubleshoot

| What you want | How |
| --- | --- |
| Which cfg flags this component will get | `llcfg` inside the component dir |
| Full cmake build commands | `mm '-DCMAKE_VERBOSE_MAKEFILE=ON'` (run `mm clean` first) |
| Cached configuration | `cat build/<platform>/<component>/CMakeCache.txt` |
| ccache hit rate | `ccache -s` |
| Derived variables in this shell | `env \| grep ^VKIT_` |
| Which components a cfg will run | Read `config/<platform>/middleware.cfg` directly |
| Cross-platform GDB (QNX, …) | `rdb <binary>` (auto-injects `solib-search-path`) |

**Common build failures**:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Changed cfg flags not taking effect | `mm` cache stickiness | `mm clean && mmm` |
| `Skip [...]` for a component during batch | cfg declares it but workspace lacks it | Normal; or `make import_full` to pull |
| `Error: Can not find platform config!` | No `config/<platform>/` for the current `VKIT_PLATFORM` | Pick an existing platform or add config per [Appendix D](#appendix-d--adding-a-new-platform--architecture) |
| `find: ... linux-x86_64 ...` error | macOS host cross-compiling Android with the wrong NDK host tag | Already auto-derived from `VKIT_HOST_PLATFORM` (see `do_copy.sh::_ndk_host_tag`) |

---

## 8. 🪟 Windows Specifics

`vkit-setup.bat` exposes the same doskey aliases as `.sh` — `mm` / `mmm` / `mm_thirdparty` / `mm_vendor` / `mm_middleware` / `mm_app` / `mm_all` / `llcfg` — but the underlying behavior differs:

| Aspect | POSIX (`.sh`) | Windows (`.bat`) |
| --- | --- | --- |
| Target platform | `auto` detection, override allowed | **Forced** to `win32-x86_64` |
| Device overlay | `VKIT_DEVICE` honored | `VKIT_DEVICE` **ignored** |
| External toolchain | `source vkit-setup.sh <name>` | **Not supported** |
| ccache | Enabled by default | Not integrated |
| `mmc` / `mmmc` | Provided | Not provided |
| `build` short alias | Provided | Not provided |
| `rdb` remote debug | Provided | Not provided |
| `make pull` | `--workers=$VKIT_BUILD_CPU_CORE` | No `--workers` |
| `make deploy_sdk` | Runs directly | Only when `deploy/vkit-deploy.{cmd,bat}` exists |
| Cleanup granularity | Wipe directory contents + delete root-level tgz | Delete the directory itself; `rclean` / `dclean` do not delete root-level tgz |
| `RELWITHDEBINFO` injection | Appended via `mm_middleware` / `_app` batch path | Same: appended via `_MM_USER_ARGS` |

**Recommended workflow**:

```bat
cd \work\vkit
cmd
call .\vkit-setup.bat                  :: inject env + doskey aliases
make import_full
make
cd middleware\vlink
mmm
```

> Need to cross-compile from Windows to other targets? Use **WSL2 / containers** and run `vkit-setup.sh` inside — `vkit-setup.bat` is not designed for cross-compilation.

---

## 9. ❓ FAQ

### 9.1 `vcs` not found

Usually the Python `bin` directory is missing from `PATH`:

```bash
echo 'PATH=$PATH:/usr/local/python39/bin' | sudo tee -a /etc/profile
```

VKit prefers the bundled `ripvcs` and falls back to `vcs` only when `ripvcs` is unavailable.

### 9.2 QNX licensing

```bash
cp -r {qnx_sdp}/.qnx ~/
source qnxsdp-env.sh        # confirm QNX_HOST and QNX_TARGET are both exported
```

### 9.3 aarch64 cross toolchain

Download [Arm GCC 10.3-2021.07](https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz), extract, then:

```bash
export CROSS_COMPILE_PREFIX=<dir>/bin/aarch64-none-linux-gnu-
```

### 9.4 CMake flags are not picked up

`mm`'s cache stickiness — an existing `CMakeCache.txt` is not overridden by new `-D…`. Run `mm clean` (or `mm dclean`) before passing new flags.

### 9.5 `make import` pulled nothing

`make import` requires a set name: `make import dev` / `make import full` / `make import <repos/X>`. No-arg form errors out explicitly.

### 9.6 `*.sym` missing from QNX images

By design. `do_copy` actively removes `prebuilt/lib/*.sym` on QNX to avoid polluting the fileset and runtime tarball.

---

## 📚 Appendices

### Appendix A · Platform support matrix

| Target | Compiler | Required env |
| --- | --- | --- |
| `linux-x86_64` | system `gcc/g++` (or `CC` / `CXX`) | — |
| `linux-aarch64` | `${CROSS_COMPILE_PREFIX}gcc/g++` (auto-detect)<br>or `CC` / `CXX` (with explicit `VKIT_PLATFORM=linux-aarch64`) | `CROSS_COMPILE_PREFIX` or `CC`+`CXX` |
| `qnx-aarch64` / `qnx-x86_64` | `qcc` / `q++` | `QNX_HOST` and `QNX_TARGET` |
| `android-aarch64` / `android-x86_64` | NDK clang | `ANDROID_NDK` (r25+ recommended) |
| `darwin-arm64` / `darwin-x86_64` | AppleClang | — |
| `win32-x86_64` | MSVC | — |

**Auto-detection**　`VKIT_PLATFORM=auto` (POSIX default) resolves the target via the rules below. Cross-compile targets resolve only to aarch64; x86_64 variants need explicit `VKIT_PLATFORM=...`.

<p align="center"><img src="tools/images/platform-dispatch.png" alt="Platform auto-detection" width="80%"></p>

### Appendix B · Full environment variable set

#### User-settable

| Variable | Default | Description |
| --- | --- | --- |
| `VKIT_PLATFORM` | `auto` (POSIX); host-forced on Windows | Target platform |
| `VKIT_DEVICE` | empty | Device sub-layer (POSIX only) |
| `VKIT_DEBUG` | `0` | `1` ⇒ `CMAKE_BUILD_TYPE=Debug` |
| `VKIT_STRIP` | `0` | `1` ⇒ `cmake --install --strip` |
| `VKIT_MIDDLEWARE_RELWITHDEBINFO` / `VKIT_APP_RELWITHDEBINFO` | `0` | Force the corresponding batch layer to `RelWithDebInfo` |
| `VKIT_DISABLE_CCACHE` | `0` | Disable ccache (default 10 GiB + compression; not enabled on Windows / QNX / clang-tidy paths) |
| `VKIT_BUILD_CPU_CORE` | host physical / logical cores | Build parallelism. When entered via `make`, the `Makefile` parses `-jN` from `MAKEFLAGS` and overrides this |
| `VKIT_PACKUP_RUNTIME` / `VKIT_PACKUP_SDK` | `1` / `0` | Package shape |
| `CROSS_COMPILE_PREFIX` | — | linux-aarch64 compiler prefix |
| `QNX_HOST` / `QNX_TARGET` | — | QNX SDP paths (both required) |
| `ANDROID_NDK` | — | Android NDK path |
| `OE_CMAKE_TOOLCHAIN_FILE` / `SYSROOT` | — | Provided by an external toolchain script |

#### Auto-derived (no need to set)

`VKIT_ROOT_DIR / VKIT_HOST_{OS,TYPE,ARCH,PLATFORM} / VKIT_DEVICE_PLATFORM / VKIT_BUILD_DIR / VKIT_PREBUILT_DIR / VKIT_PREBUILT_PRIVATE_DIR / VKIT_PACKUP_DIR / VKIT_SETUP_DIR / VKIT_ETC_DIR / VKIT_CODE_COMPLETE_DIR / VKIT_HOST_TOOL_DIR / VKIT_PLATFORM_CONFIG_DIR / VKIT_PLATFORM_DEPLOY_DIR / CMAKE_TOOLCHAIN_FILE / CMAKE_INSTALL_PREFIX / CMAKE_GENERATOR / CCACHE_COMPRESS / CCACHE_MAXSIZE`.

> `VKIT_VCS_TOOL` is hardcoded to `ripvcs` inside the script and **cannot be overridden via the environment**; it falls back to `vcs` only when `ripvcs` is unavailable on the host.

### Appendix C · Deploy implementation details

Read this when troubleshooting deploy issues or extending `do_copy` / `do_packup`.

#### `do_copy` private-binary whitelist
- `prebuilt-private/bin/iox-roudi` / `iox-introspection-client`: when regular files, copied to `prebuilt/bin/`
- `prebuilt-private/bin/fast-discovery-server`: when a symlink, the versioned executable matching `prebuilt-private/bin/fast-discovery-server-*` is copied as `fast-discovery-server` (the directory is expected to contain exactly one match)

#### `do_packup` sync details
- Uses `rsync -a --delete` when available; otherwise falls back to `rm -rf` + `cp -rf` full sync
- After sync, removes `target/lib/engines-*` to avoid OpenSSL engine pollution
- `prebuilt-private/` is not synced

#### QNX `vkit.build` output format
- Keeps only `bin/`, `sbin/`, `lib64/`, `etc/`, `scripts/` entries
- Symlinks recorded as `[type=link]<src> = <readlink target>`
- When `VERSION_REL=QHS_SDP220`: `bin` / `scripts` use `PERM_BIN`; other paths use `[uid=ROOT_UID gid=ROOT_GID perms=0555]`

### Appendix D · Adding a new platform / architecture

```bash
# 1) Append a VKIT_PLATFORM branch in cmake/toolchain.cmake
# elseif("$ENV{VKIT_PLATFORM}" STREQUAL "myrtos-aarch64")
#   set(VKIT_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/myrtos/myrtos.toolchain.aarch64.cmake)

# 2) Author the toolchain files
mkdir -p cmake/myrtos
$EDITOR cmake/myrtos/myrtos.toolchain.common.cmake     # compiler, find_root_path, flags
$EDITOR cmake/myrtos/myrtos.toolchain.aarch64.cmake    # SYSTEM_PROCESSOR + include common

# 3) Copy a reference platform's cfg
cp -r config/linux-aarch64 config/myrtos-aarch64
$EDITOR config/myrtos-aarch64/*.cfg

# 4) Verify
export VKIT_PLATFORM=myrtos-aarch64
make
```

**External toolchain script search order**　`source vkit-setup.sh <name>` looks for `<name>_setup.sh` in this order, **stopping at the first hit**:

```
1. <vkit>/toolchains/<name>/<name>_setup.sh       # in-repo, private
2. <vkit>/vkit-toolchains/<name>/<name>_setup.sh  # in-repo (recommended for sharing)
3. ~/vkit-toolchains/<name>/<name>_setup.sh       # user-level
4. /opt/vkit-toolchains/<name>/<name>_setup.sh    # host-level
5. /opt/<name>/<name>_setup.sh                    # SDK-bundled
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE) — you are free to use, modify, and distribute it (including for commercial purposes) as long as you retain the copyright and license notice. See [LICENSE](LICENSE) for full text.
