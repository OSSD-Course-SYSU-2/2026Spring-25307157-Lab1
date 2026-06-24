import {
  BreakpointSystem,
  BreakpointConstants,
  BreakpointType,
  BreakpointValue,
  BreakpointOptions
} from '../utils/BreakpointSystem';
import {
  DistributedDataManager,
  PomodoroState
} from '../utils/DistributedDataManager';
import { AudioManager, NoiseType } from '../utils/AudioManager';
import { ThemeManager, ThemeMode, ThemeColors } from '../utils/ThemeManager';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PomodoroTimer';
const DOMAIN: number = 0xFF00;

@Entry
@Component
struct Index {
  // 番茄钟默认时间 25 分钟
  private readonly DEFAULT_FOCUS_TIME: number = 25 * 60;
  private readonly DEFAULT_SHORT_BREAK: number = 5 * 60;
  private readonly DEFAULT_LONG_BREAK: number = 15 * 60;
  
  // 使用 @State 管理时间变量（秒）
  @State remainingTime: number = this.DEFAULT_FOCUS_TIME;
  
  // 计时器状态：是否正在运行
  @State isRunning: boolean = false;
  
  // 计时器 ID
  private timer: number = -1;
  
  // 当前模式：focus-专注, shortBreak-短休, longBreak-长休
  @State currentMode: string = 'focus';
  
  // 自定义时长（分钟）
  @State customMinutes: number = 25;
  
  // 弹窗控制
  @State showCustomDialog: boolean = false;
  @State inputMinutes: string = '25';
  
  // 弹窗选择模式：focus-专注时长, break-休息时长
  @State dialogMode: string = 'focus';
  
  // 励志弹窗控制
  @State showMotivationDialog: boolean = false;
  @State currentMotivation: string = '';
  
  // 专注模式控制
  @State focusModeEnabled: boolean = false;
  @State currentNoiseType: NoiseType = NoiseType.RAIN;
  @State noiseVolume: number = 50; // 音量百分比 (0-100)
  
  // 音频管理器
  private audioManager: AudioManager = AudioManager.getInstance();
  
  // 主题管理器
  private themeManager: ThemeManager = ThemeManager.getInstance();
  
  // 当前主题颜色
  @State themeColors: ThemeColors = {
    background: '#1C1C1E',
    cardBackground: '#2C2C2E',
    dialogBackground: '#2C2C2E',
    textPrimary: '#FFFFFF',
    textSecondary: '#EBEBF5',
    textTertiary: '#8E8E93',
    buttonPrimary: '#FF6B6B',
    buttonSecondary: '#3A3A3C',
    buttonDisabled: '#48484A',
    primary: '#FF6B6B',
    primaryLight: '#FF8E8E',
    primaryDark: '#E85555',
    success: '#32D74B',
    warning: '#FF9F0A',
    error: '#FF453A',
    border: '#38383A',
    divider: '#3A3A3C',
    shadow: 'rgba(0, 0, 0, 0.3)'
  };
  
  // 励志短句数组
  private readonly MOTIVATION_QUOTES: string[] = [
    '每一次专注，都是对自己的投资 💪',
    '坚持就是胜利，你正在变得更好 ✨',
    '专注当下，成就未来 🌟',
    '时间是最公平的资源，珍惜每一刻 ⏰',
    '你的努力，终将闪耀 🌈',
    '专注是一种超能力，你正在使用它 🚀',
    '每一个番茄钟，都是成功的基石 🍅',
    '保持专注，奇迹正在发生 ✨',
    '你比想象中更强大，继续加油 💪',
    '专注的力量，无可阻挡 🔥',
    '这一刻的坚持，是明天的骄傲 🌟',
    '时间会证明一切，你的努力不会白费 ⏰',
    '专注是最好的天赋，你拥有它 🎯',
    '每一次开始，都是新的可能 🌈',
    '你正在创造属于自己的精彩 💫',
    '专注的力量，让平凡变得不凡 ⭐',
    '坚持专注，你就是赢家 🏆',
    '时间见证成长，专注成就梦想 🌺',
    '每一分钟专注，都是对自己的承诺 💎',
    '你正在用行动书写成功的故事 📖'
  ];
  
  // 断点系统
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  
  // 当前断点
  @StorageProp(BreakpointConstants.CURRENT_BREAKPOINT)
  @Watch('onBreakpointChange')
  currentBreakpoint: BreakpointType = BreakpointConstants.BREAKPOINT_SM;
  
  // 分布式数据管理
  private distributedManager: DistributedDataManager = DistributedDataManager.getInstance();
  
  // 设备ID
  private deviceId: string = 'local';
  
  // 是否显示同步状态
  @State showSyncStatus: boolean = false;
  @State syncStatusText: string = '';
  
  /**
   * 断点变化回调
   */
  onBreakpointChange(): void {
    hilog.info(DOMAIN, TAG, `Breakpoint changed to: ${this.currentBreakpoint}`);
  }
  
  /**
   * 格式化时间为 MM:SS
   */
  private formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * 开始计时器
   */
  private startTimer(): void {
    if (this.timer === -1) {
      this.timer = setInterval(() => {
        if (this.remainingTime > 0) {
          this.remainingTime--;
          // 每5秒同步一次状态到其他设备
          if (this.remainingTime % 5 === 0) {
            this.syncState();
          }
        } else {
          // 时间到，停止计时器
          this.stopTimer();
        }
      }, 1000);
    }
  }
  
  /**
   * 停止计时器
   */
  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }
  
  /**
   * 切换开始/暂停状态
   */
  private toggleTimer(): void {
    if (this.isRunning) {
      this.stopTimer();
    } else {
      this.startTimer();
      // 开始计时时显示励志弹窗
      this.showMotivation();
    }
    this.isRunning = !this.isRunning;
    // 状态变化时同步
    this.syncState();
  }
  
  /**
   * 显示随机励志短句
   */
  private showMotivation(): void {
    const randomIndex = Math.floor(Math.random() * this.MOTIVATION_QUOTES.length);
    this.currentMotivation = this.MOTIVATION_QUOTES[randomIndex];
    this.showMotivationDialog = true;
  }
  
  /**
   * 关闭励志弹窗
   */
  private closeMotivationDialog(): void {
    this.showMotivationDialog = false;
  }
  
  /**
   * 切换专注模式
   */
  private async toggleFocusMode(): Promise<void> {
    this.focusModeEnabled = !this.focusModeEnabled;
    
    if (this.focusModeEnabled) {
      // 开启专注模式，播放白噪音
      await this.audioManager.play(this.currentNoiseType);
      hilog.info(DOMAIN, TAG, 'Focus mode enabled, playing white noise');
    } else {
      // 关闭专注模式，停止白噪音
      await this.audioManager.stop();
      hilog.info(DOMAIN, TAG, 'Focus mode disabled, stopped white noise');
    }
  }
  
  /**
   * 切换噪音类型
   */
  private async switchNoiseType(type: NoiseType): Promise<void> {
    this.currentNoiseType = type;
    if (this.focusModeEnabled) {
      await this.audioManager.switchNoiseType(type);
    }
  }
  
  /**
   * 调节音量
   */
  private adjustVolume(volume: number): void {
    this.noiseVolume = volume;
    this.audioManager.setVolume(volume / 100); // 转換為 0-1 范围
  }
  
  /**
   * 切换主题
   */
  private async toggleTheme(): Promise<void> {
    await this.themeManager.toggleTheme();
    this.updateThemeColors();
  }
  
  /**
   * 更新主题颜色
   */
  private updateThemeColors(): void {
    this.themeColors = this.themeManager.getColors();
  }
  
  /**
   * 重置计时器
   */
  private resetTimer(): void {
    this.stopTimer();
    this.isRunning = false;
    this.remainingTime = this.getModeTime();
    // 重置时同步
    this.syncState();
  }
  
  /**
   * 获取当前模式的时间（秒）
   */
  private getModeTime(): number {
    switch (this.currentMode) {
      case 'focus':
        return this.customMinutes * 60;
      case 'shortBreak':
        return this.DEFAULT_SHORT_BREAK;
      case 'longBreak':
        return this.DEFAULT_LONG_BREAK;
      default:
        return this.DEFAULT_FOCUS_TIME;
    }
  }
  
  /**
   * 切换模式
   */
  private switchMode(mode: string): void {
    this.currentMode = mode;
    this.remainingTime = this.getModeTime();
    this.stopTimer();
    this.isRunning = false;
    this.syncState();
  }
  
  /**
   * 显示自定义时长弹窗
   */
  private showCustomTimeDialog(mode: string): void {
    this.dialogMode = mode;
    if (mode === 'focus') {
      this.inputMinutes = this.customMinutes.toString();
    } else {
      this.inputMinutes = '5'; // 默认休息时长
    }
    this.showCustomDialog = true;
  }
  
  /**
   * 确认自定义时长
   */
  private confirmCustomTime(): void {
    const minutes = parseInt(this.inputMinutes);
    if (minutes >= 1 && minutes <= 120) {
      if (this.dialogMode === 'focus') {
        this.customMinutes = minutes;
        if (this.currentMode === 'focus') {
          this.remainingTime = minutes * 60;
          this.stopTimer();
          this.isRunning = false;
          this.syncState();
        }
      } else {
        // 如果是休息时长，直接应用
        if (this.currentMode === 'shortBreak' || this.currentMode === 'longBreak') {
          this.remainingTime = minutes * 60;
          this.stopTimer();
          this.isRunning = false;
          this.syncState();
        }
      }
    }
    this.showCustomDialog = false;
  }
  
  /**
   * 同步状态到其他设备
   */
  private syncState(): void {
    const state: PomodoroState = {
      remainingTime: this.remainingTime,
      isRunning: this.isRunning,
      lastUpdateTime: Date.now(),
      deviceId: this.deviceId
    };
    this.distributedManager.syncState(state);
    this.distributedManager.saveStateToLocal(state);
  }
  
  /**
   * 处理分布式状态变化
   */
  private onDistributedStateChange(state: PomodoroState): void {
    // 如果是其他设备的状态更新，则同步到本地
    if (state.deviceId !== this.deviceId) {
      hilog.info(DOMAIN, TAG, `Received state from device: ${state.deviceId}`);
      
      // 显示同步状态
      this.showSyncStatus = true;
      this.syncStatusText = `已从其他设备同步`;
      setTimeout(() => {
        this.showSyncStatus = false;
      }, 2000);
      
      // 更新本地状态
      this.remainingTime = state.remainingTime;
      if (state.isRunning !== this.isRunning) {
        if (state.isRunning) {
          this.startTimer();
        } else {
          this.stopTimer();
        }
        this.isRunning = state.isRunning;
      }
    }
  }
  
  /**
   * 处理应用接续（迁移到其他设备）
   */
  private async onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult> {
    hilog.info(DOMAIN, TAG, 'onContinue called');
    
    // 保存当前状态
    this.syncState();
    
    // 将状态数据放入wantParam中传递
    wantParam['remainingTime'] = this.remainingTime;
    wantParam['isRunning'] = this.isRunning;
    wantParam['lastUpdateTime'] = Date.now();
    
    return AbilityConstant.OnContinueResult.AGREE;
  }
  
  /**
   * 处理应用接续恢复（从其他设备迁移过来）
   */
  private restoreFromContinue(want: Want): void {
    if (want.parameters) {
      const remainingTime = want.parameters['remainingTime'] as number;
      const isRunning = want.parameters['isRunning'] as boolean;
      
      if (remainingTime !== undefined) {
        this.remainingTime = remainingTime;
      }
      if (isRunning !== undefined) {
        this.isRunning = isRunning;
        if (this.isRunning) {
          this.startTimer();
        }
      }
      
      hilog.info(DOMAIN, TAG, `Restored from continue: ${this.remainingTime}, ${this.isRunning}`);
      
      // 显示恢复提示
      this.showSyncStatus = true;
      this.syncStatusText = '已从其他设备接续';
      setTimeout(() => {
        this.showSyncStatus = false;
      }, 2000);
    }
  }
  
  /**
   * 组件即将出现
   */
  aboutToAppear(): void {
    // 注册断点监听
    this.breakpointSystem.register();
    
    // 初始化主题管理器
    const context = getContext(this) as common.UIAbilityContext;
    this.themeManager.init(context).then(() => {
      this.updateThemeColors();
      hilog.info(DOMAIN, TAG, `Theme initialized: ${this.themeManager.getCurrentMode()}`);
    });
    
    // 初始化分布式数据管理
    this.distributedManager.init();
    this.distributedManager.setOnStateChange(this.onDistributedStateChange.bind(this));
    
    // 尝试从本地恢复状态
    const savedState = this.distributedManager.restoreStateFromLocal();
    if (savedState) {
      // 计算时间差，如果是运行中状态，需要扣除已过去的时间
      const elapsedSeconds = Math.floor((Date.now() - savedState.lastUpdateTime) / 1000);
      if (savedState.isRunning && elapsedSeconds < savedState.remainingTime) {
        this.remainingTime = savedState.remainingTime - elapsedSeconds;
        this.isRunning = true;
        this.startTimer();
      } else {
        this.remainingTime = savedState.remainingTime;
        this.isRunning = savedState.isRunning;
        if (this.isRunning) {
          this.startTimer();
        }
      }
    }
    
    hilog.info(DOMAIN, TAG, `Pomodoro timer initialized, breakpoint: ${this.currentBreakpoint}`);
  }
  
  /**
   * 组件即将销毁时清理计时器
   */
  aboutToDisappear(): void {
    this.stopTimer();
    this.breakpointSystem.unregister();
    
    // 保存状态
    this.syncState();
    
    // 清理音频资源
    this.audioManager.destroy();
    
    // 清理主题管理器资源
    this.themeManager.destroy();
    
    hilog.info(DOMAIN, TAG, 'Pomodoro timer destroyed');
  }
  
  /**
   * 获取响应式尺寸值
   */
  private getResponsiveValue<T>(xs: T, sm: T, md: T, lg: T): T {
    const options: BreakpointOptions<T> = { xs, sm, md, lg };
    const value = new BreakpointValue<T>(options);
    return value.getValue(this.currentBreakpoint) || sm;
  }
  
  build() {
    Column({ space: this.getResponsiveValue(20, 40, 50, 60) }) {
      // 顶部标题和主题切换按钮
      Row() {
        Text('番茄钟')
          .fontSize(this.getResponsiveValue(24, 28, 32, 36))
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        // 主题切换按钮
        Button(this.themeManager.getModeIcon())
          .width(40)
          .height(40)
          .fontSize(20)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(20)
          .onClick(() => {
            this.toggleTheme();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ top: this.getResponsiveValue(40, 60, 80, 100) })
      
      // 同步状态提示
      if (this.showSyncStatus) {
        Text(this.syncStatusText)
          .fontSize(14)
          .fontColor(this.themeColors.success)
          .margin({ top: 10 })
      }
      
      // 倒计时显示 - 粗大明显的数字字体
      Text(this.formatTime(this.remainingTime))
        .fontSize(this.getResponsiveValue(60, 80, 100, 120))
        .fontColor(this.themeColors.primary)
        .fontWeight(FontWeight.Bolder)
        .fontFamily('monospace')
        .margin({ top: this.getResponsiveValue(30, 40, 50, 60) })
      
      // 中间的大圆形按钮 - 开始/暂停
      Button(this.isRunning ? '暂停' : '开始')
        .width(this.getResponsiveValue(120, 160, 180, 200))
        .height(this.getResponsiveValue(120, 160, 180, 200))
        .fontSize(this.getResponsiveValue(24, 32, 36, 40))
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.isRunning ? this.themeColors.warning : this.themeColors.success)
        .borderRadius(this.getResponsiveValue(60, 80, 90, 100))
        .shadow({
          radius: 20,
          color: this.isRunning ? 'rgba(255, 149, 0, 0.4)' : 'rgba(52, 199, 89, 0.4)',
          offsetX: 0,
          offsetY: 8
        })
        .onClick(() => {
          this.toggleTimer();
        })
        .margin({ top: this.getResponsiveValue(30, 40, 50, 60) })
      
      // 模式选择按钮组
      Row({ space: this.getResponsiveValue(8, 12, 15, 18) }) {
        // 专注模式
        Button('专注')
          .width(this.getResponsiveValue(60, 80, 90, 100))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.currentMode === 'focus' ? this.themeColors.textPrimary : this.themeColors.success)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.currentMode === 'focus' ? this.themeColors.success : this.themeColors.cardBackground)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            this.switchMode('focus');
          })
        
        // 短休息
        Button('短休')
          .width(this.getResponsiveValue(60, 80, 90, 100))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.currentMode === 'shortBreak' ? this.themeColors.textPrimary : this.themeColors.warning)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.currentMode === 'shortBreak' ? this.themeColors.warning : this.themeColors.cardBackground)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            this.switchMode('shortBreak');
          })
        
        // 长休息
        Button('长休')
          .width(this.getResponsiveValue(60, 80, 90, 100))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.currentMode === 'longBreak' ? this.themeColors.textPrimary : '#5856D6')
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.currentMode === 'longBreak' ? '#5856D6' : this.themeColors.cardBackground)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            this.switchMode('longBreak');
          })
      }
      .margin({ top: this.getResponsiveValue(15, 20, 25, 30) })
      
      // 快捷预设按钮组
      Row({ space: this.getResponsiveValue(8, 12, 15, 18) }) {
        // 25分钟专注
        Button('25分钟')
          .width(this.getResponsiveValue(70, 90, 100, 110))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.buttonSecondary)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            this.customMinutes = 25;
            if (this.currentMode === 'focus') {
              this.remainingTime = 25 * 60;
              this.stopTimer();
              this.isRunning = false;
              this.syncState();
            }
          })
        
        // 5分钟短休
        Button('5分钟')
          .width(this.getResponsiveValue(70, 90, 100, 110))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.buttonSecondary)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            if (this.currentMode === 'shortBreak') {
              this.remainingTime = 5 * 60;
              this.stopTimer();
              this.isRunning = false;
              this.syncState();
            }
          })
        
        // 15分钟长休
        Button('15分钟')
          .width(this.getResponsiveValue(70, 90, 100, 110))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.buttonSecondary)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            if (this.currentMode === 'longBreak') {
              this.remainingTime = 15 * 60;
              this.stopTimer();
              this.isRunning = false;
              this.syncState();
            }
          })
        
        // 自定义按钮
        Button('自定义')
          .width(this.getResponsiveValue(70, 90, 100, 110))
          .height(this.getResponsiveValue(32, 40, 45, 50))
          .fontSize(this.getResponsiveValue(12, 14, 16, 18))
          .fontColor(this.themeColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.primary)
          .borderRadius(this.getResponsiveValue(16, 20, 22, 25))
          .onClick(() => {
            this.showCustomTimeDialog(this.currentMode === 'focus' ? 'focus' : 'break');
          })
      }
      .margin({ top: this.getResponsiveValue(10, 15, 20, 25) })
      
      // 底部重置按钮
      Button('重置')
        .width(this.getResponsiveValue(100, 120, 140, 160))
        .height(this.getResponsiveValue(40, 50, 55, 60))
        .fontSize(this.getResponsiveValue(16, 20, 22, 24))
        .fontColor(this.themeColors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.themeColors.textTertiary)
        .borderRadius(this.getResponsiveValue(20, 25, 27, 30))
        .onClick(() => {
          this.resetTimer();
        })
        .margin({ top: this.getResponsiveValue(15, 20, 25, 30) })
      
      // 专注模式控制面板
      Column({ space: 15 }) {
        // 专注模式开关
        Row({ space: 10 }) {
          Text('🎵 专注模式')
            .fontSize(16)
            .fontColor(this.themeColors.textPrimary)
            .fontWeight(FontWeight.Medium)
          
          Blank()
          
          Toggle({ type: ToggleType.Switch, isOn: this.focusModeEnabled })
            .selectedColor(this.themeColors.success)
            .onChange((isOn: boolean) => {
              this.toggleFocusMode();
            })
        }
        .width('90%')
        .height(50)
        .padding({ left: 15, right: 15 })
        .backgroundColor(this.themeColors.cardBackground)
        .borderRadius(12)
        
        // 专注模式展开控制（仅在开启时显示）
        if (this.focusModeEnabled) {
          Column({ space: 12 }) {
            // 噪音类型选择
            Text('背景音效')
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width('90%')
            
            Row({ space: 8 }) {
              ForEach(this.audioManager.getAllNoiseTypes(), (type: NoiseType) => {
                Button(`${this.audioManager.getNoiseTypeIcon(type)} ${this.audioManager.getNoiseTypeName(type)}`)
                  .fontSize(12)
                  .fontColor(this.currentNoiseType === type ? this.themeColors.textPrimary : this.themeColors.textSecondary)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(this.currentNoiseType === type ? this.themeColors.primary : this.themeColors.buttonSecondary)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .onClick(() => {
                    this.switchNoiseType(type);
                  })
              })
            }
            .width('90%')
            
            // 音量调节
            Row({ space: 10 }) {
              Text('🔈')
                .fontSize(16)
              
              Slider({
                value: this.noiseVolume,
                min: 0,
                max: 100,
                step: 1,
                style: SliderStyle.OutSet
              })
                .blockColor(this.themeColors.primary)
                .trackColor(this.themeColors.buttonSecondary)
                .selectedColor(this.themeColors.primary)
                .layoutWeight(1)
                .onChange((value: number) => {
                  this.adjustVolume(value);
                })
              
              Text('🔊')
                .fontSize(16)
            }
            .width('90%')
            .height(40)
          }
          .width('90%')
          .padding(15)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(12)
        }
      }
      .width('100%')
      .margin({ top: this.getResponsiveValue(10, 15, 20, 25) })
      
      // 设备信息提示（仅在多设备场景显示）
      if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_MD ||
          this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG) {
        Text(`当前设备: ${this.deviceId} | 断点: ${this.currentBreakpoint}`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 20 })
      }
      
      // 空白占位，使布局更平衡
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .justifyContent(FlexAlign.Start)
    .bindSheet($$this.showCustomDialog, this.CustomTimeSheet(), {
      height: 280,
      backgroundColor: this.themeColors.dialogBackground,
      dragBar: true,
      showClose: true
    })
    .bindSheet($$this.showMotivationDialog, this.MotivationSheet(), {
      height: 320,
      backgroundColor: this.themeColors.dialogBackground,
      dragBar: false,
      showClose: false
    })
  }
  
  /**
   * 励志弹窗内容
   */
  @Builder
  MotivationSheet() {
    Column({ space: 25 }) {
      // 顶部图标
      Text('🍅')
        .fontSize(60)
        .margin({ top: 20 })
      
      // 励志短句
      Text(this.currentMotivation)
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .lineHeight(30)
        .padding({ left: 30, right: 30 })
      
      // 开始计时提示
      Text('计时已开始，加油！')
        .fontSize(14)
        .fontColor('#34C759')
        .fontWeight(FontWeight.Medium)
      
      // 关闭按钮
      Button('开始专注')
        .width(200)
        .height(45)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#FF6B6B')
        .borderRadius(22)
        .onClick(() => {
          this.closeMotivationDialog();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 30 })
  }
  
  /**
   * 自定义时长弹窗内容
   */
  @Builder
  CustomTimeSheet() {
    Column({ space: 20 }) {
      // 标题
      Text(this.dialogMode === 'focus' ? '设置专注时长' : '设置休息时长')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10 })
      
      // 输入提示
      Text('请输入 1-120 分钟')
        .fontSize(14)
        .fontColor('#999999')
      
      // 输入框
      TextInput({ text: $$this.inputMinutes, placeholder: '输入分钟数' })
        .width(200)
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor('#3A3A3C')
        .borderRadius(10)
        .type(InputType.Number)
        .maxLength(3)
      
      // 确认按钮
      Button('确认')
        .width(200)
        .height(45)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#34C759')
        .borderRadius(22)
        .onClick(() => {
          this.confirmCustomTime();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 30 })
  }
}
