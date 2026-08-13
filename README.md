# Live Caption

一个免费、开源、完全在 Mac 本地运行的实时双语字幕应用。

## 当前功能

- 捕获 Mac 正在播放的系统音频，或切换到麦克风输入
- 使用 Apple 设备端语音识别生成实时原文
- 使用 Apple Translation 框架生成实时译文
- 原文与译文双语显示
- 字幕窗口始终置顶，可进入全屏空间
- 顶部提供独立拖动栏，便于随时调整字幕位置
- 长字幕自动保留最近内容、限制安全行数并平滑换行
- 可直接同步调整原文和译文字号、背景透明度并隐藏原文，设置会在重启后保留
- 原文和译文使用相同字号；译文自动换行后，仅最下面的新一行加粗强调
- 不需要账户、服务器、付费 API 或订阅
- 可选 CS2 解说词库，为设备端识别加入赛事术语、武器和地图提示词，并统一高频译法
- 可自动保存每次会话的原文和译文，生成 Markdown 与 JSON 复盘记录

## 系统要求

- macOS 15 或更高版本（推荐 macOS 26）
- Apple Silicon Mac
- 首次使用某种语言时需要联网下载 Apple 离线语音与翻译语言包

## 构建和运行

需要安装一套版本一致的 Xcode 或 Apple Command Line Tools：

```bash
./scripts/test.sh
./scripts/build-app.sh
open "dist/Live Caption.app"
```

项目同时保留了 `Package.swift` 和 Swift Testing 测试，安装完整 Xcode 后也可以使用：

```bash
swift test
swift run LiveCaption
```

为确保系统能显示麦克风和语音识别权限说明，日常使用建议运行打包后的 `.app`。

如果构建脚本提示开发工具不一致，请从 App Store 安装或更新 Xcode，然后执行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## 首次权限

应用会按所选输入请求以下权限：

- **语音识别**：把音频转换成文字
- **麦克风**：仅在选择麦克风输入时使用
- **屏幕与系统音频录制**：仅在选择电脑声音时使用；应用不会接收、保存或分析画面

如果曾拒绝权限，请前往“系统设置 → 隐私与安全性”重新允许，然后退出并重开应用。

开发版使用固定 Bundle ID 的稳定本地签名要求，使系统权限在后续重新构建时保持有效。若从旧版升级后系统设置显示已允许但应用仍提示拒绝，可执行：

```bash
tccutil reset ScreenCapture local.live-caption.app
```

然后重开应用并在系统提示中重新允许一次。

## 隐私

识别和翻译均使用 macOS 的设备端能力。应用不包含网络客户端，不上传音频或字幕，也不采集遥测数据。

## 复盘记录

开启“保存复盘”后，每次点击“开始”会创建一份独立记录，点击“停止”时定稿。记录位于：

```text
~/Documents/Live Caption Records/
```

Markdown 文件适合直接阅读，JSON 文件便于后续搜索、统计或导入其他工具。应用只保存原文和译文，不保存音频。

## 已知限制

- Apple Speech 识别前需要选择原语言，首版暂不自动判断语言。
- 系统音频权限首次授予后，macOS 可能要求重新启动应用。
- 并非 Apple Translation 支持的所有语言都一定拥有设备端 Speech 语言包。
