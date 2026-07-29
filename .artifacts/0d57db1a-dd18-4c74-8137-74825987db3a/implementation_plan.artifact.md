# 实施计划 - 智能 CSV 模糊解析逻辑升级

升级 CSV 导入逻辑，引入智能表头模糊匹配，支持多种日期格式解析，并增加年份误记防护逻辑，确保从各类记账 App（懒猫、随手记、微信、支付宝等）导入数据的准确性。

## 用户评审确认

> [!IMPORTANT]
> **引入官方 CSV 库**：我们将添加 `csv` 依赖包，并设置 `shouldParseNumbers: false`，以确保日期字符串不被错误地截断或转换。
> **全能模糊匹配**：通过关键词矩阵自动识别日期、金额、收支类型、支出和里程等列，适配市面上主流记账软件。
> **全格式日期支持**：支持 `2026年07月27日`、`2026/07/27`、`2026.07.27` 等多种日期分隔符。
> **年份防护盾**：强制排除 `2024~2030` 之间的数字作为金额或里程，彻底杜绝年份误入账目的问题。

## 拟议变更

### [Component] 项目配置

#### [MODIFY] [pubspec.yaml](file:///Users/zhangyuanhua/StudioProjects/taxi_accounting_app/pubspec.yaml)
- 添加 `csv: ^6.0.0` 依赖。

### [Component] Flutter 逻辑层

#### [MODIFY] [main.dart](file:///Users/zhangyuanhua/StudioProjects/taxi_accounting_app/lib/main.dart)
- **重写 `_parseCsvRecords`**：
    - 使用 `CsvToListConverter(shouldParseNumbers: false)` 进行解析。
    - 实现一套基于关键词矩阵的 `findColumn` 模糊匹配逻辑。
    - **日期解析增强**：实现一个更通用的日期转换器，处理中文单位和各类分隔符。
    - **数值解析增强**：在解析数字时，增加对 `2024-2030` 的硬性排除。
    - **收支分类适配**：根据“收支类型”、“类别”和“备注”自动分拣金额到收入或具体的支出项。

## 验证方案

### 自动化验证
- 编写测试用例，模拟包含不同表头（如“交易时间” vs “日期”）和不同日期格式（如“2026.07.29”）的 CSV 字符串，确保解析结果一致且正确。
- 确认金额列中的 `2026` 被正确过滤。

### 手动验证
- 在平板上执行 **Hot Restart** 并重新导入包含复杂表头的 CSV 文件。
- 检查明细页面，确认金额和日期完全对齐。
