# GitHub SSH 一键配置脚本

这个脚本用于在 Linux 或 WSL 环境下快速完成 GitHub SSH Key 的本地配置，减少手动操作。

## 作用

脚本会自动完成以下事情：

- 检查必要依赖：`git`、`curl`、`openssh-client`
- 在本地生成或复用 SSH 密钥：`~/.ssh/id_ed25519_github`
- 启动 `ssh-agent` 并加载密钥
- 打开 GitHub 新增 SSH Key 页面
- 自动把公钥复制到剪贴板
- 在 WSL 下优先使用 Windows Edge 打开浏览器链接

> 说明：脚本负责帮你生成并复制公钥，但 GitHub 页面上的“添加 SSH Key”确认步骤仍需要你手动完成。

## 一句话调用

如果你已经把仓库内容放到可访问的位置，可以直接用下面这种方式执行：

```bash
curl -fsSL https://raw.githubusercontent.com/geekheart/mogon/main/github/github_ssh_setup.sh | bash
```

如果你是在本地仓库里执行，也可以直接运行脚本：

```bash
bash github_ssh_setup.sh
```

如果你想在 WSL 里运行并尽量自动打开浏览器，脚本会优先调用 Windows 侧的 Edge。

## 可操作参数

脚本通过环境变量来控制行为。你可以在命令前直接写参数，也可以先 `export` 再执行。

### `GITHUB_USER`

- 作用：指定 GitHub 用户名
- 默认值：`geekheart`
- 示例：

```bash
GITHUB_USER=geekheart bash github_ssh_setup.sh
```

### `KEY_NAME`

- 作用：指定 SSH 密钥文件名
- 默认值：`id_ed25519_github`
- 实际路径：`~/.ssh/${KEY_NAME}`
- 示例：

```bash
KEY_NAME=my_github_key bash github_ssh_setup.sh
```

### 环境变量写法说明

你可以把参数直接写在命令前面：

```bash
GITHUB_USER=geekheart KEY_NAME=id_ed25519_github bash github_ssh_setup.sh
```

也可以先导出再运行：

```bash
export GITHUB_USER=geekheart
export KEY_NAME=id_ed25519_github
bash github_ssh_setup.sh
```

## 后续如何操作

脚本执行完成后，按下面步骤继续：

1. 打开脚本自动弹出的 GitHub 页面：`https://github.com/settings/ssh/new`
2. 在页面中点击 `Add new SSH key`
3. 在 `Key` 输入框里粘贴已经复制到剪贴板的公钥
4. 填写标题
5. 点击确认保存
6. 回到终端，执行下面命令测试 SSH 是否可用：

```bash
ssh -T git@github.com
```

如果验证成功，GitHub 会返回欢迎信息。

## 注意事项

- 如果你第一次运行脚本时中断或失败，脚本会删除本次新生成的 SSH 密钥，避免留下半成品
- 如果系统里没有可用的剪贴板工具，脚本会提示你手动复制公钥
- 如果缺少依赖，脚本会尝试通过 `sudo apt-get` 自动安装
