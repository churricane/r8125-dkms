#!/bin/bash
# ---------------------------------------------------------------------------------
# r8125-dkms Debian 软件包本地构建脚本 (无需 makedeb)
# ---------------------------------------------------------------------------------
set -euo pipefail

# 1. 自动获取版本号 (优先从 PKGBUILD 中读取，也可以通过环境变量或参数传入)
PKGVER=""
if [ -n "${1-}" ]; then
    PKGVER="$1"
elif [ -f PKGBUILD ]; then
    PKGVER=$(grep -m1 '^pkgver=' PKGBUILD | sed -E 's/pkgver=(.*)/\1/' || true)
fi

if [ -z "$PKGVER" ]; then
    echo "错误：无法自动获取版本号，请指定版本参数。例如: ./build.sh 9.018.00" >&2
    exit 1
fi

PKGNAME="r8125-dkms"
PKGVER_FULL="${PKGVER}-1"
OUTPUT_DEB="${PKGNAME}_${PKGVER_FULL}_all.deb"

echo "=== 开始构建 ${PKGNAME} (${PKGVER_FULL}) ==="

# 2. 检查依赖命令
for cmd in dpkg-deb tar sed mkdir chmod install grep; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "错误：本地缺少必需的命令 '${cmd}'，请先安装相关工具包（如 apt-get install dpkg-dev tar）。" >&2
        exit 1
    fi
done

# 3. 寻找驱动源码包
DRIVER_TAR=""
# 寻找当前目录下形如 r8125-9.018.00.tar.bz2 或 r8125-*.tar.* 的文件
if [ -f "r8125-${PKGVER}.tar.bz2" ]; then
    DRIVER_TAR="r8125-${PKGVER}.tar.bz2"
elif [ -f "r8125-${PKGVER}.tar.gz" ]; then
    DRIVER_TAR="r8125-${PKGVER}.tar.gz"
elif [ -f "r8125-${PKGVER}.tar.xz" ]; then
    DRIVER_TAR="r8125-${PKGVER}.tar.xz"
else
    # 模糊匹配
    FUZZY_TAR=$(ls r8125-*.tar.* 2>/dev/null | head -n1 || true)
    if [ -n "$FUZZY_TAR" ]; then
        DRIVER_TAR="$FUZZY_TAR"
        echo "未找到精确版本包，但找到源码包: ${DRIVER_TAR}，将使用它进行构建"
    fi
fi

# 如果找不到驱动包，尝试从 GitHub 上自动下载
if [ -z "$DRIVER_TAR" ]; then
    # 尝试从本项目或其他项目的 Release 页面自动下载
    DOWNLOAD_URL="https://github.com/devome/r8125-dkms/releases/download/${PKGVER}-1/r8125-${PKGVER}.tar.bz2"
    echo "本地没有找到 r8125-${PKGVER}.tar.bz2 源码包。"
    echo "尝试从以下地址下载: ${DOWNLOAD_URL}"
    if command -v curl &>/dev/null; then
        if curl -L --fail -o "r8125-${PKGVER}.tar.bz2" "$DOWNLOAD_URL"; then
            DRIVER_TAR="r8125-${PKGVER}.tar.bz2"
            echo "下载成功！"
        fi
    elif command -v wget &>/dev/null; then
        if wget -O "r8125-${PKGVER}.tar.bz2" "$DOWNLOAD_URL"; then
            DRIVER_TAR="r8125-${PKGVER}.tar.bz2"
            echo "下载成功！"
        fi
    fi
fi

if [ -z "$DRIVER_TAR" ]; then
    echo "=========================================================================" >&2
    echo "错误：无法获取 R8125 源码压缩包！" >&2
    echo "由于 Realtek 官网经常有验证码阻挡自动下载，请按照以下任一方式提供源码包：" >&2
    echo "  1. 前往 Realtek 官网下载 '2.5G Ethernet LINUX driver r8125'" >&2
    echo "     并将其重命名为 'r8125-${PKGVER}.tar.bz2' 放到当前仓库根目录下。" >&2
    echo "  2. 手动下载其它第三方托管的 'r8125-${PKGVER}.tar.bz2' 到当前根目录下。" >&2
    echo "=========================================================================" >&2
    exit 1
fi

# 4. 创建打包目录结构
WORK_DIR="packdir"
echo "正在清理并创建临时打包目录: ${WORK_DIR}..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/DEBIAN"

# 5. 生成控制文件 (control)
if [ -f .CONTROL ]; then
    echo "正在基于 .CONTROL 生成 DEBIAN/control..."
    sed "s/^Version:.*/Version: ${PKGVER_FULL}/" .CONTROL > "$WORK_DIR/DEBIAN/control"
else
    echo "正在生成默认 DEBIAN/control..."
    printf '%s\n' \
      "Package: ${PKGNAME}" \
      "Version: ${PKGVER_FULL}" \
      "Section: non-free/kernel" \
      "Priority: optional" \
      "Architecture: all" \
      "Depends: dkms" \
      "Maintainer: Local Builder" \
      "Description: dkms source for the r8125 network driver" \
      > "$WORK_DIR/DEBIAN/control"
fi

# 6. 处理维护脚本
if [ -f postinst.sh ]; then
    echo "安装 postinst 脚本..."
    install -Dm755 postinst.sh "$WORK_DIR/DEBIAN/postinst"
fi
if [ -f prerm.sh ]; then
    echo "安装 prerm 脚本..."
    install -Dm755 prerm.sh "$WORK_DIR/DEBIAN/prerm"
fi

# 7. 解压并平铺驱动源码
SRCDIR="$WORK_DIR/usr/src/r8125-${PKGVER}"
mkdir -p "$SRCDIR"

TEMP_EXTRACT="temp_extracted"
rm -rf "$TEMP_EXTRACT"
mkdir -p "$TEMP_EXTRACT"

echo "正在解压驱动源码包: ${DRIVER_TAR}..."
tar -xf "$DRIVER_TAR" -C "$TEMP_EXTRACT"

# 寻找解压出的源码子目录下的 src 目录
# 目录名一般是 r8125-9.018.00 或类似
EXTRACTED_DIR=$(find "$TEMP_EXTRACT" -maxdepth 1 -type d -name "r8125-*" | head -n1)
if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR/src" ]; then
    echo "错误：无法在源码包中找到 src 目录。结构可能不匹配。" >&2
    rm -rf "$TEMP_EXTRACT"
    exit 1
fi

echo "正在平铺源码文件到 ${SRCDIR}..."
cp -r "$EXTRACTED_DIR"/src/* "$SRCDIR/"

# 8. 生成并写入 dkms.conf
if [ -f dkms.conf ]; then
    echo "生成 dkms.conf 并替换版本占位符..."
    sed "s/@PKGVER@/${PKGVER}/g" dkms.conf > "$SRCDIR/dkms.conf"
else
    echo "警告：未找到本地的 dkms.conf 文件！" >&2
fi

# 9. 安装文档 README
if [ -f README.md ]; then
    install -Dm644 README.md "$WORK_DIR/usr/share/doc/${PKGNAME}/README"
elif [ -f "$EXTRACTED_DIR/README" ]; then
    install -Dm644 "$EXTRACTED_DIR/README" "$WORK_DIR/usr/share/doc/${PKGNAME}/README"
fi

# 10. 清理临时解压目录
rm -rf "$TEMP_EXTRACT"

# 11. 正确设置权限
echo "正在修正打包文件权限..."
find "$WORK_DIR" -type d -print0 | xargs -0 chmod 755 || true
find "$WORK_DIR" -type f -print0 | xargs -0 chmod 644 || true
[ -f "$WORK_DIR/DEBIAN/postinst" ] && chmod 755 "$WORK_DIR/DEBIAN/postinst" || true
[ -f "$WORK_DIR/DEBIAN/prerm" ] && chmod 755 "$WORK_DIR/DEBIAN/prerm" || true

# 12. 构建包
echo "正在使用 dpkg-deb 构建软件包 ${OUTPUT_DEB}..."
dpkg-deb --build "$WORK_DIR" "$OUTPUT_DEB"

# 清理工作目录
rm -rf "$WORK_DIR"

echo "====================================================="
echo "构建成功！"
echo "生成的软件包: $(pwd)/${OUTPUT_DEB}"
echo "您可以使用以下命令在目标 Linux 机器上安装它："
echo "  sudo dpkg -i ${OUTPUT_DEB}"
echo "====================================================="
