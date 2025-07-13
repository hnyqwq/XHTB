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

import { textRecognition } from '@kit.CoreVisionKit'
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

import { pasteboard } from '@kit.BasicServicesKit';

import {
  createCollaborationServiceMenuItems,
  CollaborationServiceStateDialog,
  CollaborationServiceFilter
} from '@kit.ServiceCollaborationKit';

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
  private imageSource: image.ImageSource | undefined = undefined;
  @State chooseImage: PixelMap | undefined = undefined;
  @State dataValues: string = '';
  @State picture: PixelMap | undefined = undefined;

  private async selectImage() {
    let uri = await this.openPhoto();
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      return;
    }
    this.loadImage(uri);
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }

  private loadImage(name: string) {
    setTimeout(async () => {
      let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY);
      this.imageSource = image.createImageSource(fileSource.fd);
      this.chooseImage = await this.imageSource.createPixelMap();
    }, 100)
  }

  @Builder
  MyTestMenu() {
    Menu() {
      MenuItem({
        startIcon: $r("app.media.startIcon"),
        content: "选取本机图片꒰⑅•ᴗ•⑅꒱ ",
        builder: (): void => {
          this.selectImage();
        }
      })
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL])
    }
  }

  //@State networkPreviewUri: string = 'https://www.hnyqwq.cn/hvideo/media.png'; // 默认网络预览图
  @State networkPreviewUri: string = 'https://act-webstatic.mihoyo.com/event-static/2023/08/15/cc72ddf351003a4a9b618e5f4697dad0_2771553456903788244.jpg';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  scroller: Scroller = new Scroller() // 初始化数据数组（用于生成滚动内容）
  //private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  //@State isMuted: boolean = false
  //@State isControls: boolean = false
  private controller: VideoController = new VideoController();

  //controller: VideoController = new VideoController()

  private async textRecognitionTest() {
    if (!this.chooseImage) {
      return;
    }
    let visionInfo: textRecognition.VisionInfo = {
      pixelMap: this.chooseImage
    };
    let textConfiguration: textRecognition.TextRecognitionConfiguration = {
      isDirectionDetectionSupported: false
    };
    // Call the OCR API.
    let recognitionResult = await textRecognition.recognizeText(visionInfo, textConfiguration);
    let recognitionString = recognitionResult.value;
    this.dataValues = recognitionString;
    hilog.info(0x0000, 'OCRDemo', `Succeeded in recognizing text：${recognitionString}`);

    if (this.chooseImage && this.imageSource) {
      this.chooseImage.release();
      this.imageSource.release();
    }
  }

  async aboutToAppear(): Promise<void> {
    const initResult = await textRecognition.init();
    hilog.info(0x0000, 'OCRDemo', `OCR service initialization result:${initResult}`);
  }

  async aboutToDisappear(): Promise<void> {
    await textRecognition.release();
    hilog.info(0x0000, 'OCRDemo', 'OCR service released successfully');
  }

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
        TextInput({ placeholder: '󰇛 请输入视频直链'/*, text: 'https://hnyqwq.cn/hvideo/.mp4'*/ })
          .type(InputType.URL)
          //.backgroundColor('#FF9CCE')
          .width('55%')
          .height(50)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.networkVideoSrc = value;
          })
        Button('󰀽 分享')
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
        Button('󰂴 播放')
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
          placeholder: '󰒔 使用测试视频，仅需输入名称，如w/k/55/ay/bxqy/ctxn/dly/dsm/jzn/qxmst/ssy/y/ylzz/yzjt/sr'
        })
        //.backgroundColor('#FF9CCE')
          .width('55%')
          //.height(50)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.networkVideoSrc = 'https://www.hnyqwq.cn/hvideo/' + value + '.mp4';
          })
        Button('󰀨󰄨 扫码')
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
      /*
      Row() {
        CollaborationServiceStateDialog({
          onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
            bufferType, buffer)
        })
        Button('󰓥 选图')
          .type(ButtonType.Capsule)
          .fontColor(Color.White)
          .width('20%')
          .margin({ right: 10 })
          .height(50)
          .backgroundColor(0xffd143)
          .bindMenu(this.MyTestMenu)
        Button('󰇘 OCR')
          .type(ButtonType.Capsule)
          .fontColor(Color.White)
          .alignSelf(ItemAlign.Center)
          .width('20%')
          .height(50)
          .backgroundColor(0xffd143)
          .onClick(async () => {
            this.textRecognitionTest();
          })
      }.margin({ top: 10 })
*/

      // 使用堆叠布局，顶部起始对齐
      Stack({ alignContent: Alignment.TopStart }) {
        // 滚动区域
        Scroll(this.scroller) {
          //.height('80%') // 固定百分比高度
          Column() {
            Text(this.dataValues)
              .copyOption(CopyOptions.LocalDevice)
              .width('100%')
            Image(this.chooseImage)
              .objectFit(ImageFit.Contain)
              .aspectRatio(16 / 9) // 根据视频长宽比自动计算高度
              .constraintSize({ maxWidth: 900, minWidth: 600 })
          }
          .width('100%')
          .height('100%') // 填满Scroll容器
          //.margin({ bottom: 290 }) // 手机底部安全边距
          //.margin({ bottom: 580 }) // 平板底部安全边距
          //.margin({ bottom: 600 }) // 底部安全边距
        }
        .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
        .scrollBar(BarState.On) // 滚动条常驻显示
        .scrollBarColor(Color.Gray) // 滚动条颜色
        .scrollBarWidth(10) // 滚动条宽度
        .backgroundColor($r('app.color.start_window_background'))
        .friction(0.6) // 设置滚动摩擦系数（影响滚动惯性）
        .edgeEffect(EdgeEffect.None)
        .flexGrow(1) // 自动填充剩余空间
        .layoutWeight(1) // 添加layoutWeight确保padding生效
        /*.onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState) => {
          console.info(xOffset + ' ' + yOffset) // 滚动即将发生时触发
        })
        .onScrollEdge((side: Edge) => {       // 滚动到边缘时触发
          console.info('To the edge')
        })
        .onScrollStop(() => {                // 滚动停止时触发
          console.info('Scroll Stop')
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
        /*Button('下滑')// 150
          .backgroundColor(0x330066)
          .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离，滑动过程配置有动画
            let curve = curves.interpolatingSpring(10, 1, 228, 30) //创建一个阶梯曲线
            const yOffset: number = this.scroller.currentOffset().yOffset;
            this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 150, animation: { duration: 1000, curve: curve } })
          })
          .margin({ top: 10, left: 20 })
        Button('回顶')
          .backgroundColor(0x330066)
          .onClick(() => { // 点击后回到顶部 back top
            this.scroller.scrollEdge(Edge.Top)
          })
          .margin({ top: 0, left: 5 })
        Button('进度')
          .backgroundColor(0x330066)
          .onClick(() => {
            this.isControls = !this.isControls;
            promptAction.showToast({
              message: `控制栏已${this.isControls ? '显示' : '隐藏'}`
            });
          })
          .margin({ top: 60, left: 20 })
        //.margin({ top: 10, left: 100 })*/
        /*22222222222222222/*Button(this.currentFitMode === ImageFit.Fill ? '自适应' :'强制填充屏幕')
          .backgroundColor(0xFF66CC)
          .onClick(() => {
            this.currentFitMode = this.currentFitMode === ImageFit.Fill
              ? ImageFit.Auto
              : ImageFit.Fill;
            promptAction.showToast({
              message: `当前模式: ${this.currentFitMode === ImageFit.Fill ? 'Fill(强制填充屏幕)' : 'Auto(自适应)'}`
            });
          })
          .margin({ top: 100, left: 5 })*/
        /*Button('翻页')
          .backgroundColor(0x330066)
          .onClick(() => { // 点击后滑到下一页
            this.scroller.scrollPage({ next: true ,animation: true })
          })
          //.margin({ top: 10, left: 100 })
          .margin({ top: 110, left: 20 })*/
        /*Button(this.curRate === PlaybackSpeed.Speed_Forward_1_00_X ?  '暂停' : '继续')
          .backgroundColor(0x330066)
          .onClick(() => {
            // 通过当前播放速率判断是否正在播放
            if (this.curRate == PlaybackSpeed.Speed_Forward_1_00_X) {
              this.controller.pause();
              //this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
              promptAction.showToast({message: '已暂停播放'});
            } else {
              this.controller.start();
              //this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
              promptAction.showToast({message: '已开始播放'});
            }
          }).margin({ top: 110, left: 20 })*/

        /*22222222222222222/*Button('全屏')
          .backgroundColor('#0044fc')
          .onClick(() => {
            this.controller.requestFullscreen(true);
            window.getLastWindow(this.context).then((win) => {
              win.setPreferredOrientation(window.Orientation.LANDSCAPE);
            });
          })
          //.margin({ top: 60, left: 100 })
          .margin({ top: 50, left: 5 })

        Button(this.currentFitMode === ImageFit.Cover ? '保持比例' :'比例放大填充')
          .backgroundColor(0xFF66CC)
          .onClick(() => {
            this.currentFitMode = this.currentFitMode === ImageFit.Cover
              ? ImageFit.Contain
              : ImageFit.Cover;
            promptAction.showToast({
              message: `当前模式: ${this.currentFitMode === ImageFit.Cover ? 'Contain(保持比例)' : 'Cover(比例放大填充)'}`
            });
          })
          //.margin({ top: 10, left: 180 })
          .margin({ top: 150, left: 5 })
        Button(this.curRate === PlaybackSpeed.Speed_Forward_2_00_X ? '原速' : '倍速')
          .backgroundColor('#0044fc')
          .onClick(() => {
            this.curRate = this.curRate === PlaybackSpeed.Speed_Forward_2_00_X
              ? PlaybackSpeed.Speed_Forward_1_00_X
              : PlaybackSpeed.Speed_Forward_2_00_X;
            promptAction.showToast({
              message: `已成功切换至${this.curRate === PlaybackSpeed.Speed_Forward_2_00_X ? '2' : '1'}倍速播放`
            });
          })
          //.margin({ top: 60, left: 180 })
          .margin({ top: 0, left: 5 })*/
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

      } /*.width('100%').height('100%').backgroundColor(0xDCDCDC)*/
    }
  }

  /*doInsertPicture(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    if (stateCode != 0) {
      return;
    }
    if (bufferType == "general.image") {
      let imageSource = image.createImageSource(buffer);
      imageSource.createPixelMap().then((pixelMap) => {
        this.chooseImage = pixelMap; // 直接赋值给目标变量
      })
    }
  }*/
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