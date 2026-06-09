import { mediaquery } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';

/**
 * 断点类型定义
 * xs: 超小屏 (0-320vp) - 智能穿戴
 * sm: 小屏 (320-600vp) - 手机竖屏
 * md: 中屏 (600-840vp) - 折叠屏/小平板
 * lg: 大屏 (840vp+) - 平板/PC
 */
export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg';

/**
 * 断点常量
 */
export class BreakpointConstants {
  static readonly BREAKPOINT_XS: BreakpointType = 'xs';
  static readonly BREAKPOINT_SM: BreakpointType = 'sm';
  static readonly BREAKPOINT_MD: BreakpointType = 'md';
  static readonly BREAKPOINT_LG: BreakpointType = 'lg';
  
  // 断点范围定义
  static readonly RANGE_SM: string = '(320vp<=width<600vp)';
  static readonly RANGE_MD: string = '(600vp<=width<840vp)';
  static readonly RANGE_LG: string = '(840vp<=width)';
  
  // 当前断点存储键
  static readonly CURRENT_BREAKPOINT: string = 'currentBreakpoint';
}

/**
 * 断点系统工具类
 * 用于监听设备屏幕尺寸变化，实现响应式布局
 */
export class BreakpointSystem {
  private currentBreakpoint: BreakpointType = BreakpointConstants.BREAKPOINT_SM;
  private smListener?: mediaquery.MediaQueryListener;
  private mdListener?: mediaquery.MediaQueryListener;
  private lgListener?: mediaquery.MediaQueryListener;
  
  /**
   * 更新当前断点并存储到全局状态
   */
  private updateCurrentBreakpoint(breakpoint: BreakpointType): void {
    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = breakpoint;
      // 存储到AppStorage供全局使用
      AppStorage.setOrCreate<BreakpointType>(
        BreakpointConstants.CURRENT_BREAKPOINT,
        this.currentBreakpoint
      );
    }
  }
  
  /**
   * SM断点监听回调
   */
  private isBreakpointSM = (mediaQueryResult: mediaquery.MediaQueryResult): void => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_SM);
    }
  }
  
  /**
   * MD断点监听回调
   */
  private isBreakpointMD = (mediaQueryResult: mediaquery.MediaQueryResult): void => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_MD);
    }
  }
  
  /**
   * LG断点监听回调
   */
  private isBreakpointLG = (mediaQueryResult: mediaquery.MediaQueryResult): void => {
    if (mediaQueryResult.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_LG);
    }
  }
  
  /**
   * 注册断点监听
   */
  public register(): void {
    // 监听SM断点 (320-600vp)
    this.smListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_SM);
    this.smListener.on('change', this.isBreakpointSM);
    
    // 监听MD断点 (600-840vp)
    this.mdListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_MD);
    this.mdListener.on('change', this.isBreakpointMD);
    
    // 监听LG断点 (840vp+)
    this.lgListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_LG);
    this.lgListener.on('change', this.isBreakpointLG);
    
    // 初始化当前断点
    if (this.smListener.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_SM);
    } else if (this.mdListener.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_MD);
    } else if (this.lgListener.matches) {
      this.updateCurrentBreakpoint(BreakpointConstants.BREAKPOINT_LG);
    }
  }
  
  /**
   * 注销断点监听
   */
  public unregister(): void {
    if (this.smListener) {
      this.smListener.off('change', this.isBreakpointSM);
    }
    if (this.mdListener) {
      this.mdListener.off('change', this.isBreakpointMD);
    }
    if (this.lgListener) {
      this.lgListener.off('change', this.isBreakpointLG);
    }
  }
  
  /**
   * 获取当前断点
   */
  public getCurrentBreakpoint(): BreakpointType {
    return this.currentBreakpoint;
  }
}

/**
 * 断点值选项接口
 */
export interface BreakpointOptions<T> {
  xs?: T;
  sm?: T;
  md?: T;
  lg?: T;
}

/**
 * 断点值映射工具类
 * 根据不同断点返回不同的值
 */
export class BreakpointValue<T> {
  private xs?: T;
  private sm?: T;
  private md?: T;
  private lg?: T;
  
  constructor(options: BreakpointOptions<T>) {
    this.xs = options.xs;
    this.sm = options.sm;
    this.md = options.md;
    this.lg = options.lg;
  }
  
  /**
   * 根据断点获取对应的值
   */
  getValue(breakpoint: BreakpointType): T | undefined {
    switch (breakpoint) {
      case 'xs':
        return this.xs;
      case 'sm':
        return this.sm;
      case 'md':
        return this.md;
      case 'lg':
        return this.lg;
      default:
        return this.sm;
    }
  }
}
