# DaveTheTrainer

<p align="center">
  <img src="Assets/AppIcon/DaveTheTrainerIcon.png" width="144" alt="DaveTheTrainer 应用图标">
</p>

<p align="center">
  面向 macOS 版 <code>DAVE THE DIVER</code> 的 manifest 驱动修改器。
</p>

<p align="center">
  <a href="README.md">English README</a> ·
  <a href="https://github.com/Empress7211/DaveTheTrainer/releases/latest">下载最新版</a>
</p>

DaveTheTrainer 是一个原生 macOS SwiftUI 修改器。它不是通用内存扫描器，也不是
Cheat Engine 风格工具。玩家按钮都绑定到已审查的 manifest feature、已验证的
Mach-O 模块形态、确定的补丁点或运行时对象路径。`v1.0.6.675.mac` 是已完整验证的
基线 profile，不是全局兼容性开关。

> 本项目与 MINTROCKET、Nexon 或 `DAVE THE DIVER` 创作者没有隶属、赞助、
> 背书或官方合作关系。

## 项目状态

| 项目 | 状态 |
| --- | --- |
| 平台 | macOS |
| 应用类型 | 原生 SwiftUI app |
| 包管理 | Swift Package Manager |
| 已验证基线版本 | `v1.0.6.675.mac` |
| 目标模块 | `GameAssembly.dylib` |
| Manifest schema | `1.0` |
| 测试 | 覆盖 manifest 策略、事务补丁、运行时增量、发布脚本和玩家路径契约 |
| 协议 | MIT |

## 下载和安装

预构建 `.app` zip 发布在
[GitHub Releases](https://github.com/Empress7211/DaveTheTrainer/releases)。

当前 Release 包是 ad-hoc signed，未经过 Apple notarization。因此 macOS 首次
打开时可能提示“无法验证开发者”或阻止启动。请先阅读源码和 Release notes，再决定是否运行。

安装步骤：

1. 从最新 Release 下载 `DaveTheTrainer-v0.1.0-macOS.zip`。
2. 解压 zip。
3. 把 `DaveTheTrainer.app` 移动到 `/Applications` 或 `$HOME/Applications`。
4. 启动 macOS 版 `DAVE THE DIVER`。
5. 打开 `DaveTheTrainer.app`。

如果 Gatekeeper 阻止首次启动，优先使用 Finder 右键 `Open` 流程。如果你已经审查并信任该下载包，也可以移除 quarantine：

```bash
xattr -dr com.apple.quarantine /Applications/DaveTheTrainer.app
```

## 兼容性边界

兼容性是功能级、验证驱动的。当前仓库完整验证的基线是 `v1.0.6.675.mac`；Steam
或其他渠道更新后的 Mac build 也可能有部分功能可用，但必须由该功能自己的 locator、
目标校验、写入和读回校验逐项证明。

游戏版本号、build GUID、Mach-O UUID 和 metadata 信息只作为 profile 选择和诊断信号。
某个功能定位不到或校验失败时，该功能会明确失败，不会把失败伪装成成功。

## 功能范围

当前面向玩家的功能包括：

- 潜水补丁：无敌、氧气、弹药、螃蟹陷阱、负重、伤害、无人机、游速。
- 货币：金币、贝、丛林金币、匠人火焰。
- 背包：主线食材、分类食材、丛林 DLC 已有物品、鲛人村/丛林村庄已有物品。
- 寿司店：体力和芥末相关补丁。

背包功能默认只修改已有条目，除非 manifest 明确声明支持创建条目。缺失根对象、
缺失条目、目标不匹配和写后校验失败都会显式失败，不会假装成功。

## 使用方式

1. 先启动 macOS 版 `DAVE THE DIVER`。
2. 启动 `DaveTheTrainer`。
3. 确认修改器检测到游戏进程和 build fingerprint。
4. 只点击你确实要使用的一键功能。
5. 如果 macOS 请求管理员权限，请确认它只用于目标进程 attach/read/write 操作。

当游戏未运行、目标模块形态不匹配、功能目标校验失败、权限被拒绝或写后校验失败时，
应用应该明确报错。

## 权限和隐私

DaveTheTrainer 会修改本机正在运行的游戏进程。macOS 可能要求管理员授权，
用于 task access 和进程内存读写。

应用不会上传 telemetry、内存 dump、存档、API key、崩溃日志或诊断信息。本地日志只用于排查问题。
公开反馈问题时请删掉家目录路径、原始内存地址、存档路径、Steam 账号目录、无关进程信息、
提取出的符号和 memory dump。

详细说明见 [Permissions And Privacy](docs/permissions-and-privacy.md)。

## 从源码构建

```bash
git clone https://github.com/Empress7211/DaveTheTrainer.git
cd DaveTheTrainer
swift test
./script/build_and_run.sh
```

`script/build_and_run.sh` 会构建 SwiftPM executable，生成真实的
`DaveTheTrainer.app` bundle，签名，复制到
`${DAVE_TRAINER_LOCAL_APP_DIR:-$HOME/Applications}`，同时在 `dist/` 下生成
`DaveTheTrainer.zip`。

GitHub Actions 运行公开测试套件，并跳过需要本机游戏安装或专有游戏文件的测试：

```bash
swift test \
  --skip GameInstallResolverTests \
  --skip Il2CppFeatureLocatorTests \
  --skip MachOModuleResolverTests
```

本机如果安装了基线游戏文件，可以运行完整测试：

```bash
swift test
```

## 项目结构

```text
Sources/
  DaveTrainerApp/      SwiftUI 应用、状态、视图和展示逻辑
  TrainerCore/         Manifest、补丁、扫描、运行时和存档服务
  MachMemory/          Mach task memory C bridge
Tests/
  DaveTrainerAppTests/ 玩家路径、发布脚本和 app service 契约测试
  TrainerCoreTests/    核心补丁、manifest、scanner 和 runtime 测试
docs/                  公开策略、发布和能力说明
script/                构建、发布和 legacy admin helper 脚本
Assets/                应用图标资源
```

## 开发原则

- Manifest first：玩家按钮映射到已审查的 manifest feature ID。
- 功能级兼容：未知 build 可以尝试，但每个功能都必须验证模块、目标字节或对象路径、
  写入和读回结果。
- 不做静默 fallback：失败必须通过错误、日志或测试暴露。
- 事务式补丁：多点补丁先 preflight，再提交，失败时 rollback。
- 写后校验：运行时数值写入必须读回确认。
- 公开边界：不要提交游戏二进制、memory dump、存档 fixture、日志或签名材料。

## 文档

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Release Checklist](docs/release-checklist.md)
- [Resource Capabilities](docs/resource-capabilities.md)
- [Inventory Taxonomy](docs/inventory-taxonomy.md)
- [Development Fixtures](docs/development-fixtures.md)

## License

DaveTheTrainer 使用 [MIT License](LICENSE) 发布。
