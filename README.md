# Folia Apple Music 接入补丁（实验版）

为 **Windows 官方 Folia 0.7.25** 增加 Apple Music 连接入口。安装后，在 Folia 的「连接在线平台」中选择 **Apple Music**，使用自己的订阅账号在应用内的 Apple 官方页面登录，即可尝试浏览歌库、选歌、播放和使用 Folia 歌词界面。

> 这是社区实验补丁，并非 Folia 或 Apple 官方产品，也不是通用 Folium 插件。它替换经过校验的应用文件，只适配指定的 0.7.25 Windows 官方构建；不能承诺其他版本或每个账号都能正常播放。

## 原作者与许可

Folia 由 **[chthollyphile（冬霧）及原项目贡献者](https://github.com/chthollyphile/folia-major)** 开发。本项目基于原项目 [v0.7.25](https://github.com/chthollyphile/folia-major/releases/tag/v0.7.25)，按 [AGPL-3.0](LICENSE) 发布修改后的源码。原项目说明和贡献者名单分别见[原项目说明](https://github.com/chthollyphile/folia-major/blob/v0.7.25/README.md)和[贡献者名单](https://github.com/chthollyphile/folia-major/blob/v0.7.25/CONTRIBUTORS.md)。

## 下载并安装

1. 从 [Folia 官方发布页](https://github.com/chthollyphile/folia-major/releases/tag/v0.7.25)安装 **Windows 官方 0.7.25**，先运行并退出 Folia（包括托盘）。
2. 从本仓库的 [Releases](../../releases) 下载 `Folia-AppleMusic-0.7.25-windows-experimental.zip`，完整解压。不要使用 GitHub 的 “Source code” 下载来直接安装补丁。
3. 安装 [Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)，并准备有效的 Apple Music 订阅。
4. 双击解压目录中的「检查兼容性.cmd」。只有显示兼容时，才双击「安装补丁.cmd」。安装器会检查特定版本的文件哈希、备份原应用文件，并拒绝覆盖不匹配的构建。
5. 启动 Folia，打开「连接在线平台」→ **Apple Music**，在内嵌的 Apple 官方页面登录。歌库和歌单加载后，即可尝试选择并播放歌曲。歌词舞台和歌词样式仍从 Folia 界面进入。

默认查找 `%LOCALAPPDATA%\Programs\Folia`。安装目录不同时，可在解压后的目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Action install -InstallDir 'Folia 的完整安装目录'
```

发行包 SHA-256：`A74747C0593842F761DEC2203C2C1413446D730A54825F7EDBFB77CB745D53BE`。文件哈希用于核对文件一致性，不代表数字签名或官方背书。

## 已验证与限制

- 在一台 Windows 电脑的既有登录会话中，验证了歌库、播放进度、暂停、切歌、歌词样式，以及随机抽取的 10 首歌曲开始播放且进度前进；未将每首歌从头听到结束。
- 另一独立登录会话曾能读取歌库，却不能播放测试歌曲；部分歌曲也曾返回空播放队列。**登录成功不保证所有歌曲或所有电脑均可播放。**
- Apple Music 音频由官方网页播放器处理。Folia 中依赖原始音频数据的频谱、均衡器和自动混音等功能不能保证与其他音源相同；歌词和翻译的可用性也因歌曲而异。
- 补丁禁用 Folia 自动更新以避免被覆盖；升级 Folia 前应先恢复原版，并确认新版补丁的兼容性。它不会自动适配未知版本。
- 不提供音乐文件、Apple 登录信息或解密后的音频。请在 Apple 官方页面自行登录，勿向他人提供密码、验证码或令牌。

## 恢复原版

退出 Folia 后运行「卸载补丁.cmd」。安装器核验备份后恢复原应用文件；设置、歌库、Apple 登录会话及播放器组件保留。若应用文件或备份不匹配，安装器会停止，避免覆盖未知改动。

## 源码

Release 安装包中的 `完整源代码.zip` 包含对应的修改后 Folia 0.7.25 源码；其中 `electron/apple/host/` 为 Windows WebView2 播放宿主。`installer/` 是安装器脚本和组件清单，其二进制负载在 Release 安装包中。安装包同时附带对应的许可文本。构建需要 Node.js 24、项目依赖、.NET 9 和 WebView2 SDK；此仓库目前没有一键生成发行包的构建流程。

---

Unofficial experimental Apple Music integration for the verified Windows build of Folia 0.7.25. Install the original Folia release first, download the patch ZIP from Releases, run the compatibility check and installer, then choose **Apple Music** from Folia's online platform connection dialog. Playback availability and audio-analysis features differ by account and source; see the limitations above.

