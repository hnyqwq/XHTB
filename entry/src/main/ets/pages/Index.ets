import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { curves } from '@kit.ArkUI' // 导入ArkUI动画曲线库
import userAuth from '@ohos.userIAM.userAuth'
import { promptAction } from '@kit.ArkUI';

const TAG = 'User_Auth';

@Extend(Button) function globalButtonStyle() {
  .width('90%')
  .height(150)
  .backgroundColor(0x99CCFF)  // 白色背景
  .borderRadius(15)           // 圆角半径
  .margin({ top: 10 })         // 顶部间距
}

@Entry
@Component
// 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
struct VideoCreateComponent {// 创建滚动控制器实例
  @State videoSrc: Resource | string = $rawfile('a.mp4');
  @State previewUri: Resource = $rawfile('a.jpg')
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isAutoPlay: boolean = true
  @State showControls: boolean = true
  @State isShortcutKeyEnabled: boolean = false
  @State message: string = '用户认证'
  @State userAuthResult?: userAuth.UserAuthResult = undefined
  @State networkVideoSrc: string = '';


  scroller: Scroller = new Scroller()// 初始化数据数组（用于生成滚动内容）
  //private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  /*@State listPosition: number = 0; // 0代表滚动到List顶部，1代表中间值，2代表滚动到List底部。
  private arr: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  private scrollerForScroll: Scroller = new Scroller()
  private scrollerForList: Scroller = new Scroller()*/

  //@State isMuted: boolean = false
  //@State isControls: boolean = false
  private controller: VideoController = new VideoController();
  //controller: VideoController = new VideoController()

  build() {
    Column() {
      Video({
        //src: this.videoSrc,
        previewUri: this.previewUri,
        currentProgressRate: this.curRate,
        //controller: this.controller,
        src: this.networkVideoSrc, // 绑定网络视频源状态变量
        // ... 其他视频属性保持不变 ...
        controller: this.controller
      })
        .muted(false) // 设置是否静音
        .controls(false) // 设置是否显示默认控制条
        .autoPlay(true) // 设置是否自动播放
        .loop(true) // 设置是否循环播放
        .objectFit(ImageFit.Contain) // 设置视频适配模式
        .width('100%')
        .height('50%')
        //.autoPlay(this.isAutoPlay)
        //.controls(this.showControls)
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
        .onPrepared(() => {
          // 在onPrepared回调中执行controller的start方法，确保视频源更换后直接开始播放。
          this.controller.start();
        })
        .onDrop((e: DragEvent) => {
          // 外部视频拖入应用Video组件范围，松手后触发通过onDrop注册的回调。
          // 在DragEvent中会包含拖入的视频源信息，取出后赋值给状态变量videoSrc即可改变Video的视频源。
          let record = e.getData().getRecords()[0];
          if (record.getType() == uniformTypeDescriptor.UniformDataType.VIDEO) {
            let videoInfo = record as unifiedDataChannel.Video;
            this.videoSrc = videoInfo.videoUri;
          }
        })

      /*Row() {
        Button('视频换第一个').height('5%').onClick(() => {
          this.videoSrc = $rawfile('a.mp4') // 切换视频源
        }).margin(5)
        Button('封面换第一个').onClick(() => {
          this.previewUri = $rawfile('a.jpg') // 切换视频预览海报
        }).margin(5)
      }

      Row() {
        Button('视频换第二个').onClick(() => {
          this.videoSrc = $rawfile('b.mp4') // 切换视频源
        }).margin(5)
        Button('封面换第二个').onClick(() => {
          this.previewUri = $rawfile('b.jpg') // 切换视频预览海报
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
        Button('退出全屏播放').onClick(() => {
          this.controller.exitFullscreen() // 退出全屏播放
        }).margin(2)
      }
      Row() {
        Button('0.75倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_0_75_X // 0.75倍速播放
        }).margin(5)
        Button('1倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_1_00_X // 原倍速播放
        }).margin(5)
        Button('1.25倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_1_25_X // 1.25倍速播放
        }).margin(5)
        Button('1.75倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_1_75_X // 1.75倍速播放
        }).margin(5)
        Button('2倍速播放').onClick(() => {
          this.curRate = PlaybackSpeed.Speed_Forward_2_00_X // 2倍速播放
        }).margin(5)
      }*/
      // 使用堆叠布局，顶部起始对齐
      Stack({ alignContent: Alignment.TopStart }) {// 滚动容器组件
        Scroll(this.scroller) {// 垂直排列的子组件容器
          Column() { // 循环生成滚动内容项
            //ForEach(this.arr, (item: number) => {
              //Text(item.toString())
            Button('空空儿')
              .globalButtonStyle()
              .onClick(() => {
                // 设置网络视频源（请替换为实际的视频URL）
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E7%A9%BA%E7%A9%BA%E5%84%BF.mp4';

                // 启动视频播放（假设Video组件的controller已经正确初始化）
                this.controller.start();
              })
            Button('蛇年限定 愿照九天')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E6%84%BF%E7%85%A7%E4%B9%9D%E5%A4%A9.mp4';
                this.controller.start();
              })
            Button('影')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E5%BD%B1.mp4';
                this.controller.start();
              })
            Button('群星魔术团')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E7%BE%A4%E6%98%9F%E9%AD%94%E6%9C%AF%E5%9B%A2.mp4';
                this.controller.start();
              })
            Button('少司缘')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E5%B0%91%E5%8F%B8%E7%BC%98.mp4';
                this.controller.start();
              })
            Button('55')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/55.mp4';
                this.controller.start();
              })
            Button('穿透信念')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E7%A9%BF%E9%80%8F%E4%BF%A1%E5%BF%B5.mp4';
                this.controller.start();
              })
            Button('朵莉亚')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E6%9C%B5%E8%8E%89%E4%BA%9A.mp4';
                this.controller.start();
              })
            Button('冰雪奇缘')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E5%86%B0%E9%9B%AA%E5%A5%87%E7%BC%98.mp4';
                this.controller.start();
              })
            Button('元流之子')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E5%85%83%E6%B5%81%E4%B9%8B%E5%AD%90.mp4';
                this.controller.start();
              })
            Button('大司命')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E5%A4%A7%E5%8F%B8%E5%91%BD.mp4';
                this.controller.start();
              })
            Button('熬隐')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E7%86%AC%E9%9A%90.mp4';
                this.controller.start();
              })
            Button('九周年限定 鸣野蒿 桑启')
              .globalButtonStyle()
              .onClick(() => {
                this.networkVideoSrc = 'https://gitee.com/hnyqwq/video/releases/download/v0.1/%E4%B9%9D%E5%91%A8%E5%B9%B4.mp4';
                this.controller.start();
              })
            Button('想看看你的小脸')
              .globalButtonStyle()
              .onClick(() => {
                const authParam : userAuth.AuthParam = {
                  challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                  authType: [userAuth.UserAuthType.FACE],
                  authTrustLevel: userAuth.AuthTrustLevel.ATL1,
                }
                const widgetParam :userAuth.WidgetParam = {
                  title: '请认证人脸'
                }
                this.startUserAuth(authParam, widgetParam)
              })
            Button('想亲亲你的手指')
              .globalButtonStyle()
              .onClick(() => {
                const authParam : userAuth.AuthParam = {
                  challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                  authType: [userAuth.UserAuthType.FINGERPRINT],
                  authTrustLevel: userAuth.AuthTrustLevel.ATL1,
                }
                const widgetParam :userAuth.WidgetParam = {
                  title: '把你的小手手放在指纹感应区~~'
                }
                this.startUserAuth(authParam, widgetParam)
              })
            //.fontSize(16)               // 文字大小
              // .textAlign(TextAlign.Center)// 文字居中
              //}, (item: string) => item)       // 使用项值作为唯一标识
            Button('就想偷窥你密码')
              .globalButtonStyle()
              .onClick(() => {
                const authParam : userAuth.AuthParam = {
                  challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                  authType: [userAuth.UserAuthType.PIN],
                  authTrustLevel: userAuth.AuthTrustLevel.ATL2,
                }
                const widgetParam :userAuth.WidgetParam = {
                  title: '让我来瞅瞅你的锁屏密码是多少！！'
                }
                this.startUserAuth(authParam, widgetParam)
              })
            /*Button('2025新春愿照九天视频')
              .globalButtonStyle()
              .onClick(() => {
                this.videoSrc = $rawfile('a.mp4') // 切换视频源
              })
            Button('2025新春愿照九天封面')
              .globalButtonStyle()
              .onClick(() => {
                this.previewUri = $rawfile('a.jpg') // 切换视频预览海报
              })
            Button('空空儿视频')
              .globalButtonStyle()
              .onClick(() => {
                this.videoSrc = $rawfile('b.mp4') // 切换视频源
              })
            Button('空空儿封面')
              .globalButtonStyle()
              .onClick(() => {
                this.previewUri = $rawfile('b.jpg') // 切换视频预览海报
              })*/
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
        .scrollBar(BarState.On) // 滚动条常驻显示
        .scrollBarColor(Color.Gray) // 滚动条颜色
        .scrollBarWidth(10) // 滚动条宽度
        .height('54%') // 关键高度设置
        .backgroundColor(Color.White)
        .friction(0.6)                      // 设置滚动摩擦系数（影响滚动惯性）
        .edgeEffect(EdgeEffect.None)
        /*.onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState) => {
          console.info(xOffset + ' ' + yOffset) // 滚动即将发生时触发
        })
        .onScrollEdge((side: Edge) => {       // 滚动到边缘时触发
          console.info('To the edge')
        })
        .onScrollStop(() => {                // 滚动停止时触发
          console.info('Scroll Stop')
        })*/

        /*Button('查询是否支持面容识别和ATL4认证')
          .margin({ bottom: 20 })
          .onClick(() => {
            this.checkAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4)
          })

        Button('查询是否支持指纹和ATL1认证')
          .margin({ bottom: 20 })
          .onClick(() => {
            this.checkAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1)
          })

        Button('查询是否支持密码和ATL1认证')
          .margin({ bottom: 20 })
          .onClick(() => {
            this.checkAvailableStatus(userAuth.UserAuthType.PIN, userAuth.AuthTrustLevel.ATL1)
          })*/
        /*
        Button('下滑 100 →切换视频')
          .height('5%')
          .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离，滑动过程配置有动画
            let curve = curves.interpolatingSpring(10, 1, 228, 30) //创建一个阶梯曲线
            const yOffset: number = this.scroller.currentOffset().yOffset;
            this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 100, animation: { duration: 1000, curve: curve } })
          }).margin({ top: 10, left: 20 })*/



        /*Button('下滑 150')
          .height('5%')
          .onClick(() => { // 点击后下滑指定距离150.0vp
            this.scroller.scrollBy(0, 150)
          })
          .margin({ top: 10, left: 20 })*/
        /*Button('下滑100.0vp')
          .height('5%')
          .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离
            const yOffset: number = this.scroller.currentOffset().yOffset;
            this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 100 })
          })
          .margin({ top: 60, left: 20 })*/
        Button('下滑 150')
          .height('5%')
          .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离，滑动过程配置有动画
            let curve = curves.interpolatingSpring(10, 1, 228, 30) //创建一个阶梯曲线
            const yOffset: number = this.scroller.currentOffset().yOffset;
            this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 150, animation: { duration: 1000, curve: curve } })
          })
          .margin({ top: 10, left: 20 })
        Button('返回顶部')
          .height('5%')
          .onClick(() => { // 点击后回到顶部 back top
            this.scroller.scrollEdge(Edge.Top)
          })
          .margin({ top: 60, left: 20 })
        Button('下一页')
          .height('5%')
          .onClick(() => { // 点击后滑到下一页
            this.scroller.scrollPage({ next: true ,animation: true })
          })
          .margin({ top: 110, left: 20 })
        Button('全屏')
          .onClick(() => {
            this.controller.requestFullscreen(true)
          }).margin({ top: 160, left: 20 })
        /*Button('触发初始速度为-3000vp/s的惯性滚动')
          .height('5%')
          .onClick(() => { // 点击后触发初始速度为-3000vp/s的惯性滚动 fling -3000
            this.scroller.fling(-3000)
          })
          .margin({ top: 210, left: 20 })
        Button('滑到下边缘,速度值是700vp/s')
          .height('5%')
          .onClick(() => { // 点击后滑到下边缘，速度值是700vp/s scroll to bottom 700
            this.scroller.scrollEdge(Edge.Bottom, { velocity: 700 })
          })
          .margin({ top: 260, left: 20 })*/
      }.width('100%').height('100%').backgroundColor(0xDCDCDC)
    }
  }
  startUserAuth (authParam: userAuth.AuthParam, widgetParam: userAuth.WidgetParam) {
    try {
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      userAuthInstance.on('result', {
        onResult: (result) => {
          // 认证成功
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            this.userAuthResult = result
            console.log(TAG, 'userAuthInstance callback result ' + JSON.stringify(result));
          }
        }
      })
      userAuthInstance.start()
    } catch (e) {
      promptAction.showToast({
        message: `拉起用户认证失败 ${e.code} ${e.message}`
      })
    }
  }
}


//   build() {
//     Column({ space: 10 }) {
//       Text('Video演示')
//         .textAlign(TextAlign.Center)
//         .fontSize(20)
//       MySubTitle({ example: '示例1', subTitle: '加载视频资源' })
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

interface DurationObject {
  duration: number;
}

interface TimeObject {
  time: number;
}

interface FullscreenObject {
  fullscreen: boolean;
}
