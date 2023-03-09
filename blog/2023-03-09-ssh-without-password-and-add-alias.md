---
slug: ssh-without-password-and-add-alias
title: SSH免密登录及添加别名
authors: frankxii
tags: [ssh]
---

## 起因
这周重装了`win11`系统，所以需要重新配置一下连接腾讯云服务器的配置，且准备重新开始写博客，部署也需要用到`ssh`命令，所以重新设置了以下连接服务器的环境。写博客的理由在于像这种`ssh`配置快的话在网上找教程10来分钟就能搞定，但是总会遇到重装系统、换电脑、换工作的情况，所以自己记录一下方便后续使用。

## 前置条件
我在连接云服务器之前，已经安装了git并配置了`username`和`email`，并且生成了ssh key，这个比较简单且网上很多教程，就不详述，完成此前置条件的好处在于已经在用户.ssh文件夹下生成了ssh公钥和known_hosts文件，后续不用再生成ssh key

## 免密登录
```shell
# 首先使用用户名+ip的方式登录云服务器
ssh root@4x.1xx.1xx.1xx

# 再进入服务器ssh文件夹
cd ~/.ssh

# 使用vim编辑认证keys
vim authorized_keys
```
在`vim`里按`a`键可以开始编辑，粘贴本地客户端ssh公钥成功后，可按`esc`退出编辑模式，最后输入`:wq`完成保存

保存完成后退出再重新使用`ssh root@4x.1xx.1xx.1xx`就可以免密登录了

## 添加别名
光是免密登录就比较省事了，但是每次登录服务器还得输入用户名和公网ip，公网ip一般都记不住，经常需要在云服务器控制面板去查找，很麻烦，所以更方便的是为服务器配置一个别名

在本地客户端输入以下命令进入ssh文件夹，linux命令比较好记方便，可以使用git bash来输入此命令
```shell
# 进入ssh文件夹
cd ~/.ssh

# ls 查看是否有config文件
ls

# 如果没有config文件可使用以下命令创建
touch config
```
然后使用vim编辑config文件，输入以下内容
```shell
Host tencent
HostName 4x.1xx.1xx.1xx
User root
IdentitiesOnly yes
```
配置完成后同样使用`esc`退出编辑，并使用`:wq`保存，保存之后就可以使用以下命令直接免密登录了
```shell
ssh tencent
```

包括我的博客也可以使用scp+别名的方式直接同步，且不用担心暴露自己的ip
```shell
yarn build
scp -r ./build/* tencent:~/blog
```

## 参考
[SSH 三步解决免密登录](https://blog.csdn.net/jeikerxiao/article/details/84105529)

[Linux服务器别名设置](https://blog.csdn.net/Woody0729/article/details/79404247)