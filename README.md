# RF2T 使用说明书 / User Manual
# 基于RF2的遥测显示与飞行日志系统

**版本 / Version:** 2.1  
**作者 / Author:** 212049  
**平台 / Platform:** EdgeTX / OpenTX (128x64 LCD 屏幕)

---

## 快速开始 / Quick Start

### 这是什么？/ What is this?

**中文：** RF2T 是一个遥控直升机的飞行数据显示和日志记录系统。自动记录每次飞行的电压、电流、转速等数据，支持多架飞机分别管理。

**English:** RF2T is a flight telemetry display and logging system for RC helicopters. Automatically records voltage, current, RPM and other data for each flight, with multi-model support.

### 主要功能 / Main Features

✅ **实时显示** 10种飞行数据（电压、电流、转速、温度等）  
✅ **自动记录** 每次飞行数据保存到SD卡  
✅ **多机型支持** 每架飞机独立文件夹管理  
✅ **日志浏览** 按日期查看历史飞行记录  
✅ **统计功能** 自动统计每架飞机总飞行次数

---

## 📥 安装步骤 / Installation 

**中文：**
1. 将 `rf2t.lua` 复制到遥控器SD卡：`/SCRIPTS/TELEMETRY/rf2t.lua`
2. 在遥控器中：机型设置 → 显示 → 屏幕1 → 选择 `rf2t.lua`
3. 完成！长按PAGE键即可查看

**English:**
1. Copy `rf2t.lua` to radio SD card: `/SCRIPTS/TELEMETRY/rf2t.lua`
2. In radio: Model Setup → Display → Screen 1 → Select `rf2t.lua`
3. Done! Long press PAGE to view

## ⚠️ 重要：日志重组工具 / IMPORTANT: Log Reorganization Tool

### 什么时候需要使用？/ When to use?

**如果您之前使用过旧版本脚本（一凡开源版本），有以下情况：**
- 所有机型的日志混在一个文件里
- `/LOGS/` 文件夹下直接有格式为 `RFLog_20250115.csv` 这样的文件

**If you used old version script and have:**
- Multiple models mixed in same log files
- Files like `RFLog_20250115.csv` directly in `/LOGS/` folder

### 如何使用？/ How to use?

#### 方法一：Windows 一键运行（推荐）/ Method 1: Windows One-Click (Recommended)

```
1. 将SD卡插入电脑或直接连接遥控器到电脑
2. 将以下文件复制到SD卡根目录：
   - reorganize_logs.ps1
   - 运行日志重组.bat
3. 双击运行 "运行日志重组.bat"
4. 等待完成（会显示进度）
5. 完成！旧文件会被自动删除，现在你可以直接使用lua脚本了
```

**English:**
```
1. Insert SD card to computer
2. Copy these files to SD card root:
   - reorganize_logs.ps1
   - 运行日志重组.bat
3. Double-click "运行日志重组.bat"
4. Wait for completion (progress shown)
5. Done! Old files will be deleted automatically
```

#### 方法二：PowerShell 手动运行 / Method 2: PowerShell Manual

```powershell
# 打开PowerShell，切换到SD卡目录
cd X:\  # X是SD卡盘符
.\reorganize_logs.ps1
```

### 重组后的文件结构 / File structure after reorganization

**重组前 / Before:**
```
/LOGS/
  RFLog_20250115.csv  (包含多个机型)
  RFLog_20250114.csv  (包含多个机型)
```

**重组后 / After:**
```
/LOGS/
  MyHeli1/
    RFLog_20250115.csv  (只包含MyHeli1)
    RFLog_20250114.csv
  MyHeli2/
    RFLog_20250115.csv  (只包含MyHeli2)
    RFLog_20250114.csv
  RFStats.csv  (统计文件)
```

### 重组工具功能说明 / Tool Features

✅ 自动识别日志中的所有机型  
✅ 为每个机型创建独立文件夹  
✅ 将日志按机型分类存放  
✅ 显示详细的处理进度和统计  
✅ 自动删除原始混合文件  

---

## 📱 界面说明 / User Interface

系统有4个主界面，按钮操作：

| 按钮 | 功能 |
|------|------|
| **PAGE** (长按) | 进入遥测屏幕 |
| **MENU** | 进入日志列表 → 日期选择 |
| **EXIT** | 返回上一级 |
| **ENTER** | 确认选择 / 查看详情 |
| **滚轮** | 上下滚动选择 |

### 界面 0：主遥测屏幕（默认）

**显示内容：**
```
┌────────────────────────────────────┐
│ 机型名  调速器状态  发射机电池    │
├─────────┬──────────────────────────┤
│ [电池%] │     [转速 RPM]           │
│ [电压V] │     大字显示             │
│ [容量]  │     [油门%] [温度°C]     │
├─────────┼──────────────────────────┤
│         │ 时间: MM:SS              │
│         │ BEC: XX.XV  信号: XXdB   │
└─────────┴──────────────────────────┘
```

**操作：**
- 飞行中自动显示实时数据
- 解锁后计时器自动开始
- 降落断开后自动弹出飞行摘要

### 界面 1：飞行日志列表

**显示内容：**
```
┌────────────────────────────────────┐
│ 2025-01-15          5次飞行        │
├──────────┬─────────────────────────┤
│ 01 机型  │ 电压: 22.3V             │
│ 02 机型  │ 容量: 2450mAh           │
│→03 机型  │ 电流: 65.2A             │
│ 04 机型  │ 转速: 2650RPM           │
└──────────┴─────────────────────────┘
```

**操作：**
- 从主界面按 **MENU** 进入
- 滚轮上下选择日志
- 按 **ENTER** 查看详细信息
- 按 **MENU** 进入日期选择

### 界面 2：日期选择

**操作流程：**
1. 左侧选择月份（滚轮上下选择）
2. 按 **ENTER** 确认月份
3. 右侧选择具体日期
4. 按 **ENTER** 查看该日期的日志
5. 按 **EXIT** 返回

**首次进入：**
- 会显示扫描进度条
- 扫描365天的日志文件
- 只需等待1-2分钟

### 界面 3：日志详情

**显示内容：**
```
┌────────────────────────────────────┐
│ 机型: RFDB2.1    最大功率: 1450W   │
│ 时间: 05:23      最大转速: 2650RPM │
│ 今日: 第3次      最低电压: 22.3V   │
│ 总计: 147次      最大电流: 65.2A   │
│                  消耗: 2450mAh     │
└────────────────────────────────────┘
```

**操作：**
- 按 **EXIT** 或 **ENTER** 返回日志列表

---

## 🎯 使用流程 / Operation Workflow

### 飞行前 / Pre-Flight
1. ✅ 打开遥控器和接收机
2. ✅ 检查屏幕显示机型名称（无"RX LOSS"）
3. ✅ 确认所有传感器数据正常

### 飞行中 / During Flight
1. ⏱️ 解锁后计时器自动开始
2. 📢 每分钟语音播报时间
3. 📊 实时更新所有数据

### 飞行后 / Post-Flight
1. 🔒 锁定后计时器暂停
2. 📋 断开连接后自动弹出飞行摘要（需飞行>30秒）
3. 💾 数据自动保存到SD卡
4. ✅ 按EXIT关闭摘要

### 查看日志 / View Logs
1. 📱 主界面按 **MENU**
2. 📜 浏览今日飞行列表
3. 🔍 按 **ENTER** 查看详情
4. 📅 再按 **MENU** 可选择历史日期

---

## 📁 日志文件说明 / Log Files

### 文件位置 / File Location

```
SD卡 /LOGS/
├── RFStats.csv              # 统计文件（自动生成）
├── 机型名称1/               # 每个机型独立文件夹
│   ├── RFLog_20250115.csv
│   └── RFLog_20250114.csv
└── 机型名称2/
    └── RFLog_20250115.csv
```

### 日志格式 / Log Format

每条日志包含11个字段，用 `|` 分隔：

```
日期|机型|时间|当日#|容量|最低压|最大流|最大功率|最大转速|最低BEC|总次数
20250115|RFDB2.1|05:23|1|2450|22.3|65.2|1450|2650|7.8|147
```

### 导出分析 / Export & Analysis

**方法：**
1. 取出SD卡插入电脑
2. 打开 `/LOGS/机型名/RFLog_YYYYMMDD.csv`
3. 用Excel打开，分隔符选择 `|`
4. 可进行数据分析、制作图表等

---

## ⚙️ 常用设置 / Common Settings

### 修改最小记录时间 / Change Minimum Flight Time

默认30秒以上才记录日志，修改方法：

```lua
-- 打开 rf2t.lua 文件，修改第2行：
local MIN_FLIGHT_TIME_SEC = 30  -- 改为您想要的秒数
```

### 修改扫描天数 / Change Scan Days

默认扫描365天历史，如果日志很多可以减少：

```lua
-- 修改第5行：
local SCAN_TOTAL_DAYS = 365  -- 改为180或90
```

### 修改传感器名称 / Change Sensor Names

如果您的传感器名称不同：

```lua
-- 修改第38行：
local teleItemName = { 
    "Vbat",   -- 改为您的电压传感器名称
    "Curr",   -- 改为您的电流传感器名称
    "Hspd",   -- 改为您的转速传感器名称
    -- ... 其他传感器
}
```

---

## ❓ 常见问题 / FAQ

### 1. 一直显示"RX LOSS"？
**原因：** 无遥测信号  
**解决：** 检查接收机通电、对频、遥测启用、传感器接线

### 2. 没有保存日志？
**原因：** 飞行时间不足30秒或SD卡问题  
**解决：** 
- 确保飞行时间>30秒
- 检查SD卡未写保护
- 检查SD卡有足够空间

### 3. 总飞行次数显示0？
**原因：** 统计文件丢失  
**解决：** 
- 删除 `/LOGS/RFStats.csv`
- 重启脚本等待自动扫描

### 4. 日期浏览器显示"No logs found"？
**原因：** 扫描未完成或无日志  
**解决：**
- 等待扫描进度条完成
- 先飞几次创建日志
- 检查 `/LOGS/` 文件夹

### 5. 运行卡顿、缓慢？
**原因：** 日志文件太多  
**解决：**
- 修改 `SCAN_TOTAL_DAYS = 90`（减少扫描天数）
- 删除或归档旧日志
- 使用Class 10或更好的SD卡

### 6. 旧版本日志如何转换？
**解决：** 使用 **日志重组工具**（见上方"重要：日志重组工具"章节）

### 7. 如何备份日志？
**方法：**
1. SD卡插入电脑
2. 复制整个 `/LOGS/` 文件夹到电脑
3. 恢复时复制回SD卡即可

### 8. 可以用于固定翼或穿越机吗？
**可以！** 但需要修改传感器名称以匹配您的设备。脚本主要针对直升机优化。

### 9. 更换机型名称后怎么办？
脚本会把新名称当作新机型。如需合并，手动移动日志文件到对应文件夹。

### 10. 如何删除旧日志？
直接删除 `/LOGS/机型名/` 下的旧CSV文件，然后删除 `RFStats.csv` 让统计重新生成。

---

## 🔧 故障排除 / Troubleshooting

| 问题 | 检查项 | 解决方法 |
|------|--------|----------|
| 无遥测显示 | 接收机通电？传感器接线？ | 检查硬件连接 |
| 数据不更新 | 传感器名称对吗？ | 检查第38行配置 |
| 不记录日志 | 飞行时间>30秒？SD卡正常？ | 检查时间和SD卡 |
| 打开卡顿 | 日志文件太多？ | 减少扫描天数 |
| 统计错误 | RFStats.csv损坏？ | 删除后重新扫描 |

---

## 📊 技术参数 / Specifications

**系统要求 / Requirements:**
- 屏幕：128x64 单色LCD
- 平台：EdgeTX 或 OpenTX 2.2+
- 最低传感器：Vbat, 1RSS

**性能 / Performance:**
- 脚本大小：~40KB
- 内存占用：~15-30KB
- 单条日志：~100-150字节
- 扫描速度：批量处理，不卡顿

**兼容性 / Compatibility:**
- ✅ EdgeTX - 完全支持
- ✅ OpenTX 2.2+ - 完全支持  
- ⚠️ OpenTX 2.1 - 部分支持

---

## 📝 更新日志 / Changelog

### 版本 2.1 (当前)
- ✨ 新增多机型支持，独立文件夹
- ✨ 新增统计文件自动生成
- ✨ 新增365天历史扫描
- ⚡ 优化内存使用和缓存
- ⚡ 优化CSV解析性能
- 🐛 修复日志显示bug

---

## 💝 致谢 / Credits

**作者 / Author:** RFDB  
**许可 / License:** 开源免费使用

**感谢 / Thanks:**
- EdgeTX/OpenTX 开发团队
- RC直升机社区测试和反馈
- 所有提供建议的飞手

---

## 📞 支持 / Support

**获取帮助：**
- 通过RC社区论坛反馈问题
- 提交功能建议
- 分享使用经验

**安全提示：**
⚠️ 飞行安全第一！日志记录是辅助工具，不要在飞行中查看屏幕。

---

## 🎉 开始使用 / Get Started

**3步开始飞行记录：**
1. ✅ 复制 `rf2t.lua` 到 `/SCRIPTS/TELEMETRY/`
2. ✅ 机型设置中选择脚本
3. ✅ 长按PAGE查看，开始飞行！

**如有旧版本日志，记得先运行日志重组工具！**

---

**祝您飞行愉快！记录精彩！**  
**Happy Flying & Keep Logging!**

---

*说明书版本：2.1 | 最后更新：2025-01*







