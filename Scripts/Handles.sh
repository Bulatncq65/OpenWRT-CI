#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改aurora菜单式样
if [ -d *"luci-app-aurora-config"* ]; then
	echo " " && cd ./luci-app-aurora-config/

	sed -i "s/nav_submenu_type '.*'/nav_submenu_type 'boxed-dropdown'/g" $(find ./root/usr/share/aurora/ -type f -name "*.template")

	cd $PKG_PATH && echo "theme-aurora has been fixed!"
fi

#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	echo " "

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	cd $PKG_PATH && echo "qca-nss-drv has been fixed!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	echo " "

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	cd $PKG_PATH && echo "qca-nss-pbuf has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
#if [ -f "$TS_FILE" ]; then
#	echo " "
#	sed -i "/PKG_VERSION:=1.9/cPKG_VERSION:=1.94.2" $TS_FILE
#	sed -i "/PKG_HASH:=/cPKG_HASH:=c45975beb4cb7bab8047cfba77ec8b170570d184f3c806258844f3e49c60d7aa" $TS_FILE
#	sed -i '/\/files/d' $TS_FILE
#
#	cd $PKG_PATH && echo "tailscale has been fixed!"
#fi

if [ -f "$TS_FILE" ]; then
echo 'include $(TOPDIR)/rules.mk

PKG_NAME:=tailscale
PKG_VERSION:=1.98.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/tailscale/tailscale/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=7a789d593996bf375ebb2d60bb2de0dee62e760349af8725e9af981b622971a5

PKG_MAINTAINER:=GuNan <gunanovo@gmail.com>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:tailscale:tailscale

PKG_BUILD_DIR:=$(BUILD_DIR)/tailscale-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=tailscale.com/cmd/tailscaled
GO_PKG_LDFLAGS:=-s -w -X '"'"'tailscale.com/version.longStamp=$(PKG_VERSION)-$(PKG_RELEASE) (OpenWrt-UPX)'"'"'
GO_PKG_LDFLAGS_X:=tailscale.com/version.shortStamp=$(PKG_VERSION)
GO_PKG_TAGS:=ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient

ifneq ($(filter mips64% riscv64% loongarch64%,$(ARCH)),)
  DISABLE_UPX:=1
endif

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/tailscale
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=Zero config VPN (UPX Compressed)
  URL:=https://github.com/GuNanOvO/openwrt-tailscale
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +kmod-tun
  PROVIDES:=tailscale tailscaled
endef

define Package/tailscale/description
  A smaller version of Tailscale. Built for OpenWrt.
  It creates a secure network between your servers, computers,
  and cloud instances. Even when separated by firewalls or subnets.
endef

define Package/tailscale/conffiles
/etc/config/tailscale
/etc/tailscale/
endef

define Package/tailscale/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/tailscaled $(1)/usr/sbin

ifneq ($(DISABLE_UPX),1)
	if ! $(TOPDIR)/upx/upx -t $(GO_PKG_BUILD_BIN_DIR)/tailscaled >/dev/null 2>&1; then \
		echo "==> UPX enabling on ARCH $(ARCH)"; \
		$(TOPDIR)/upx/upx --best --lzma $(GO_PKG_BUILD_BIN_DIR)/tailscaled; \
	else \
		echo "==> UPX already compressed on ARCH $(ARCH)"; \
	fi
else
	echo "==> UPX disabled on ARCH $(ARCH)"
endif
	# [Maintainer Note] Save a copy of the binary for the repository. 
    # Feel free to remove the next two lines for local builds.
	# 可选：以下两行仅用于为本项目仓库保留一份二进制副本，自行使用时可删除
	mkdir -p $(TOPDIR)/bin/packages/$(ARCH_PACKAGES)/base
	$(CP) $(GO_PKG_BUILD_BIN_DIR)/tailscaled $(TOPDIR)/bin/packages/$(ARCH_PACKAGES)/base/tailscaled

	$(LN) tailscaled $(1)/usr/sbin/tailscale
	$(INSTALL_BIN) ./tailscale.init $(1)/etc/init.d/tailscale
	$(INSTALL_DATA) ./tailscale.conf $(1)/etc/config/tailscale
endef

$(eval $(call BuildPackage,tailscale))
' > $TS_FILE
	cd $PKG_PATH && echo "tailscale has been fixed!"
fi


#升级easytier 
easytier_FILE=$(find ./luci-app-easytier/ -maxdepth 3 -type f -wholename "*/easytier/Makefile")
if [ -f "$easytier_FILE" ]; then
	echo " "

	sed -i 's/EASYTIER_VERSION),2.6.2/EASYTIER_VERSION),2.6.3/g' $easytier_FILE

	cd $PKG_PATH && echo "easytier version is already the latest!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
