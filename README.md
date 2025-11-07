# RF2 Telemetry Display and Flight Log System
## Instruction Manual

### Version 2.1
### For OpenTX/EdgeTX Transmitters

---

## Table of Contents

1. [Introduction](#introduction)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Features Overview](#features-overview)
5. [Main Display Page](#main-display-page)
6. [Flight Logging](#flight-logging)
7. [Viewing Flight Logs](#viewing-flight-logs)
8. [Navigation and Controls](#navigation-and-controls)
9. [File Structure](#file-structure)
10. [Troubleshooting](#troubleshooting)
11. [Technical Specifications](#technical-specifications)

---

## Introduction

The RF2 Telemetry Display and Flight Log System is a comprehensive Lua script for OpenTX/EdgeTX radio transmitters that provides real-time telemetry monitoring and automatic flight logging for RC helicopters and aircraft. The system tracks flight data, displays telemetry information, and maintains detailed flight history logs.

### Key Capabilities

- **Real-time Telemetry Display**: Monitor battery voltage, current, RPM, temperature, and more
- **Automatic Flight Logging**: Automatically records flight data when connection is established
- **Flight History Browser**: Review past flights by date with detailed statistics
- **Flight Statistics**: Track total flight count per model
- **Flight Timer**: Automatic timer with audio alerts
- **Post-Flight Summary**: View flight statistics after disconnection

---

## System Requirements

### Hardware
- OpenTX or EdgeTX compatible transmitter
- Telemetry-enabled receiver
- Compatible sensors for the following telemetry values:
  - Battery voltage (Vbat)
  - Current (Curr)
  - Head speed/RPM (Hspd)
  - Capacity (Capa)
  - Battery percentage (Bat%)
  - ESC temperature (Tesc)
  - Throttle (Thr)
  - RSSI (1RSS)
  - BEC voltage (Vbec)
  - Governor state (GOV)

### Software
- OpenTX 2.3.x or later, OR EdgeTX 2.5.x or later
- Lua script support enabled

---

## Installation

1. **Copy the Script**
   - Copy `rf2t.lua` to your transmitter's `/SCRIPTS/TELEMETRY/` directory
   - Ensure the file is named exactly `rf2t.lua`

2. **Create Log Directory**
   - The script will automatically create the `/LOGS/` directory structure
   - Logs are organized by model name: `/LOGS/[ModelName]/`

3. **Enable the Script**
   - On your transmitter, navigate to the Telemetry page
   - Select "Scripts" and choose `rf2t`
   - The script will initialize automatically

4. **Initial Setup**
   - On first run, the system will scan existing log files (up to 365 days)
   - This may take a few minutes depending on the number of logs
   - Progress is displayed on the date selection screen

---

## Features Overview

### Main Features

1. **Telemetry Display (Page 0)**
   - Real-time monitoring of all telemetry values
   - Flight timer
   - Connection status indicator
   - Governor state display

2. **Flight Logging**
   - Automatic logging when telemetry connection is established
   - Minimum flight time: 30 seconds
   - Logs saved to CSV format

3. **Flight History (Page 1)**
   - Browse flights by date
   - View flight list with model name and duration
   - Quick statistics display

4. **Date Selection (Page 2)**
   - Browse months and dates with available logs
   - Automatic scanning of log files

5. **Flight Detail View (Page 3)**
   - Detailed information for each flight
   - Complete flight statistics

---

## Main Display Page

The main display (Page 0) shows real-time telemetry data when connected to your model.

### Display Layout

**Top Bar:**
- **Left**: Model name
- **Center**: Governor state (or "RX LOSS" if disconnected)
- **Right**: Transmitter battery voltage

**Left Panel:**
- **Battery Percentage Bar**: Visual indicator (0-100%)
- **Battery Voltage**: Main battery voltage (V)
- **Capacity**: Current capacity used (mAh)
- **Current**: Current draw / Maximum current (A)

**Center Panel:**
- **RPM**: Large display of head speed/RPM
- **Throttle**: Throttle percentage (%)
- **ESC Temperature**: ESC temperature (°C)

**Right Panel:**
- **Flight Time**: MM:SS format timer
- **BEC Voltage**: BEC output voltage (V)
- **RSSI**: Signal strength (dB)

### Flight Timer

- **Start Condition**: Timer starts when:
  - Telemetry connection is established (RSSI > 0)
  - Model is armed (Channel 5 > 0)
- **Pause Condition**: Timer pauses when:
  - Model is disarmed
  - Telemetry connection is lost
- **Audio Alerts**: Announces flight time at each minute interval

### Connection Status

- **Connected**: Green indicator, governor state displayed
- **Disconnected**: "RX LOSS" blinking indicator
- **Auto-switch**: Automatically returns to main page when connection is restored

---

## Flight Logging

### Automatic Logging

The system automatically logs flight data when:

1. Telemetry connection is established
2. Model is armed (Channel 5 > 0)
3. Flight duration exceeds 30 seconds
4. Connection is lost (disarm or signal loss)

### Logged Data

Each flight log entry contains:

1. **Date**: YYYYMMDD format
2. **Model Name**: Current model name
3. **Flight Time**: Duration in MM:SS format
4. **Flight Number**: Sequential number for the day
5. **Capacity**: Battery capacity used (mAh)
6. **Minimum Voltage**: Lowest battery voltage during flight (V)
7. **Maximum Current**: Peak current draw (A)
8. **Maximum Power**: Peak power consumption (W)
9. **Maximum RPM**: Peak head speed (RPM)
10. **Minimum BEC Voltage**: Lowest BEC voltage (V)
11. **Total Flights**: Cumulative flight count for the model

### Log File Format

- **Location**: `/LOGS/[ModelName]/RFLog_YYYYMMDD.csv`
- **Format**: Pipe-delimited CSV (|)
- **Example**: `20250115|MyHeli|05:23|3|1250|3.6|45|162|2800|5.0|127`

### Post-Flight Summary

After disconnection, a summary board displays:

- **Flight Time**: Total duration
- **Date**: Flight date
- **Flight Number**: Today's flight number
- **Battery Capacity**: Used capacity (mAh)
- **Maximum Current**: Peak current (A)
- **Maximum RPM**: Peak head speed
- **Minimum Voltage**: Lowest battery voltage
- **Maximum Power**: Peak power (W)
- **Minimum BEC Voltage**: Lowest BEC voltage
- **Total Flights**: Model's total flight count

**To close the summary**: Press the exit/back button

---

## Viewing Flight Logs

### Accessing Flight Logs

1. **From Main Page**: Press MENU button
2. **From Log List**: Press EXIT to return to main page

### Log List Page (Page 1)

**Display:**
- **Top Bar**: Selected date and total flight count
- **Left Panel**: List of flights with:
  - Flight number
  - Model name
  - Flight duration
- **Right Panel**: Quick statistics for selected flight:
  - Minimum voltage
  - Capacity used
  - Maximum current
  - Maximum RPM

**Navigation:**
- **Rotary Encoder Left/Right**: Navigate through flights
- **ENTER**: View detailed flight information
- **MENU**: Open date selection
- **EXIT**: Return to main page or date selection

### Date Selection Page (Page 2)

**Two-Level Selection:**

1. **Month Selection** (Default):
   - Left panel shows available months (YYYY-MM format)
   - Right panel shows "Select Month" prompt
   - Navigate with rotary encoder
   - Press ENTER to select month

2. **Date Selection**:
   - Left panel shows selected month
   - Right panel shows available dates (DD format)
   - Navigate with rotary encoder
   - Press ENTER to view flights for selected date
   - Press EXIT to return to month selection

**Scanning:**
- On first access, the system scans for log files (up to 365 days)
- Progress bar shows scanning status
- Scanning occurs in background and doesn't block operation
- Maximum 24 months displayed

### Flight Detail Page (Page 3)

**Left Panel:**
- Model name
- Flight time
- Today's flight number
- Total flights (cumulative)

**Right Panel:**
- Maximum power (W)
- Maximum RPM
- Minimum BEC voltage (V)
- Minimum battery voltage (V)
- Maximum current (A)
- Battery capacity used (mAh)

**Navigation:**
- **ENTER or EXIT**: Return to log list

---

## Navigation and Controls

### Button Functions

| Button | Main Page | Log List | Date Select | Detail View |
|--------|-----------|----------|-------------|-------------|
| **MENU** | Open log list | Open date selection | - | - |
| **ENTER** | - | View flight detail | Select month/date | Return to list |
| **EXIT** | Close summary (if shown) | Return to main/date select | Return to log list/month select | Return to list |
| **Rotary Left** | - | Previous flight | Previous month/date | - |
| **Rotary Right** | - | Next flight | Next month/date | - |

### Page Flow

```
Main Page (0)
    ↓ MENU
Log List (1) ←→ Date Select (2)
    ↓ ENTER          ↓ ENTER
Detail View (3)     Log List (1)
```

---

## File Structure

### Directory Structure

```
/LOGS/
├── RFStats.csv                    # Flight statistics (model name | total flights)
└── [ModelName]/                   # Per-model log directory
    ├── RFLog_20250101.csv         # Daily log files
    ├── RFLog_20250102.csv
    └── ...
```

### Log File Format

**RFLog_YYYYMMDD.csv:**
```
Date|Model|Time|#|Capa|MinV|MaxI|MaxP|MaxRPM|MinBEC|Total
20250115|MyHeli|05:23|1|1250|3.6|45|162|2800|5.0|127
20250115|MyHeli|04:15|2|1180|3.7|42|151|2750|5.1|128
```

**RFStats.csv:**
```
ModelName1|150
ModelName2|75
MyHeli|128
```

### Legacy Support

The system supports both:
- **New format**: `/LOGS/[ModelName]/RFLog_YYYYMMDD.csv`
- **Old format**: `/LOGS/RFLog_YYYYMMDD.csv` (for backward compatibility)

---

## Troubleshooting

### Common Issues

**1. Script Not Loading**
- Verify file is in `/SCRIPTS/TELEMETRY/` directory
- Check file name is exactly `rf2t.lua`
- Ensure Lua is enabled in transmitter settings
- Check transmitter firmware version compatibility

**2. No Telemetry Data Displayed**
- Verify telemetry sensors are properly configured
- Check sensor names match expected values:
  - Vbat, Curr, Hspd, Capa, Bat%, Tesc, Thr, 1RSS, Vbec, GOV
- Ensure telemetry is enabled in model settings
- Check receiver telemetry is active

**3. Flights Not Logging**
- Verify minimum flight time (30 seconds) is met
- Check model is armed (Channel 5 > 0)
- Ensure telemetry connection is established
- Verify SD card has sufficient space
- Check `/LOGS/` directory is writable

**4. Logs Not Appearing**
- Wait for initial scan to complete (up to 365 days)
- Check log files exist in `/LOGS/` directory
- Verify date format is correct (YYYYMMDD)
- Try accessing date selection to trigger rescan

**5. Timer Not Starting**
- Ensure telemetry connection is active (RSSI > 0)
- Verify model is armed (Channel 5 > 0)
- Check governor state is not "LOST-HS"

**6. Statistics Not Updating**
- Statistics file (`RFStats.csv`) is created/updated automatically
- First-time scan may take several minutes
- Statistics update after each logged flight
- Manual rescan: Delete `RFStats.csv` and restart script

**7. Display Issues**
- Clear screen issues: Normal, script refreshes each cycle
- Missing data: Check telemetry sensor configuration
- Overlapping text: Normal for long model names (truncated)

### Performance Tips

- **First Run**: Initial statistics scan may take 2-5 minutes
- **Large Log History**: System limits display to 24 months
- **Memory Management**: Script includes automatic memory cleanup
- **Scanning**: Log scanning runs in background, doesn't block operation

---

## Technical Specifications

### Constants

- **Maximum Log Entries**: 99 per date
- **Minimum Flight Time**: 30 seconds
- **Scan Range**: 365 days
- **Maximum Display Months**: 24
- **Date Cache Size**: 50 entries
- **Timer Cache Size**: 60 entries

### Telemetry Items

| Index | Name | Description | Unit |
|-------|------|-------------|------|
| 1 | Vbat | Battery Voltage | V |
| 2 | Curr | Current | A |
| 3 | Hspd | Head Speed | RPM |
| 4 | Capa | Capacity | mAh |
| 5 | Bat% | Battery Percentage | % |
| 6 | Tesc | ESC Temperature | °C |
| 7 | Thr | Throttle | % |
| 8 | 1RSS | RSSI | dB |
| 9 | Vbec | BEC Voltage | V |
| 10 | GOV | Governor State | - |

### Governor States

0. OFF
1. IDLE
2. SPOOLUP
3. RECOVERY
4. ACTIVE
5. THR-OFF
6. LOST-HS
7. AUTOROT
8. BAILOUT

### Flight Data Array

| Index | Field | Description |
|-------|-------|-------------|
| 1 | Date | YYYYMMDD format |
| 2 | Model | Model name |
| 3 | Time | Flight duration (MM:SS) |
| 4 | Flight# | Today's flight number |
| 5 | Capacity | Battery capacity used (mAh) |
| 6 | MinVoltage | Minimum battery voltage (V) |
| 7 | MaxCurrent | Maximum current (A) |
| 8 | MaxPower | Maximum power (W) |
| 9 | MaxRPM | Maximum head speed (RPM) |
| 10 | MinBEC | Minimum BEC voltage (V) |
| 11 | Total | Total flights for model |

### Batch Processing

- **Stats Scan Batch Size**: 3 files per cycle (Phase 1)
- **Stats Scan Batch Size**: 2 files per cycle (Phase 2)
- **Log Scan Batch Size**: 5 files per cycle

---

## Additional Notes

### Best Practices

1. **Regular Backups**: Periodically backup `/LOGS/` directory
2. **SD Card Maintenance**: Ensure SD card has adequate free space
3. **Model Naming**: Use consistent model names for accurate statistics
4. **Telemetry Setup**: Verify all sensors before first flight
5. **Flight Review**: Regularly review logs to monitor model performance

### Limitations

- Maximum 99 log entries displayed per date
- Statistics scan limited to 365 days
- Display limited to 24 months of history
- Model names longer than 7 characters are truncated in detail view
- Requires Channel 5 for arming detection

### Future Enhancements

- Export logs to external format
- Graphical flight data visualization
- Customizable telemetry display layout
- Additional statistics and analytics

---

## Support and Updates

For issues, questions, or feature requests, please refer to the project documentation or contact the development team.

**Version History:**
- v2.1: Current version with enhanced statistics and date selection

---

## License and Disclaimer

This software is provided as-is for use with compatible OpenTX/EdgeTX transmitters. Users are responsible for ensuring proper operation and data backup. The developers are not responsible for any data loss or equipment damage resulting from the use of this software.

---

**End of Manual**

# Rotorflight Dashboard V2.1 中文说明书

## 脚本简介

Rotorflight Dashboard V2.1 是一款专为ELRS遥控器设计的 Lua 脚本，提供直观简洁的遥测数据面板。该脚本支持常见的遥测数据项，具备一键配置功能，能够在飞行结束后自动统计飞行数据并记录每日飞行次数，内置简单计时器，支持 1/2/3/4/5 分钟的语音提示。

**重要提示：仅支持 RF2.1 及以上版本，需要启用 ELRS 自定义遥测功能。**

---

## 主要功能

### 1. 实时遥测数据显示
- **电池电压**：实时显示电池电压和电量百分比
- **电流监控**：显示当前电流和最大电流
- **飞行速度**：显示实时转速（RPM）
- **电池容量**：显示已消耗的电池容量（mAh）
- **BEC 电压**：监控 BEC 输出电压
- **RSSI 信号**：显示接收机信号强度
- **电调温度**：显示电调温度
- **油门百分比**：显示当前油门位置
- **飞行模式**：显示当前调速器状态（OFF/IDLE/SPOOLUP/RECOVERY/ACTIVE/THR-OFF/LOST-HS/AUTOROT/BAILOUT）

### 2. 飞行数据自动记录
- 自动记录每次飞行的关键数据
- 记录内容包括：
  - 日期
  - 机型名称
  - 飞行时长
  - 当日飞行次数
  - 电池容量消耗
  - 最低电压
  - 最大电流
  - 最大功率
  - 最大转速
  - 最低 BEC 电压
  - 总飞行次数

### 3. 飞行日志管理
- 按日期查看历史飞行记录
- 支持按月份和日期筛选
- 查看单次飞行的详细数据
- 自动统计每日飞行次数
- 自动统计模型总飞行次数

### 4. 内置计时器
- 自动计时功能（仅在连接状态下工作）
- 语音提示：1/2/3/4/5 分钟时自动播报
- 最小飞行时间限制：30 秒（低于此时间的飞行不计入统计）

### 5. 数据统计功能
- 自动统计每日飞行次数
- 自动统计模型总飞行次数
- 支持多机型数据管理
- 首次使用时自动扫描历史数据生成统计文件

---

## 安装和配置

### 前置要求
1. 遥控器（支持 EdgeTX 或 OpenTX 系统）
2. Rotorflight 2.1 及以上固件
3. ELRS 接收机（需启用自定义遥测功能）
4. 支持的遥测传感器：
   - 电池电压传感器
   - 电流传感器
   - 转速传感器
   - BEC 电压传感器
   - 电调温度传感器

### 安装步骤

1. **复制脚本文件**
   - 将 `rf2t.lua` 文件复制到遥控器的 `/SCRIPTS/TELEMETRY/` 目录下

2. **创建日志文件夹**
   - **重要：首次使用前，必须手动创建对应的模型文件夹**
   - 在遥控器的 `/LOGS/` 目录下，创建以模型名称命名的文件夹
   - 例如：如果模型名称为 "M4"，则创建 `/LOGS/M4/` 文件夹
   - 飞行日志将自动保存在此文件夹中

3. **配置遥测**
   - 确保遥控器已正确配置遥测传感器
   - 检查以下遥测项是否可用：
     - Vbat（电池电压）
     - Curr（电流）
     - Hspd（转速）
     - Capa（电池容量）
     - Bat%（电池百分比）
     - Tesc（电调温度）
     - Thr（油门）
     - 1RSS（RSSI 信号）
     - Vbec（BEC 电压）
     - GOV（调速器状态）

4. **启用脚本**
   - 在遥控器的遥测页面，选择并启用 "RFDB2.1" 脚本
   - 确保脚本能够正常加载和运行

---

## 使用方法

### 主界面（默认页面）

主界面显示实时遥测数据，分为三个区域：

**左侧区域（电池信息）**
- 电池图标和电量百分比条
- 电池电压（大字体显示）
- 电池容量消耗（mAh）
- 电流显示（当前/最大）

**中间区域（核心数据）**
- 转速（RPM）大字体显示
- 油门百分比
- 电调温度

**右侧区域（其他信息）**
- 飞行计时器
- BEC 电压
- RSSI 信号强度

**顶部状态栏**
- 左侧：模型名称
- 中间：飞行模式或 "RX LOSS"（连接丢失）
- 右侧：遥控器电池电压

### 操作说明

#### 按键功能

- **MENU 键**：从主界面进入日志列表页面
- **EXIT 键**：
  - 在主界面：无特殊功能
  - 在日志列表：返回主界面或日期选择页面
  - 在日期选择：返回上级页面
  - 在日志详情：返回日志列表
- **旋转编码器（左右旋转）**：
  - 在日志列表：上下浏览飞行记录
  - 在日期选择：选择月份或日期
- **旋转编码器（按下）**：
  - 在日志列表：查看选中记录的详细信息
  - 在日期选择：确认选择月份或日期
  - 在日志详情：返回日志列表

### 页面导航

**主界面 → 日志列表**
1. 在主界面按 MENU 键
2. 进入当日飞行记录列表
3. 左侧显示飞行记录列表（机型名称 + 飞行时长）
4. 右侧显示选中记录的简要信息（电压、容量、电流、转速）

**日志列表 → 日期选择**
1. 在日志列表页面按 MENU 键
2. 进入日期选择页面
3. 左侧显示有日志记录的月份列表
4. 旋转编码器选择月份，按下确认
5. 右侧显示该月份的日期列表
6. 旋转编码器选择日期，按下确认
7. 返回日志列表，显示选中日期的飞行记录

**日志列表 → 日志详情**
1. 在日志列表页面，使用旋转编码器选择要查看的记录
2. 按下旋转编码器
3. 进入日志详情页面，显示该次飞行的完整数据
4. 再次按下旋转编码器返回列表

### 飞行数据记录

**自动记录流程**
1. 脚本启动后，自动检测遥控器与接收机的连接状态
2. 当检测到连接时，开始监控飞行数据
3. 检测到解锁（ARM）后，开始记录：
   - 记录初始电池电压和 BEC 电压
   - 开始计时
   - 监控并记录最大值（电流、功率、转速）
   - 监控并记录最小值（电压、BEC 电压）
4. 当连接断开时：
   - 检查飞行时间是否超过 30 秒
   - 如果超过，将此次飞行计入统计
   - 自动保存飞行数据到日志文件
   - 显示飞行数据面板（可手动关闭）

**飞行数据面板**
- 飞行结束后自动弹出
- 显示本次飞行的关键数据
- 按 EXIT 键或旋转编码器关闭面板

### 数据统计功能

**首次使用**
- 脚本首次运行时，如果 `/LOGS/RFStats.csv` 文件不存在，会自动启动统计扫描
- 扫描过程分为两个阶段：
  - 阶段 1：查找所有模型名称（进度 0-50%）
  - 阶段 2：统计各模型的飞行次数（进度 50-100%）
- 扫描在后台进行，不影响正常使用
- 扫描完成后，自动生成 `/LOGS/RFStats.csv` 统计文件

**统计文件更新**
- 每次完成有效飞行后，自动更新模型的飞行次数
- 统计文件保存在 `/LOGS/RFStats.csv`
- 格式：`模型名称|飞行次数`

---

## 日志文件格式

### 日志文件位置

**新格式（推荐）**
- 路径：`/LOGS/[模型名称]/RFLog_YYYYMMDD.csv`
- 例如：`/LOGS/M4/RFLog_20250101.csv`

**旧格式（兼容）**
- 路径：`/LOGS/RFLog_YYYYMMDD.csv`
- 脚本会自动尝试读取旧格式文件，但新记录会保存到新格式

### CSV 文件格式

日志文件使用管道符（|）分隔的 CSV 格式，每行代表一次飞行记录：

```
日期|模型名称|飞行时长|当日次数|容量|最低电压|最大电流|最大功率|最大转速|最低BEC|总飞行次数
```

**字段说明**
1. **日期**：YYYYMMDD 格式（如 20250101）
2. **模型名称**：当前使用的模型名称
3. **飞行时长**：MM:SS 格式（如 05:30 表示 5 分 30 秒）
4. **当日次数**：当天的第几次飞行
5. **容量**：电池容量消耗（mAh）
6. **最低电压**：飞行过程中的最低电池电压（V）
7. **最大电流**：飞行过程中的最大电流（A）
8. **最大功率**：飞行过程中的最大功率（W）
9. **最大转速**：飞行过程中的最大转速（RPM）
10. **最低BEC**：飞行过程中的最低 BEC 电压（V）
11. **总飞行次数**：该模型的总飞行次数

**示例**
```
20250101|M4|05:30|1|1200|3.5|45|157.5|12000|5.0|25
20250101|M4|06:15|2|1350|3.4|48|163.2|12500|4.9|26
```

---

## 界面说明

### 主界面布局

```
┌─────────────────────────────────┐
│ 模型名  │  飞行模式  │ 遥控器电压 │ ← 状态栏
├─────────────────────────────────┤
│ 电池图标 [电量条]                │
│ 电池电压（大字体）               │
│ ─────────────────────            │
│ 容量消耗 mAh                     │
│ ─────────────────────            │
│ 电流 当前/最大 A                 │
├───────┬─────────────────────────┤
│       │ 转速（大字体，居中）     │
│       │ RPM                     │
│       ├─────────────────────────┤
│       │ 油门 %  │ 电调温度 °C   │
├───────┴─────────────────────────┤
│ Time  │        飞行时长          │
│ ───── │                         │
│ BEC   │        BEC 电压          │
│ ───── │                         │
│ RSSI  │        信号强度 dB       │
└─────────────────────────────────┘
```

### 日志列表界面

```
┌─────────────────────────────────┐
│ 日期      │      飞行次数        │ ← 状态栏
├───────────┼─────────────────────┤
│ 01. 机型   │ 时长                │
│ 02. 机型   │ 时长                │ ← 可滚动列表
│ 03. 机型   │ 时长                │
│ ...       │                     │
├───────────┼─────────────────────┤
│           │ 电压图标 电压 V      │
│           │ 电池图标 容量 mAh    │
│           │ 电流图标 最大电流 A  │
│           │ 转速图标 最大转速 RPM│
└───────────┴─────────────────────┘
```

### 日期选择界面

```
┌─────────────────────────────────┐
│ Select Month  │  月份数量        │ ← 状态栏
├───────────────┼─────────────────┤
│ 2025-01       │    Select       │
│ 2024-12       │    Month        │
│ 2024-11       │                  │
│ ...           │                  │
└───────────────┴─────────────────┘

选择月份后：

┌─────────────────────────────────┐
│ 2025-01       │   日期数量       │ ← 状态栏
├───────────────┼─────────────────┤
│ 2025-01       │    01           │
│ 2024-12       │    02           │
│ 2024-11       │    03           │
│ ...           │    ...          │
└───────────────┴─────────────────┘
```

### 日志详情界面

```
┌─────────────────────────────────┐
│ Log Detail    │  记录序号/总数   │ ← 状态栏
├───────────────┼─────────────────┤
│ Model: 机型名 │ 功率图标 Power:  │
│               │      XXX W      │
│ Time: MM:SS   │                 │
│               │ 转速图标 RPM:   │
│ Today#: XX    │      XXXX       │
│               │                 │
│ Total: XXX    │ BEC图标 BEC:    │
│               │      X.X V      │
│               │                 │
│               │ 电压图标 MinV:   │
│               │      X.X V      │
│               │                 │
│               │ 电流图标 MaxI:   │
│               │      XX A       │
│               │                 │
│               │ 容量图标 Capa:   │
│               │      XXX mAh    │
└───────────────┴─────────────────┘
```

---

## 注意事项

### 重要提示

1. **首次使用必须创建模型文件夹**
   - 脚本不会自动创建模型文件夹
   - 使用前必须在 `/LOGS/` 目录下手动创建对应模型名称的文件夹
   - 例如：模型名为 "M4"，则创建 `/LOGS/M4/` 文件夹

2. **兼容性要求**
   - 仅支持 Rotorflight 2.1 及以上版本
   - 需要启用 ELRS 自定义遥测功能
   - 确保所有遥测传感器正确配置

3. **飞行时间限制**
   - 只有飞行时间超过 30 秒的飞行才会被记录
   - 低于 30 秒的飞行不会计入统计

4. **数据记录时机**
   - 飞行数据仅在连接断开时记录
   - 确保飞行结束后完全断开连接，以便数据正确保存

5. **内存管理**
   - 脚本会自动管理内存，限制日志条目数量（最多 99 条）
   - 日期扫描最多保留最近 24 个月的数据
   - 每月最多保留 31 天的记录

6. **统计文件生成**
   - 首次使用时，如果统计文件不存在，会自动扫描历史数据
   - 扫描过程在后台进行，可能需要一些时间
   - 扫描期间会显示进度条

### 常见问题

**Q: 脚本无法加载？**
- 检查脚本文件是否放在正确的目录（`/SCRIPTS/TELEMETRY/`）
- 检查遥控器系统是否支持 Lua 脚本
- 检查脚本文件名是否正确

**Q: 遥测数据不显示？**
- 检查遥测传感器是否已正确配置
- 检查 ELRS 自定义遥测是否已启用
- 检查接收机是否已连接

**Q: 飞行数据未记录？**
- 检查模型文件夹是否已创建
- 检查飞行时间是否超过 30 秒
- 检查连接是否正常断开（数据在断开时记录）

**Q: 日志文件无法读取？**
- 检查文件路径是否正确
- 检查文件格式是否正确
- 尝试手动打开 CSV 文件检查内容

**Q: 统计不准确？**
- 删除 `/LOGS/RFStats.csv` 文件，让脚本重新扫描
- 检查历史日志文件是否完整

---

## 技术参数

### 常量配置

- **最大日志条目数**：99 条
- **最小有效飞行时间**：30 秒
- **统计扫描批次大小**：3 个文件/批次
- **日志扫描批次大小**：5 天/批次
- **总扫描天数**：365 天
- **统计扫描第二阶段批次大小**：2 个文件/批次
- **日期字符串长度**：8 位（YYYYMMDD）

### 性能优化

- 使用缓存机制减少重复计算
- 批量处理文件读取，避免阻塞
- 智能内存管理，自动清理不需要的数据
- 优化的排序算法，提高响应速度

---

## 更新日志

### V2.1
- 支持按模型分类存储日志文件
- 改进的数据统计功能
- 优化的内存管理
- 改进的用户界面
- 支持日期选择功能
- 详细的日志查看功能

---

## 许可证

本脚本为开源软件，可自由使用和修改。

---

## 技术支持

如有问题或建议，请参考脚本注释或联系开发者。

---

**祝您飞行愉快！**




