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






# ==================== UPX HOOK DIAGNOSTIC + INJECTION BEGIN ====================
set +e

GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"
TOPDIR="$PWD"
UPX_PREP_LOG="$GITHUB_WORKSPACE/build-reports/upx-prepare.log"
UPX_LOG_ABS="$GITHUB_WORKSPACE/build-reports/upx-hook.log"
UPX_HOOK_MK="$TOPDIR/upx-hook.mk"
UPX_ROOTFS_SH="$TOPDIR/upx-rootfs.sh"

UPX_TARGET_BINS="${UPX_TARGET_BINS:-tailscaled,sing-box,mihomo,xray,docker,dockerd}"
UPX_ENABLED_CONFIGS="${UPX_ENABLED_CONFIGS:-}"
UPX_SKIP_KEYWORDS="${UPX_SKIP_KEYWORDS:-x86,rockchip,airoha}"
UPX_FORCE_ENABLE="${UPX_FORCE_ENABLE:-0}"
UPX_COMPRESS_ALL="${UPX_COMPRESS_ALL:-0}"

mkdir -p "$(dirname "$UPX_PREP_LOG")" 2>/dev/null || true
: > "$UPX_PREP_LOG" 2>/dev/null || true
: > "$UPX_LOG_ABS" 2>/dev/null || true

uplog() { printf '%s\n' "$*" | tee -a "$UPX_PREP_LOG" 2>/dev/null || true; }
uplog_block() { tee -a "$UPX_PREP_LOG" 2>/dev/null || true; }
sed_escape() { printf '%s' "$1" | sed -e 's/[\\&#]/\\&/g'; }

uplog "==================== UPX Hook 诊断+注入开始 ===================="
uplog "PWD=$PWD"
uplog "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"
uplog "TOPDIR=$TOPDIR"
uplog "WRT_TARGET=${WRT_TARGET:-<unset>} (仅显示/优先，不限制)"
uplog "WRT_SUBTARGET=${WRT_SUBTARGET:-<unset>} (仅显示/优先，不限制)"
uplog "WRT_CONFIG=${WRT_CONFIG:-<unset>}"
uplog "BOARD=${BOARD:-<unset>}"
uplog "UPX_PREP_LOG=$UPX_PREP_LOG"
uplog "UPX_LOG_ABS=$UPX_LOG_ABS"
uplog "UPX_HOOK_MK=$UPX_HOOK_MK"
uplog "UPX_ROOTFS_SH=$UPX_ROOTFS_SH"

if [ ! -f rules.mk ]; then
    uplog "WARNING: 当前目录没有 rules.mk，可能不在 OpenWrt 源码根目录"
fi

uplog "-------------------- 工具版本探测 --------------------"
for cmd in upx readelf file timeout stat find grep awk sed make sha256sum tar uname nproc df du; do
    uplog "command -v $cmd: $(command -v "$cmd" 2>&1 || true)"
done
{
    echo "===== upx --version ====="; upx --version 2>&1 || true
    echo "===== readelf --version ====="; readelf --version 2>&1 | head -3 || true
    echo "===== file --version ====="; file --version 2>&1 | head -3 || true
    echo "===== uname -a ====="; uname -a
    echo "===== nproc ====="; nproc
} 2>&1 | uplog_block || true

uplog "-------------------- 自动探测注入候选 --------------------"
CANDIDATE_IMAGE_MAKEFILES=""
if [ -n "${WRT_TARGET:-}" ]; then
    _pref="target/linux/${WRT_TARGET}/image/Makefile"
    if [ -f "$_pref" ]; then
        CANDIDATE_IMAGE_MAKEFILES="$_pref"
        uplog "优先候选(WRT_TARGET): $_pref"
    else
        uplog "WARNING: WRT_TARGET=${WRT_TARGET} 但 $_pref 不存在，改为全局探测"
    fi
fi
if [ -z "$CANDIDATE_IMAGE_MAKEFILES" ]; then
    CANDIDATE_IMAGE_MAKEFILES="$(grep -RIl --include=Makefile -F '$(eval $(call BuildImage))' target/linux/*/image/Makefile 2>/dev/null | sort -u)"
    uplog "全局探测结果:"
    printf '%s\n' "$CANDIDATE_IMAGE_MAKEFILES" 2>&1 | uplog_block || true
fi
if [ -z "$CANDIDATE_IMAGE_MAKEFILES" ]; then
    uplog "WARNING: 没有找到任何含 '$(eval $(call BuildImage))' 的 target/linux/*/image/Makefile"
fi
uplog "CANDIDATE_IMAGE_MAKEFILES=$CANDIDATE_IMAGE_MAKEFILES"

uplog "-------------------- 计算 UPX_SHOULD_APPLY --------------------"
UPX_SHOULD_APPLY=0
UPX_REASON=""
_BOARD_STR="$(echo "${WRT_TARGET:-} ${WRT_SUBTARGET:-} ${WRT_CONFIG:-} ${BOARD:-}" | tr 'A-Z' 'a-z')"
if [ "$UPX_FORCE_ENABLE" = "1" ]; then
    UPX_SHOULD_APPLY=1
    UPX_REASON="forced by UPX_FORCE_ENABLE=1"
else
    SKIP_HIT=""
    for kw in $(echo "$UPX_SKIP_KEYWORDS" | tr ',' ' '); do
        [ -z "$kw" ] && continue
        _kw_lc="$(echo "$kw" | tr 'A-Z' 'a-z')"
        case "$_BOARD_STR" in
            *"$_kw_lc"*) SKIP_HIT="$kw"; break;;
        esac
    done
    if [ -n "$SKIP_HIT" ]; then
        UPX_SHOULD_APPLY=0
        UPX_REASON="hit skip keyword '$SKIP_HIT' in '${WRT_TARGET:-} ${WRT_SUBTARGET:-} ${WRT_CONFIG:-} ${BOARD:-}'"
    else
        if [ -z "$UPX_ENABLED_CONFIGS" ] || [ "$UPX_ENABLED_CONFIGS" = "<unset>" ]; then
            UPX_SHOULD_APPLY=1
            UPX_REASON="UPX_ENABLED_CONFIGS empty, enable all"
        else
            for c in $(echo "$UPX_ENABLED_CONFIGS" | tr ',' ' '); do
                if [ "$c" = "${WRT_CONFIG:-}" ]; then
                    UPX_SHOULD_APPLY=1
                    UPX_REASON="WRT_CONFIG matched UPX_ENABLED_CONFIGS entry '$c'"
                    break
                fi
            done
            if [ "$UPX_SHOULD_APPLY" != "1" ]; then
                UPX_REASON="WRT_CONFIG=${WRT_CONFIG:-} not in UPX_ENABLED_CONFIGS=$UPX_ENABLED_CONFIGS"
            fi
        fi
    fi
fi

uplog "UPX_ENABLED_CONFIGS=$UPX_ENABLED_CONFIGS"
uplog "UPX_SKIP_KEYWORDS=$UPX_SKIP_KEYWORDS"
uplog "UPX_FORCE_ENABLE=$UPX_FORCE_ENABLE"
uplog "UPX_COMPRESS_ALL=$UPX_COMPRESS_ALL"
uplog "size filtering: disabled (按文件大小降序处理，不设 min/max)"
uplog "UPX_TARGET_BINS=$UPX_TARGET_BINS"
uplog "UPX_SHOULD_APPLY=$UPX_SHOULD_APPLY"
uplog "UPX_REASON=$UPX_REASON"

uplog "-------------------- 生成 upx-rootfs.sh --------------------"
cat > "$UPX_ROOTFS_SH" <<'UPX_ROOTFS_EOF'
#!/bin/sh
set +e

LOG="${UPX_LOG:-/tmp/upx-rootfs.log}"
ROOTFS="${ROOTFS:-$1}"
ARCH="${ARCH:-unknown}"
BOARD="${BOARD:-unknown}"
SUBTARGET="${SUBTARGET:-unknown}"
TARGET="${TARGET:-unknown}"
UPX_HOOK_ENABLE="${UPX_HOOK_ENABLE:-0}"
UPX_TARGET_BINS="@UPX_TARGET_BINS@"
UPX_COMPRESS_ALL="@UPX_COMPRESS_ALL@"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

log() {
    _msg="$*"
    printf '%s [upx-rootfs] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_msg" >> "$LOG" 2>&1 || true
    printf '[upx-rootfs] %s\n' "$_msg" >&2 || true
}

TOTAL=0
CAND_COUNT=0
COMPRESSED=0
SKIPPED=0
FAILED=0
TOTAL_SAVED=0

skip() { SKIPPED=$((SKIPPED + 1)); log "SKIP rel=$rel reason=$*"; }
fail() { FAILED=$((FAILED + 1)); log "FAIL rel=$rel reason=$*"; }

run_upx_capture() {
    _out="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout 180 upx "$@" > "$_out" 2>&1
    else
        upx "$@" > "$_out" 2>&1
    fi
    _rc=$?
    cat "$_out" >> "$LOG" 2>/dev/null || true
    cat "$_out" >&2 2>/dev/null || true
    rm -f "$_out"
    return $_rc
}

in_whitelist() {
    _base="$1"
    if [ "$UPX_COMPRESS_ALL" = "1" ] || [ -z "$UPX_TARGET_BINS" ] || [ "$UPX_TARGET_BINS" = "ALL" ]; then
        return 0
    fi
    for _bin in $(echo "$UPX_TARGET_BINS" | tr ',' ' '); do
        [ -z "$_bin" ] && continue
        if [ "$_base" = "$_bin" ]; then
            return 0
        fi
    done
    return 1
}

is_all_mode() {
    [ "$UPX_COMPRESS_ALL" = "1" ] || [ -z "$UPX_TARGET_BINS" ] || [ "$UPX_TARGET_BINS" = "ALL" ]
}

log "==================== upx-rootfs start ===================="
log "pid=$$ pwd=$(pwd)"
log "ROOTFS=$ROOTFS"
log "ARCH=$ARCH BOARD=$BOARD SUBTARGET=$SUBTARGET TARGET=$TARGET"
log "UPX_HOOK_ENABLE=$UPX_HOOK_ENABLE"
log "UPX_COMPRESS_ALL=$UPX_COMPRESS_ALL"
log "UPX_TARGET_BINS=$UPX_TARGET_BINS"
log "size filtering: disabled"
log "LOG=$LOG"

if [ "$UPX_HOOK_ENABLE" != "1" ]; then
    log "UPX_HOOK_ENABLE != 1，退出"
    exit 0
fi

if ! command -v upx >/dev/null 2>&1; then
    log "FATAL: upx 不存在"
    exit 0
fi

if [ -z "$ROOTFS" ] || [ ! -d "$ROOTFS" ]; then
    log "FATAL: ROOTFS 不是目录或为空: [$ROOTFS]"
    exit 0
fi

log "rootfs exists: $(ls -ld "$ROOTFS" 2>&1)"
log "rootfs file count: $(find "$ROOTFS" -xdev -type f 2>/dev/null | wc -l)"
log "rootfs executable count: $(find "$ROOTFS" -xdev -type f -perm -111 2>/dev/null | wc -l)"
log "rootfs size: $(du -sh "$ROOTFS" 2>/dev/null | awk '{print $1}')"
log "df rootfs: $(df -h "$ROOTFS" 2>&1 | tail -1)"

STD_DIRS="bin sbin usr/bin usr/sbin usr/libexec"
CAND_LIST="${LOG}.candidates"
PATHS_TMP="${LOG}.paths"
: > "$CAND_LIST"
: > "$PATHS_TMP"

if is_all_mode; then
    log "===== 全量模式：find -perm -111，按大小降序 ====="
    find "$ROOTFS" -xdev -type f -perm -111 2>/dev/null | sort -u > "$PATHS_TMP"
else
    log "===== 白名单模式：先标准目录按名字找，找不到再全 rootfs fallback ====="
    for _bin in $(echo "$UPX_TARGET_BINS" | tr ',' ' '); do
        [ -z "$_bin" ] && continue
        _std_hit=""
        for d in $STD_DIRS; do
            [ -d "$ROOTFS/$d" ] || continue
            _one="$(find "$ROOTFS/$d" -xdev -type f -name "$_bin" 2>/dev/null)"
            if [ -n "$_one" ]; then
                _std_hit="${_std_hit}${_one}
"
            fi
        done
        if [ -n "$_std_hit" ]; then
            log "lookup bin=$_bin standard=HIT"
            printf '%s' "$_std_hit" >> "$PATHS_TMP"
        else
            log "lookup bin=$_bin standard=MISS, fallback full rootfs"
            find "$ROOTFS" -xdev -type f -name "$_bin" 2>/dev/null >> "$PATHS_TMP"
        fi
    done
    sort -u "$PATHS_TMP" -o "$PATHS_TMP"
fi

while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    _s="$(stat -c %s "$_p" 2>/dev/null || echo 0)"
    printf '%s\t%s\n' "$_s" "$_p"
done < "$PATHS_TMP" | sort -k1,1nr > "$CAND_LIST"

CAND_COUNT=$(wc -l < "$CAND_LIST" 2>/dev/null || echo 0)
TOTAL=$CAND_COUNT
log "path list saved to $PATHS_TMP"
log "candidate list saved to $CAND_LIST"
log "candidate files: $CAND_COUNT"
log "===== 候选列表（按大小降序）====="
while IFS="$(printf '\t')" read -r _s _p; do
    [ -n "$_p" ] || continue
    log "cand size=$_s path=$_p"
done < "$CAND_LIST"

EXPECT_PATTERN=""
case "$ARCH" in
    aarch64|arm64) EXPECT_PATTERN="AArch64" ;;
    arm|armv7|armv8) EXPECT_PATTERN="ARM" ;;
    x86_64) EXPECT_PATTERN="X86-64" ;;
    i386|i486|i586|i686) EXPECT_PATTERN="80386" ;;
    mips|mipsel) EXPECT_PATTERN="MIPS" ;;
    *) EXPECT_PATTERN="" ;;
esac
log "EXPECT_PATTERN=[$EXPECT_PATTERN]"

while IFS="$(printf '\t')" read -r SIZE_BEFORE f; do
    [ -n "$f" ] || continue
    rel="${f#$ROOTFS/}"
    base="$(basename "$f")"

    case "$rel" in
        *.ko|*.ko.*|*.so|*.so.*|*.a|*.o|*.la|*.lai)
            skip "kernel module/shared/static object by suffix"
            continue
            ;;
    esac

    if [ -L "$f" ]; then
        skip "symlink"
        continue
    fi
    if [ ! -f "$f" ]; then
        skip "not regular file"
        continue
    fi
    if ! in_whitelist "$base"; then
        skip "not in UPX_TARGET_BINS"
        continue
    fi

    HL="$(stat -c %h "$f" 2>/dev/null || echo 0)"
    if [ "$HL" -gt 1 ]; then
        log "WARN rel=$rel hardlink_count=$HL, will break hardlink and compress independently"
    fi

    if head -c 2 "$f" 2>/dev/null | grep -aq '^#!'; then
        skip "script shebang"
        continue
    fi
    if grep -aq 'UPX!' "$f" 2>/dev/null; then
        skip "already UPX compressed"
        continue
    fi

    FILE_OUT="$(file -b "$f" 2>/dev/null || true)"
    case "$FILE_OUT" in
        *ELF*executable*) ;;
        *)
            skip "not ELF executable: $FILE_OUT"
            continue
            ;;
    esac
    case "$FILE_OUT" in
        *shared\ object*)
            skip "ELF shared object: $FILE_OUT"
            continue
            ;;
    esac

    READELF_H="$(readelf -h "$f" 2>/dev/null || true)"
    MACHINE="$(printf '%s\n' "$READELF_H" | awk -F: '/Machine:/{gsub(/^[ \t]+/,"",$2); print $2; exit}')"
    TYPE="$(printf '%s\n' "$READELF_H" | awk -F: '/Type:/{gsub(/^[ \t]+/,"",$2); print $2; exit}')"
    log "candidate rel=$rel size=$SIZE_BEFORE machine=[$MACHINE] type=[$TYPE] file=[$FILE_OUT]"

    if [ -n "$EXPECT_PATTERN" ]; then
        case "$MACHINE" in
            *"$EXPECT_PATTERN"*) ;;
            *)
                skip "machine mismatch expected=[$EXPECT_PATTERN] actual=[$MACHINE]"
                continue
                ;;
        esac
    fi

    TMP="${f}.upx.$$"
    UPX_OUT="${f}.upxout.$$"
    if ! cp -p "$f" "$TMP" 2>>"$LOG"; then
        fail "cp to temp failed"
        continue
    fi

    run_upx_capture "$UPX_OUT" -9 -q "$TMP"
    RC=$?
    if [ "$RC" -eq 0 ]; then
        run_upx_capture "$UPX_OUT" -t -q "$TMP"
        RCT=$?
        if [ "$RCT" -eq 0 ]; then
            OLD="$(stat -c %s "$f" 2>/dev/null || echo 0)"
            NEW="$(stat -c %s "$TMP" 2>/dev/null || echo 0)"
            if mv -f "$TMP" "$f" 2>>"$LOG"; then
                COMPRESSED=$((COMPRESSED + 1))
                TOTAL_SAVED=$((TOTAL_SAVED + OLD - NEW))
                log "OK rel=$rel old=$OLD new=$NEW saved=$((OLD - NEW))"
            else
                rm -f "$TMP"
                fail "mv temp back failed"
            fi
        else
            rm -f "$TMP"
            fail "upx -t failed rc=$RCT"
        fi
    else
        rm -f "$TMP"
        fail "upx -9 failed rc=$RC"
    fi
done < "$CAND_LIST"

log "==================== upx-rootfs summary ===================="
log "SUMMARY total=$TOTAL candidate=$CAND_COUNT compressed=$COMPRESSED skipped=$SKIPPED failed=$FAILED saved=$TOTAL_SAVED"
log "candidate list: $CAND_LIST"
log "==================== upx-rootfs end ===================="
exit 0
UPX_ROOTFS_EOF

sed -i "s#@UPX_TARGET_BINS@#$(sed_escape "$UPX_TARGET_BINS")#g" "$UPX_ROOTFS_SH" 2>/dev/null || true
sed -i "s#@UPX_COMPRESS_ALL@#$(sed_escape "$UPX_COMPRESS_ALL")#g" "$UPX_ROOTFS_SH" 2>/dev/null || true
chmod +x "$UPX_ROOTFS_SH" 2>/dev/null || true
uplog "upx-rootfs.sh 已生成: $(ls -l "$UPX_ROOTFS_SH" 2>&1)"

uplog "-------------------- 生成 upx-hook.mk --------------------"
cat > "$UPX_HOOK_MK" <<'UPX_HOOK_EOF'
$(info [upx-mk] ===== file parsed =====)
$(info [upx-mk] CURDIR=$(CURDIR))
$(info [upx-mk] TOPDIR=$(TOPDIR))
$(info [upx-mk] MAKEFILE_LIST=$(MAKEFILE_LIST))
$(info [upx-mk] ARCH=$(ARCH) BOARD=$(BOARD) SUBTARGET=$(SUBTARGET))
$(info [upx-mk] ROOTFS_POSTPROCESS_COMMAND=[$(ROOTFS_POSTPROCESS_COMMAND)])
$(info [upx-mk] origin prepare_rootfs=$(origin prepare_rootfs))
$(info [upx-mk] origin BuildImage=$(origin BuildImage))
$(info [upx-mk] value TARGET_DIR=[$(TARGET_DIR)])
$(info [upx-mk] value TARGET_ROOTFS_DIR=[$(TARGET_ROOTFS_DIR)])
$(info [upx-mk] value BUILD_DIR=[$(BUILD_DIR)])
$(info [upx-mk] value BIN_DIR=[$(BIN_DIR)])
$(info [upx-mk] value KDIR=[$(KDIR)])

ifdef UPX_HOOK_INCLUDED
$(info [upx-mk] WARNING: upx-hook.mk included again)
else
UPX_HOOK_INCLUDED := 1
$(info [upx-mk] first include)
endif

UPX_LOG := __UPX_LOG__
UPX_ROOTFS_SCRIPT := $(TOPDIR)/upx-rootfs.sh
UPX_HOOK_ENABLE := __UPX_HOOK_ENABLE__

$(info [upx-mk] UPX_HOOK_ENABLE=$(UPX_HOOK_ENABLE))
$(info [upx-mk] UPX_ROOTFS_SCRIPT=$(UPX_ROOTFS_SCRIPT))
$(info [upx-mk] UPX_LOG=$(UPX_LOG))

define UpXRootfsHook
@@TAB@@@echo "[upx] hook invoked rootfs=$(1)" >> "$(UPX_LOG)" 2>&1; echo "[upx] hook invoked rootfs=$(1)" >&2; \
@@TAB@@UPX_LOG="$(UPX_LOG)" ROOTFS="$(1)" ARCH="$(ARCH)" BOARD="$(BOARD)" SUBTARGET="$(SUBTARGET)" TARGET="$(TARGET)" UPX_HOOK_ENABLE="$(UPX_HOOK_ENABLE)" sh "$(UPX_ROOTFS_SCRIPT)"; \
@@TAB@@if [ -n "$(TARGET_DIR)" ] && [ "$(TARGET_DIR)" != "$(1)" ]; then \
@@TAB@@  echo "[upx] also compressing TARGET_DIR=$(TARGET_DIR)" >> "$(UPX_LOG)" 2>&1; echo "[upx] also compressing TARGET_DIR=$(TARGET_DIR)" >&2; \
@@TAB@@  UPX_LOG="$(UPX_LOG)" ROOTFS="$(TARGET_DIR)" ARCH="$(ARCH)" BOARD="$(BOARD)" SUBTARGET="$(SUBTARGET)" TARGET="$(TARGET)" UPX_HOOK_ENABLE="$(UPX_HOOK_ENABLE)" sh "$(UPX_ROOTFS_SCRIPT)"; \
@@TAB@@fi; \
@@TAB@@rc=$$?; echo "[upx] hook script rc=$$rc" >> "$(UPX_LOG)" 2>&1; echo "[upx] hook script rc=$$rc" >&2
endef

$(info [upx-mk] defining UpXRootfsHook done)
$(info [upx-mk] ===== file parsed end =====)
UPX_HOOK_EOF

sed -i 's/^@@TAB@@/\t/' "$UPX_HOOK_MK" 2>/dev/null || true
sed -i "s#__UPX_LOG__#$(sed_escape "$UPX_LOG_ABS")#g" "$UPX_HOOK_MK" 2>/dev/null || true
sed -i "s#__UPX_HOOK_ENABLE__#$UPX_SHOULD_APPLY#g" "$UPX_HOOK_MK" 2>/dev/null || true

uplog "upx-hook.mk 已生成: $(ls -l "$UPX_HOOK_MK" 2>&1)"
uplog "-------------------- upx-hook.mk 全文 begin --------------------"
cat "$UPX_HOOK_MK" 2>&1 | uplog_block || true
uplog "-------------------- upx-hook.mk 全文 end --------------------"

uplog "-------------------- upx-rootfs.sh 全文 begin --------------------"
cat "$UPX_ROOTFS_SH" 2>&1 | uplog_block || true
uplog "-------------------- upx-rootfs.sh 全文 end --------------------"

uplog "-------------------- upx-hook.mk 关键行 --------------------"
grep -n 'UpXRootfsHook\|UPX_HOOK_ENABLE\|UPX_LOG\|UPX_ROOTFS_SCRIPT\|file parsed\|TARGET_DIR' "$UPX_HOOK_MK" 2>&1 | uplog_block || true

inject_rootfs_mk_include() {
    _file="include/rootfs.mk"
    if [ ! -f "$_file" ]; then
        uplog "inject rootfs.mk include: missing $_file"
        return 1
    fi
    if grep -qF 'include $(TOPDIR)/upx-hook.mk' "$_file"; then
        uplog "inject rootfs.mk include: already contains upx-hook.mk"
        return 0
    fi
    _tmp="$_file.upx.tmp.$$"
    awk 'BEGIN{done=0} { if (!done && index($0, "define prepare_rootfs") > 0) { print "include $(TOPDIR)/upx-hook.mk"; done=1 } print } END{ if(!done) exit 1 }' "$_file" > "$_tmp"
    _rc=$?
    if [ $_rc -eq 0 ]; then
        mv -f "$_tmp" "$_file"
        uplog "inject rootfs.mk include: success before define prepare_rootfs in $_file"
        return 0
    else
        rm -f "$_tmp"
        uplog "inject rootfs.mk include: define prepare_rootfs anchor not found in $_file"
        return 1
    fi
}

inject_prepare_rootfs_call() {
    _file="include/rootfs.mk"
    if [ ! -f "$_file" ]; then
        uplog "inject prepare_rootfs call: missing $_file"
        return 1
    fi
    if grep -qF '$(call UpXRootfsHook,$(1))' "$_file"; then
        uplog "inject prepare_rootfs call: already contains UpXRootfsHook call"
        return 0
    fi
    _line_num=$(grep -n '$(call mklibs,$(1))' "$_file" | head -1 | cut -d: -f1)
    if [ -z "$_line_num" ]; then
        uplog "inject prepare_rootfs call: mklibs anchor not found in $_file"
        return 1
    fi
    sed -i "${_line_num}a\\
\t\$(call UpXRootfsHook,\$(1))" "$_file"
    uplog "inject prepare_rootfs call: success after mklibs (line $_line_num) in $_file"
    return 0
}

inject_before_buildimage() {
    _file="$1"
    if [ ! -f "$_file" ]; then
        uplog "inject: missing $_file"
        return 1
    fi
    if grep -qF 'include $(TOPDIR)/upx-hook.mk' "$_file"; then
        uplog "inject: already contains upx-hook.mk in $_file"
        return 0
    fi
    _tmp="$_file.upx.tmp.$$"
    awk 'BEGIN{done=0} { if (!done && index($0, "$(eval $(call BuildImage))") > 0) { print "include $(TOPDIR)/upx-hook.mk"; done=1 } print } END{ if(!done) exit 1 }' "$_file" > "$_tmp"
    _rc=$?
    if [ $_rc -eq 0 ]; then
        mv -f "$_tmp" "$_file"
        uplog "inject: success before BuildImage in $_file"
        return 0
    else
        rm -f "$_tmp"
        uplog "inject: BuildImage anchor not found in $_file"
        return 1
    fi
}

uplog "-------------------- 注入 upx-hook.mk 到 include/rootfs.mk 开头 --------------------"
inject_rootfs_mk_include
ROOTFS_INCLUDE_INJECTED=$?

uplog "-------------------- 注入 UpXRootfsHook 调用到 prepare_rootfs --------------------"
inject_prepare_rootfs_call
PREPARE_CALL_INJECTED=$?

uplog "-------------------- 注入 upx-hook.mk 到 target image Makefile（冗余保护） --------------------"
UPX_INJECTED_COUNT=0
for mf in $CANDIDATE_IMAGE_MAKEFILES; do
    if inject_before_buildimage "$mf"; then
        UPX_INJECTED_COUNT=$((UPX_INJECTED_COUNT + 1))
    fi
done
uplog "UPX_INJECTED_COUNT=$UPX_INJECTED_COUNT"

uplog "-------------------- 注入后 include/rootfs.mk 上下文 --------------------"
{
    echo "===== head -20 include/rootfs.mk ====="
    head -20 include/rootfs.mk 2>&1 || true
    echo "===== grep upx-hook.mk in include/rootfs.mk ====="
    grep -n -B3 -A3 'upx-hook.mk' include/rootfs.mk 2>&1 || true
    echo "===== grep UpXRootfsHook in include/rootfs.mk ====="
    grep -n -B5 -A5 'UpXRootfsHook' include/rootfs.mk 2>&1 || true
} 2>&1 | uplog_block || true

uplog "-------------------- 注入后 target image Makefile 上下文 --------------------"
for mf in $CANDIDATE_IMAGE_MAKEFILES; do
    {
        echo "===== grep upx-hook.mk in $mf ====="
        grep -n -B5 -A5 'upx-hook.mk' "$mf" 2>&1 || true
    } 2>&1 | uplog_block || true
done

uplog "-------------------- 全局锚点扫描（增强版） --------------------"
{
    echo "===== BuildImage eval anchors ====="
    grep -RIn --include=Makefile -F '$(eval $(call BuildImage))' target/linux/*/image/Makefile 2>&1 || true
    echo "===== prepare_rootfs definitions ====="
    grep -RIn --include='*.mk' 'define prepare_rootfs' include target/linux 2>&1 || true
    echo "===== mklibs in prepare_rootfs ====="
    grep -RIn --include='*.mk' 'call mklibs' include target/linux 2>&1 || true
    echo "===== ROOTFS_POSTPROCESS_COMMAND ====="
    grep -RIn --include='*.mk' 'ROOTFS_POSTPROCESS_COMMAND' include target/linux 2>&1 || true
    echo "===== Image/Prepare ====="
    grep -RIn --include='*.mk' 'Image/Prepare' include target/linux 2>&1 || true
    echo "===== All calls to prepare_rootfs ====="
    grep -RIn --include='*.mk' 'call prepare_rootfs' . 2>/dev/null | head -20 || true
    echo "===== package/Makefile prepare_rootfs/opkg ====="
    grep -n 'prepare_rootfs\|opkg' package/Makefile 2>/dev/null || true
} 2>&1 | uplog_block || true

uplog "==================== UPX Hook 诊断+注入结束 ===================="
uplog "重点检查:"
uplog "1) include/rootfs.mk 开头是否出现 include $(TOPDIR)/upx-hook.mk"
uplog "2) make[2] package/install 后是否出现 [upx-mk] first include（说明 rootfs.mk include 生效）"
uplog "3) 是否出现 [upx] hook invoked rootfs=.../root-... 或 TARGET_DIR 路径"
uplog "4) 是否出现 [upx] also compressing TARGET_DIR=..."
uplog "5) upx-hook.log 是否同时有 TARGET_DIR 和 target-dir-* 的 SUMMARY"
uplog "6) ROOTFS_INCLUDE_INJECTED=$ROOTFS_INCLUDE_INJECTED PREPARE_CALL_INJECTED=$PREPARE_CALL_INJECTED"

true
# ==================== UPX HOOK DIAGNOSTIC + INJECTION END ====================