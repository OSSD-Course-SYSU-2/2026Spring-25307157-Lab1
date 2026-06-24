import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'AudioManager';
const DOMAIN: number = 0xFF00;

/**
 * 噪音类型枚举
 */
export enum NoiseType {
  RAIN = 'rain',           // 雨声
  CAFE = 'cafe',           // 咖啡馆
  FOREST = 'forest',       // 森林
  OCEAN = 'ocean'          // 海浪
}

/**
 * 音频管理器 - 管理背景白噪音播放
 */
export class AudioManager {
  private static instance: AudioManager;
  private avPlayer: media.AVPlayer | null = null;
  private currentNoiseType: NoiseType = NoiseType.RAIN;
  private isPlaying: boolean = false;
  private volume: number = 0.5; // 默认音量 50%
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }
  
  /**
   * 获取噪音类型对应的音频文件路径
   */
  private getNoiseFilePath(type: NoiseType): string {
    switch (type) {
      case NoiseType.RAIN:
        return 'rain.mp3';
      case NoiseType.CAFE:
        return 'cafe.mp3';
      case NoiseType.FOREST:
        return 'forest.mp3';
      case NoiseType.OCEAN:
        return 'ocean.mp3';
      default:
        return 'rain.mp3';
    }
  }
  
  /**
   * 获取噪音类型的中文名称
   */
  getNoiseTypeName(type: NoiseType): string {
    switch (type) {
      case NoiseType.RAIN:
        return '雨声';
      case NoiseType.CAFE:
        return '咖啡馆';
      case NoiseType.FOREST:
        return '森林';
      case NoiseType.OCEAN:
        return '海浪';
      default:
        return '雨声';
    }
  }
  
  /**
   * 获取噪音类型的图标
   */
  getNoiseTypeIcon(type: NoiseType): string {
    switch (type) {
      case NoiseType.RAIN:
        return '🌧️';
      case NoiseType.CAFE:
        return '☕';
      case NoiseType.FOREST:
        return '🌲';
      case NoiseType.OCEAN:
        return '🌊';
      default:
        return '🌧️';
    }
  }
  
  /**
   * 初始化并播放音频
   */
  async play(type: NoiseType = NoiseType.RAIN): Promise<void> {
    try {
      // 如果正在播放且类型相同，则不重复播放
      if (this.isPlaying && this.currentNoiseType === type) {
        hilog.info(DOMAIN, TAG, 'Already playing the same noise type');
        return;
      }
      
      // 停止当前播放
      await this.stop();
      
      // 创建新的 AVPlayer
      this.avPlayer = await media.createAVPlayer();
      
      // 获取音频文件描述符
      const context = getContext() as common.UIAbilityContext;
      const audioPath = this.getNoiseFilePath(type);
      
      hilog.info(DOMAIN, TAG, `Loading audio: ${audioPath}`);
      
      try {
        // 尝试从rawfile加载音频
        const fileDescriptor = await context.resourceManager.getRawFd(audioPath);
        this.avPlayer.fdSrc = {
          fd: fileDescriptor.fd,
          offset: fileDescriptor.offset,
          length: fileDescriptor.length
        };
        
        // 设置状态监听
        this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
          hilog.info(DOMAIN, TAG, `Player state changed to: ${state}`);
          if (state === 'prepared') {
            // 设置循环播放
            this.avPlayer!.loop = true;
            // 设置音量
            await this.avPlayer!.setVolume(this.volume);
            // 开始播放
            await this.avPlayer!.play();
            this.isPlaying = true;
            hilog.info(DOMAIN, TAG, `Started playing: ${this.getNoiseTypeName(type)}`);
          }
        });
        
        // 设置错误监听
        this.avPlayer.on('error', (err: BusinessError) => {
          hilog.error(DOMAIN, TAG, `Audio error: ${err.message}`);
          this.isPlaying = false;
        });
        
        // 准备播放
        await this.avPlayer.prepare();
        
        this.currentNoiseType = type;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to load audio file: ${JSON.stringify(error)}`);
        this.isPlaying = false;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to play audio: ${JSON.stringify(error)}`);
      this.isPlaying = false;
    }
  }
  
  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    try {
      if (this.avPlayer) {
        if (this.isPlaying) {
          await this.avPlayer.stop();
        }
        await this.avPlayer.release();
        this.avPlayer = null;
        this.isPlaying = false;
        hilog.info(DOMAIN, TAG, 'Audio stopped');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to stop audio: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    try {
      if (this.avPlayer && this.isPlaying) {
        await this.avPlayer.pause();
        this.isPlaying = false;
        hilog.info(DOMAIN, TAG, 'Audio paused');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to pause audio: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 恢复播放
   */
  async resume(): Promise<void> {
    try {
      if (this.avPlayer && !this.isPlaying) {
        await this.avPlayer.play();
        this.isPlaying = true;
        hilog.info(DOMAIN, TAG, 'Audio resumed');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to resume audio: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 设置音量 (0.0 - 1.0)
   */
  async setVolume(volume: number): Promise<void> {
    this.volume = Math.max(0, Math.min(1, volume));
    if (this.avPlayer && this.isPlaying) {
      try {
        await this.avPlayer.setVolume(this.volume);
        hilog.info(DOMAIN, TAG, `Volume set to: ${this.volume}`);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to set volume: ${JSON.stringify(error)}`);
      }
    }
  }
  
  /**
   * 获取当前音量
   */
  getVolume(): number {
    return this.volume;
  }
  
  /**
   * 切换噪音类型
   */
  async switchNoiseType(type: NoiseType): Promise<void> {
    if (type !== this.currentNoiseType) {
      await this.play(type);
    }
  }
  
  /**
   * 获取当前噪音类型
   */
  getCurrentNoiseType(): NoiseType {
    return this.currentNoiseType;
  }
  
  /**
   * 获取所有噪音类型
   */
  getAllNoiseTypes(): NoiseType[] {
    return [NoiseType.RAIN, NoiseType.CAFE, NoiseType.FOREST, NoiseType.OCEAN];
  }
  
  /**
   * 是否正在播放
   */
  getIsPlaying(): boolean {
    return this.isPlaying;
  }
  
  /**
   * 清理资源
   */
  async destroy(): Promise<void> {
    await this.stop();
    hilog.info(DOMAIN, TAG, 'AudioManager destroyed');
  }
}
