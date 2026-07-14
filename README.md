本项目fork自https://github.com/devome/r8125-dkms
原项目需要makedeb编译，但是makedeb已经停止更新无法正常安装
所以就请AI帮忙写了这个在线编译的Action

## 这是什么

RealTek R8125B 网卡驱动的 DKMS 版本，启用 TX 多队列，启用 RSS，禁用 ASPM。

为和 [官方仓库中的包](https://packages.debian.org/sid/r8125-dkms) 保持一致，从 9.013.02-2 起，本人维护的包名和Github仓库名都从 `realtek-r8125-dkms` 更改为 `r8125-dkms`。更新时直接安装新的包，安装时在提示卸载旧包时确认即可。

事实上，由Debian官方维护的 `r8125-dkms` 已经进入 [`sid` 仓库](https://packages.debian.org/unstable/r8125-dkms)和 [`bookworm` 仓库](https://packages.debian.org/bookworm/r8125-dkms)的 `non-free` Component，由Proxmox维护的 `r8125-dkms` 也已经进入 PVE 8.x的 `pve-no-subscription` Component（见[这里](http://download.proxmox.com/debian/pve/dists/bookworm/pve-no-subscription/binary-amd64)的r8125-dkms）。版本虽然相对会老一些，但针对他们所维护的内核是适配的。也就是说，你如果不想追新，你可以直接在sources.list中启用 `bookworm/non-free`（针对Debian bookworm），或者 `bookworm/pve-no-subscription` （针对PVE 8），然后直接安装 `r8125-dkms` 。

```
$ apt policy r8125-dkms
r8125-dkms:
  Installed: 9.011.00-4.1
  Candidate: 9.011.00-4.1
  Version table:
 *** 9.011.00-4.1 500
        500 http://download.proxmox.com/debian/pve bookworm/pve-no-subscription amd64 Packages
     9.011.00-3 500
        500 https://deb.debian.org/debian bookworm/non-free amd64 Packages
```

## 适用对象

适用于 Debian 和基于 Debian 的发行版。

## 如何使用

需要先安装以下两个包：

- `dkms`

- 内核的`headers`文件，比如 Debian 是`linux-headers-amd64`这个包，Proxmox VE 是`proxmox-default-headers`这个包（8.0.3+），其他发行版类似。

提供一个 Proxmox VE 安装本驱动的教程：https://evine.win/p/pve-install-realtek-8125-driver/

## 如何构建安装包

本项目提供了两种构建 Debian/Ubuntu 安装包 (`r8125-dkms_<version>_all.deb`) 的方法：

### 方法一：通过 GitHub Actions 在线构建（推荐，无需本地 Linux 环境）

本项目已经配置了自动化 GitHub Actions 工作流，你可以非常方便地在云端完成打包并下载。

1. **Fork 本仓库** 到你自己的 GitHub 账号下。
2. 在你 Fork 后的仓库页面中，点击顶部的 **Actions** 标签页，并启用 Workflows。
3. 在左侧列表选择 **Build r8125-dkms**。
4. 点击右侧的 **Run workflow** 下拉菜单：
   - **Optional direct URL to r8125 tarball**: 如果你有该驱动最新版本的直接下载直链，可以填入；如果不填，工作流将尝试自动读取仓库内的 `PKGBUILD` 版本，或从第三方托管的 Releases 获取。
   - **Optional driver version**: 欲打包的驱动版本号（例如 `9.018.00`），如果留空将自动从 `PKGBUILD` 读取。
   - **If "true", create a GitHub Release...**: 设为 `true`，构建成功后将自动在你的仓库创建一个 Release，你可以直接在 Release 页面下载打包好的 `.deb` 文件及源码包。
5. 点击 **Run workflow** 按钮，等待 1-2 分钟构建完成后，在生成的 Artifacts 或 Release 页面中下载 `.deb` 安装包。

---

### 方法二：在本地 Linux 系统一键构建

由于 `makedeb` 已经停止维护，本项目已移除对 `makedeb` 的依赖，并提供了一个基于纯 Bash 和 `dpkg-deb` 的超轻量本地一键打包脚本 `build.sh`。

只要你使用的是 Debian / Ubuntu 或基于其的系统（如 Proxmox VE），均可在本地一键打包：

1. **安装依赖**：
   在开始构建之前，请确保你的系统已经安装了以下必要的构建工具和依赖包：
   ```shell
   sudo apt update
   sudo apt install dkms build-essential linux-headers-amd64 \
                    dpkg-dev tar bzip2 curl wget
   ```
   *注：如果你使用的是 Proxmox VE 8.0.3+，请将 `linux-headers-amd64` 替换为 `proxmox-default-headers`。*

3. **准备驱动源码包**（任选其一，推荐第一种）：
   - **手动下载（推荐）**：由于 Realtek 官网加入了人机验证码，脚本可能无法直接从官网下载最新的源码。建议先前往 [Realtek 官网](https://www.realtek.com/Download/List?cate_id=584) 手动下载 `2.5G Ethernet LINUX driver r8125`（格式为 `.tar.bz2`，例如 `r8125-9.018.00.tar.bz2`），下载后直接放入本仓库的根目录下。
   - **自动下载**：如果本地没有检测到驱动压缩包，`build.sh` 脚本在运行时也会尝试从已知的公共 Release 节点自动下载对应版本的源码。

2. **给脚本赋予执行权限并运行**：
   ```shell
   chmod +x build.sh
   ./build.sh
   ```
   *注：如果你想打包特定版本（如 `9.018.00`），也可以直接作为参数传入：`./build.sh 9.018.00`*

3. **安装生成的软件包**：
   构建完成后，会在根目录下生成 `r8125-dkms_<version>-1_all.deb`。运行以下命令即可安装：
   ```shell
   sudo dpkg -i r8125-dkms_*.deb
   ```
