# 智能 CSV 导入增强与编码兼容修复

解决 CSV 导入显示 0.00 的问题，增加深度日志输出，并实现 GBK/UTF-8 自动识别，同时优化设置页面的敏感操作展示。

## 用户评审确认

> [!IMPORTANT]
> **编码兼容（GBK/UTF-8）**：
> 针对中国环境下 Excel 导出的 CSV 常使用 GBK 编码的问题，我将修改 Android 原生逻辑，自动尝试 UTF-8 和 GBK 解析。
>
> **全方位日志调试**：
> 将在控制台输出：
> 1. 原始文件前 300 字符。
> 2. 解析总行数。
> 3. 识别到的表头行。
> 4. 各个关键列（日期、金额等）的匹配索引。
> 5. 前 3 行数据的解析细节。
>
> **逻辑降级（Fallback）**：
> 如果通过关键词没匹配到“金额”列，系统将自动扫描数据，寻找非日期列的纯数字列作为金额。

## 拟议变更

### [Component] Android 原生层

#### [MODIFY] [MainActivity.kt](file:///Users/zhangyuanhua/StudioProjects/taxi_accounting_app/android/app/src/main/kotlin/com/outefol/taxi_accounting_app/MainActivity.kt)
- 引入 `java.nio.charset.Charset`。
- 修改 `openText` 逻辑：读取文件字节流，尝试 UTF-8 解析，若包含非法字符则回退到 GBK 解析，解决中文乱码导致的识别失败。

### [Component] Flutter 逻辑层

#### [MODIFY] [main.dart](file:///Users/zhangyuanhua/StudioProjects/taxi_accounting_app/lib/main.dart)

- **重构 `_parseCsvRecords`**：
    - 添加要求的 `print` 日志。
    - **表头搜索增强**：不仅搜索包含“日期”的行，还将根据数据列特征进一步确认表头行。
    - **自动探测金额列**：若 `amountIdx` 为 -1，遍历前几行数据，寻找能够成功解析为正数且不是年份的数字列。
- **优化 `_cleanToDouble`**：增加对空值和特殊符号更稳健的处理。
- **UI 优化（SettingsPage）**：
    - 确保“危险区域（点击展开）”折叠面板及其内部的“清空流水”功能展示符合预期。

## 验证方案

### 调试验证
- 导入一个 GBK 编码的 CSV 文件，确认控制台输出的文字不是乱码。
- 检查控制台日志中的 `Matched Indices`，确认各列定位准确。

### 手动验证
- 在平板上点击 **Hot Restart** 并导入 CSV。
- 确认明细页面金额恢复正常。
