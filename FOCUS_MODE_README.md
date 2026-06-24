# 专注模式 + 背景白噪音功能实现说明

## 功能概述

已成功实现专注模式 + 背景白噪音功能，包括：

### 1. 专注模式开关
- 一键开启/关闭专注模式
- 开启时自动播放背景白噪音
- 关闭时自动停止音效

### 2. 四种白噪音类型
- 🌧️ **雨声**：轻柔的雨滴声，适合深度专注
- ☕ **咖啡馆**：咖啡馆环境音，适合轻度专注
- 🌲 **森林**：森林鸟鸣声，适合自然放松
- 🌊 **海浪**：海浪拍岸声，适合冥想专注

### 3. 音量控制
- 音量范围：0-100%
- 实时调节，即时生效
- 默认音量：50%

### 4. 后台持续播放
- 音效在后台持续循环播放
- 不会因为应用切换而停止
- 退出专注模式自动停止

## 技术实现

### 文件结构
```
entry/src/main/ets/
├── pages/
│   └── Index.ets          # 主页面（已添加专注模式UI）
└── utils/
    └── AudioManager.ets   # 音频管理工具类
```

### 核心类：AudioManager

**功能：**
- 单例模式管理音频播放
- 支持四种白噪音类型切换
- 音量控制（0.0-1.0）
- 循环播放支持

**API：**
```typescript
// 获取实例
const audioManager = AudioManager.getInstance();

// 播放指定类型的白噪音
await audioManager.play(NoiseType.RAIN);

// 停止播放
await audioManager.stop();

// 设置音量
await audioManager.setVolume(0.5); // 0.0-1.0

// 切换噪音类型
await audioManager.switchNoiseType(NoiseType.CAFE);

// 获取当前噪音类型
const currentType = audioManager.getCurrentNoiseType();

// 获取所有噪音类型
const allTypes = audioManager.getAllNoiseTypes();

// 销毁资源
await audioManager.destroy();
```

## ⚠️ 重要：音频文件配置

### 需要添加的音频文件

请在以下目录添加对应的音频文件：

```
entry/src/main/resources/rawfile/
├── rain.mp3      # 雨声（必需）
├── cafe.mp3      # 咖啡馆声音（必需）
├── forest.mp3    # 森林声音（必需）
└── ocean.mp3     # 海浪声音（必需）
```

### 音频文件要求

1. **格式**：MP3 格式（推荐）或 AAC、M4A、WAV
2. **时长**：建议 1-5 分钟的循环音频
3. **质量**：建议 128kbps 或以上
4. **大小**：单个文件建议不超过 5MB

### 音频文件获取建议

可以从以下渠道获取免费的白噪音音频：

1. **免费音频网站**：
   - Freesound (https://freesound.org)
   - Pixabay Music (https://pixabay.com/music)
   - Mixkit (https://mixkit.co/free-sound-effects)

2. **推荐关键词**：
   - 雨声：rain sounds, rain ambience
   - 咖啡馆：cafe ambience, coffee shop sounds
   - 森林：forest sounds, nature ambience
   - 海浪：ocean waves, sea sounds

## 使用说明

### 开启专注模式

1. 在主界面找到「🎵 专注模式」开关
2. 点击开关开启专注模式
3. 默认播放雨声，音量 50%

### 切换白噪音类型

1. 开启专注模式后，下方会显示「背景音效」选项
2. 点击对应的按钮切换噪音类型：
   - 🌧️ 雨声
   - ☕ 咖啡馆
   - 🌲 森林
   - 🌊 海浪

### 调节音量

1. 在专注模式面板中找到音量滑块
2. 拖动滑块调节音量（0-100%）
3. 左侧🔈表示静音，右侧🔊表示最大音量

### 关闭专注模式

1. 点击「🎵 专注模式」开关关闭
2. 音效自动停止
3. 音量设置会被保留

## 注意事项

1. **音频文件缺失**：如果没有添加音频文件，专注模式开关可以正常切换，但不会播放声音
2. **权限要求**：应用需要音频播放权限（已在 module.json5 中配置）
3. **后台播放**：当前实现不支持应用退到后台后继续播放，如需后台播放需要申请长时任务
4. **音频焦点**：应用会自动处理音频焦点，不会打断其他应用的音频播放

## 扩展建议

### 1. 添加更多白噪音类型

在 `AudioManager.ets` 中：

```typescript
// 添加新的噪音类型
export enum NoiseType {
  RAIN = 'rain',
  CAFE = 'cafe',
  FOREST = 'forest',
  OCEAN = 'ocean',
  FIRE = 'fire',      // 新增：篝火声
  WIND = 'wind'       // 新增：风声
}

// 添加对应的文件路径
private getNoiseFilePath(type: NoiseType): string {
  switch (type) {
    case NoiseType.FIRE:
      return 'fire.mp3';
    case NoiseType.WIND:
      return 'wind.mp3';
    // ...
  }
}
```

### 2. 添加计时器联动

可以实现在计时结束时自动停止白噪音：

```typescript
// 在计时结束回调中
if (this.focusModeEnabled) {
  await this.audioManager.stop();
}
```

### 3. 添加音效预设

可以添加不同的音效组合预设：

```typescript
// 混合音效预设
interface AudioPreset {
  name: string;
  tracks: {
    type: NoiseType;
    volume: number;
  }[];
}
```

## 问题排查

### 问题1：没有声音

**检查项：**
1. 确认音频文件已添加到 `rawfile` 目录
2. 确认音频文件名称正确（rain.mp3, cafe.mp3 等）
3. 确认音量滑块不在 0 位置
4. 查看日志输出（hilog）是否有错误信息

### 问题2：应用崩溃

**可能原因：**
1. 音频文件格式不支持
2. 音频文件损坏
3. 内存不足

**解决方案：**
1. 使用标准 MP3 格式
2. 检查音频文件是否可以正常播放
3. 减小音频文件大小

### 问题3：音效卡顿

**可能原因：**
1. 音频文件过大
2. 设备性能不足

**解决方案：**
1. 压缩音频文件
2. 降低音频质量
3. 使用更短的循环音频

## 编译验证

✅ 代码编译成功
✅ 无语法错误
✅ 无类型错误

## 下一步

1. **添加音频文件**：按照上述说明添加四个音频文件
2. **测试功能**：运行应用测试专注模式功能
3. **调整参数**：根据实际效果调整默认音量和UI布局
