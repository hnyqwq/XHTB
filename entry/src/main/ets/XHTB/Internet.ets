import { hilog } from '@kit.PerformanceAnalysisKit';
import { initTabData } from './InternetTab/TabViewModel';
import { TabItem } from './InternetTab/TabItem';

import { promptAction } from '@kit.ArkUI';//视频
import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

import router from '@ohos.router';

@Extend(Text) function text() {
  .maxLines(2)
  .fontSize(11)
  .maxFontScale(1.75)
  .width('100%')
  .constraintSize({ minHeight: 16 })
  .fontColor($r('sys.color.font_secondary'))
  .fontFamily('HarmonyHeiTi')
  .textAlign(TextAlign.Center)
}

@Entry
@Component
struct BackgroundLightTab {
  @State tabArray: Array<TabItem> = initTabData();
  @State focusIndex: number = 0;
  @State index: number = 0;
  private controller: TabsController = new TabsController();
  private listScroller: Scroller = new Scroller();
  private barHeight: number = 0;

  WebController: WebController = new WebController();

  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @State networkVideoSrc: string = 'https://www.hnyqwq.cn/hvideo/dly.mp4';
  @State isPlaying: boolean = true;
  @State picture: PixelMap | undefined = undefined;
  @State savefileUri:string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  private controllerr: VideoController = new VideoController();

  @Builder
  tabBuilder(tabName: string | Resource, tabIndex: number) {
    Row() {
      Text(tabName)
        .fontSize(13)
        .fontColor(tabIndex === this.focusIndex ? Color.White : '#E6000000')
        .id(tabIndex.toString())
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(100)
    .backgroundColor(tabIndex === this.focusIndex ? '#0A59F7' : '#0D000000')
    .borderRadius(21)
    .height(40)
    .margin({ left: 4, right: 4 })
    .onClick(() => {
      this.controller.changeIndex(tabIndex);
      this.listScroller.scrollToIndex(tabIndex, true, ScrollAlign.CENTER);
    })
  }

  build() {
    Column() {
      Row() {
        Text('󰃚') // 自定义返回图标
          .fontSize(35)
          .margin({ left: 20 }) // 左侧留白
          .onClick(() => {
            router.back();
          })
        // [Start BackgroundLightTab_list]
        List({ scroller: this.listScroller }) {
          ForEach(this.tabArray.slice(0, 7),
            (item: TabItem, index: number) => {
              this.tabBuilder(item.name, index);
            }, (item: TabItem, index: number) => JSON.stringify(item) + index)
        }
        // [End BackgroundLightTab_list]
        .layoutWeight(1)
        .height(52)
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .margin({ top: 10, right: 10 })
      }
      .alignItems(VerticalAlign.Center)
      .height(52)
      .margin({ top: 10 })
      Row() {
        Text($r('app.string.InternetMon'))
          .text()
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      // [Start Underline_tab_tabs_part]
      Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
        ForEach(this.tabArray.slice(0, 7),
          (item: TabItem, index: number) => {
            TabContent() {
              Column() {
                // 根据不同的tab索引显示不同内容
                if (index === 0) {
                Text('http://connectivitycheck.platform.hicloud.com')
                  .text()
                Text($r('app.string.Internet1success'))
                  .text()
                  Web({ src: 'http://connectivitycheck.platform.hicloud.com', controller: this.WebController })
                } else if (index === 1) {
                  Text('http://www.msftconnecttest.com/redirect')
                    .text()
                  Text($r('app.string.Internet2success'))
                    .text()
                  Web({ src: 'http://www.msftconnecttest.com/redirect', controller: this.WebController })
                } else if (index === 2) {
                  Text('http://captive.apple.com')
                    .text()
                  Text($r('app.string.Internet2success'))
                    .text()
                  Web({ src: 'http://captive.apple.com', controller: this.WebController })
                } else if (index === 3) {
                  Text('http:///www.google.com/generate_204')
                    .text()
                  Text($r('app.string.Internet2success'))
                    .text()
                  Web({ src: 'http:///www.google.com/generate_204', controller: this.WebController })
                } else if (index === 4) {
                  Text('http://1.1.1.1')
                    .text()
                  Text($r('app.string.Internet2success'))
                    .text()
                  Web({ src: 'http://1.1.1.1', controller: this.WebController })
                } else if (index === 5) {
                  Text('https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-allversion')
                    .text()
                  Text($r('app.string.Internet3success'))
                    .text()
                  Web({ src: 'https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-allversion', controller: this.WebController })
                } else {
                  Text('https://www.hnyqwq.cn/hvideo/dly.mp4')
                    .text()
                  Text($r('app.string.Internetselfsuccess'))
                    .text()
                  Video({
                    currentProgressRate: this.curRate,
                    src: this.networkVideoSrc,
                    controller: this.controllerr
                  })
                    .muted(false) // 设置是否静音
                    .controls(this.isControls) // 设置是否显示默认控制条
                    .autoPlay(true) // 设置是否自动播放
                    .loop(true) // 设置是否循环播放
                    .objectFit(this.currentFitMode)
                    .width('100%')
                    .aspectRatio(16 / 9) // 根据视频长宽比自动计算高度
                    .constraintSize({ maxWidth: 750, minWidth: 500 })
                    .onClick(() => {
                      this.isControls = !this.isControls;
                      if (this.isControls) { // 显示状态的分支
                        promptAction.showToast({
                          message: $r('app.string.controlon')
                        });
                      } else { // 隐藏状态的分支
                        promptAction.showToast({
                          message: $r('app.string.controloff')
                        });
                      }
                    })
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
                    .onPrepared(() => {
                      this.controllerr.start();
                    })
                    .onDrop((e: DragEvent) => {
                      let record = e.getData().getRecords()[0];
                      if (record.getType() == uniformTypeDescriptor.UniformDataType.VIDEO) {
                        let videoInfo = record as unifiedDataChannel.Video;
                        this.networkVideoSrc = videoInfo.videoUri;
                      }
                    })
                }
              }
              .width('100%')
              .height('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .backgroundColor(Color.White)
          }, (item: TabItem, index: number) => JSON.stringify(item) + index)
      }
      .width('100%')
      // [End Underline_tab_tabs_part]
      .barHeight(this.barHeight)
      .onAnimationStart((index: number, targetIndex: number) => {
        hilog.info(0x0000, 'index', index.toString());
        this.focusIndex = targetIndex;
        this.listScroller.scrollToIndex(targetIndex, true, ScrollAlign.CENTER);
      })
    }
    .height('100%')
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