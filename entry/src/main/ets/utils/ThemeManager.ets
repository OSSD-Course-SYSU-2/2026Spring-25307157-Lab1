import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ThemeManager';
const DOMAIN: number = 0xFF00;
const THEME_KEY: string = 'app_theme_mode';

/**
 * 主题模式枚举
 */
export enum ThemeMode {
  LIGHT = 'light',  // 浅色模式
  DARK = 'dark'     // 深色模式
}

/**
 * 主题颜色配置接口
 */
export interface ThemeColors {
  // 背景色
  background: string;
  cardBackground: string;
  dialogBackground: string;
  
  // 文本色
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  
  // 按钮色
  buttonPrimary: string;
  buttonSecondary: string;
  buttonDisabled: string;
  
  // 主题色
  primary: string;
  primaryLight: string;
  primaryDark: string;
  
  // 状态色
  success: string;
  warning: string;
  error: string;
  
  // 边框色
  border: string;
  divider: string;
  
  // 阴影色
  shadow: string;
}

/**
 * 浅色主题颜色配置
 */
const LIGHT_THEME: ThemeColors = {
  background: '#F5F5F5',
  cardBackground: '#FFFFFF',
  dialogBackground: '#FFFFFF',
  
  textPrimary: '#1C1C1E',
  textSecondary: '#3C3C43',
  textTertiary: '#8E8E93',
  
  buttonPrimary: '#FF6B6B',
  buttonSecondary: '#3A3A3C',
  buttonDisabled: '#C7C7CC',
  
  primary: '#FF6B6B',
  primaryLight: '#FF8E8E',
  primaryDark: '#E85555',
  
  success: '#34C759',
  warning: '#FF9500',
  error: '#FF3B30',
  
  border: '#C6C6C8',
  divider: '#E5E5EA',
  
  shadow: 'rgba(0, 0, 0, 0.1)'
};

/**
 * 深色主题颜色配置
 */
const DARK_THEME: ThemeColors = {
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

/**
 * 主题管理器 - 管理应用主题切换
 */
export class ThemeManager {
  private static instance: ThemeManager;
  private currentMode: ThemeMode = ThemeMode.LIGHT;
  private preferences: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }
  
  /**
   * 初始化主题管理器
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context;
      
      // 获取Preferences实例
      this.preferences = await preferences.getPreferences(context, 'theme_preferences');
      
      // 读取保存的主题设置
      const savedMode = await this.preferences.get(THEME_KEY, ThemeMode.LIGHT) as string;
      this.currentMode = savedMode as ThemeMode;
      
      hilog.info(DOMAIN, TAG, `Theme initialized: ${this.currentMode}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init theme: ${JSON.stringify(error)}`);
      this.currentMode = ThemeMode.LIGHT;
    }
  }
  
  /**
   * 获取当前主题模式
   */
  getCurrentMode(): ThemeMode {
    return this.currentMode;
  }
  
  /**
   * 判断是否为深色模式
   */
  isDarkMode(): boolean {
    return this.currentMode === ThemeMode.DARK;
  }
  
  /**
   * 获取当前主题颜色
   */
  getColors(): ThemeColors {
    return this.currentMode === ThemeMode.DARK ? DARK_THEME : LIGHT_THEME;
  }
  
  /**
   * 切换主题模式
   */
  async toggleTheme(): Promise<void> {
    const newMode = this.currentMode === ThemeMode.LIGHT ? ThemeMode.DARK : ThemeMode.LIGHT;
    await this.setTheme(newMode);
  }
  
  /**
   * 设置主题模式
   */
  async setTheme(mode: ThemeMode): Promise<void> {
    try {
      this.currentMode = mode;
      
      // 保存主题设置
      if (this.preferences) {
        await this.preferences.put(THEME_KEY, mode);
        await this.preferences.flush();
        hilog.info(DOMAIN, TAG, `Theme saved: ${mode}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to save theme: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取主题模式名称
   */
  getModeName(): string {
    return this.currentMode === ThemeMode.DARK ? '深色模式' : '浅色模式';
  }
  
  /**
   * 获取主题图标
   */
  getModeIcon(): string {
    return this.currentMode === ThemeMode.DARK ? '🌙' : '☀️';
  }
  
  /**
   * 根据主题获取颜色
   */
  getColor(colorKey: keyof ThemeColors): string {
    const colors = this.getColors();
    switch (colorKey) {
      case 'background':
        return colors.background;
      case 'cardBackground':
        return colors.cardBackground;
      case 'dialogBackground':
        return colors.dialogBackground;
      case 'textPrimary':
        return colors.textPrimary;
      case 'textSecondary':
        return colors.textSecondary;
      case 'textTertiary':
        return colors.textTertiary;
      case 'buttonPrimary':
        return colors.buttonPrimary;
      case 'buttonSecondary':
        return colors.buttonSecondary;
      case 'buttonDisabled':
        return colors.buttonDisabled;
      case 'primary':
        return colors.primary;
      case 'primaryLight':
        return colors.primaryLight;
      case 'primaryDark':
        return colors.primaryDark;
      case 'success':
        return colors.success;
      case 'warning':
        return colors.warning;
      case 'error':
        return colors.error;
      case 'border':
        return colors.border;
      case 'divider':
        return colors.divider;
      case 'shadow':
        return colors.shadow;
      default:
        return colors.background;
    }
  }
  
  /**
   * 获取对比色（用于文本在背景上的显示）
   */
  getContrastColor(background: string): string {
    // 简单的对比色计算
    const isDark = this.isColorDark(background);
    return isDark ? '#FFFFFF' : '#1C1C1E';
  }
  
  /**
   * 判断颜色是否为深色
   */
  private isColorDark(color: string): boolean {
    // 移除 # 号
    const hex = color.replace('#', '');
    
    // 解析RGB值
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    
    // 计算亮度
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    
    return brightness < 128;
  }
  
  /**
   * 获取半透明背景色
   */
  getTranslucentBackground(opacity: number = 0.8): string {
    const colors = this.getColors();
    const hex = colors.background.replace('#', '');
    
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }
  
  /**
   * 销毁资源
   */
  async destroy(): Promise<void> {
    try {
      if (this.preferences) {
        await this.preferences.flush();
      }
      hilog.info(DOMAIN, TAG, 'ThemeManager destroyed');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to destroy: ${JSON.stringify(error)}`);
    }
  }
}
