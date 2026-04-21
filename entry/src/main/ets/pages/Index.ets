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

  // 格式化时间为 MM:SS
  private formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // 开始计时器
  private startTimer(): void {
    if (this.timer === -1) {
      this.timer = setInterval(() => {
        if (this.remainingTime > 0) {
          this.remainingTime--;
        } else {
          // 时间到，停止计时器
          this.stopTimer();
        }
      }, 1000);
    }
  }

  // 停止计时器
  private stopTimer(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  // 切换开始/暂停状态
  private toggleTimer(): void {
    if (this.isRunning) {
      this.stopTimer();
    } else {
      this.startTimer();
    }
    this.isRunning = !this.isRunning;
  }

  // 重置计时器
  private resetTimer(): void {
    this.stopTimer();
    this.isRunning = false;
    this.remainingTime = this.DEFAULT_TIME;
  }

  // 组件即将销毁时清理计时器
  aboutToDisappear(): void {
    this.stopTimer();
  }

  build() {
    Column({ space: 40 }) {
      // 顶部标题
      Text('番茄钟')
        .fontSize(28)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60 })

      // 倒计时显示 - 粗大明显的数字字体
      Text(this.formatTime(this.remainingTime))
        .fontSize(80)
        .fontColor('#FF6B6B')
        .fontWeight(FontWeight.Bolder)
        .fontFamily('monospace')
        .margin({ top: 40 })

      // 中间的大圆形按钮 - 开始/暂停
      Button(this.isRunning ? '暂停' : '开始')
        .width(160)
        .height(160)
        .fontSize(32)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.isRunning ? '#FF9500' : '#34C759')
        .borderRadius(80) // 圆形按钮
        .shadow({
          radius: 20,
          color: this.isRunning ? '#66FF9500' : '#6634C759',
          offsetX: 0,
          offsetY: 8
        })
        .onClick(() => {
          this.toggleTimer();
        })
        .margin({ top: 40 })

      // 底部重置按钮
      Button('重置')
        .width(120)
        .height(50)
        .fontSize(20)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#8E8E93')
        .borderRadius(25)
        .onClick(() => {
          this.resetTimer();
        })
        .margin({ top: 20 })

      // 空白占位，使布局更平衡
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1C1C1E') // 深色主题背景
    .justifyContent(FlexAlign.Start)
  }
}
