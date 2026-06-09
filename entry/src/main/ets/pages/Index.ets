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
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PomodoroTimer';
const DOMAIN: number = 0xFF00;

@Entry
@Component
struct Index {
  // 番茄钟默认时间 25 分钟
  private readonly DEFAULT_TIME: number = 25 * 60;
  
  // 使用 @State 管理时间变量（秒）
  @State remainingTime: number = this.DEFAULT_TIME;
  
  // 计时器状态：是否正在运行
  @State isRunning: boolean = false;
  
  // 计时器 ID
  private timer: number = -1;
  
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
    }
    this.isRunning = !this.isRunning;
    // 状态变化时同步
    this.syncState();
  }
  
  /**
   * 重置计时器
   */
  private resetTimer(): void {
    this.stopTimer();
    this.isRunning = false;
    this.remainingTime = this.DEFAULT_TIME;
    // 重置时同步
    this.syncState();
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
      // 顶部标题
      Text('番茄钟')
        .fontSize(this.getResponsiveValue(24, 28, 32, 36))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .margin({ top: this.getResponsiveValue(40, 60, 80, 100) })
      
      // 同步状态提示
      if (this.showSyncStatus) {
        Text(this.syncStatusText)
          .fontSize(14)
          .fontColor('#4CAF50')
          .margin({ top: 10 })
      }
      
      // 倒计时显示 - 粗大明显的数字字体
      Text(this.formatTime(this.remainingTime))
        .fontSize(this.getResponsiveValue(60, 80, 100, 120))
        .fontColor('#FF6B6B')
        .fontWeight(FontWeight.Bolder)
        .fontFamily('monospace')
        .margin({ top: this.getResponsiveValue(30, 40, 50, 60) })
      
      // 中间的大圆形按钮 - 开始/暂停
      Button(this.isRunning ? '暂停' : '开始')
        .width(this.getResponsiveValue(120, 160, 180, 200))
        .height(this.getResponsiveValue(120, 160, 180, 200))
        .fontSize(this.getResponsiveValue(24, 32, 36, 40))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.isRunning ? '#FF9500' : '#34C759')
        .borderRadius(this.getResponsiveValue(60, 80, 90, 100))
        .shadow({
          radius: 20,
          color: this.isRunning ? '#66FF9500' : '#6634C759',
          offsetX: 0,
          offsetY: 8
        })
        .onClick(() => {
          this.toggleTimer();
        })
        .margin({ top: this.getResponsiveValue(30, 40, 50, 60) })
      
      // 底部重置按钮
      Button('重置')
        .width(this.getResponsiveValue(100, 120, 140, 160))
        .height(this.getResponsiveValue(40, 50, 55, 60))
        .fontSize(this.getResponsiveValue(16, 20, 22, 24))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#8E8E93')
        .borderRadius(this.getResponsiveValue(20, 25, 27, 30))
        .onClick(() => {
          this.resetTimer();
        })
        .margin({ top: this.getResponsiveValue(15, 20, 25, 30) })
      
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
    .backgroundColor('#1C1C1E')
    .justifyContent(FlexAlign.Start)
  }
}
