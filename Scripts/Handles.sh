#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

#修改argon主题字体和颜色
if [ -d "$PACKAGE_PATH/luci-theme-argon" ]; then
	echo " "
	if sed -i "s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
		"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"; then
		echo "theme-argon has been fixed!"
	else
		echo "theme-argon fix failed; continuing!"
	fi
fi

#修改aurora菜单式样
if [ -d "$PACKAGE_PATH/luci-app-aurora-config" ]; then
	echo " "
	if find "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec \
		sed -i "s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +; then
		echo "theme-aurora has been fixed!"
	else
		echo "theme-aurora fix failed; continuing!"
	fi
fi

#修改mini-diskmanager菜单位置
if [ -d "$PACKAGE_PATH/luci-app-mini-diskmanager" ]; then
	echo " "
	if sed -i "s/services/system/g" \
		"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"; then
		echo "mini-diskmanager has been fixed!"
	else
		echo "mini-diskmanager fix failed; continuing!"
	fi
fi

#修改natmapt菜单位置
if [ -d "$PACKAGE_PATH/luci-app-natmapt" ]; then
	echo " "
	if sed -i "s/network/services/g" \
		"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"; then
		echo "natmapt has been fixed!"
	else
		echo "natmapt fix failed; continuing!"
	fi
fi

#修复Rust编译失败
if [ -d "$FEEDS_PATH/packages/lang/rust" ]; then
	echo " "
	if sed -i 's/ci-llvm=true/ci-llvm=false/g' \
		"$FEEDS_PATH/packages/lang/rust/Makefile"; then
		echo "rust has been fixed!"
	else
		echo "rust fix failed; continuing!"
	fi
fi



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
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=26.9.9" $XRAY_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=efb871a981690688191433a76beef7afdab6750d53cc1775cf8e9e995730ef22" $XRAY_FILE
	echo "xray-core version has update to 26.9.9!"
   #add_upx_compress "$XRAY_FILE" "xray" "usr/bin" && echo "xray 将被压缩"
	echo " "
    echo "---- xray-core_Makefile内容 start ----"
    cat $XRAY_FILE
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
    cat $MIHOMO_META_FILE
    echo "---- mihomo-meta_Makefile内容 end ----"
	echo " "
    echo "---- mihomo-alpha_Makefile内容 start ----"
    cat $MIHOMO_ALPHA_FILE
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
    cat $SING_BOX_FILE
    echo "---- sing-box_Makefile内容 end ----"
	echo " "
fi



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

#修复TailScale配置文件冲突
TS_FILE="$(find "$FEEDS_PATH/packages" -maxdepth 3 -type f -wholename '*/tailscale/Makefile' -print -quit 2>/dev/null)"
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
   #add_upx_compress "$TS_FILE" "tailscaled" "usr/sbin" && echo "tailscaled 将被压缩"
    echo "---- tailscale_Makefile内容 start ----"
    cat $TS_FILE
    echo "---- tailscale_Makefile内容 end ----"
    echo " "
fi
