# 安装 Live Caption

[English](INSTALL.md) · [返回中文 README](README.zh-CN.md)

## 系统要求

- Apple Silicon Mac
- macOS 15 或更高版本（推荐 macOS 26）
- 首次下载应用和 Apple 语言包时需要联网

## 从 GitHub Releases 安装

1. 打开项目的 [GitHub Releases](https://github.com/BGuoMax/live-caption/releases) 页面。
2. 打开最新版本，下载名称类似下面的两个文件：

   ```text
   Live-Caption-v0.1.0-macOS-arm64.zip
   Live-Caption-v0.1.0-macOS-arm64.zip.sha256
   ```

3. 打开“终端”，在运行应用前校验下载文件：

   ```bash
   cd ~/Downloads
   shasum -a 256 -c Live-Caption-v0.1.0-macOS-arm64.zip.sha256
   ```

   将 `v0.1.0` 换成实际下载的版本号。只有结果显示 `OK` 时才继续。

4. 双击 ZIP 文件解压，将 **Live Caption.app** 拖入“应用程序”文件夹。
5. 从“应用程序”打开 **Live Caption**。

## 首次打开与 Gatekeeper

当前社区构建使用临时本地签名，尚未使用 Apple Developer ID 签名，也未经 Apple 公证，因此 macOS 可能会拦截首次启动。

只有在发布包来自本项目官方 Releases 页面，且校验结果通过时，才建议执行以下操作：

1. 先尝试打开一次 **Live Caption**，然后关闭警告。
2. 打开“系统设置 → 隐私与安全性”。
3. 滚动到“安全性”，在 Live Caption 旁边点击“仍要打开”。
4. 再次点击“打开”，并按需要进行身份验证。

Apple 在[安全打开 Mac App](https://support.apple.com/102445) 中解释了这项保护机制和例外流程。未来配置 Developer ID 与 Apple 公证后，可以去掉这个额外步骤。

## 下载语言资源

Live Caption 使用 Apple 的设备端语音识别和翻译，因此 macOS 中必须存在对应的语言资源。

### 原文语音识别

下载音频中实际使用的原文语言：

1. 打开“系统设置 → 键盘”。
2. 打开“听写”。
3. 打开“语言”并添加原文语言。
4. 保持联网，等待 macOS 完成下载。

### 翻译

原文和译文两种语言都需要下载：

1. 打开“系统设置 → 通用 → 语言与地区”。
2. 点击“翻译语言”。
3. 下载原文语言和译文语言。
4. 打开“设备端模式”，然后点击“完成”。

并非 Apple Translation 支持的所有语言都一定拥有对应的设备端 Speech 语言包。

## 授予权限

启动 Live Caption 并选择声音来源。macOS 只会按当前声音来源请求所需权限：

- **语音识别**：将捕获到的音频转换为原文。
- **麦克风**：仅在选择麦克风时需要。
- **屏幕与系统音频录制**：仅在选择电脑声音时需要；Live Caption 会排除屏幕画面，只处理音频。

如果曾经拒绝某项权限，请打开“系统设置 → 隐私与安全性”，在对应项目中允许 Live Caption，然后完全退出并重新打开应用。

如果是旧开发版遗留的系统音频权限，可以执行：

```bash
tccutil reset ScreenCapture local.live-caption.app
```

重新打开应用并再次允许。

## 从源码构建

安装 Xcode 或 Apple Command Line Tools，然后执行：

```bash
git clone https://github.com/BGuoMax/live-caption.git
cd live-caption
./scripts/test.sh
./scripts/build-app.sh
open "dist/Live Caption.app"
```

构建完成的应用位于 `dist/Live Caption.app`。

## 发布新版本（维护者）

仓库工作流会在推送语义化版本标签后，自动测试、构建、临时签名、压缩、生成校验值并发布应用：

```bash
git switch main
git pull --ff-only
git tag -a v0.1.0 -m "Live Caption v0.1.0"
git push origin v0.1.0
```

每次发布都要使用新版本号。也可以打开“GitHub → Actions → Build and publish release → Run workflow”，手动输入版本标签。

工作流会把 Apple Silicon ZIP 和对应的 SHA-256 校验文件附加到 GitHub Release。Developer ID 签名与 Apple 公证尚未配置，因为这需要 Apple Developer Program 身份和仓库密钥。
