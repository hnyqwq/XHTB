import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入默认界面需要的日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { resourceManager } from '@kit.LocalizationKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import Logger from '../utils/Logger';

import { pasteboard } from '@kit.BasicServicesKit';

let logger = Logger.getLogger('[TextScenario]');

/*
@Extend(Button) function globalButtonStyle() {
  .width('60%')
  .height(80)
  //.backgroundColor(0x99CCFF)  // 白色背景
  .borderRadius(15)           // 圆角半径
  .margin({ top: 10 })         // 顶部间距
}*/

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct HomePage {
  context: common.Context = getContext(this);
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @State networkVideoSrc: string = '';
  @State chooseImage: PixelMap | undefined = undefined;
  @State picture: PixelMap | undefined = undefined;

  @State networkPreviewUri: string = 'https://www.hnyqwq.cn/hvideo/130.png'; // 默认网络预览图
  //@State networkPreviewUri: string = 'https://act-webstatic.mihoyo.com/event-static/2023/08/15/cc72ddf351003a4a9b618e5f4697dad0_2771553456903788244.jpg';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true;//设置组件支持快捷键响应。

  private controller: VideoController = new VideoController();

  private async share() {
    if (!this.networkVideoSrc) {
      promptAction.showToast({ message: '请输入有效的视频链接' });
      return;
    }

    const contextFaker: Context = getContext(this);
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    const fileData: Uint8Array = await resourceMgr.getMediaContent($r('app.media.startIcon'));

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc, // 使用输入框中的视频链接
      title: '视频链接分享（当前仅可唤醒应用）',
      description: '当前链接：' + this.networkVideoSrc,
      thumbnail: fileData,
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      logger.info('ShareController show success.');
      promptAction.showToast({ message: '分享成功: ' + this.networkVideoSrc });
    }).catch((error: BusinessError) => {
      logger.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      promptAction.showToast({ message: '分享失败: ' + error.message });
    });
  }

  build() {
    Column() {
      // 固定在顶部的输入框区域
      Video({
        previewUri: this.networkPreviewUri,
        currentProgressRate: this.curRate,
        src: this.networkVideoSrc,
        controller: this.controller
      })
        .muted(false) // 设置是否静音
        .controls(this.isControls) // 设置是否显示默认控制条
        .autoPlay(true) // 设置是否自动播放
        .loop(true) // 设置是否循环播放
        .objectFit(this.currentFitMode)
        .width('100%')
        .aspectRatio(16 / 9) // 根据视频长宽比自动计算高度
        .constraintSize({ maxWidth: 900, minWidth: 600 })
        .onClick(() => {
          this.isControls = !this.isControls;
          promptAction.showToast({
            message: `控制栏已${this.isControls ? '显示' : '隐藏'}`
          });
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
        .onFullscreenChange((e?: FullscreenObject) => {
          if (e != undefined) {
            console.info('onFullscreenChange is ' + e.fullscreen)
            window.getLastWindow(this.context).then((win: window.Window) => {
              if (e.fullscreen) {
                // 进入全屏时旋转到横屏
                win.setPreferredOrientation(window.Orientation.LANDSCAPE);
              } else {
                // 退出全屏时恢复原始方向
                win.setPreferredOrientation(this.initialOrientation);
              }
            }).catch((err: Error) => {
              console.error('方向设置失败:', err);
              promptAction.showToast({ message: '方向设置失败' });
            });
          }
        })
        .onPrepared(() => {
          this.controller.start();
        })
        .onDrop((e: DragEvent) => {
          let record = e.getData().getRecords()[0];
          if (record.getType() == uniformTypeDescriptor.UniformDataType.VIDEO) {
            let videoInfo = record as unifiedDataChannel.Video;
            this.networkVideoSrc = videoInfo.videoUri;
          }
        })
      Row() {
        TextInput({ placeholder: $r('app.string.linkinput')})
          .type(InputType.URL)
          //.backgroundColor('#FF9CCE')
          .width('55%')
          .height(50)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.networkVideoSrc = value;
          })
        Button($r('app.string.share'))
        //.type(ButtonType.Capsule)
          .width('20%')
          .height(50)
          .backgroundColor(0xFF66CC)
          //.backgroundColor(0x66CCFF)//浅蓝色
          .margin({ right: 10 })
          .onClick(() => {
            logger.info('分享按钮被点击');
            try {
              this.share();
            } catch (error) {
              logger.error(`分享按钮点击异常: ${error.message}`);
              promptAction.showToast({ message: '分享功能异常: ' + error.message });
            }
          })
        Button($r('app.string.play'))
          //.fontSize(10)
        //.type(ButtonType.Capsule)
          .width('20%')
          .height(50)
          .backgroundColor(0xFF66CC)
          .onClick(() => {
            if (this.networkVideoSrc) {
              this.controller.start();
              promptAction.showToast({ message: '正在播放视频...' });
            } else {
              promptAction.showToast({ message: '请输入视频链接' });
            }
          })
      }
      .width('90%')
      .margin({ top: 5, bottom: 10 })

      Row() {
        TextArea({
          placeholder: $r('app.string.testinput')
        })
        //.backgroundColor('#FF9CCE')
          .width('55%')
          //.height(50)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.networkVideoSrc = 'https://www.hnyqwq.cn/hvideo/' + value + '.mp4';
          })
        Button($r('app.string.scancode'))
        //.globalButtonStyle()
          .type(ButtonType.Capsule)
          .backgroundColor(0x66CCFF)//蓝色
          //.backgroundColor('#0044fc')
          .labelStyle({ overflow: TextOverflow.Ellipsis, maxLines: 3, minFontSize: 0 })
          .width('20%')
          .height(50)
          .margin({ right: 10 })
          .onClick(async () => {
            try {
              // 定义扫码参数options
              let options: scanBarcode.ScanOptions = {
                scanTypes: [scanCore.ScanType.ALL],
                enableMultiMode: true,
                enableAlbum: true
              };
              // 调用扫码功能
              scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                // 正确获取扫描结果的字符串值
                const originalValue: string = result.originalValue; // 假设ScanResult有originalValue属性
                this.networkVideoSrc = originalValue;
                promptAction.showToast({ duration: 10000, message: '扫码成功: ' + originalValue });
              }).catch((error: BusinessError) => {
                hilog.error(0x0001, '[Scan Sample]',
                  `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                promptAction.showToast({ message: '扫码失败: ' + error.message });
              });
            } catch (error) {
              promptAction.showToast({ message: '扫码失败: ' + error.message });
              hilog.error(0x0001, '[Scan CPSample]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          })
          .bindPopup(this.handlePopup, { message: '点击扫码输入视频链接' });
        PasteButton({ icon: PasteIconStyle.LINES, text: PasteDescription.PASTE, buttonType: ButtonType.Capsule })
        //.fontSize(10)
          .width('20%')
          .height(50)
          .backgroundColor(0x66CCFF)//蓝色
          //.padding({top: 12, bottom: 12, left: 24, right: 24})
          .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
            if (PasteButtonOnClickResult.SUCCESS === result) {
              pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                if (err) {
                  console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                  return;
                }
                this.networkVideoSrc = pasteData.getPrimaryText();
              });
            }
          })
      }
      .width('90%')
      .margin({ top: 5, bottom: 10 })

      Row() {
        Button(this.curRate === PlaybackSpeed.Speed_Forward_2_00_X ? '原速' : '倍速')
        //.backgroundColor('#0044fc')
          .backgroundColor(0xFF66CC)
          //.width('20%')
          .onClick(() => {
            this.curRate = this.curRate === PlaybackSpeed.Speed_Forward_2_00_X
              ? PlaybackSpeed.Speed_Forward_1_00_X
              : PlaybackSpeed.Speed_Forward_2_00_X;
            promptAction.showToast({
              message: `已成功切换至${this.curRate === PlaybackSpeed.Speed_Forward_2_00_X ? '2' : '1'}倍速播放`
            });
          })
        /*Button('全屏')
          .backgroundColor(0xFF66CC)
          .margin({ left: 10 })
          .onClick(() => {
            this.controller.requestFullscreen(true);
            window.getLastWindow(this.context).then((win) => {
              win.setPreferredOrientation(window.Orientation.LANDSCAPE);
            });
          })*/
        Button(this.currentFitMode === ImageFit.Fill ? '自适应' : '强制填充屏幕')
          .backgroundColor(0xFF66CC)
          .margin({ left: 10 })
          .onClick(() => {
            this.currentFitMode = this.currentFitMode === ImageFit.Fill
              ? ImageFit.Auto
              : ImageFit.Fill;
            promptAction.showToast({
              message: `当前模式: ${this.currentFitMode === ImageFit.Fill ? 'Fill(强制填充屏幕)' : 'Auto(自适应)'}`
            });
          })
        Button(this.currentFitMode === ImageFit.Cover ? '保持比例' : '比例放大填充')
          .backgroundColor(0xFF66CC)
          .margin({ left: 10 })
          .onClick(() => {
            this.currentFitMode = this.currentFitMode === ImageFit.Cover
              ? ImageFit.Contain
              : ImageFit.Cover;
            promptAction.showToast({
              message: `当前模式: ${this.currentFitMode === ImageFit.Cover ? 'Contain(保持比例)' :
                'Cover(比例放大填充)'}`
            });
          })
      }

      // 使用堆叠布局，顶部起始对齐
      Stack({ alignContent: Alignment.TopStart }) {
        // 滚动区域
        Column() {
          Column() {
            Text('当前播放的视频链接')
            Text(this.networkVideoSrc)
              .copyOption(CopyOptions.LocalDevice)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .margin({ top: 10 })
          .width('100%')
          .height('100%')
          //.backgroundColor($r('app.color.start_window_background'))
        }
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