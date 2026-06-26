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

## 如何自己编译

直接使用 [makedeb](https://docs.makedeb.org/) 来构建安装包，简单方便。先安装 [makedeb](https://docs.makedeb.org/)，然后在本仓库根目录下运行以下命令即可编译产生`r8125-dkms_<version>_all.deb`。

```shell
makedeb
```

注：现在RealTEK针对下载驱动启用了验证码验证，所以 [makedeb](https://docs.makedeb.org/) 无法自动下载RealTEK的驱动源码压缩包，这时，你需要自行前往 [官网](https://www.realtek.com/Download/List?cate_id=584) 将 `2.5G Ethernet LINUX driver r8125` 驱动手动下载到仓库根目录，然后再运行上述命令。
