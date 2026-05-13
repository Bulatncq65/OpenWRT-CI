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
    local repo_url="https://github.com/GuNanOvO/openwrt-tailscale.git"
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
    #if ! sed -i '/\/builder/d' "$target_dir/Makefile"; then
    #    echo "错误：修改 Makefile 失败" >&2
    #    exit 1
    #fi
    # 清除临时文件夹的残留
    rm -rf "$tmp_dir"
    
    echo "使用GuNanOvO/openwrt-tailscale的tailscale！" 
}

#update_tailscale

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=1.94.2" $TS_FILE
#	sed -i "/PKG_RELEASE:=/cPKG_RELEASE:=1" $TS_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=c45975beb4cb7bab8047cfba77ec8b170570d184f3c806258844f3e49c60d7aa" $TS_FILE
	sed -i '/\/files/d' $TS_FILE
    cat $TS_FILE
	echo " "
	cd $PKG_PATH && echo "tailscale 使用1.94.2版本"
fi

Xray_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/xray-core/Makefile")
if [ -f "$Xray_FILE" ]; then
	echo " "
	sed -i "/PKG_VERSION:=/cPKG_VERSION:=26.5.9" $Xray_FILE
	sed -i "/PKG_HASH:=/cPKG_HASH:=2cbd37f70b246d93aa4f1f5d4261cf2e622ff78ca71a7f7a4271aa517e749025" $Xray_FILE

	cd $PKG_PATH && echo "xray-core version has update to 26.5.9!"
fi


#升级easytier 
easytier_FILE=$(find ./luci-app-easytier/ -maxdepth 3 -type f -wholename "*/easytier/Makefile")
if [ -f "$easytier_FILE" ]; then
	echo " "

#    sed -i 's/EASYTIER_VERSION),2.6.2/EASYTIER_VERSION),2.6.4/g' $easytier_FILE
	sed -i '/^PKG_VERSION:=\$(or \$(EASYTIER_VERSION),/cPKG_VERSION:=$(or $(EASYTIER_VERSION),2.6.4)' $easytier_FILE
    cat $easytier_FILE
	echo " "
	cd $PKG_PATH && echo "easytier-core version has update to 2.6.4!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
