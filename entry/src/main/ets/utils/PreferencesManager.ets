import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PreferencesManager';
const DOMAIN: number = 0xFF00;
const PREFERENCES_NAME: string = 'pomodoro_settings';

/**
 * 用户首选项管理类
 * 用于保存和读取用户设置（主题、自定义时长、专注模式等）
 */
export class PreferencesManager {
  private static instance: PreferencesManager;
  private preferences: preferences.Preferences | null = null;

  // 默认值常量
  private readonly DEFAULT_FOCUS_TIME: number = 25; // 默认专注时长（分钟）
  private readonly DEFAULT_SHORT_BREAK: number = 5; // 默认短休息时长（分钟）
  private readonly DEFAULT_LONG_BREAK: number = 15; // 默认长休息时长（分钟）
  private readonly DEFAULT_IS_DARK_MODE: boolean = false; // 默认浅色模式
  private readonly DEFAULT_NOISE_TYPE: string = 'rain'; // 默认噪音类型
  private readonly DEFAULT_NOISE_VOLUME: number = 50; // 默认音量

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): PreferencesManager {
    if (!PreferencesManager.instance) {
      PreferencesManager.instance = new PreferencesManager();
    }
    return PreferencesManager.instance;
  }

  /**
   * 初始化首选项管理器
   */
  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      hilog.info(DOMAIN, TAG, 'PreferencesManager initialized');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 保存专注时长（分钟）
   */
  public async saveFocusTime(minutes: number): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('focus_time', minutes);
      await this.preferences.flush();
    }
  }

  /**
   * 获取专注时长（分钟）
   */
  public async getFocusTime(): Promise<number> {
    if (this.preferences) {
      return await this.preferences.get('focus_time', this.DEFAULT_FOCUS_TIME) as number;
    }
    return this.DEFAULT_FOCUS_TIME;
  }

  /**
   * 保存短休息时长（分钟）
   */
  public async saveShortBreakTime(minutes: number): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('short_break_time', minutes);
      await this.preferences.flush();
    }
  }

  /**
   * 获取短休息时长（分钟）
   */
  public async getShortBreakTime(): Promise<number> {
    if (this.preferences) {
      return await this.preferences.get('short_break_time', this.DEFAULT_SHORT_BREAK) as number;
    }
    return this.DEFAULT_SHORT_BREAK;
  }

  /**
   * 保存长休息时长（分钟）
   */
  public async saveLongBreakTime(minutes: number): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('long_break_time', minutes);
      await this.preferences.flush();
    }
  }

  /**
   * 获取长休息时长（分钟）
   */
  public async getLongBreakTime(): Promise<number> {
    if (this.preferences) {
      return await this.preferences.get('long_break_time', this.DEFAULT_LONG_BREAK) as number;
    }
    return this.DEFAULT_LONG_BREAK;
  }

  /**
   * 保存深色模式设置
   */
  public async saveDarkMode(isDark: boolean): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('is_dark_mode', isDark);
      await this.preferences.flush();
    }
  }

  /**
   * 获取深色模式设置
   */
  public async getDarkMode(): Promise<boolean> {
    if (this.preferences) {
      return await this.preferences.get('is_dark_mode', this.DEFAULT_IS_DARK_MODE) as boolean;
    }
    return this.DEFAULT_IS_DARK_MODE;
  }

  /**
   * 保存噪音类型
   */
  public async saveNoiseType(type: string): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('noise_type', type);
      await this.preferences.flush();
    }
  }

  /**
   * 获取噪音类型
   */
  public async getNoiseType(): Promise<string> {
    if (this.preferences) {
      return await this.preferences.get('noise_type', this.DEFAULT_NOISE_TYPE) as string;
    }
    return this.DEFAULT_NOISE_TYPE;
  }

  /**
   * 保存噪音音量
   */
  public async saveNoiseVolume(volume: number): Promise<void> {
    if (this.preferences) {
      await this.preferences.put('noise_volume', volume);
      await this.preferences.flush();
    }
  }

  /**
   * 获取噪音音量
   */
  public async getNoiseVolume(): Promise<number> {
    if (this.preferences) {
      return await this.preferences.get('noise_volume', this.DEFAULT_NOISE_VOLUME) as number;
    }
    return this.DEFAULT_NOISE_VOLUME;
  }
}
