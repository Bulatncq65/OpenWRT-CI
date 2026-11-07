#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

# ============================================
# 恢复 golang1.26 包 (用于编译 Tailscale 1.94.2)
# ============================================
GOLANG126_DIR="$FEEDS_PATH/packages/lang/golang/golang1.26"
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
./scripts/feeds update -i packages
./scripts/feeds install golang1.26

#GOLANG_VERSION="$FEEDS_PATH/packages/lang/golang/golang-version.mk"
#if [ -f "$GOLANG_VERSION" ]; then
#    if grep -q '$(if $(PKG_HOST_ONLY),BUILDONLY:=1)' "$GOLANG_VERSION"; then
#      echo "---- GOLANG_VERSION start ----"&&  cat "$GOLANG_VERSION"
#      echo "---- GOLANG_VERSION end ----"  &&     echo " "
#        sed -i '/\$(if \$(PKG_HOST_ONLY),BUILDONLY:=1)/d' "$GOLANG_VERSION"
#        echo "Removed BUILDONLY line from $GOLANG_VERSION" &&     echo " "
#      echo "---- GOLANG_VERSION start ----"&&  cat "$GOLANG_VERSION"
#      echo "---- GOLANG_VERSION end ----"
#    else
#        echo "BUILDONLY line not found, skipping."
#    fi
#fi


#修补命令统一入口：FIX <名称> <守卫目录> <命令...>
#守卫目录不存在时直接跳过，保证在 bash -e 下不中断
FIX() {
	local NAME=$1
	local GUARD=$2
	shift 2

	[ -d "$GUARD" ] || return 0

	echo " "
	if "$@"; then
		echo "$NAME has been fixed!"
	else
		echo "$NAME fix failed; continuing!"
	fi
}

#修改argon主题字体和颜色
FIX "theme-argon" "$PACKAGE_PATH/luci-theme-argon" sed -i \
	"s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
	"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"

#修改aurora菜单式样
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

#修改mini-diskmanager菜单位置
FIX "mini-diskmanager" "$PACKAGE_PATH/luci-app-mini-diskmanager" sed -i "s/services/system/g" \
	"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"

#修改natmapt菜单位置
FIX "natmapt" "$PACKAGE_PATH/luci-app-natmapt" sed -i "s/network/services/g" \
	"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"


# ============================================
# 修改 package/luci-app-nikki/Makefile：
#   在 LUCI_DEPENDS 行后插入 postinst/postrm 钩子，
#   安装/卸载时自动为 mihomo(nikki) 创建/清理软链接：
#     /etc/nikki/run/GeoSite.dat -> /usr/share/v2ray/geosite.dat
#     /etc/nikki/run/GeoIP.dat   -> /usr/share/v2ray/geoip.dat
# ============================================
NIKKI_MAKEFILE="$(find "$PACKAGE_PATH" -maxdepth 4 -type f -path '*/luci-app-nikki/Makefile' -print -quit 2>/dev/null)"

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
V2RAY_GEODATA_MAKEFILE="$(find "$PACKAGE_PATH" "$PACKAGE_PATH/../feeds/packages" \
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


#升级Xray
XRAY_FILE="$(find "$FEEDS_PATH/packages" -maxdepth 3 -type f -wholename "*/xray-core/Makefile" -print -quit 2>/dev/null)"
if [ -f "$XRAY_FILE" ]; then
	echo " "
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=26.10.21"  "$XRAY_FILE"
	sed -i "/PKG_HASH:=/cPKG_HASH:=44ef4874529a03848c90f1fdcfb763350fbc5f1de741ec90e0024d651df25650"  "$XRAY_FILE"
	echo "xray-core version has update to 26.10.21!"
   #add_upx_compress "$XRAY_FILE" "xray" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- xray-core_Makefile内容 start ----"
    cat  "$XRAY_FILE"
    echo "---- xray-core_Makefile内容 end ----"
	echo " "
fi

#压缩mihomo
MIHOMO_META_FILE=$(find "$PACKAGE_PATH" -maxdepth 5 -type f -wholename "*/mihomo-meta/Makefile")
MIHOMO_ALPHA_FILE=$(find "$PACKAGE_PATH" -maxdepth 5 -type f -wholename "*/mihomo-alpha/Makefile")
if [ -f "$MIHOMO_META_FILE" ]; then
	echo " "
   #add_upx_compress "$MIHOMO_META_FILE" "mihomo" "/usr/libexec" && echo "mihomo 将被压缩"
	echo " "
    echo "---- mihomo-meta_Makefile内容 start ----"
    cat "$MIHOMO_META_FILE"
    echo "---- mihomo-meta_Makefile内容 end ----"
	echo " "
    echo "---- mihomo-alpha_Makefile内容 start ----"
    cat "$MIHOMO_ALPHA_FILE"
    echo "---- mihomo-alpha_Makefile内容 end ----"
	echo " "
fi


#压缩sing-box
SING_BOX_FILE=$(find "$PACKAGE_PATH" -maxdepth 3 -type f -wholename "*/sing-box/Makefile")
if [ -f "$SING_BOX_FILE" ]; then
	echo " "
   #add_upx_compress "$SING_BOX_FILE" "sing-box" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- sing-box_Makefile内容 start ----"
    cat "$SING_BOX_FILE"
    echo "---- sing-box_Makefile内容 end ----"
	echo " "
fi





#修复TailScale配置文件冲突
TS_FILE="$(find "$FEEDS_PATH/packages" -maxdepth 3 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)"
if [ -f "$TS_FILE" ]; then
     sed -i "/PKG_VERSION:=/cPKG_VERSION:=1.94.2" "$TS_FILE"
     sed -i "/PKG_HASH:=/cPKG_HASH:=c45975beb4cb7bab8047cfba77ec8b170570d184f3c806258844f3e49c60d7aa"  "$TS_FILE"
     echo " " && echo "tailscale 使用1.94.2版本"	
     sed -i 's|PKG_BUILD_DEPENDS:=golang/host|PKG_BUILD_DEPENDS:=golang1.26/host|'  "$TS_FILE"
     echo " " &&echo "tailscale 已指定使用 golang1.26"
     echo " "
     if sed -i '/\/files/d' "$TS_FILE"; then
     	echo "tailscale has been fixed!"
     else
     	echo "tailscale fix failed; continuing!"
     fi
   #add_upx_compress "$TS_FILE" "tailscaled" "usr/sbin" && echo "tailscaled 将被压缩"
    echo "---- tailscale_Makefile内容 start ----"
    cat "$TS_FILE"
    echo "---- tailscale_Makefile内容 end ----"
    echo " "
fi

EASYTIER_CORE="$(find "$PACKAGE_PATH" -maxdepth 4 -type f -path '*/easytier/Makefile' -print -quit 2>/dev/null)"

if [ -f "$EASYTIER_CORE" ]; then
	echo " "
    sed -i '/^PKG_VERSION:=/c\PKG_VERSION:=$(or $(EASYTIER_VERSION),2.6.4)' "$EASYTIER_CORE"
	echo "easytier-core version has update to 2.6.4!"
   #add_upx_compress "$EASYTIER_CORE" "easytier-core" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- easytier-core_Makefile内容 start ----"
    cat  "$EASYTIER_CORE"
    echo "---- easytier-core_Makefile内容 end ----"
	echo " "
fi





# ==================== UPX COMPRESS FOR GO BINARIES (PRECISION) BEGIN ====================
# 精准注入 UPX 压缩，仅处理 tailscaled、sing-box、mihomo、xray
# 依赖：./package/openwrt-upx 提供的 upx/host -> $(STAGING_DIR_HOST)/bin/upx
# =======================================================================================
set +e

UPX_INJECT_LOG() { echo "[UPX-INJECT] $*"; }

# 检查当前目标架构是否适合 UPX（跳过 mips64 / riscv64 / loongarch64）
upx_arch_supported() {
    local _target="${WRT_TARGET:-} ${ARCH:-}"
    for _skip in mips64 riscv64 loongarch64; do
        case "$_target" in *"$_skip"*) UPX_INJECT_LOG "SKIP arch: matched $_skip in '$_target'"; return 1;; esac
    done
    return 0
}

# 判断一行是否为“含二进制的安装行”
# 匹配：$(INSTALL_BIN) ...  或  $(call GoPackage/Package/Install/Bin,$(1))
is_bin_install_line() {
    local line="$1"
    case "$line" in
        *'$(call GoPackage/Package/Install/Bin,$(1))'*) return 0 ;;
        *'$(INSTALL_BIN)'*)
            # 排除明显是配置/数据文件的行
            case "$line" in
                *.json*|*.conf*|*.cnf*|*.ini*|*.yaml*|*.yml*) return 1 ;;
                *'/etc/'*) return 1 ;;
                *'/usr/share/'*) return 1 ;;
            esac
            return 0
            ;;
    esac
    return 1
}

# 核心：精准注入到单个 Makefile
# $1: Makefile 路径
# $2: 二进制基名（用于日志，如 tailscaled / sing-box / mihomo / xray）
inject_upx_precise() {
    local MAKE_FILE="$1"
    local BIN_LABEL="$2"

    [ -f "$MAKE_FILE" ] || { UPX_INJECT_LOG "SKIP: missing $MAKE_FILE"; return 0; }
    [ -w "$MAKE_FILE" ] || { UPX_INJECT_LOG "SKIP: read-only $MAKE_FILE"; return 0; }

    # 防重复：检查标记
    grep -qF '# UPX_PRECISION_INJECTED' "$MAKE_FILE" && { UPX_INJECT_LOG "SKIP: already injected $MAKE_FILE"; return 0; }

    UPX_INJECT_LOG "Processing: $MAKE_FILE  (bin=$BIN_LABEL)"

    # 1) 注入 upx/host 依赖
    if ! grep -q 'upx/host' "$MAKE_FILE"; then
        if grep -q '^PKG_BUILD_DEPENDS' "$MAKE_FILE"; then
            sed -i '/^PKG_BUILD_DEPENDS/ s/$/ upx\/host/' "$MAKE_FILE" 2>/dev/null
        else
            sed -i '/^include \$(TOPDIR)\/rules.mk/a\PKG_BUILD_DEPENDS:=upx/host' "$MAKE_FILE" 2>/dev/null
        fi
        UPX_INJECT_LOG "  + upx/host added to PKG_BUILD_DEPENDS"
    fi

    # 2) 逐行处理，跟踪 install 块，精准替换
    local TMP="${MAKE_FILE}.upxprec.$$"
    local IN_INSTALL=0
    local MOD_COUNT=0
    : > "$TMP"

    while IFS= read -r line || [ -n "$line" ]; do
        # 进入 install 块
        if printf '%s\n' "$line" | grep -qE '^define Package/[^/]+/install'; then
            IN_INSTALL=1
            printf '%s\n' "$line" >> "$TMP"
            continue
        fi
        # 离开 install 块
        if [ "$IN_INSTALL" -eq 1 ] && printf '%s\n' "$line" | grep -qE '^endef'; then
            IN_INSTALL=0
            printf '%s\n' "$line" >> "$TMP"
            continue
        fi

        if [ "$IN_INSTALL" -eq 1 ] && is_bin_install_line "$line"; then
            MOD_COUNT=$((MOD_COUNT + 1))
            UPX_INJECT_LOG "  Matched install line in $MAKE_FILE: $line"
            printf '%s\n' "# UPX_PRECISION_INJECTED (original: $line)" >> "$TMP"

            # 分支 A：GoPackage/Package/Install/Bin
            case "$line" in
                *'$(call GoPackage/Package/Install/Bin,$(1))'*)
                    cat >> "$TMP" <<'UPX_GOINSTALL'
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/.upx
	$(call GoPackage/Package/Install/Bin,$(PKG_BUILD_DIR)/.upx)
	@for f in $(PKG_BUILD_DIR)/.upx$(or $(GO_PKG_INSTALL_BIN_PATH),/usr/bin)/*; do \
		if [ -f "$$f" ] && [ -x "$$f" ]; then \
			if [ -x "$(STAGING_DIR_HOST)/bin/upx" ]; then \
				echo "[UPX] compressing $$f"; \
				SZ0=$$(stat -c %s "$$f" 2>/dev/null || echo 0); \
				$(STAGING_DIR_HOST)/bin/upx --lzma --best "$$f" || true; \
				SZ1=$$(stat -c %s "$$f" 2>/dev/null || echo 0); \
				echo "[UPX] done $$f  $$SZ0 -> $$SZ1"; \
			else \
				echo "[UPX] upx not found, skip $$f"; \
			fi; \
			$(INSTALL_BIN) "$$f" $(1)$(or $(GO_PKG_INSTALL_BIN_PATH),/usr/bin)/; \
		fi; \
	done
UPX_GOINSTALL
                    continue
                    ;;
            esac

            # 分支 B：$(INSTALL_BIN) source dest
            # 提取 source 与 dest（取最后两个非空字段）
            local SRC DST
            SRC=$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /\$\(INSTALL_BIN\)/){src=$(i+1); dst=$NF}} print src}')
            DST=$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /\$\(INSTALL_BIN\)/){src=$(i+1); dst=$NF}} print dst}')
            if [ -n "$SRC" ] && [ -n "$DST" ]; then
                local BNAME
                BNAME=$(basename "$SRC")
                cat >> "$TMP" <<UPX_INSTALLBIN
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/.upx
	$(INSTALL_BIN) $SRC $(PKG_BUILD_DIR)/.upx/$BNAME
	@if [ -x "$(STAGING_DIR_HOST)/bin/upx" ]; then \\
		echo "[UPX] compressing $BNAME"; \\
		SZ0=\$\$(stat -c %s $(PKG_BUILD_DIR)/.upx/$BNAME 2>/dev/null || echo 0); \\
		$(STAGING_DIR_HOST)/bin/upx --lzma --best $(PKG_BUILD_DIR)/.upx/$BNAME || true; \\
		SZ1=\$\$(stat -c %s $(PKG_BUILD_DIR)/.upx/$BNAME 2>/dev/null || echo 0); \\
		echo "[UPX] done $BNAME  \$\$SZ0 -> \$\$SZ1"; \\
	else \\
		echo "[UPX] upx not found, skip $BNAME"; \\
	fi
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/.upx/$BNAME $DST
UPX_INSTALLBIN
                UPX_INJECT_LOG "  Injected INSTALL_BIN: $BNAME -> $DST"
                continue
            fi
        fi

        printf '%s\n' "$line" >> "$TMP"
    done < "$MAKE_FILE"

    # 3) 应用修改（若至少处理了一行）
    if [ "$MOD_COUNT" -gt 0 ] && [ -s "$TMP" ]; then
        cp -f "$MAKE_FILE" "${MAKE_FILE}.bak.$$" 2>/dev/null
        mv -f "$TMP" "$MAKE_FILE" 2>/dev/null && {
            echo "# UPX_PRECISION_INJECTED" | cat - "$MAKE_FILE" > "${MAKE_FILE}.tag.$$" 2>/dev/null && mv -f "${MAKE_FILE}.tag.$$" "$MAKE_FILE"
            UPX_INJECT_LOG "  injected $MOD_COUNT line(s) into $MAKE_FILE"
        }
        rm -f "${MAKE_FILE}.bak.$$" 2>/dev/null

        # 打印修改前后关键对比（install 块）
        UPX_INJECT_LOG "  ---- BEFORE (install block) ----"
        sed -n '/^define Package\/.*\/install/,/^endef/p' "${MAKE_FILE}.bak.$$" 2>/dev/null | while IFS= read -r l; do UPX_INJECT_LOG "  | $l"; done
        UPX_INJECT_LOG "  ---- AFTER (install block) ----"
        sed -n '/^define Package\/.*\/install/,/^endef/p' "$MAKE_FILE" 2>/dev/null | while IFS= read -r l; do UPX_INJECT_LOG "  | $l"; done
    else
        UPX_INJECT_LOG "  no binary install lines found, skip"
    fi
    rm -f "$TMP" 2>/dev/null
}

# ==================== 主流程 ====================
if upx_arch_supported; then
    # tailscale
    TS_MK=$(find "$FEEDS_PATH/packages" -maxdepth 4 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)
    [ -n "$TS_MK" ] && [ -f "$TS_MK" ] && inject_upx_precise "$TS_MK" "tailscaled"

    # sing-box（可能在 package/ 或 feeds/packages）
    SB_MK=$(find "$PACKAGE_PATH" "$FEEDS_PATH/packages" -maxdepth 6 -type f -wholename '*/sing-box/Makefile' -print -quit 2>/dev/null)
    [ -n "$SB_MK" ] && [ -f "$SB_MK" ] && inject_upx_precise "$SB_MK" "sing-box"

    # mihomo（mihomo-meta / mihomo-alpha）
    for MH_MK in $(find "$PACKAGE_PATH" "$FEEDS_PATH/packages" -maxdepth 6 -type f -wholename '*/mihomo*/Makefile' 2>/dev/null); do
        [ -f "$MH_MK" ] && inject_upx_precise "$MH_MK" "mihomo"
    done

    # xray-core
    XR_MK=$(find "$PACKAGE_PATH" "$FEEDS_PATH/packages" -maxdepth 6 -type f -wholename '*/xray-core/Makefile' -print -quit 2>/dev/null)
    [ -n "$XR_MK" ] && [ -f "$XR_MK" ] && inject_upx_precise "$XR_MK" "xray"
else
    UPX_INJECT_LOG "架构不支持，跳过全部 UPX 注入。"
fi

UPX_INJECT_LOG "UPX precision injection completed."
set -e
# ==================== UPX COMPRESS FOR GO BINARIES (PRECISION) END ====================