#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package"

#预置HomeProxy数据，隔离临时变量和清理信号，避免影响后续修复
hp_preset_resources() (
	local HP_DIR="$1"
	RESOURCES_DIR="$HP_DIR/root/etc/homeproxy/resources"
	DASHBOARD_DIR="$HP_DIR/root/etc/homeproxy/dashboard"

	GEOIP_SOURCE="${GEOIP_SOURCE:-https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs}"
	GEOIP_VERSION_URL="${GEOIP_VERSION_URL:-https://github.com/SagerNet/sing-geoip/releases/latest}"
	GEOSITE_SOURCE="${GEOSITE_SOURCE:-https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set-unstable/geosite-cn.srs}"
	GEOSITE_VERSION_URL="${GEOSITE_VERSION_URL:-https://github.com/SagerNet/sing-geosite/releases/latest}"
	DASHBOARD_SOURCE="${DASHBOARD_SOURCE:-https://codeload.github.com/SagerNet/sing-box-dashboard/zip/refs/heads/gh-pages}"
	DASHBOARD_VERSION_URL="${DASHBOARD_VERSION_URL:-https://github.com/SagerNet/sing-box-dashboard/commits/gh-pages.atom}"
	USER_AGENT="${USER_AGENT:-HomeProxy resource preset}"

	TMP_DIR="$(mktemp -d)" || {
		echo "Failed to prepare temporary resource directory." >&2
		return 1
	}
	DASHBOARD_STAGE="${DASHBOARD_DIR}.new.$$"
	trap 'rm -rf -- "$TMP_DIR" "$DASHBOARD_STAGE" "$RESOURCES_DIR/.update.$$.tmp"' EXIT
	trap 'exit 130' INT
	trap 'exit 143' TERM

	warn() {
		echo "WARNING: $*" >&2
	}

	fetch_release_version() {
		local effective_url version
		effective_url="$(curl -fsSL --compressed --retry 3 --retry-all-errors \
			--retry-delay 1 --connect-timeout 10 --max-time 30 \
			-A "$USER_AGENT" -o /dev/null -w '%{url_effective}' "$1")" || return 1
		version="${effective_url##*/}"
		case "$version" in
			''|*[!0-9]*) return 1 ;;
		esac
		printf '%s\n' "$version"
	}

	fetch_dashboard_version() {
		local feed version
		feed="$(curl -fsSL --compressed --retry 3 --retry-all-errors \
			--retry-delay 1 --connect-timeout 10 --max-time 30 \
			-A "$USER_AGENT" "$DASHBOARD_VERSION_URL")" || return 1
		version="$(printf '%s\n' "$feed" | awk -F '[<>]' '
			/<updated>/ {
				version = $3
				gsub(/[-:TZ]/, "", version)
				print version
				exit
			}
		')"
		case "$version" in
			??????????????) case "$version" in *[!0-9]*) return 1 ;; esac ;;
			*) return 1 ;;
		esac
		printf '%s\n' "$version"
	}

	download() {
		curl -fsSL --compressed --retry 3 --retry-all-errors --retry-delay 1 \
			--connect-timeout 10 --max-time 60 -A "$USER_AGENT" -o "$2" "$1" &&
			test -s "$2"
	}

	validate_rule_set() {
		# Download checks cover transfer errors; only check the SRS envelope here.
		[[ "$(head -c 3 "$1" 2>/dev/null)" == SRS && $(wc -c < "$1") -gt 4 ]]
	}

	versioned_url() {
		case "$1" in
		http://*|https://*) printf '%s?v=%s' "$1" "$2" ;;
		*) printf '%s' "$1" ;;
		esac
	}

	install_rule_set() {
		local source_file="$1" version="$2" resource="$3"
		local stage_dir="$RESOURCES_DIR/.update.$$.tmp"

		mkdir -p "$stage_dir" &&
			cp "$source_file" "$stage_dir/$resource.srs" &&
			printf '%s\n' "$version" > "$stage_dir/$resource.ver" &&
			chmod 0644 "$stage_dir/$resource.srs" "$stage_dir/$resource.ver" &&
			mv -f "$stage_dir/$resource.srs" "$RESOURCES_DIR/$resource.srs" &&
			mv -f "$stage_dir/$resource.ver" "$RESOURCES_DIR/$resource.ver"
	}

	update_rule_set() {
		local resource="$1" source_url="$2" version_url="$3"
		local version old_version

		version="$(fetch_release_version "$version_url")" || return 1
		old_version="$(cat "$RESOURCES_DIR/$resource.ver" 2>/dev/null)"
		if [ "$old_version" = "$version" ] && validate_rule_set "$RESOURCES_DIR/$resource.srs"; then
			echo "HomeProxy resources: $resource $version (current)"
			return 0
		fi
		download "$(versioned_url "$source_url" "$version")" "$TMP_DIR/$resource.srs" &&
			validate_rule_set "$TMP_DIR/$resource.srs" &&
			install_rule_set "$TMP_DIR/$resource.srs" "$version" "$resource" || return 1
		echo "HomeProxy resources: $resource $version"
	}

	update_dashboard() {
		local version old_version index source_dir=""
		local backup_dir="${DASHBOARD_DIR}.old.$$"

		version="$(fetch_dashboard_version)" || return 1
		old_version="$(cat "$DASHBOARD_DIR/dashboard.ver" 2>/dev/null)"
		if [ "$old_version" = "$version" ] && [ -s "$DASHBOARD_DIR/index.html" ]; then
			echo "HomeProxy dashboard: $version (current)"
			return 0
		fi
		download "$(versioned_url "$DASHBOARD_SOURCE" "$version")" "$TMP_DIR/dashboard.zip" &&
			unzip -q "$TMP_DIR/dashboard.zip" -d "$TMP_DIR/dashboard" || return 1
		for index in "$TMP_DIR/dashboard/index.html" "$TMP_DIR"/dashboard/*/index.html; do
			if [ -s "$index" ]; then
				source_dir="${index%/index.html}"
				break
			fi
		done
		[ -n "$source_dir" ] || return 1
		mkdir -p "$DASHBOARD_STAGE" &&
			cp -a "$source_dir/." "$DASHBOARD_STAGE/" &&
			rm -f "$DASHBOARD_STAGE/.etag" &&
			printf '%s\n' "$version" > "$DASHBOARD_STAGE/dashboard.ver" &&
			chmod -R a+rX "$DASHBOARD_STAGE" || return 1
		mv "$DASHBOARD_DIR" "$backup_dir" || return 1
		if ! mv "$DASHBOARD_STAGE" "$DASHBOARD_DIR"; then
			mv "$backup_dir" "$DASHBOARD_DIR" || warn "Unable to restore the dashboard; backup retained at $backup_dir."
			return 1
		fi
		rm -rf "$backup_dir"
		echo "HomeProxy dashboard: $version"
	}

	mkdir -p "$RESOURCES_DIR" "$DASHBOARD_DIR" || return 1
	update_failed=0
	if ! update_rule_set geoip_cn "$GEOIP_SOURCE" "$GEOIP_VERSION_URL"; then
		warn "Failed to update HomeProxy geoip resource; continuing."
		update_failed=1
	fi
	if ! update_rule_set geosite_cn "$GEOSITE_SOURCE" "$GEOSITE_VERSION_URL"; then
		warn "Failed to update HomeProxy geosite; continuing."
		update_failed=1
	fi
	if ! update_dashboard; then
		warn "Failed to update HomeProxy dashboard; continuing."
		update_failed=1
	fi

	return "$update_failed"
)

HP_DIR="$(find "$PKG_PATH" -maxdepth 3 -type d -iname '*homeproxy*' -print -quit 2>/dev/null)"
if [ -n "$HP_DIR" ]; then
	echo " "
	if hp_preset_resources "$HP_DIR"; then
		echo "homeproxy data has been updated!"
	else
		echo "homeproxy resource preset completed with errors; continuing!"
	fi
fi

#修改argon主题字体和颜色
if [ -d "$PKG_PATH/luci-theme-argon" ]; then
	echo " "
	if sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" \
		"$PKG_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"; then
		echo "theme-argon has been fixed!"
	else
		echo "theme-argon fix failed; continuing!"
	fi
fi

#修改aurora菜单式样
if [ -d "$PKG_PATH/luci-app-aurora-config" ]; then
	echo " "
	if find "$PKG_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec \
		sed -i "s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +; then
		echo "theme-aurora has been fixed!"
	else
		echo "theme-aurora fix failed; continuing!"
	fi
fi

#修改mini-diskmanager菜单位置
if [ -d "$PKG_PATH/luci-app-mini-diskmanager" ]; then
	echo " "
	if sed -i "s/services/system/g" \
		"$PKG_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"; then
		echo "mini-diskmanager has been fixed!"
	else
		echo "mini-diskmanager fix failed; continuing!"
	fi
fi

# ============================================
# 恢复 golang1.26 包 (用于编译 Tailscale 1.94.2)
# ============================================
GOLANG126_DIR="$PKG_PATH/../feeds/packages/lang/golang/golang1.26"
GOLANG126_MAKEFILE="$GOLANG126_DIR/Makefile"

if [ ! -f "$GOLANG126_MAKEFILE" ]; then
    echo " "
    echo "golang1.26 Makefile not found, restoring..."
    mkdir -p "$GOLANG126_DIR"
    cat > "$GOLANG126_MAKEFILE" << 'GOLANG126_EOF'
#
# Copyright (C) 2018-2023 Jeffery To
# Copyright (C) 2025-2026 George Sapkin
#
# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=golang1.26
GO_VERSION_MAJOR_MINOR:=1.26
GO_VERSION_PATCH:=7
GO_VERSION_RC:=
GO_BOOTSTRAP_VERSION:=bootstrap
PKG_HASH:=0ed24eac755105085b89fe9cabc2742b91a0ad7b94b59d3ad364918ebc8956ad

PKG_VERSION:=$(GO_VERSION_MAJOR_MINOR)$(if $(GO_VERSION_RC),.0)$(if $(GO_VERSION_PATCH),.$(GO_VERSION_PATCH))
PKG_FILE_VERSION:=$(GO_VERSION_MAJOR_MINOR)$(if $(GO_VERSION_RC),rc$(GO_VERSION_RC))$(if $(GO_VERSION_PATCH),.$(GO_VERSION_PATCH))
PKG_RELEASE:=1

GO_SOURCE_URLS:=https://go.dev/dl/ \
                https://golang.google.cn/dl/ \
                https://mirrors.nju.edu.cn/golang/ \
                https://mirrors.ustc.edu.cn/golang/

PKG_SOURCE:=go$(PKG_FILE_VERSION).src.tar.gz
PKG_SOURCE_URL:=$(GO_SOURCE_URLS)

PKG_MAINTAINER:=George Sapkin <george@sapk.in>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:golang:go

PKG_BUILD_DEPENDS:=$(PKG_NAME)/host
PKG_BUILD_DIR:=$(BUILD_DIR)/go-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PKG_GO_PREFIX:=/usr
PKG_GO_VERSION_ID:=$(GO_VERSION_MAJOR_MINOR)

HOST_BUILD_DEPENDS:=golang$(if $(filter bootstrap,$(GO_BOOTSTRAP_VERSION)),-)$(GO_BOOTSTRAP_VERSION)/host
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/go-$(PKG_VERSION)
HOST_BUILD_PARALLEL:=1

# From go tool dist list
HOST_GO_VALID_OS_ARCH:= \
  aix/ppc64 \
  android/386 \
  android/amd64 \
  android/arm \
  android/arm64 \
  darwin/amd64 \
  darwin/arm64 \
  dragonfly/amd64 \
  freebsd/386 \
  freebsd/amd64 \
  freebsd/arm \
  freebsd/arm64 \
  illumos/amd64 \
  ios/amd64 \
  ios/arm64 \
  js/wasm \
  linux/386 \
  linux/amd64 \
  linux/arm \
  linux/arm64 \
  linux/loong64 \
  linux/mips \
  linux/mips64 \
  linux/mips64le \
  linux/mipsle \
  linux/ppc64 \
  linux/ppc64le \
  linux/riscv64 \
  linux/s390x \
  netbsd/386 \
  netbsd/amd64 \
  netbsd/arm \
  netbsd/arm64 \
  openbsd/386 \
  openbsd/amd64 \
  openbsd/arm \
  openbsd/arm64 \
  openbsd/ppc64 \
  openbsd/riscv64 \
  plan9/386 \
  plan9/amd64 \
  plan9/arm \
  solaris/amd64 \
  wasip1/wasm \
  windows/386 \
  windows/amd64 \
  windows/arm64

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include ../golang-version.mk

$(eval $(call HostBuild))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-doc))
$(eval $(call BuildPackage,$(PKG_NAME)-misc))
$(eval $(call BuildPackage,$(PKG_NAME)-src))
$(eval $(call BuildPackage,$(PKG_NAME)-tests))
GOLANG126_EOF
    echo "golang1.26 Makefile has been restored!"
    cat "$GOLANG126_MAKEFILE"
else
    echo " "
    echo "golang1.26 Makefile already exists, skipping."
fi

GOLANG_VERSION_MK="$PKG_PATH/../feeds/packages/lang/golang/golang-version.mk"

if [ -f "$GOLANG_VERSION_MK" ]; then
    if ! grep -q "golang1.26" "$GOLANG_VERSION_MK"; then
        sed -i '/^GO_VERSIONED_PKGS:=/ s/$/ golang1.26/' "$GOLANG_VERSION_MK"
        # 如果上面这行不匹配，尝试更通用的添加方式
        # sed -i '/GO_VERSIONED_PKGS/a golang1.26' "$GOLANG_VERSION_MK"
        echo "golang1.26 has been registered in golang-version.mk"
    fi
fi

GOLANG_VALUES_MK="$PKG_PATH/../feeds/packages/lang/golang/golang-values.mk"

if [ -f "$GOLANG_VALUES_MK" ]; then
    # 确保 GO_VERSIONED_PKGS 变量存在并包含 golang1.26
    if ! grep -q "GO_VERSIONED_PKGS" "$GOLANG_VALUES_MK"; then
        echo "GO_VERSIONED_PKGS:=golang1.26" >> "$GOLANG_VALUES_MK"
    fi
fi

update_tailscale() {
    echo " " # 处理 UPX 压缩工具依赖
    echo "正在检查并配置 UPX 压缩工具依赖..."
  # local upx_dir="$PKG_PATH"upx
    local upx_dir="$GITHUB_WORKSPACE/wrt/upx"
    local upx_path="$upx_dir/upx"

    if [ ! -x "$upx_path" ]; then
        mkdir -p "$upx_dir"
        
        # 检查系统全局是否已经安装了 upx
        if ! command -v upx &> /dev/null; then
            echo "系统未安装 upx, 正在尝试通过 apt-get 自动安装..."
            # 这里的 || true 是为了防止网络卡顿时 update 报错导致整个脚本退出
            sudo apt-get update -y || true
            sudo apt-get install -y upx-ucl
        fi
        
        # 找到系统 upx 的绝对路径，并建立 Makefile 需要的软链接
        local sys_upx=$(command -v upx)
        if [ -n "$sys_upx" ]; then
            ln -sf "$sys_upx" "$upx_path"
            echo "✔ 成功创建 UPX 软链接: $sys_upx -> $upx_path"
        else
            echo "❌ 警告: UPX 安装失败或未找到，稍后的编译可能仍然会报错！" >&2
        fi
    else
        echo "✔ UPX 工具已就绪 ($upx_path)"
    fi

    # 使用GuNanOvO/openwrt-tailscale的tailscale 
    local repo_url="https://github.com/Bulatncq65/openwrt-tailscale.git"
    # tailscale 路径
    local target_dir="$GITHUB_WORKSPACE/wrt/feeds/packages/net/tailscale" 
    # 源码在大仓库里的实际相对路径
    local sub_dir="package/tailscale"
    # 设置一个临时克隆目录
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # 1. 如果存在旧的，先删掉
    if [ -d "$target_dir" ]; then
        echo "正在从 $target_dir 删除旧的 tailscale..."
        rm -rf "$target_dir"
    fi

    echo "正在使用稀疏克隆(sparse-checkout)拉取最新版 tailscale..."
    
    # 初始化并拉取仓库的骨架（不下载具体文件，极速）
    rm -rf "$tmp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "$repo_url" "$tmp_dir"; then
        echo "错误：从 $repo_url 拉取仓库骨架失败" >&2
        exit 1
    fi

    # 告诉 Git 我们只需要 package/tailscale 这一个文件夹
    git -C "$tmp_dir" sparse-checkout set "$sub_dir"

    # 将下载好的子文件夹移动到我们真正需要的目标路径
    mv "$tmp_dir/$sub_dir" "$target_dir"
    # 修改 Makefile（删除包含 /builder 的行）
    sed -i 's|$(TOPDIR)/upx/upx|upx|g' "$target_dir/Makefile"   # ← 新增这一行
    #if ! sed -i '/\/builder/d' "$target_dir/Makefile"; then
    #    echo "错误：修改 Makefile 失败" >&2
    #    exit 1
    #fi
    # 清除临时文件夹的残留
    rm -rf "$tmp_dir"
    
    echo "使用GuNanOvO/openwrt-tailscale的tailscale！" 
}

#update_tailscale

Xray_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/xray-core/Makefile")
if [ -f "$Xray_FILE" ]; then
	echo " "
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=26.9.9" $Xray_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=efb871a981690688191433a76beef7afdab6750d53cc1775cf8e9e995730ef22" $Xray_FILE

	cd $PKG_PATH && echo "xray-core version has update to 26.9.9!"
fi

#修复TailScale配置文件冲突
FEEDS_PACKAGES="$PKG_PATH/../feeds/packages"
TS_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)"
if [ -f "$TS_FILE" ]; then
	echo " "
    sed -i 's|PKG_BUILD_DEPENDS:=golang/host|PKG_BUILD_DEPENDS:=golang1.26/host|' "$TS_FILE"
    echo " " &&echo "tailscale 已指定使用 golang1.26"
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=1.94.2" $TS_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=c45975beb4cb7bab8047cfba77ec8b170570d184f3c806258844f3e49c60d7aa" $TS_FILE
	echo " " && echo "tailscale 使用1.94.2版本"	
	if sed -i '/\/files/d' "$TS_FILE"; then
		echo "tailscale has been fixed!"
	    cat $TS_FILE
	else
		echo "tailscale fix failed; continuing!"
	fi
fi

#修复Rust编译失败
RUST_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename '*/rust/Makefile' -print -quit 2>/dev/null)"
if [ -f "$RUST_FILE" ]; then
	echo " "

	if sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"; then
		echo "rust has been fixed!"
	else
		echo "rust fix failed; continuing!"
	fi
fi
