# SSH密钥配置指南

## 问题说明

如果你使用SSH密钥登录服务器，Windows的scp命令需要能找到你的密钥文件。

## 方法一：使用默认密钥位置（推荐）

如果你的SSH密钥在默认位置，scp会自动使用：

**默认位置：**
```
C:\Users\你的用户名\.ssh\id_rsa
```

**测试是否能连接：**
```bash
ssh root@139.224.200.133
```

如果能直接登录（不需要输入密码），说明密钥配置正确，bat脚本可以直接使用。

## 方法二：指定密钥文件

如果密钥不在默认位置，需要修改bat脚本。

### 1. 找到你的密钥文件

例如：`D:\keys\my_server_key.pem`

### 2. 修改bat脚本

打开 `一键更新数据.bat`，找到这一行：
```batch
scp approval_data.json %SERVER_USER%@%SERVER_IP%:/var/www/approval-viewer/approvalquery/
```

改成：
```batch
scp -i "D:\keys\my_server_key.pem" approval_data.json %SERVER_USER%@%SERVER_IP%:/var/www/approval-viewer/approvalquery/
```

## 方法三：使用密码登录

如果不想配置密钥，可以使用密码登录：

1. 运行bat脚本
2. 当提示输入密码时，输入服务器密码
3. 按回车

**注意：** 每次都需要输入密码。

## 方法四：配置SSH config（最方便）

### 1. 创建或编辑SSH配置文件

文件位置：`C:\Users\你的用户名\.ssh\config`

### 2. 添加配置

```
Host myserver
    HostName 139.224.200.133
    User root
    IdentityFile D:\keys\my_server_key.pem
```

### 3. 修改bat脚本

把服务器IP改成 `myserver`：
```batch
scp approval_data.json myserver:/var/www/approval-viewer/approvalquery/
```

### 4. 测试

```bash
ssh myserver
```

应该能直接登录。

## 推荐方案

**最简单：** 把密钥放到默认位置 `C:\Users\你的用户名\.ssh\id_rsa`

**最方便：** 配置SSH config文件

## 测试连接

运行这个命令测试：
```bash
ssh root@139.224.200.133 "echo 连接成功"
```

如果显示"连接成功"，说明配置正确。

## 常见问题

### Q: 提示"Permission denied"

**原因：** 密钥权限不对或找不到密钥

**解决：**
1. 检查密钥文件是否存在
2. 确保密钥文件权限正确
3. 尝试手动SSH连接测试

### Q: 提示"Host key verification failed"

**原因：** 首次连接服务器

**解决：**
```bash
ssh root@139.224.200.133
# 输入 yes 确认
```

### Q: 每次都要输入密码

**原因：** 密钥未配置或配置不对

**解决：** 按照上面的方法配置密钥

## 如果实在搞不定

**备用方案：** 直接在服务器上更新数据

```bash
# 1. 用FTP工具上传Excel到服务器
# 2. SSH登录服务器
ssh root@139.224.200.133

# 3. 运行更新脚本
cd /var/www/approval-viewer/approvalquery
bash daily_update.sh 线上建店审批.xlsx
```

这样就不需要配置Windows的SSH了。
