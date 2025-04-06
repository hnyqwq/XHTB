// import { MySubTitle } from '../common/CommonTitle';
//
// @Entry
// @Component
// struct VideoDemo {
//   private controller: VideoController = new VideoController()
@Entry
@Component
struct VideoCreateComponent {
  @State videoSrc: Resource = $rawfile('a.mp4')
  @State previewUri: Resource = $rawfile('a.jpg')
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isAutoPlay: boolean = false
  @State showControls: boolean = true
  @State isShortcutKeyEnabled: boolean = false
  controller: VideoController = new VideoController()
  build() {
    Column() {
      Video({
        src: this.videoSrc,
        previewUri: this.previewUri,
        currentProgressRate: this.curRate,
        controller: this.controller
      })
        .width('100%')
        .height(500)
        .autoPlay(this.isAutoPlay)
        .controls(this.showControls)
        .enableShortcutKey(this.isShortcutKeyEnabled)
        .onStart(() => {
          console.info('onStart')
        })
        .onPause(() => {
          console.info('onPause')
        })
        .onFinish(() => {
          console.info('onFinish')
        })
        .onError(() => {
          console.info('onError')
        })
        .onStop(() => {
          console.info('onStop')
        })
        .onPrepared((e?: DurationObject) => {
          if (e != undefined) {
            console.info('onPrepared is ' + e.duration)
          }
        })
        .onSeeking((e?: TimeObject) => {
          if (e != undefined) {
            console.info('onSeeking is ' + e.time)
          }
        })
        .onSeeked((e?: TimeObject) => {
          if (e != undefined) {
            console.info('onSeeked is ' + e.time)
          }
        })
        .onUpdate((e?: TimeObject) => {
          if (e != undefined) {
            console.info('onUpdate is ' + e.time)
          }
        })
        .onFullscreenChange((e?: FullscreenObject) => {
          if (e != undefined) {
            console.info('onFullscreenChange is ' + e.fullscreen)
          }
        })

      Row() {
        Button('视频换2').onClick(() => {
          this.videoSrc = $rawfile('b.mp4') // 切换视频源
        }).margin(5)
        Button('封面换2').onClick(() => {
          this.previewUri = $rawfile('b.jpg') // 切换视频预览海报
        }).margin(5)
      }

      Row() {
        Button('视频换1').onClick(() => {
          this.videoSrc = $rawfile('a.mp4') // 切换视频源
        }).margin(5)
        Button('封面换1').onClick(() => {
          this.previewUri = $rawfile('a.jpg') // 切换视频预览海报
        }).margin(5)
      }

      Row() {
        Button('显示/隐藏视频控制栏').onClick(() => {
          this.showControls = !this.showControls // 切换是否显示视频控制栏
        }).margin(5)
      }

      Row() {
        Button('开始播放').onClick(() => {
          this.controller.start() // 开始播放
        }).margin(2)
        Button('暂停播放').onClick(() => {
          this.controller.pause() // 暂停播放
        }).margin(2)
        Button('结束播放').onClick(() => {
          this.controller.stop() // 结束播放
        }).margin(2)
      }
      Row() {
        Button('重置AVPlayer').onClick(() => {
          this.controller.reset() // 重置AVPlayer
        }).margin(2)
        Button('精准跳转到视频的10s位置').onClick(() => {
          this.controller.setCurrentTime(10, SeekMode.Accurate) // 精准跳转到视频的10s位置
        }).margin(2)
      }
      Row() {
        Button('0.75倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_0_75_X // 0.75倍速播放
        }).margin(5)
        Button('1倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_1_00_X // 原倍速播放
        }).margin(5)
        Button('2倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_2_00_X // 2倍速播放
        }).margin(5)
      }
    }
  }
}

interface DurationObject {
  duration: number;
}

interface TimeObject {
  time: number;
}

interface FullscreenObject {
  fullscreen: boolean;
}
//   build() {
//     Column({ space: 10 }) {
//       Text('Video演示')
//         .textAlign(TextAlign.Center)
//         .fontSize(20)
//       MySubTitle({ shili: '示例1', subTitle: '加载视频资源' })
//       Row({ space: 10 }) {
//         Column({ space: 5 }) {
//           Video({
//             src: $rawfile('a.mp4'),
//             previewUri: $rawfile('a.jpg'),
//             controller: this.controller
//           })
//             .width(220)
//             .height(180)
//           Button('开始播放视频')
//             .onClick(() => {
//               this.controller.start()
//             })
//           Button('暂停播放视频')
//             .onClick(() => {
//               this.controller.pause()
//             })
//           Button('停止播放视频')
//             .onClick(() => {
//               this.controller.stop()
//             })
//           Button('全屏播放视频')
//             .onClick(() => {
//               this.controller.requestFullscreen(true)
//             })
//         }
//       }
//     }
//     .height('100%')
//     .width('100%')
//   }
// }