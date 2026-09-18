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
GOLANG126_TEST="$GOLANG126_DIR/test.sh"
GOLANG126_TEST_VERSION="$GOLANG126_DIR/test-version.sh"

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
   echo " " 
   echo "---- GOLANG126_MAKEFILE srart ----"&& cat "$GOLANG126_MAKEFILE"
   echo "---- GOLANG126_MAKEFILE end ----"
 cat > "$GOLANG126_TEST" << 'GOLANG126_EOF'
#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-only

case "$1" in
	golang*doc|golang*misc|golang*src|golang*tests) exit ;;
esac

cat <<'EOF' > hello.go
package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}

EOF

go run hello.go
rm hello.go
GOLANG126_EOF

 echo " " && echo "golang126_test has been restored!"
 echo " "  
 echo "---- GOLANG126_TEST start ----"
 echo " " && cat "$GOLANG126_TEST"
 echo "---- GOLANG126_TEST end ----"

 cat > "$GOLANG126_TEST_VERSION" << 'GOLANG126_EOF'
#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-only

# shellcheck shell=busybox

case "$PKG_NAME" in
golang?.??-doc|\
golang?.??-misc|\
golang?.??-src|\
golang?.??-tests)
	exit 0
	;;

golang?.??)
	go version | grep -F " go$PKG_VERSION "
	;;

*)
	echo "Untested package: $PKG_NAME" >&2
	exit 1
	;;
esac
GOLANG126_EOF

  echo " " && echo "golang126_test_version has been restored!" 
  echo " "  
  echo "---- GOLANG126_TEST_VERSION start ----"&&  cat "$GOLANG126_TEST_VERSION"
  echo "---- GOLANG126_TEST_VERSION end ----"
else
    echo " "
    echo "golang1.26 Makefile already exists, skipping."
fi


# ============================================
# UPX 二进制压缩工具函数
# ============================================
STAGING_DIR_HOST="${GITHUB_WORKSPACE}/wrt/staging_dir/host"

# ============================================
# 确保 upx 包源存在于构建系统中
# 优先通过 feeds 添加，失败则直接克隆到 package 目录
# ============================================
ensure_upx_source() {
    # 如果 upx/host 已经编译过，直接返回
    if [ -x "$STAGING_DIR_HOST/bin/upx" ]; then
        echo "✔ UPX 已就绪: $STAGING_DIR_HOST/bin/upx"
        return 0
    fi

    echo "正在准备 UPX 包源..."

    # 方式1：尝试通过 feeds 添加
    local FEEDS_CONF="$GITHUB_WORKSPACE/wrt/feeds.conf"
    local FEEDS_DEFAULT="$GITHUB_WORKSPACE/wrt/feeds.conf.default"
    local UPX_FEED_LINE='src-git upx https://github.com/selfcan/openwrt-upx.git'
    local feeds_target=""

    if [ -f "$FEEDS_CONF" ]; then
        feeds_target="$FEEDS_CONF"
    elif [ -f "$FEEDS_DEFAULT" ]; then
        feeds_target="$FEEDS_DEFAULT"
    fi

    if [ -n "$feeds_target" ]; then
        if ! grep -q "selfcan/openwrt-upx" "$feeds_target" 2>/dev/null; then
            echo "$UPX_FEED_LINE" >> "$feeds_target"
            echo "已添加 upx feed 到 $feeds_target"
        fi
        if (cd "$GITHUB_WORKSPACE/wrt" && \
            ./scripts/feeds update upx 2>/dev/null && \
            ./scripts/feeds install -a -p upx 2>/dev/null); then
            echo "✔ UPX feed 安装成功"
            return 0
        fi
        echo "⚠ feeds 方式安装 UPX 失败，回退到直接克隆"
    fi

    # 方式2：直接克隆到 package 目录
    local upx_pkg_dir="$GITHUB_WORKSPACE/wrt/package/openwrt-upx"
    if [ ! -d "$upx_pkg_dir/upx" ]; then
        echo "正在克隆 openwrt-upx 到 package 目录..."
        rm -rf "$upx_pkg_dir"
        git clone --depth 1 https://github.com/selfcan/openwrt-upx.git "$upx_pkg_dir" || {
            echo "❌ 克隆 openwrt-upx 失败" >&2
            return 1
        }
    fi
    echo "✔ UPX 包源已就位，将在后续 make 时自动编译"
	echo " " && cat $feeds_target
    return 0
}

# ============================================
# 为指定 Makefile 添加 upx/host 依赖并注入压缩命令
# 用法: add_upx_compress <Makefile> <二进制名> <安装目录>
# 例:   add_upx_compress "$TS_FILE" "tailscaled" "usr/sbin"
# ============================================
add_upx_compress() {
    local makefile="$1"
    local binary="$2"
    local install_dir="${3:-usr/bin}"

    # 去掉可能的前导斜杠
    install_dir="${install_dir#/}"

    if [ ! -f "$makefile" ]; then
        echo "❌ Makefile 不存在: $makefile" >&2
        return 1
    fi

    # 1. 确保 UPX 源存在（不强制编译）
    ensure_upx_source || return 1

    # 2. 添加 upx/host 到 PKG_BUILD_DEPENDS（幂等）
    if ! grep -q "upx/host" "$makefile" 2>/dev/null; then
        if grep -q "^PKG_BUILD_DEPENDS" "$makefile"; then
            sed -i '/^PKG_BUILD_DEPENDS/ s/$/ upx\/host/' "$makefile"
        else
            sed -i '/^PKG_BUILD_PARALLEL/i PKG_BUILD_DEPENDS:=upx/host' "$makefile"
        fi
        echo "✔ 已添加 upx/host 依赖: $makefile"
    fi

    # 3. 检查是否已注入过该二进制的压缩命令（幂等）
    if grep -q "UPX compressing ${binary}" "$makefile" 2>/dev/null; then
        echo "ℹ UPX 压缩已存在于: $makefile ($binary)"
        return 0
    fi

    # 4. 确认存在 install 段
    if ! grep -q "^define Package/.*/install" "$makefile"; then
        echo "⚠ $makefile 中没有找到 define Package/.../install 段，跳过 $binary" >&2
        return 1
    fi

    # 5. 生成压缩代码块并注入
    local tmp_insert
    tmp_insert=$(mktemp)
    cat > "$tmp_insert" << EOF
	if echo "\$(ARCH)" | grep -qE '^(mips64|riscv64|loongarch64)'; then \\
		echo "==> UPX skipped for \$(ARCH) (${binary})"; \\
	elif [ -x "\$(STAGING_DIR_HOST)/bin/upx" ]; then \\
		if ! \$(STAGING_DIR_HOST)/bin/upx -t \$(1)/${install_dir}/${binary} >/dev/null 2>&1; then \\
			echo "==> UPX compressing ${binary} on \$(ARCH)"; \\
			\$(STAGING_DIR_HOST)/bin/upx --best --lzma \$(1)/${install_dir}/${binary} || true; \\
		else \\
			echo "==> ${binary} already compressed on \$(ARCH)"; \\
		fi; \\
	else \\
		echo "==> UPX not found, skipping compression for ${binary}"; \\
	fi
EOF

    sed -i "/^define Package\/.*\/install/,/^endef/ {
        /^endef/ r $tmp_insert
    }" "$makefile"

    rm -f "$tmp_insert"

    if grep -q "UPX compressing ${binary}" "$makefile"; then
        echo "✔ 已为 $binary 注入 UPX 压缩: $makefile"
        return 0
    else
        echo "❌ 注入 UPX 压缩失败: $makefile" >&2
        return 1
    fi
}

#修复TailScale配置文件冲突
FEEDS_PACKAGES="$PKG_PATH/../feeds/packages"
TS_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)"
if [ -f "$TS_FILE" ]; then
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=1.94.2" $TS_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=c45975beb4cb7bab8047cfba77ec8b170570d184f3c806258844f3e49c60d7aa" $TS_FILE
	echo " " && echo "tailscale 使用1.94.2版本"	
    sed -i 's|PKG_BUILD_DEPENDS:=golang/host|PKG_BUILD_DEPENDS:=golang1.26/host|' $TS_FILE
    echo " " &&echo "tailscale 已指定使用 golang1.26"
	echo " "
	if sed -i '/\/files/d' "$TS_FILE"; then
		echo "tailscale has been fixed!"
	else
		echo "tailscale fix failed; continuing!"
	fi
    add_upx_compress "$TS_FILE" "tailscaled" "usr/sbin"
    echo "---- tailscale_Makefile内容 start ----"
    cat $TS_FILE
    echo "---- tailscale_Makefile内容 end ----"
    echo " "
fi

#升级Xray
XRAY_FILE="$(find "$FEEDS_PACKAGES" -maxdepth 3 -type f -wholename "*/xray-core/Makefile" -print -quit 2>/dev/null)"
if [ -f "$XRAY_FILE" ]; then
	echo " "
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=26.9.9" $Xray_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=efb871a981690688191433a76beef7afdab6750d53cc1775cf8e9e995730ef22" $Xray_FILE
	cd $PKG_PATH && echo "xray-core version has update to 26.9.9!"
    add_upx_compress "$XRAY_FILE" "xray" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- xray-core_Makefile内容 start ----"
    cat $XRAY_FILE
    echo "---- xray-core_Makefile内容 end ----"
	echo " "
fi

#压缩mihomo
MIHOMO_META_FILE=$(find "$PKG_PATH" -maxdepth 5 -type f -wholename "*/mihomo-meta/Makefile")
if [ -f "$MIHOMO_META_FILE" ]; then
	echo " "
    add_upx_compress "$MIHOMO_META_FILE" "mihomo" "/usr/libexec"
	echo "mihomo 将被压缩"
	echo " "
    echo "---- mihomo-meta_Makefile内容 start ----"
    cat $MIHOMO_META_FILE
    echo "---- mihomo-meta_Makefile内容 end ----"
	echo " "
fi


#压缩sing-box
SING_BOX_FILE=$(find "$PKG_PATH" -maxdepth 3 -type f -wholename "*/sing-box/Makefile")
if [ -f "$SING_BOX_FILE" ]; then
	echo " "
    add_upx_compress "$SING_BOX_FILE" "sing-box" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- sing-box_Makefile内容 start ----"
    cat $SING_BOX_FILE
    echo "---- sing-box_Makefile内容 end ----"
	echo " "
fi

# ============================================
# 修改 package/luci-app-nikki/Makefile：
#   在 LUCI_DEPENDS 行后插入 postinst/postrm 钩子，
#   安装/卸载时自动为 mihomo(nikki) 创建/清理软链接：
#     /etc/nikki/run/GeoSite.dat -> /usr/share/v2ray/geosite.dat
#     /etc/nikki/run/GeoIP.dat   -> /usr/share/v2ray/geoip.dat
# ============================================
NIKKI_MAKEFILE="$(find "$PKG_PATH" -maxdepth 4 -type f -path '*/luci-app-nikki/Makefile' -print -quit 2>/dev/null)"

if [ -n "$NIKKI_MAKEFILE" ] && [ -f "$NIKKI_MAKEFILE" ]; then
    echo " "
    echo "Patching $NIKKI_MAKEFILE ..."

    if grep -q 'Package/luci-app-nikki/postinst' "$NIKKI_MAKEFILE"; then
        echo "luci-app-nikki Makefile already has postinst hook, skipping."
    else
        NIKKI_HOOK_TMP="$(mktemp)"

        cat > "$NIKKI_HOOK_TMP" << 'NIKKI_HOOK_EOF'
define Package/luci-app-nikki/postinst
#!/bin/sh
[ -f "$${IPKG_INSTROOT}/usr/share/v2ray/geosite.dat" ] && {
	mkdir -p "$${IPKG_INSTROOT}/etc/nikki/run"
	ln -sf /usr/share/v2ray/geosite.dat "$${IPKG_INSTROOT}/etc/nikki/run/GeoSite.dat"
}
[ -f "$${IPKG_INSTROOT}/usr/share/v2ray/geoip.dat" ] && {
	mkdir -p "$${IPKG_INSTROOT}/etc/nikki/run"
	ln -sf /usr/share/v2ray/geoip.dat "$${IPKG_INSTROOT}/etc/nikki/run/GeoIP.dat"
}
exit 0
endef

define Package/luci-app-nikki/postrm
#!/bin/sh
[ -L "$${IPKG_INSTROOT}/etc/nikki/run/GeoSite.dat" ] && rm -f "$${IPKG_INSTROOT}/etc/nikki/run/GeoSite.dat"
[ -L "$${IPKG_INSTROOT}/etc/nikki/run/GeoIP.dat" ] && rm -f "$${IPKG_INSTROOT}/etc/nikki/run/GeoIP.dat"
exit 0
endef

NIKKI_HOOK_EOF

        # 在 LUCI_DEPENDS 行之后追加钩子内容（r 命令会追加到匹配行后面）
        if sed -i "/^LUCI_DEPENDS:=/r $NIKKI_HOOK_TMP" "$NIKKI_MAKEFILE"; then
            echo "luci-app-nikki Makefile has been patched!"
			echo " "
            echo "---- NIKKI_MAKEFILE start ----"
            cat "$NIKKI_MAKEFILE"
            echo "---- NIKKI_MAKEFILE end ----"
			echo " " 
        else
            echo "luci-app-nikki patch failed; continuing!"
        fi

        rm -f "$NIKKI_HOOK_TMP"
    fi
else
    echo " "
    echo "luci-app-nikki Makefile not found, skipping."
fi

# ============================================
# 修改 net/v2ray-geodata/Makefile：
#   GeoIP   -> MetaCubeX geoip-lite.dat（自动获取 sha256）
#   GeoSite -> MetaCubeX geosite.dat    （自动获取 sha256）
#   Iran    -> 保持原样
# ============================================
V2RAY_GEODATA_MAKEFILE="$(find "$PKG_PATH" "$PKG_PATH/../feeds/packages" \
    -maxdepth 6 -type f -path '*/v2ray-geodata/Makefile' -print -quit 2>/dev/null)"

if [ -n "$V2RAY_GEODATA_MAKEFILE" ] && [ -f "$V2RAY_GEODATA_MAKEFILE" ]; then
    echo " "
    echo "Patching $V2RAY_GEODATA_MAKEFILE ..."

    if grep -q 'GEOIP_URL_FILE:=geoip-lite.dat' "$V2RAY_GEODATA_MAKEFILE"; then
        echo "v2ray-geodata Makefile already patched, skipping."
    else
        V2RAY_NEW_BLOCK_TMP="$(mktemp)"

        cat > "$V2RAY_NEW_BLOCK_TMP" << 'V2RAY_BLOCK_EOF'
# ---- GeoIP：使用 MetaCubeX geoip-lite.dat，并自动获取 sha256 ----
GEOIP_VER:=$(shell date -u +%Y%m%d%H%M)
GEOIP_URL:=https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/
GEOIP_URL_FILE:=geoip-lite.dat
GEOIP_HASH:=$(shell (curl -fsSL $(GEOIP_URL)$(GEOIP_URL_FILE).sha256sum 2>/dev/null || wget -qO- $(GEOIP_URL)$(GEOIP_URL_FILE).sha256sum 2>/dev/null) | awk '{print $$1}')
GEOIP_FILE:=geoip-lite.dat.$(GEOIP_VER).$(GEOIP_HASH)
define Download/geoip
  URL:=$(GEOIP_URL)
  URL_FILE:=$(GEOIP_URL_FILE)
  FILE:=$(GEOIP_FILE)
  HASH:=$(GEOIP_HASH)
endef

# ---- GeoSite：使用 MetaCubeX geosite.dat，并自动获取 sha256 ----
GEOSITE_VER:=$(shell date -u +%Y%m%d%H%M%S)
GEOSITE_URL:=https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/
GEOSITE_URL_FILE:=geosite.dat
GEOSITE_HASH:=$(shell (curl -fsSL $(GEOSITE_URL)$(GEOSITE_URL_FILE).sha256sum 2>/dev/null || wget -qO- $(GEOSITE_URL)$(GEOSITE_URL_FILE).sha256sum 2>/dev/null) | awk '{print $$1}')
GEOSITE_FILE:=geosite.dat.$(GEOSITE_VER).$(GEOSITE_HASH)
define Download/geosite
  URL:=$(GEOSITE_URL)
  URL_FILE:=$(GEOSITE_URL_FILE)
  FILE:=$(GEOSITE_FILE)
  HASH:=$(GEOSITE_HASH)
endef

V2RAY_BLOCK_EOF

        # 1) 删除从 GEOIP_VER 行到 GEOSITE_IRAN_VER 行之前的所有行（保留 GEOSITE_IRAN_VER 行）
        sed -i '/^GEOIP_VER:=/,/^GEOSITE_IRAN_VER:=/{/^GEOSITE_IRAN_VER:=/!d;}' "$V2RAY_GEODATA_MAKEFILE"

        # 2) 在 include $(INCLUDE_DIR)/package.mk 行之后插入新块
        #    删除后，该行之后紧接着就是 GEOSITE_IRAN_VER，所以效果等于在 GEOSITE_IRAN_VER 之前插入
        sed -i "/^include \$(INCLUDE_DIR)\/package.mk/r $V2RAY_NEW_BLOCK_TMP" "$V2RAY_GEODATA_MAKEFILE"

        rm -f "$V2RAY_NEW_BLOCK_TMP"

        echo "v2ray-geodata Makefile has been patched!"
        echo "   "
		echo "---- V2RAY_GEODATA_MAKEFILE start ----"
        cat "$V2RAY_GEODATA_MAKEFILE"
        echo "---- V2RAY_GEODATA_MAKEFILE end ----"
    fi
else
    echo " "
    echo "v2ray-geodata Makefile not found, skipping."
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
