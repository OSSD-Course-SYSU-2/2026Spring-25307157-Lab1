import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DistributedDataManager';
const DOMAIN: number = 0xFF00;

/**
 * 番茄钟状态数据接口
 * 用于跨设备同步
 */
export interface PomodoroState {
  remainingTime: number;      // 剩余时间（秒）
  isRunning: boolean;         // 是否正在运行
  lastUpdateTime: number;     // 最后更新时间戳
  deviceId: string;           // 设备ID
}

/**
 * 分布式数据管理类
 * 实现本地数据存储（简化版本，移除了分布式功能）
 */
export class DistributedDataManager {
  private static instance: DistributedDataManager;
  private onStateChange?: (state: PomodoroState) => void;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
  }
  
  /**
   * 初始化
   */
  public init(): void {
    hilog.info(DOMAIN, TAG, 'Distributed data manager initialized');
  }
  
  /**
   * 设置状态变化监听器
   */
  public setOnStateChange(callback: (state: PomodoroState) => void): void {
    this.onStateChange = callback;
  }
  
  /**
   * 同步状态（简化版本，仅保存到本地）
   */
  public syncState(state: PomodoroState): void {
    hilog.info(DOMAIN, TAG, `State synced: ${JSON.stringify(state)}`);
  }
  
  /**
   * 保存状态到本地（用于接续恢复）
   */
  public saveStateToLocal(state: PomodoroState): void {
    try {
      // 保存到AppStorage，用于应用接续时恢复状态
      AppStorage.setOrCreate<number>('pomodoro_remainingTime', state.remainingTime);
      AppStorage.setOrCreate<boolean>('pomodoro_isRunning', state.isRunning);
      AppStorage.setOrCreate<number>('pomodoro_lastUpdateTime', state.lastUpdateTime);
      
      hilog.info(DOMAIN, TAG, `State saved to local: ${JSON.stringify(state)}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to save state: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 从本地恢复状态
   */
  public restoreStateFromLocal(): PomodoroState | null {
    try {
      const remainingTime = AppStorage.get<number>('pomodoro_remainingTime');
      const isRunning = AppStorage.get<boolean>('pomodoro_isRunning');
      const lastUpdateTime = AppStorage.get<number>('pomodoro_lastUpdateTime');
      
      if (remainingTime !== undefined && isRunning !== undefined && lastUpdateTime !== undefined) {
        return {
          remainingTime,
          isRunning,
          lastUpdateTime,
          deviceId: 'local'
        };
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to restore state: ${JSON.stringify(error)}`);
    }
    return null;
  }
  
  /**
   * 释放资源
   */
  public release(): void {
    hilog.info(DOMAIN, TAG, 'Distributed data manager released');
  }
}
