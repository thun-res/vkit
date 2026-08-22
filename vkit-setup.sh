#!/usr/bin/env bash

[ -n "$BASH_VERSION" ] && shopt -s extglob
[ -n "$ZSH_VERSION" ] && setopt extendedglob
[ -n "$ZSH_VERSION" ] && zmodload zsh/datetime zsh/system 2>/dev/null

if [ -z "$VKIT_ROOT_DIR" ]; then
    export VKIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
fi
export VKIT_HOST_OS="$(uname -o 2>/dev/null | tr '[:upper:]' '[:lower:]')"
export VKIT_HOST_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
export VKIT_HOST_ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"

if [ "$VKIT_HOST_OS" = "cygwin" ] || [ "$VKIT_HOST_OS" = "msys" ] || [ "$VKIT_HOST_OS" = "mingw" ]; then
    export VKIT_HOST_PLATFORM="$VKIT_HOST_OS-$VKIT_HOST_ARCH"
else
    export VKIT_HOST_PLATFORM="$VKIT_HOST_TYPE-$VKIT_HOST_ARCH"
fi

if [ "$0" != "$BASH_SOURCE" ] && [ -n "$1" ]; then
    if [ -f "$VKIT_ROOT_DIR/toolchains/$1/$1_setup.sh" ]; then
        . "$VKIT_ROOT_DIR/toolchains/$1/$1_setup.sh"
    elif [ -f "$VKIT_ROOT_DIR/vkit-toolchains/$1/$1_setup.sh" ]; then
        . "$VKIT_ROOT_DIR/vkit-toolchains/$1/$1_setup.sh"
    elif [ -f ~/vkit-toolchains/"$1/$1_setup.sh" ]; then
        . ~/vkit-toolchains/"$1/$1_setup.sh"
    elif [ -f "/opt/vkit-toolchains/$1/$1_setup.sh" ]; then
        . "/opt/vkit-toolchains/$1/$1_setup.sh"
    elif [ -f "/opt/$1/$1_setup.sh" ]; then
        . "/opt/$1/$1_setup.sh"
    else
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find $1_setup.sh!\033[0m"
        return 1
    fi
fi

if [ -z "$VKIT_PLATFORM" ] || [ "$VKIT_PLATFORM" = "auto" ]; then
    if [ -n "$QNX_TARGET" ] && [ -n "$QNX_HOST" ]; then
        export VKIT_PLATFORM="qnx-aarch64"
    elif [ -n "$ANDROID_NDK" ]; then
        export VKIT_PLATFORM="android-aarch64"
    elif [ -n "$CROSS_COMPILE_PREFIX" ]; then
        export VKIT_PLATFORM="linux-aarch64"
    else
        export VKIT_PLATFORM="$VKIT_HOST_PLATFORM"
    fi
fi

if [ -z "$VKIT_DEVICE" ]; then
    export VKIT_DEVICE_PLATFORM="$VKIT_PLATFORM"
else
    export VKIT_DEVICE_PLATFORM="$VKIT_PLATFORM-$VKIT_DEVICE"
fi

if [ -d "$VKIT_ROOT_DIR/config/$VKIT_DEVICE_PLATFORM" ]; then
    export VKIT_PLATFORM_CONFIG_DIR="$VKIT_ROOT_DIR/config/$VKIT_DEVICE_PLATFORM"
elif [ -d "$VKIT_ROOT_DIR/config/$VKIT_PLATFORM" ]; then
    export VKIT_PLATFORM_CONFIG_DIR="$VKIT_ROOT_DIR/config/$VKIT_PLATFORM"
else
    export VKIT_PLATFORM_CONFIG_DIR=
fi

if [ -d "$VKIT_ROOT_DIR/deploy/$VKIT_DEVICE_PLATFORM" ]; then
    export VKIT_PLATFORM_DEPLOY_DIR="$VKIT_ROOT_DIR/deploy/$VKIT_DEVICE_PLATFORM"
elif [ -d "$VKIT_ROOT_DIR/deploy/$VKIT_PLATFORM" ]; then
    export VKIT_PLATFORM_DEPLOY_DIR="$VKIT_ROOT_DIR/deploy/$VKIT_PLATFORM"
else
    export VKIT_PLATFORM_DEPLOY_DIR=
fi

if [ -z "$VKIT_PLATFORM_CONFIG_DIR" ]; then
    echo -e "\033[1;31m$_mm_ico_fail Error: Can not find platform config!\033[0m"
    [ "$0" != "$BASH_SOURCE" ] && return 1
    exit 1
fi

export VKIT_HOST_TOOL_DIR="$VKIT_ROOT_DIR/tools/$VKIT_HOST_PLATFORM"
export VKIT_BUILD_DIR="$VKIT_ROOT_DIR/build/$VKIT_DEVICE_PLATFORM"
export VKIT_PREBUILT_DIR="$VKIT_ROOT_DIR/prebuilt/$VKIT_DEVICE_PLATFORM"
export VKIT_PREBUILT_PRIVATE_DIR="$VKIT_ROOT_DIR/prebuilt-private/$VKIT_DEVICE_PLATFORM"
export VKIT_PACKUP_DIR="$VKIT_ROOT_DIR/packup/$VKIT_DEVICE_PLATFORM"
export VKIT_SETUP_DIR="$VKIT_ROOT_DIR/setup/$VKIT_DEVICE_PLATFORM"
export VKIT_ETC_DIR="$VKIT_PREBUILT_DIR/etc"
export VKIT_CODE_COMPLETE_DIR="$VKIT_ETC_DIR/vkit-completions"
export VKIT_PACKUP_RUNTIME=${VKIT_PACKUP_RUNTIME:-"1"}
export VKIT_PACKUP_SDK=${VKIT_PACKUP_SDK:-"0"}
export VKIT_VCS_TOOL=ripvcs

export CMAKE_TOOLCHAIN_FILE="$VKIT_ROOT_DIR/cmake/toolchain.cmake"
export CMAKE_INSTALL_PREFIX="$VKIT_PREBUILT_DIR"
command -v ninja &> /dev/null && export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"

export CCACHE_COMPRESS=1
export CCACHE_MAXSIZE=10G

export VLINK_ROOT_DIR="$VKIT_PREBUILT_DIR"
export VLINK_ETC_DIR="$VKIT_ETC_DIR"
export VLINK_COMPLETIONS="$VLINK_ETC_DIR/vlink/vlink-completions.sh"

[[ "$PATH" != *"$VKIT_HOST_TOOL_DIR/bin"* ]] && export PATH="$VKIT_HOST_TOOL_DIR/bin:$PATH"
[[ "$LD_LIBRARY_PATH" != *"$VKIT_HOST_TOOL_DIR/lib"* ]] && export LD_LIBRARY_PATH="$VKIT_HOST_TOOL_DIR/lib:$LD_LIBRARY_PATH"

if ! command -v "$VKIT_VCS_TOOL" &>/dev/null; then
    export VKIT_VCS_TOOL=vcs
fi

[ -d "$VKIT_ROOT_DIR/build" ] && mkdir -p "$VKIT_BUILD_DIR"
[ -d "$VKIT_ROOT_DIR/prebuilt" ] && mkdir -p "$VKIT_PREBUILT_DIR"
[ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && mkdir -p "$VKIT_PREBUILT_PRIVATE_DIR"

if [ -d "$VKIT_ROOT_DIR/middleware/vmsgs/schemas" ]; then
    [ -z "$VLINK_PROTO_DIR" ] && export VLINK_PROTO_DIR="$VKIT_ROOT_DIR/middleware/vmsgs/schemas"
    [ -z "$VLINK_FBS_DIR" ] && export VLINK_FBS_DIR="$VKIT_ROOT_DIR/middleware/vmsgs/schemas"
    export VLINK_SCHEMA_PLUGIN=vmsgs
fi

# [ -f $VKIT_ROOT_DIR/rust/rust_setup.sh ] && . $VKIT_ROOT_DIR/rust/rust_setup.sh

function _get_build_cpu_count() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _cpu_count=$(sysctl -n hw.physicalcpu)
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        _cpu_count=$(sysctl -n hw.ncpu)
    else
        _cpu_count=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)
    fi
    echo $_cpu_count
}

export VKIT_BUILD_CPU_CORE=${VKIT_BUILD_CPU_CORE:-$(_get_build_cpu_count)}
unset MAKEFLAGS
unset MAKELEVEL
unset __cache_mm_project
unset __cache_mm_dir
unset __cache_mmm_cfg

case "${LC_ALL:-${LC_CTYPE:-$LANG}}" in
    *[Uu][Tt][Ff]*)
        _mm_ico_run="▶"; _mm_ico_ok="✔"; _mm_ico_fail="✘"; _mm_ico_warn="⚠"
        ;;
    *)
        _mm_ico_run=">"; _mm_ico_ok="*"; _mm_ico_fail="x"; _mm_ico_warn="!"
        ;;
esac

function _mm_time_now() {
    if [ -n "$EPOCHREALTIME" ]; then
        echo "${EPOCHREALTIME/,/.}"
    else
        date +%s
    fi
}

function _mm_time_elapsed() {
    local _f _now _tenths _fmt _t0t=0
    case "$1" in
        *[.,]*)
            _f="${1#*[.,]}"
            _t0t=$(( ${1%%[.,]*} * 10 + ${_f:0:1} ))
            ;;
    esac
    _mm_status_tenths "$1" "$_t0t"
    _mm_status_fmt $_tenths
    printf '%s' "$_fmt"
}

function _mm_kill_tree() {
    local _p
    for _p in $(pgrep -P "$1" 2>/dev/null); do
        _mm_kill_tree "$_p"
    done
    kill -TERM "$1" 2>/dev/null
}

function _mm_key_esc() {
    local _k=""
    local _k2=""
    if [ -n "$ZSH_VERSION" ]; then
        read -r -s -t 0 -k 1 _k < /dev/tty 2>/dev/null || return 1
    else
        read -t 0 < /dev/tty 2>/dev/null || return 1
        IFS= read -r -s -n 1 -t 0.05 _k < /dev/tty 2>/dev/null || return 1
    fi
    [ "$_k" = $'\033' ] || return 1
    if [ -n "$ZSH_VERSION" ]; then
        read -r -s -t 0.05 -k 1 _k2 < /dev/tty 2>/dev/null
    else
        IFS= read -r -s -n 1 -t 0.05 _k2 < /dev/tty 2>/dev/null
    fi
    [ -n "$_k2" ] && return 1
    return 0
}

function _mm_sbar_begin() {
    [ -n "$_mm_sbar_on" ] && return 1
    { [ -t 1 ] && [ "$VKIT_SBAR_DISABLE" != "1" ] && { [ -z "$ZSH_VERSION" ] || zmodload -e zsh/system 2>/dev/null; }; } || return 1
    local _sz="$(stty size < /dev/tty 2>/dev/null)"
    local _rows="${_sz%% *}"
    { [ -n "$_rows" ] && [ "$_rows" -ge 4 ]; } || return 1
    _mm_sbar_stty="$(stty -g < /dev/tty 2>/dev/null)"
    [ -n "$_mm_sbar_stty" ] && stty -echo -icanon min 1 time 0 < /dev/tty 2>/dev/null
    if [ -n "$ZSH_VERSION" ]; then
        _mm_sbar_trap0="${functions[TRAPINT]-}"
        _mm_sbar_trap1=""
        if [ -z "$_mm_sbar_trap0" ]; then
            trap 2>/dev/null > "${TMPDIR:-/tmp}/.vkit_trap_$$"
            _mm_sbar_trap1="$(grep " INT\$" "${TMPDIR:-/tmp}/.vkit_trap_$$" 2>/dev/null)"
            rm -f "${TMPDIR:-/tmp}/.vkit_trap_$$"
        fi
        functions[TRAPINT]='_mm_sbar_end; kill -INT $$'
    else
        _mm_sbar_trap0="$(trap -p INT)"
        _mm_sbar_trap1=""
        trap '_mm_sbar_end; kill -INT $$' INT
    fi
    _mm_sbar_rows="$_rows"
    _mm_sbar_on=1
    printf '\033[?25l\n\0337\033[1;%dr\0338\033[A' $((_rows - 1))
    return 0
}

function _mm_sbar_end() {
    [ -n "$_mm_sbar_on" ] || return 0
    _mm_sbar_on=""
    if [ -n "$ZSH_VERSION" ]; then
        if [ -n "$_mm_sbar_trap0" ]; then
            functions[TRAPINT]="$_mm_sbar_trap0"
        else
            trap - INT
            [ -n "$_mm_sbar_trap1" ] && eval "$_mm_sbar_trap1"
        fi
    else
        trap - INT
        [ -n "$_mm_sbar_trap0" ] && eval "$_mm_sbar_trap0"
    fi
    if [ -n "$_mm_sbar_stty" ]; then
        stty -icanon min 0 time 0 < /dev/tty 2>/dev/null
        dd if=/dev/tty of=/dev/null bs=4096 count=1 2>/dev/null
        stty "$_mm_sbar_stty" < /dev/tty 2>/dev/null
    fi
    printf '\0337\033[%d;1H\033[2K\0338\0337\033[r\0338\033[?25h' "$_mm_sbar_rows"
    unset _mm_sbar_on _mm_sbar_stty _mm_sbar_trap0 _mm_sbar_trap1 _mm_sbar_rows
}

function _mm_status_end() {
    trap - INT
    if [ -n "$_mm_trap0" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            functions[TRAPINT]="$_mm_trap0"
        else
            eval "$_mm_trap0"
        fi
    elif [ -n "$_mm_trap1" ]; then
        eval "$_mm_trap1"
    fi
    if [ "$_pinned" = "1" ]; then
        [ "$_first" = "0" ] && { printf '\n'; _first=1; }
    else
        if [ -n "$_mm_stty" ]; then
            stty -icanon min 0 time 0 < /dev/tty 2>/dev/null
            dd if=/dev/tty of=/dev/null bs=4096 count=1 2>/dev/null
            stty "$_mm_stty" < /dev/tty 2>/dev/null
            _mm_stty=""
        fi
        printf '\r\033[2K\033[?25h'
    fi
}

function _mm_status_tenths() {
    if [ -n "$EPOCHREALTIME" ] && [ "$2" -ne 0 ]; then
        _now="$EPOCHREALTIME"
        _f="${_now#*[.,]}"
        _tenths=$(( ${_now%%[.,]*} * 10 + ${_f:0:1} - $2 ))
    else
        _tenths=$(( ($(date +%s) - ${1%%[.,]*}) * 10 ))
    fi
}

function _mm_status_fmt() {
    local _ft=$1
    local _fs=$((_ft / 10))
    if [ $_fs -ge 3600 ]; then
        _fmt="$((_fs / 3600))h $((_fs % 3600 / 60))min $((_fs % 60))s"
    elif [ $_fs -ge 60 ]; then
        _fmt="$((_fs / 60))min $((_fs % 60)).$((_ft % 10))s"
    else
        _fmt="$_fs.$((_ft % 10))s"
    fi
}

function _mm_status_draw() {
    local _fmt _spin _tot _r _avail _dn _dot="..."
    _mm_status_tenths "$_t0" "$_t0t"
    _spin="${_d:$(( _tenths % (${#_d} / _dw) * _dw )):_dw}"
    if [ -n "$EPOCHREALTIME" ]; then
        _now="$EPOCHREALTIME"
        _f="${_now#*[.,]}"
        _dn=$(( ( ${_now%%[.,]*} * 100 + 10#${_f:0:2} ) / 25 % 4 ))
    else
        _dn=$(( _tenths * 2 / 5 % 4 ))
    fi
    _mm_status_fmt $_tenths
    _dot="${_dot:0:_dn}   "
    _status="${_spin}[$_pkg] Building${_dot:0:3} [$_fmt]"
    [ -n "$_progress" ] && _status="$_status [$_progress]"
    _tot=""
    if [ -n "$_tt0" ]; then
        _mm_status_tenths "$_tt0" "$_tt0t"
        _mm_status_fmt $_tenths
        _tot="$_fmt"
    fi
    _avail=$((_cols - 1))
    [ $_avail -lt 0 ] && _avail=0
    _r=""
    if [ $_avail -ge $(( ${#_cc} + 44 )) ]; then
        _r="[$_cc]"
        if [ -n "$_tot" ] && [ $_avail -ge $(( ${#_cc} + ${#_tot} + 54 )) ]; then
            _r="[$_cc] [total: $_tot]"
        fi
        _avail=$((_avail - ${#_r} - 2))
    fi
    if [ ${#_status} -gt $_avail ]; then
        if [ $_avail -gt 8 ]; then
            _status="${_status:0:$((_avail - 3))}..."
        else
            _status="${_status:0:$_avail}"
        fi
    fi
    [ "$_status|$_r" = "$_mm_status_last" ] && return 0
    _mm_status_last="$_status|$_r"
    if [ $_pinned -eq 1 ]; then
        printf '\0337\033[%d;1H\033[1;97;48;5;39m%s\033[38;5;250m%*s\033[0m\0338' "$_rows" "$_status" $((_cols - ${#_status})) "$_r"
    else
        printf '\r\033[1;97;48;5;39m%s\033[38;5;250m%*s\033[0m' "$_status" $((_cols - ${#_status} - 1)) "$_r"
    fi
}

function _mm_status_filter() {
    local _pkg="$1"
    local _t0="$2"
    local _progress="$__mm_status_progress"
    local _line _rc _sz _f _d _dw _now _chunk _t1s _done _tenths _status
    local _buf="" _ret=130 _tick=0 _esc=0 _first=1 _pinned=0 _t0t=0 _ninja_progress=0
    local _mm_trap0="" _mm_trap1=""
    if [ -n "$ZSH_VERSION" ]; then
        _mm_trap0="${functions[TRAPINT]-}"
        if [ -z "$_mm_trap0" ]; then
            trap 2>/dev/null > "${TMPDIR:-/tmp}/.vkit_trap_$$"
            _mm_trap1="$(grep " INT\$" "${TMPDIR:-/tmp}/.vkit_trap_$$" 2>/dev/null)"
            rm -f "${TMPDIR:-/tmp}/.vkit_trap_$$"
        fi
    else
        _mm_trap0="$(trap -p INT)"
    fi
    local _rto=0.05
    [ -n "$BASH_VERSION" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && _rto=1
    _sz="$(stty size < /dev/tty 2>/dev/null)"
    local _rows="${_sz%% *}"
    local _cols="${_sz##* }"
    [ -z "$_cols" ] && _cols=80
    case "$_t0" in
        *[.,]*)
            _f="${_t0#*[.,]}"
            _t0t=$(( ${_t0%%[.,]*} * 10 + ${_f:0:1} ))
            ;;
    esac
    local _tt0="$__mm_status_total_t0"
    local _tt0t=0
    case "$_tt0" in
        *[.,]*)
            _f="${_tt0#*[.,]}"
            _tt0t=$(( ${_tt0%%[.,]*} * 10 + ${_f:0:1} ))
            ;;
    esac
    local _cc="ccache:off"
    if [ "$VKIT_DISABLE_CCACHE" != "1" ] && [[ "$VKIT_PLATFORM" != qnx-* ]] && command -v ccache >/dev/null 2>&1; then
        _cc="ccache:on"
    fi
    local _mm_status_last=""
    case "${LC_ALL:-${LC_CTYPE:-$LANG}}" in
        *[Uu][Tt][Ff]*)
            _d="⠉⠇⠈⡇⢀⡇⣀⡆⣄⡄⣆⡀⣇⠀⡏⠀⠏⠁⠋⠃"
            _dw=2
            ;;
        *)
            _d='|/-\'
            _dw=1
            ;;
    esac
    local _mm_stty=""
    if [ -n "$_mm_sbar_on" ]; then
        _pinned=1
        if [ -n "$_rows" ] && [ "$_rows" != "$_mm_sbar_rows" ]; then
            printf '\0337\033[1;%dr\0338' $((_rows - 1))
            _mm_sbar_rows="$_rows"
        fi
    else
        _mm_stty="$(stty -g < /dev/tty 2>/dev/null)"
        [ -n "$_mm_stty" ] && stty -echo -icanon min 1 time 0 < /dev/tty 2>/dev/null
        printf '\033[?25l'
    fi
    trap '_esc=2' INT
    _mm_status_draw
    while :; do
        [ $_esc -ne 0 ] && break
        _done=0
        if [ -n "$ZSH_VERSION" ]; then
            _chunk=""
            sysread -s 4096 -t $_rto _chunk
            _rc=$?
            if [ $_rc -eq 0 ]; then
                _buf="$_buf$_chunk"
            elif [ $_rc -ne 4 ]; then
                break
            fi
        else
            _line=
            _t1s=0
            [ -z "$EPOCHREALTIME" ] && _t1s=$(date +%s)
            IFS= read -r -t $_rto _line
            _rc=$?
            if [ $_rc -eq 0 ]; then
                _buf="$_buf$_line"$'\n'
            elif [ $_rc -gt 128 ]; then
                _buf="$_buf$_line"
            elif [ "$_t1s" != "0" ] && [ $(( $(date +%s) - _t1s )) -ge 1 ]; then
                :
            else
                break
            fi
        fi
        while [ "${_buf#*$'\n'}" != "$_buf" ]; do
            _line="${_buf%%$'\n'*}"
            _buf="${_buf#*$'\n'}"
            if [ "${_line#*__MM_RET_${_mm_key}__}" != "$_line" ]; then
                _ret="${_line##*__MM_RET_${_mm_key}__}"
                case "$_ret" in
                    ''|*[!0-9]*) _ret=1 ;;
                esac
                _line="${_line%%__MM_RET_${_mm_key}__*}"
                _done=1
                [ -z "$_line" ] && break
            fi
            if [ $_pinned -eq 1 ]; then
                if [[ "$_line" =~ ^\[[0-9]+/[0-9]+\]\  ]]; then
                    if [ $_ninja_progress -eq 1 ]; then
                        printf '\r\033[2K%s' "$_line"
                    elif [ $_first -eq 1 ]; then
                        _first=0
                        printf '%s' "$_line"
                    else
                        printf '\n%s' "$_line"
                    fi
                    _ninja_progress=1
                elif [ $_first -eq 1 ]; then
                    _first=0
                    printf '%s' "$_line"
                else
                    printf '\n%s' "$_line"
                    _ninja_progress=0
                fi
            else
                printf '\r\033[2K%s\n' "$_line"
                _mm_status_last=""
            fi
            [ $_done -eq 1 ] && break
        done
        [ $_done -eq 1 ] && break
        if [ $_esc -eq 0 ] && [ -n "$_mm_bpid" ] && _mm_key_esc; then
            _esc=1
            if [ $_pinned -eq 1 ]; then
                if [ $_first -eq 1 ]; then
                    _first=0
                    printf '\033[1;33m%s Stopping build (ESC pressed)\033[0m' "$_mm_ico_warn"
                else
                    printf '\n\033[1;33m%s Stopping build (ESC pressed)\033[0m' "$_mm_ico_warn"
                fi
            else
                printf '\r\033[2K\033[1;33m%s Stopping build (ESC pressed)\033[0m\n' "$_mm_ico_warn"
            fi
            _mm_kill_tree "$_mm_bpid"
        fi
        _tick=$((_tick + 1))
        if [ $_pinned -eq 1 ] && [ $((_tick % 10)) -eq 0 ]; then
            _sz="$(stty size < /dev/tty 2>/dev/null)"
            if [ -n "$_sz" ] && [ "$_sz" != "$_rows $_cols" ] && [ "${_sz%% *}" -ge 4 ]; then
                printf '\0337\033[r\0338'
                _rows="${_sz%% *}"
                _cols="${_sz##* }"
                printf '\n\0337\033[1;%dr\0338\033[A' $((_rows - 1))
                _mm_sbar_rows="$_rows"
                _mm_status_last=""
            fi
        fi
        _mm_status_draw
    done
    [ $_esc -eq 2 ] && [ -n "$_mm_bpid" ] && _mm_kill_tree "$_mm_bpid"
    _mm_status_end
    [ $_esc -ne 0 ] && _ret=130
    return $_ret
}

function _mm_cmake_project() {
    if [ ! -f "$VKIT_BUILD_DIR/$_project/CMakeCache.txt" ]; then
        cmake -S "$_project_dir" -B "$VKIT_BUILD_DIR/$_project" -DCMAKE_TOOLCHAIN_FILE="$VKIT_ROOT_DIR/cmake/toolchain.cmake" "$@" || return $?
    fi
    cmake --build "$VKIT_BUILD_DIR/$_project" -j"$VKIT_BUILD_CPU_CORE" || return $?
    if [ "$VKIT_STRIP" = "1" ]; then
        cmake --install "$VKIT_BUILD_DIR/$_project" --strip >/dev/null
    else
        cmake --install "$VKIT_BUILD_DIR/$_project" >/dev/null
    fi
}

function _mm_shell_project() {
    mkdir -p "$VKIT_BUILD_DIR/$_project" && cp -rf "$_project_dir"/* "$VKIT_BUILD_DIR/$_project/" || return $?
    "$VKIT_BUILD_DIR/$_project/build.sh" "$@"
}

function _mm_run() {
    if [ -t 1 ] && [ "$VKIT_SBAR_DISABLE" != "1" ] && { [ -z "$ZSH_VERSION" ] || zmodload -e zsh/system 2>/dev/null; }; then
        local _mm_fifo="${TMPDIR:-/tmp}/.vkit_mm_$$_$RANDOM"
        local _mm_bpid=""
        local _mm_rc=0
        local _mm_key=""
        mkfifo "$_mm_fifo" 2>/dev/null || { "$@"; return $?; }
        _mm_key="${$}_${RANDOM}"
        _mm_bpid=$( ( ( exec >/dev/null 2>&1; exec > "$_mm_fifo"; "$@" 2>&1; printf '__MM_RET_%s__%s\n' "$_mm_key" "$?" ) & echo $! ) )
        _mm_status_filter "$_project" "$_mm_t0" < "$_mm_fifo"
        _mm_rc=$?
        rm -f "$_mm_fifo"
        return $_mm_rc
    else
        "$@"
    fi
}

function mm() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo -e "Usage:"
        echo -e "       mm"
        echo -e "       mm '-D{CMAKE_FLAG}'"
        echo -e "       mm clean"
        return 0
    fi
    if [ -n "$__cache_mm_dir" ]; then
        local _project_dir="$__cache_mm_dir"
    else
        local _project_dir="$(pwd)"
    fi
    if [ -n "$__cache_mm_project" ]; then
        local _project="$__cache_mm_project"
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/"* ]]; then
        local _project="${_project_dir#$VKIT_ROOT_DIR/}"
    else
        local _project="$(basename "$_project_dir")"
    fi
    local _build_type=0
    if [ -f "$_project_dir/CMakeLists.txt" ]; then
        _build_type=0 # cmake
    elif [ -f "$_project_dir/cmake/CMakeLists.txt" ]; then
        _build_type=0 # cmake
        _project_dir="$_project_dir/cmake"
    elif [ -f "$_project_dir/build.sh" ]; then
        _build_type=1 # build.sh
    elif [ -f "$_project_dir/Makefile" ]; then
        _build_type=2 # Makefile
        [ "$_project_dir" = "$VKIT_ROOT_DIR" ] && echo -e "\033[1;31m$_mm_ico_fail Error: Can not mm project [$_project_dir]!\033[0m" && return 1
    elif [ -n "$__cache_mm_dir" ] && [ -z "$(ls -A "$_project_dir")" ]; then
        echo -e "\033[1;33m$_mm_ico_warn [$_project] Skipped\033[0m"
        return 0
    else
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not mm project [$_project_dir]!\033[0m" && return 1
    fi
    if [ "$1" = "clean" ]; then
        if [ -d "$VKIT_BUILD_DIR/$_project" ]; then
            echo -e "\033[1;32m$_mm_ico_ok [$_project] Cleaned...\033[0m"
            if [ $_build_type -eq 2 ]; then
                make -C "$_project_dir" clean
            fi
            rm -rf "$VKIT_BUILD_DIR/$_project"
        fi
        return 0
    elif [ "$1" = "dclean" ]; then
        if [ -d "$VKIT_BUILD_DIR/$_project" ]; then
            echo -e "\033[1;32m$_mm_ico_ok [$_project] Cleaned...\033[0m"
            if [ $_build_type -eq 0 ]; then
                cmake --build "$VKIT_BUILD_DIR/$_project" --target __uninstall
            elif [ $_build_type -eq 2 ]; then
                make -C "$_project_dir" clean
            fi
            rm -rf "$VKIT_BUILD_DIR/$_project"
        fi
        return 0
    else
        local _mm_ret=0
        local _mm_t0="$(_mm_time_now)"
        local _mm_own=""
        _mm_sbar_begin && _mm_own=1
        echo -e "\n\033[1;34m$_mm_ico_run [$_project] Building...\033[0m"
        if [ $_build_type -eq 0 ]; then
            local _has_target=0
            local _a
            for _a in "$@"; do
                if [ "$_a" = "--target" ] || [[ "$_a" == "--target="* ]]; then
                    _has_target=1
                    break
                fi
            done
            if [ $_has_target -eq 1 ]; then
                _mm_run cmake --build "$VKIT_BUILD_DIR/$_project" -j"$VKIT_BUILD_CPU_CORE" "$@"
            else
                _mm_run _mm_cmake_project "$@"
            fi
        elif [ $_build_type -eq 1 ]; then
            _mm_run _mm_shell_project "$@"
        elif [ $_build_type -eq 2 ]; then
            _mm_run make -C "$_project_dir" "$@" -j"$VKIT_BUILD_CPU_CORE"
        fi
        _mm_ret=$?
        [ -n "$_mm_own" ] && _mm_sbar_end
        if [ $_mm_ret -ne 0 ]; then
            echo -e "\n\033[1;31m$_mm_ico_fail [$_project] Build failed [$(_mm_time_elapsed "$_mm_t0")]\033[0m"
            return 1
        fi
        echo -e "\033[1;32m$_mm_ico_ok [$_project] Finished [$(_mm_time_elapsed "$_mm_t0")]\033[0m"
        echo -e ""
        return 0
    fi
}

function _mm_for_cfg() {
    local _path="$1"
    local _arg="${2-}"
    [ $# -ge 1 ] && shift
    [ $# -ge 1 ] && shift
    local _reval=0
    [ ! -f "$_path" ] && echo -e "\033[1;31m$_mm_ico_fail Error: Path [$_path] not exists!\033[0m" && return 1
    local lines=()
    while read _line || [[ -n "$_line" ]]; do
        _line="${_line#"${_line%%[![:space:]]*}"}"
        ([ -z "$_line" ] || [[ "$_line" == \#* ]] || [[ "$_line" == \;* ]] || [[ "$_line" == //* ]]) && continue
        lines+=("$_line")
    done < "$_path"
    local _total=${#lines[@]}
    local _idx=0
    local _t0="$(_mm_time_now)"
    local __mm_status_total_t0="${__mm_status_total_t0:-$_t0}"
    local _mm_own=""
    [ "$_arg" != "clean" ] && _mm_sbar_begin && _mm_own=1
    for _line in "${lines[@]}"; do
        _idx=$((_idx + 1))
        local _project=$(echo "$_line" | cut -d ";" -f 1)
        local _cfg_arg=$(echo "$_line" | cut -d ";" -f 2)
        local __cache_mm_project="$_project"
        local __cache_mm_dir="$VKIT_ROOT_DIR/$_project"
        local __mm_status_progress="$_idx/$_total"
        [ -z "$_project" ] && echo -e "\033[1;33m$_mm_ico_warn Warning: Split line [$_line] failed!\033[0m" && continue
        [ ! -d "$__cache_mm_dir" ] && echo -e "\033[1;33m$_mm_ico_warn [$_project] Skipped\033[0m" && continue
        if [ "$_arg" = "clean" ]; then
            mm clean
        elif [ -n "$_arg" ]; then
            mm $(echo "${_cfg_arg}") "$_arg" "$@"
        else
            mm $(echo "${_cfg_arg}") "$@"
        fi
        [ $? -ne 0 ] && _reval=1 && break
    done
    [ -n "$_mm_own" ] && _mm_sbar_end
    if [ "$_arg" != "clean" ] && [ $_total -gt 0 ]; then
        if [ $_reval -eq 0 ]; then
            echo -e "\033[1;32m$_mm_ico_ok Summary: $_total projects finished [$(_mm_time_elapsed "$_t0")]\033[0m\n"
        else
            echo -e "\033[1;33m$_mm_ico_warn Summary: stopped at [$(_mm_time_elapsed "$_t0")] [$_idx/$_total]\033[0m\n"
        fi
    fi
    return $_reval
}

function _mmm_get_cfg() {
    local _path="$1"
    local _pwd="$2"
    [ ! -f "$_path" ] && echo -e "\033[1;31m$_mm_ico_fail Error: Path [$_path] not exists!\033[0m" && return 1
    local lines=()
    while read _line || [[ -n "$_line" ]]; do
        _line="${_line#"${_line%%[![:space:]]*}"}"
        ([ -z "$_line" ] || [[ "$_line" == \#* ]] || [[ "$_line" == \;* ]] || [[ "$_line" == //* ]]) && continue
        lines+=("$_line")
    done < "$_path"
    for _line in "${lines[@]}"; do
        local _project=$(echo "$_line" | cut -d ";" -f 1)
        local _cfg_arg=$(echo "$_line" | cut -d ";" -f 2)
        local __cache_mm_project="$_project"
        local __cache_mm_dir="$VKIT_ROOT_DIR/$_project"
        [ -z "$_project" ]  && continue
        [ ! -d "$__cache_mm_dir" ]  && continue
        if [[ "$_pwd" == */"$_project" ]]; then
            __cache_mmm_cfg="$_cfg_arg"
            return 0
        fi
    done
    return 1
}

function _mmm_ll_cfg() {
    local _project_dir="$1"
    local _skip_app=0
    local _skip_middleware=0
    local _skip_vendor=0
    local _skip_thirdparty=0
    if [[ "$_project_dir" == "$VKIT_ROOT_DIR/app/"* ]]; then
        _skip_app=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/middleware/"* ]]; then
        _skip_middleware=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/vendor/"* ]]; then
        _skip_vendor=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/thirdparty/"* ]]; then
        _skip_thirdparty=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$_project_dir" && return 0
    fi
    [ $_skip_app -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$_project_dir" && return 0
    [ $_skip_middleware -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$_project_dir" && return 0
    [ $_skip_vendor -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$_project_dir" && return 0
    [ $_skip_thirdparty -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$_project_dir" && return 0
    return 1
}

function mm_thirdparty() {
    _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$@"
}

function mm_vendor() {
    _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$@"
}

function mm_middleware() {
    if [ "$1" != "clean" ] && [ "${VKIT_MIDDLEWARE_RELWITHDEBINFO}" = "1" ]; then
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$@" -DCMAKE_BUILD_TYPE="RelWithDebInfo"
    else
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$@"
    fi
}

function mm_app() {
    if [ "$1" != "clean" ] && [ "${VKIT_APP_RELWITHDEBINFO}" = "1" ]; then
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$@" -DCMAKE_BUILD_TYPE="RelWithDebInfo"
    else
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$@"
    fi
}

function mm_all() {
    local _has_component=0
    local _reval=0
    local _c
    local __mm_status_total_t0="$(_mm_time_now)"
    local _mm_own=""
    [ "$1" != "clean" ] && _mm_sbar_begin && _mm_own=1
    for _c in thirdparty vendor middleware app; do
        [ -f "$VKIT_PLATFORM_CONFIG_DIR/$_c.cfg" ] || continue
        _has_component=1
        mm_$_c "$@"
        [ $? -ne 0 ] && _reval=1 && break
    done
    [ -n "$_mm_own" ] && _mm_sbar_end
    if [ $_has_component -eq 0 ]; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find any project to build!\033[0m" && return 1
    fi
    return $_reval
}

function mmm() {
    local _project_dir="$(pwd)"
    local __cache_mmm_cfg=
    _mmm_ll_cfg "$_project_dir"
    [ $? -ne 0 ] && echo -e "\033[1;31m$_mm_ico_fail Error: Can not mmm project [$_project_dir]!\033[0m" && return 1
    if [ "$1" = "clean" ]; then
        mm clean
    else
        mm $(echo $__cache_mmm_cfg) "$@"
    fi
    [ $? -ne 0 ] && return 1
    return 0
}

function mmc() {
    if [ "$1" = "fix" ]; then
        mm "${@:2}" -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-fix;-fix-errors"
    else
        mm "$@" -DCMAKE_CXX_CLANG_TIDY="clang-tidy"
    fi
}

function mmmc() {
    if [ "$1" = "fix" ]; then
        mmm "${@:2}" -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-fix;-fix-errors"
    else
        mmm "$@" -DCMAKE_CXX_CLANG_TIDY="clang-tidy"
    fi
}

function llcfg() {
    local _project_dir="$(pwd)"
    _mmm_ll_cfg "$_project_dir"
    [ $? -ne 0 ] && echo -e "\033[1;31m$_mm_ico_fail Error: Can not find cfg [$_project_dir]!\033[0m" && return 1
    local _print_result=$(echo -e "$__cache_mmm_cfg" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    local _print_result=$(echo -e "$_print_result" | sed -E 's/[[:space:]]+/\ \\\n\ \ \ /g')
    echo "mm $_print_result"
    return 0
}

function rdb() {
    if [ "$VKIT_PLATFORM" = "qnx-aarch64" ]; then
        ntoaarch64-gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    elif [ "$VKIT_PLATFORM" = "qnx-x86_64" ]; then
        ntox86_64-gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    elif [ "$VKIT_PLATFORM" != "linux-aarch64" ] && [ "$VKIT_PLATFORM" != "linux-x86_64" ]; then
        gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    fi
}

function _import_repo() {
    local _repo="$1"
    local _shallow="$2"
    if [ -f "$_repo" ] && [ -s "$_repo" ]; then
        "$VKIT_VCS_TOOL" import --input "$_repo" --workers "$VKIT_BUILD_CPU_CORE" $_shallow
    fi
}

function build() {
    if [ "$1" = "thirdparty" ] || [ "$1" = "3rd" ]; then
        mm_thirdparty "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "vendor" ] || [ "$1" = "ven" ]; then
        mm_vendor "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "middleware" ] || [ "$1" = "mid" ]; then
        mm_middleware "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "app" ]; then
        mm_app "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "deploy" ]; then
        "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "deploy_sdk" ] || [ "$1" = "sdk" ]; then
        VKIT_PACKUP_SDK=1 "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
        [ $? -ne 0 ] && return 1
    else
        echo -e "\033[1;31m$_mm_ico_fail Error: Unsupported command!\033[0m"
        return 1
    fi
    return 0
}

if [ "$0" != "$BASH_SOURCE" ]; then
    echo -e -n "\033[2J\033[H"
    echo -e "Setup VKIT build environment..."
    echo -e -n "\033[1;32m"
    echo -e "╔═════════════════════════════════════╗"
    echo -e "║  _    __   __      _           __   ║"
    echo -e "║ | |  / /  / /     (_) ____    / /__ ║"
    echo -e "║ | | / /  / /     / / / __ \\  / //_/ ║"
    echo -e "║ | |/ /  / /___  / / / / / / / ,<    ║"
    echo -e "║ |___/  /_____/ /_/ /_/ /_/ /_/|_|   ║"
    echo -e "║                                     ║"
    echo -e "╚═════════════════════════════════════╝"
    echo -e -n "\033[0m"
    echo -e "Platform: $VKIT_PLATFORM"
    echo -e "Device: $VKIT_DEVICE"
    echo -e ""
    echo -e "Note: You can run the following command:"
    echo -e "      mmm            Build a component with config compile flags"
    echo -e "      mm             [ '-D{CMAKE_FLAG}' | clean ]   \"Build a component\""
    echo -e "      mm_thirdparty  [ '-D{CMAKE_FLAG}' | clean ]   \"Build thirdparty\""
    echo -e "      mm_vendor      [ '-D{CMAKE_FLAG}' | clean ]   \"Build vendor\""
    echo -e "      mm_middleware  [ '-D{CMAKE_FLAG}' | clean ]   \"Build middleware\""
    echo -e "      mm_app         [ '-D{CMAKE_FLAG}' | clean ]   \"Build app\""
    echo -e "      mm_all         [ '-D{CMAKE_FLAG}' | clean ]   \"Build ALL\""
    echo -e ""
    if [ "$VKIT_PLATFORM" = "$VKIT_HOST_PLATFORM" ]; then
        [[ "$PATH" != *"$VKIT_PREBUILT_DIR/bin"* ]] && export PATH="$VKIT_PREBUILT_DIR/bin:$PATH"
        [[ "$LD_LIBRARY_PATH" != *"$VKIT_PREBUILT_DIR/lib"* ]] && export LD_LIBRARY_PATH="$VKIT_PREBUILT_DIR/lib:$LD_LIBRARY_PATH"
        if [ -n "$BASH" ]; then
            if [ -f "$VLINK_COMPLETIONS" ]; then
                . "$VLINK_COMPLETIONS"
            fi
            if [ -d "$VKIT_CODE_COMPLETE_DIR" ]; then
                for code_script in "$VKIT_CODE_COMPLETE_DIR"/*.sh; do
                    [ -f "$code_script" ] && . "$code_script"
                done
            fi
        fi
    fi
    return 0
fi

if [ "$1" = "import" ]; then
    if [ -z "$2" ]; then
        echo -e "\033[1;31m$_mm_ico_fail Error: 'import' requires a repo set name (e.g. 'make import dev')!\033[0m"
        exit 1
    fi
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33m$_mm_ico_warn Warning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/$2" ]; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find repo [$VKIT_ROOT_DIR/repos/$2]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/$2/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/$2/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/$2/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/app.repos"
    exit 0
elif [ "$1" = "import_dev" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33m$_mm_ico_warn Warning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/dev" ]; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find repo [$VKIT_ROOT_DIR/repos/dev]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/dev/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/dev/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/dev/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/app.repos"
    exit 0
elif [ "$1" = "import_full" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33m$_mm_ico_warn Warning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/full" ]; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find repo [$VKIT_ROOT_DIR/repos/full]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/full/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/full/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/full/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/app.repos"
    exit 0
elif [ "$1" = "pull" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33m$_mm_ico_warn Warning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1;31m$_mm_ico_fail Error: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _pull_list=("$VKIT_ROOT_DIR")
    [ -d "$VKIT_ROOT_DIR/setup" ] && _pull_list+=("$VKIT_ROOT_DIR/setup")
    [ -d "$VKIT_ROOT_DIR/prebuilt" ] && _pull_list+=("$VKIT_ROOT_DIR/prebuilt")
    [ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && _pull_list+=("$VKIT_ROOT_DIR/prebuilt-private")
    [ -d "$VKIT_ROOT_DIR/thirdparty" ] && _pull_list+=("$VKIT_ROOT_DIR/thirdparty")
    [ -d "$VKIT_ROOT_DIR/vendor" ] && _pull_list+=("$VKIT_ROOT_DIR/vendor")
    [ -d "$VKIT_ROOT_DIR/middleware" ] && _pull_list+=("$VKIT_ROOT_DIR/middleware")
    [ -d "$VKIT_ROOT_DIR/app" ] && _pull_list+=("$VKIT_ROOT_DIR/app")
    "$VKIT_VCS_TOOL" pull "${_pull_list[@]}" --workers "$VKIT_BUILD_CPU_CORE"
    unset _pull_list
    exit 0
elif [ "$1" = "install" ]; then
    mm_all
    exit $?
elif [ "$1" = "clean" ]; then
    mm_all clean
    exit $?
elif [ "$1" = "rclean" ]; then
    [ -d "$VKIT_BUILD_DIR" ] && rm -rf "$VKIT_BUILD_DIR"/*
    [ -d "$VKIT_PACKUP_DIR" ] && rm -rf "$VKIT_PACKUP_DIR"/*
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz"
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz"
    if [ -d "$VKIT_ROOT_DIR/prebuilt/.git" ]; then
        if [ -d "$VKIT_PREBUILT_DIR" ]; then
            git -C "$VKIT_PREBUILT_DIR" clean -fdx .
            git -C "$VKIT_PREBUILT_DIR" checkout HEAD .
        elif [ -d "$VKIT_ROOT_DIR/prebuilt" ]; then
            git -C "$VKIT_ROOT_DIR/prebuilt" checkout HEAD "$VKIT_DEVICE_PLATFORM"
        fi
    else
        [ -d "$VKIT_PREBUILT_DIR" ] && rm -rf "$VKIT_PREBUILT_DIR"/*
    fi
    if [ -d "$VKIT_ROOT_DIR/prebuilt-private/.git" ]; then
        if [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ]; then
            git -C "$VKIT_PREBUILT_PRIVATE_DIR" clean -fdx .
            git -C "$VKIT_PREBUILT_PRIVATE_DIR" checkout HEAD .
        elif [ -d "$VKIT_ROOT_DIR/prebuilt-private" ]; then
            git -C "$VKIT_ROOT_DIR/prebuilt-private" checkout HEAD "$VKIT_DEVICE_PLATFORM"
        fi
    else
        [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ] && rm -rf "$VKIT_PREBUILT_PRIVATE_DIR"/*
    fi
    exit 0
elif [ "$1" = "dclean" ]; then
    [ -d "$VKIT_PREBUILT_DIR" ] && rm -rf "$VKIT_PREBUILT_DIR"/*
    [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ] && rm -rf "$VKIT_PREBUILT_PRIVATE_DIR"/*
    [ -d "$VKIT_BUILD_DIR" ] && rm -rf "$VKIT_BUILD_DIR"/*
    [ -d "$VKIT_PACKUP_DIR" ] && rm -rf "$VKIT_PACKUP_DIR"/*
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz"
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz"
    exit 0
elif [ "$1" = "aclean" ]; then
    [ -d "$VKIT_ROOT_DIR/build" ] && rm -rf "$VKIT_ROOT_DIR/build"/*
    [ -d "$VKIT_ROOT_DIR/prebuilt" ] && rm -rf "$VKIT_ROOT_DIR/prebuilt"/*
    [ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && rm -rf "$VKIT_ROOT_DIR/prebuilt-private"/*
    [ -d "$VKIT_ROOT_DIR/packup" ] && rm -rf "$VKIT_ROOT_DIR/packup"/*
    exit 0
elif [ "$1" = "deploy" ]; then
    "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
    exit $?
elif [ "$1" = "deploy_sdk" ]; then
    VKIT_PACKUP_SDK=1 "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
    exit $?
else
    echo -e "Usage:"
    echo -e "        source vkit-setup.sh"
    echo -e "        vkit-setup.sh import [component]"
    echo -e "        vkit-setup.sh import_dev"
    echo -e "        vkit-setup.sh import_full"
    echo -e "        vkit-setup.sh pull"
    echo -e "        vkit-setup.sh install"
    echo -e "        vkit-setup.sh clean"
    echo -e "        vkit-setup.sh rclean"
    echo -e "        vkit-setup.sh dclean"
    echo -e "        vkit-setup.sh aclean"
    echo -e "        vkit-setup.sh deploy"
    echo -e "        vkit-setup.sh deploy_sdk"
    exit 0
fi
