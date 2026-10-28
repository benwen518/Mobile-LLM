# A800-2 端侧 AI 开发容器：新手交接手册

> 适用环境：`sbw_mobile_ai_dev_a2` 容器、PLR110 Android 手机。  
> 状态核查日期：2026-10-28。动态信息以每次开工时的检查结果为准。

## 1. 先理解：你实际上在操作三台“逻辑机器”

```text
你的 Windows 电脑
  └─ USB 连接手机，真正的 ADB server 当前运行在 Windows 5037
       │
       └─ SSH 反向隧道
            │
A800-2 上的 Docker：sbw_mobile_ai_dev_a2
  ├─ /workspace：写代码、编译、保存实验回执
  ├─ /models：只读模型库
  └─ 127.0.0.1:5038：通过隧道访问 Windows 上的 ADB server
            │
            └─ Android 手机：PLR110 / arm64-v8a / Android 16（API 36）
```

一句话理解：**代码在容器里编译，模型从容器只读库取，最终程序通过 ADB 装到或推到手机上运行。**

不要把三层混在一起：

- `/workspace/...` 是 A800-2 容器路径。
- `/models/...` 是 A800-2 的只读模型快照，不在手机上。
- `/data/local/tmp/...` 和 `/data/user/0/...` 才是手机路径。
- `adb push` 会真的占用手机磁盘，不是“挂载”。

## 2. 当前最重要的事实

| 项目 | 当前状态 |
| --- | --- |
| 容器 | `sbw_mobile_ai_dev_a2`，运行中 |
| 容器连接 | `ssh A8002-sbw_mobile_ai_dev_a2` |
| 手机 | 1 台：`3B661K0119Q00000`，型号 `PLR110` |
| 手机架构 | `arm64-v8a` |
| Android | Android 16，API 36 |
| ADB 身份 | `uid=2000(shell)`，不是 root |
| 容器 ADB | `127.0.0.1:5038` |
| 手机数据盘 | **已用 98%，约剩 12 GB** |
| Git 仓库 | `/workspace/Mobile-LLM`；基础设施回执提交为 `afdaa85`，实际 HEAD 以 `git log -1` 为准 |
| 模型快照 | `/models/20261028`，95 个文件，约 23.63 GiB，只读 |

手机空间是当前最大的操作风险。**严禁把 `/models/20261028` 整体推到手机。** 它比手机剩余空间大，而且手机已经存在多份历史模型。

## 3. 五分钟上手

### 3.1 从 Windows 进入容器

```powershell
ssh A8002-sbw_mobile_ai_dev_a2
```

进入后，提示符所在机器应为：

```bash
hostname
# 预期：sbw-mobile-ai-a2
```

### 3.2 在容器里定义一个方便使用的 ADB 函数

```bash
phone_adb() { adb -H 127.0.0.1 -P 5038 "$@"; }
```

这个函数只在当前终端会话有效。后面的示例都假设已经定义它。

### 3.3 确认连接的是正确手机

```bash
phone_adb devices -l
phone_adb -s 3B661K0119Q00000 shell getprop ro.product.model
phone_adb -s 3B661K0119Q00000 shell getprop ro.product.cpu.abi
```

预期能看到：

```text
3B661K0119Q00000  device  model:PLR110
PLR110
arm64-v8a
```

如果设备数量不是 1，或者序列号不同，**立即停止，不要安装、推送或删除任何文件。**

### 3.4 每次开工先检查手机剩余空间

```bash
phone_adb -s 3B661K0119Q00000 shell 'df -h /data /sdcard'
```

当前只剩约 12 GB。任何超过 500 MB 的推送，都应先记录：来源、目标、精确大小、是否已有同一份文件。

### 3.5 检查 Git 工作区

```bash
cd /workspace/Mobile-LLM
git status --short --branch
git log -1 --oneline
```

不要在一个有陌生未提交改动的工作区上直接覆盖文件。看到不属于自己的改动时，先联系项目负责人。

## 4. 推荐的完整开发流程

### 第 1 步：为自己的工作创建 Git 分支

```bash
cd /workspace/Mobile-LLM
git pull --ff-only
git switch -c handoff/<你的名字>-<任务简称>-<日期>
```

例如：

```bash
git switch -c handoff/xiaoming-mobileo-smoke-20261028
```

当前 `Mobile-LLM` 仓库主要保存基础设施、拓扑和模型清单。新增源码应放在名称明确的子目录中，例如：

```text
/workspace/Mobile-LLM/projects/mobile-o/
/workspace/Mobile-LLM/projects/omnineural/
/workspace/Mobile-LLM/projects/nexa-cv/
```

不要把源码放进 `/models`，也不要直接修改 `/config`。

### 第 2 步：确定本次实验的唯一对象

开始前写清楚四件事：

1. 测哪个模型和精确版本。
2. 用 CPU、GPU、NPU 中的哪个后端。
3. 是 APK 应用还是 `/data/local/tmp` 下的命令行程序。
4. 成功标准是什么，例如“生成一张可打开的 PNG”，不能只写“程序没崩”。

每次只做一个主要变量。不要同时换模型、量化格式、运行时和输入尺寸，否则出错后无法定位。

### 第 3 步：从只读模型库选择模型

```bash
find /models/20261028 -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
```

当前可见模型根目录：

- `Mobile-O-0.5B`
- `Qwen2.5-Omni-3B-GGUF`
- `Qwen3-4B-Q4_0`
- `MiniCPM-o-4_5-GGUF`
- `MiniCPM-V-4.6-GGUF`
- `OmniNeural-4B-mobile`
- `LFM2-1.2B-npu-mobile`
- `Nexa-CV-NPU`
- 两组 Mobile-O 手机侧中间张量样例

模型库是只读的。正确做法是直接读取；若工具必须写同目录，应把**必要的小文件**复制到自己的工作目录，而不是复制整套模型。

### 第 4 步：在容器里编译

常见 Android APK：

```bash
cd /workspace/Mobile-LLM/projects/<项目目录>
./gradlew assembleDebug
```

常见 native/CMake 工程：

```bash
cmake -S . -B build-android \
  -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk-r28b/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-27
cmake --build build-android -j"$(nproc)"
```

项目自己的构建参数优先于这里的通用示例。不要为了“能编译”随便改 ABI、minSdk 或删掉 NPU 依赖。

### 第 5 步：部署前做四项检查

```bash
# 1. 手机仍然在线
phone_adb devices -l

# 2. 手机空间
phone_adb -s 3B661K0119Q00000 shell 'df -h /data'

# 3. 待推文件大小和哈希
stat -c '%n %s bytes' <文件>
sha256sum <文件>

# 4. 若是 APK，先确认包名是否已存在
phone_adb -s 3B661K0119Q00000 shell pm path <package.name>
```

如果包名已存在，`adb install -r` 会更新现有应用。新手默认应使用新的 debug applicationId；覆盖现有应用必须先征得负责人同意。

### 第 6 步：只在自己的新目录里部署命令行实验

建议为每次实验创建唯一目录：

```bash
RUN_ID="$(date +%Y%m%d-%H%M%S)-<你的名字>-<任务简称>"
PHONE_RUN="/data/local/tmp/sbw-handoff/$RUN_ID"
phone_adb -s 3B661K0119Q00000 shell "mkdir -p '$PHONE_RUN'/bin '$PHONE_RUN'/input '$PHONE_RUN'/output '$PHONE_RUN'/logs"
```

然后只推本次需要的文件：

```bash
phone_adb -s 3B661K0119Q00000 push <本地二进制> "$PHONE_RUN/bin/"
phone_adb -s 3B661K0119Q00000 shell "chmod 755 '$PHONE_RUN/bin/<二进制名>'"
```

大模型推送前必须再次核查空间。优先复用手机上已有、哈希一致的模型；不要为了省事再复制一份。

### 第 7 步：运行时保存完整证据

不要只截一张图。至少保存：

- 完整命令行和参数。
- Git commit。
- 手机序列号、Android 版本和 ABI。
- 模型相对路径、字节数和 SHA256。
- stdout、stderr、退出码。
- 生成的 PNG/JSON/音频等真实输出。
- 墙钟时间、内存、温度。
- CPU/GPU/NPU 后端日志。

建议把输出全部写进本次 `PHONE_RUN` 的 `output/` 和 `logs/`。

读取 logcat 时不要先清空全局日志：

```bash
phone_adb -s 3B661K0119Q00000 logcat -T 1 > logcat.txt
```

不要默认执行 `adb logcat -c`，它会清掉其他任务的日志证据。

### 第 8 步：把结果拉回容器

```bash
mkdir -p "/workspace/Mobile-LLM/runs/$RUN_ID"
phone_adb -s 3B661K0119Q00000 pull "$PHONE_RUN/output" "/workspace/Mobile-LLM/runs/$RUN_ID/"
phone_adb -s 3B661K0119Q00000 pull "$PHONE_RUN/logs" "/workspace/Mobile-LLM/runs/$RUN_ID/"
```

拉回后计算哈希并写 README：

```bash
find "/workspace/Mobile-LLM/runs/$RUN_ID" -type f -exec sha256sum {} \; \
  > "/workspace/Mobile-LLM/runs/$RUN_ID/SHA256SUMS"
```

确认结果在容器中可读之后，才能提出手机端清理申请。**新手不要自行删除历史模型或历史实验目录。**

### 第 9 步：提交代码和小型回执

```bash
git status --short
git diff --check
git add <明确的文件>
git commit -m "描述本次改动"
git push -u origin HEAD
```

不要提交：

- `.gguf`、`.nexa`、`.safetensors` 等模型权重。
- APK/AAR 和大体积 build 输出。
- 私钥、PAT、`authorized_keys`、`.env`。
- 包含个人信息或其他项目日志的手机目录。

共享容器没有统一 GitHub PAT。每位同学使用自己的 GitHub 身份推送。

## 5. 手机文件红黄绿清单

### 5.1 绿色：默认可以做的事情

| 操作/位置 | 可以做什么 |
| --- | --- |
| 新建的 `/data/local/tmp/sbw-handoff/<RUN_ID>/` | 推自己的二进制、输入和本次输出 |
| `/data/local/tmp/mobile-t2i/out/` | 只读查看、`adb pull` 历史结果；新增文件应使用唯一名字 |
| `/data/local/tmp/omni-o45/output/` | 只读查看、拉取；新增文件使用唯一名字 |
| `adb shell getprop`、`df`、`ps`、`pm list packages` | 只读诊断 |
| `adb pull` | 把明确的文件拉回容器，通常安全 |
| 容器 `/workspace/Mobile-LLM` 的个人 Git 分支 | 修改源码、脚本和文档 |
| 容器 `/models/20261028` | 只读使用和计算哈希 |

即使在绿色区域，也不要覆盖同名文件；新文件应带 `RUN_ID`。

### 5.2 黄色：必须先说明目标和影响

| 操作/位置 | 风险 |
| --- | --- |
| `adb push` 大于 500 MB 的文件 | 手机仅剩约 12 GB，可能写满数据盘 |
| `adb install -r` | 会覆盖同包名 APK，可能改变原有实验环境 |
| `am force-stop <包名>` | 会中断该应用当前任务 |
| 修改已有 `.sh` 脚本 | 历史实验可能依赖原内容和参数 |
| 修改已有 `output/` 文件 | 会破坏旧实验回执 |
| 终止进程 | 只允许终止自己本次启动并记录了 PID 的进程 |
| 清理本次 `PHONE_RUN` | 必须先拉回结果、核对哈希，并确认路径就是自己的 RUN_ID |

黄色操作前至少报告：精确路径/包名、大小、是否已有文件、回滚方法。

### 5.3 红色：新手不要碰

#### 手机系统目录

以下目录不要写入、删除、改权限或重新挂载：

```text
/system
/vendor
/odm
/product
/data/adb
/data/misc
/dev
/proc
/sys
```

不要执行：

```text
su
setenforce 0
mount -o rw,remount ...
reboot
pm uninstall ...
pm clear ...
adb kill-server
pkill -f ...
rm -rf /data/local/tmp/*
```

除非项目负责人对本次具体操作给出明确授权。

#### `/data/local/tmp` 顶层和历史实验

`/data/local/tmp` 不是本项目的专属临时目录。它包含长期实验、NPU 运行时、模型、功耗脚本以及其他自动化任务。

尤其不要碰：

- 所有 `dingtalk-*` 文件和 root 所有的心跳/状态文件：与本项目无关，可能仍在运行。
- `gpu_limit.sh`、`gpu_reset.sh`、`android_*_sampler.sh` 等系统/功耗脚本。
- `nllama*`、`bonsai*`、`mllm*`、`heterogeneous*` 等其他实验目录。
- 任何不认识的 root 所有文件。
- 整个 `/data/local/tmp` 的批量清理、改权限或递归复制。

#### 已安装应用的私有目录

以下路径由 Android 包管理器维护，不要直接修改：

```text
/data/app/...
/data/user/0/org.example.nexacvpilot
/data/user/0/org.example.omnineuralpilot
/data/user/0/org.example.nexalfm2pilot
/data/user/0/org.example.omniinferbaseline
```

不要用 `rm` 修改这些目录，也不要对这些包执行 `pm clear` 或卸载。

#### 容器基础设施

不要修改：

```text
/models
/config
/config/authorized_keys
/etc/ssh
容器网络模式、端口 32328/5038
Windows 计划任务 “A8002 Mobile AI ADB tunnel”
```

不要在容器中执行 `adb -H 127.0.0.1 -P 5038 kill-server`；它会影响 Windows 上真实的 ADB server。

## 6. 当前手机端主要资产地图

以下大小来自 2026-10-28 实时核查，单位换算为近似值。

| 路径 | 约占用 | 用途 | 新手规则 |
| --- | ---: | --- | --- |
| `/data/local/tmp/mobile-t2i` | 17.65 GiB | 历史文生图模型、二进制和输出 | `models/`、`bin*/` 不碰；`out/` 只读或新增唯一文件名 |
| `/data/local/tmp/baseline` | 7.76 GiB | llama.cpp/NPU 基线和多份 Qwen 权重 | 整体保护，不覆盖、不删除、不改库文件 |
| `/data/local/tmp/omni-o45` | 6.47 GiB | MiniCPM-o 4.5 GGUF、Omni 二进制 | `model/`、`bin/` 不碰；`output/` 可拉取 |
| `/data/local/tmp/mobile-o-pilot` | 5.96 GiB | Mobile-O Ubuntu rootfs、模型资产和脚本 | `rootfs/`、`assets/` 不碰；脚本先复制到个人目录再改 |
| `/data/local/tmp/nexa-cv-pilot-stage` | 4 KiB | Nexa CV 部署 staging 标记 | 不因“空”就删除；部署前核对 APK 私有数据 |
| `/data/local/tmp/nexa-lfm2-pilot-stage` | 4 KiB | LFM2 部署 staging 标记 | 同上 |
| `/data/local/tmp/omnineural-pilot-stage` | 4 KiB | OmniNeural staging 标记 | 同上 |

已安装相关 APK：

| 包名 | 版本 | 规则 |
| --- | --- | --- |
| `org.example.nexacvpilot` | 1.0 | 不覆盖、清数据或卸载，除非负责人批准 |
| `org.example.omnineuralpilot` | 1.0 | 同上 |
| `org.example.nexalfm2pilot` | 1.0 | 同上 |
| `org.example.omniinferbaseline` | 0.1 | 同上 |

注意：APK 已安装、模型已加载、后端执行、输出语义正确，是四个不同的验收门槛。不能因为应用能打开，就宣称 NPU 推理成功。

## 7. 如何判断一次端侧实验真的成功

按以下顺序验收：

1. **文件完整性**：模型大小和 SHA256 与清单一致。
2. **入口兼容**：模型格式、manifest、输入名称、shape 和 dtype 正确。
3. **后端证据**：日志能证明 CPU/GPU/NPU 中实际用了哪个后端。
4. **数值正确**：至少与已知基准比较误差或关键中间值。
5. **语义正确**：图像能打开且内容符合提示词；文本不是乱码或固定重复。
6. **性能数据**：区分冷启动/热启动，记录延迟、内存、温度和功耗。

“程序退出码为 0”只证明程序没有报告错误，不等于模型正确。

## 8. 故障处理

### 8.1 容器里看不到手机

先检查：

```bash
phone_adb devices -l
```

然后在 Windows PowerShell 检查：

```powershell
adb -P 5037 devices -l
adb -P 5038 devices -l
Get-ScheduledTask -TaskName 'A8002 Mobile AI ADB tunnel'
```

- Windows 能看到、容器看不到：检查隧道计划任务，不要重启手机或删除文件。
- 显示 `unauthorized`：解锁手机并在屏幕上确认 USB 调试授权。
- 显示 `offline`：先重新插拔 USB；不要一上来就杀所有 adb/ssh 进程。
- 序列号变化或出现多台设备：停止部署，明确使用 `-s <serial>`。

### 8.2 手机空间不足

```bash
phone_adb -s 3B661K0119Q00000 shell 'df -h /data; du -sk /data/local/tmp/<你的RUN_ID>'
```

不要自行寻找“大目录然后删除”。正确流程是：

1. 列出候选路径和精确大小。
2. 确认归属和是否已有备份。
3. 拉回必要文件并校验哈希。
4. 得到负责人对精确路径的删除授权。
5. 删除后再次检查空间和其他任务是否正常。

### 8.3 NPU/HTP 报错

先保存：

- 完整命令和退出码。
- `logcat -T 1`。
- QNN/HTP/CDSP 相关日志。
- 模型 manifest、输入 shape/dtype、运行时版本。

不要通过替换 `/vendor` 库、关闭 SELinux、停止系统服务来“试一试”。这类操作必须由熟悉设备的人审批和执行。

### 8.4 GitHub 推不上去

容器没有共享 PAT。先确认自己有仓库权限，并使用自己的凭据。不要把 Token 写进脚本、README、Git remote URL 或 shell history。

若只是需要交付结果，可以先提交到本地分支并报告 commit；不要为了推送而改全局代理或 SSH 配置。

## 9. 每次实验的最小回执模板

在 `runs/<RUN_ID>/README.md` 中至少填写：

```markdown
# <RUN_ID>

- 操作者：
- 日期：
- Git commit：
- 手机序列号：3B661K0119Q00000
- Android / ABI：Android 16 / arm64-v8a
- 模型路径：
- 模型字节数：
- 模型 SHA256：
- 后端：CPU / GPU / NPU
- 完整命令：
- 退出码：
- 输出文件：
- 输出 SHA256：
- 冷启动耗时：
- 热启动耗时：
- 峰值内存：
- 温度：
- 语义检查结果：
- 已知问题：
```

## 10. 新手离场前检查表

- [ ] 没有修改 `/models`、`/config`、手机系统目录或他人实验目录。
- [ ] 没有执行整目录 `rm -rf`、`pm clear`、卸载、重启或 remount。
- [ ] 手机仍能被容器 ADB 识别，序列号正确。
- [ ] 本次手机文件全部位于自己的 `RUN_ID` 目录。
- [ ] 输出、日志和哈希已拉回 `/workspace/Mobile-LLM/runs/<RUN_ID>`。
- [ ] 没有把模型、APK、密钥或 Token 提交到 GitHub。
- [ ] Git 工作区没有不明改动。
- [ ] 记录了失败结果，不把“后端执行”误写成“模型正确”。
- [ ] 若申请清理空间，已给出精确路径、大小、备份和哈希证据。

## 11. 遇到拿不准的情况怎么办

遵守一个简单规则：**先停手，先读，先报告精确路径和命令，再请求确认。**

可以做只读检查，但不要用“先删了再说”“先覆盖试试”“先关闭安全机制”来排错。端侧开发最宝贵的不是某一个二进制，而是可复现的环境和完整的失败证据。
