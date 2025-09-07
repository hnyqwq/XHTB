import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入默认界面需要的日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import Logger from '../utils/Logger';

//两个临时无需权限组件
import { pasteboard } from '@kit.BasicServicesKit';

//分享相关
import { fileUri } from '@kit.CoreFileKit';
import request from '@ohos.request';
import router from '@ohos.router';
//本地
import { fileIo, picker } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import MediaFileUri from '../media/MediaFileUri';
import { dataSharePredicates } from '@kit.ArkData';
import { uri } from '@kit.ArkTS';
import KnockShareGuideCard, { CardRes } from '../model/KnockShareGuideCard';

interface myParams {
  uri: string
};

let logger = Logger.getLogger('[KnockShare]');
let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

/*
@Extend(Button) function globalButtonStyle() {
  .width('60%')
  .height(80)
  //.background (0x99CCFF)  // 白色背景
  .borderRadius(15)           // 圆角半径
  .margin({ top: 10 })         // 顶部间距
}*/

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct HomePage {
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State isPlaying: boolean = true;
  @State picture: PixelMap | undefined = undefined;
  //@State networkPreviewUri: string = 'https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250814201313.54764824779401317176433540350951:50001231000000:2800:0987A5ACC48494286FD28FDE9DDACFBCA0C24FD30400A3FE0AD75E2BC2A9EB2D.png'; // 默认网络预览图
  @State sharepng: string = 'https://www.hnyqwq.cn/hvideo/share.png'
  //@State networkPreviewUri: Resource = $r('app.media.homepageback');
  @State savefileUri: string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  //碰一碰
  @State whiteStatus: boolean = false;
  private controller: VideoController = new VideoController();
  saveButtonOptions: SaveButtonOptions = {
    icon: SaveIconStyle.FULL_FILLED,
    /*text: SaveDescription.SAVE_IMAGE,
    buttonType: ButtonType.Capsule*/
  }
  //本地
  @State myContext: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State myFileTypes: number = 0;
  @State myFileName: string = '';
  @State myFileSize: number = 0;
  @State myUris: string = (this.getUIContext().getRouter().getParams() as myParams)?.uri ?? ' ';
  @State uri: string = '';
  mediaFileUri: MediaFileUri = new MediaFileUri();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  //华为系统分享
  private async share() {
    if (!this.networkVideoSrc) {
      promptAction.showToast({ message: $r('app.string.nopeng') });
      return;
    }

    const contextFaker: Context = getContext(this);
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    const fileData: Uint8Array = await resourceMgr.getMediaContent($r('app.media.CIcon'));

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc, // 使用输入框中的视频链接
      title: context.resourceManager.getStringSync($r('app.string.shareinfo').id),
      description: this.networkVideoSrc,
      thumbnail: fileData,
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      logger.info('ShareController show success.');
      promptAction.showToast({ message: $r('app.string.sharesuccess') + this.networkVideoSrc });
    }).catch((error: BusinessError) => {
      logger.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      //promptAction.showToast({ message: '分享失败: ' + error.message });
      promptAction.showToast({ message: $r('app.string.nopeng') });
    });
  }

  //碰一碰分享
  private readonly cardSwiperResources: CardRes[] = [
    {
      text: '对方手机需 HarmonyOS 5 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
      framesCount: 128,
      startDelay: 50,
      stopDelay: 500,
    },
    {
      text: '对方电脑需 HarmonyOS 6 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_pc_',
      framesCount: 104,
      startDelay: 50,
      stopDelay: 50,
    },
  ];
  private debounceTimer: number = 0
  // 修改 handleImageUpdate 方法
  private handleImageUpdate() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.DownloadToSandbox();
    }, 1000); // 1秒防抖
  }

  // 修改 DownloadToSandbox 方法
  private async DownloadToSandbox() {
    if (!this.isValidUrl(this.sharepng)) {
      console.log('Invalid URL, skipping download');
      return;
    }

    if (this.sharepng !== '') {
      try {
        // 先删除旧文件（如果存在）
        try {
          await fs.unlink(filesDir + '/pengyipeng.jpg');
        } catch (e) {
          // 文件不存在是正常情况，忽略错误
        }

        // 下载新文件
        await request.downloadFile(context, {
          url: this.sharepng,
          filePath: filesDir + '/pengyipeng.jpg'
        });

        console.log('Image downloaded successfully');
      } catch (error) {
        console.error('Download failed:', error);
      }
    }
  }

  isValidUrl(url: string): boolean {
    const pattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$/;
    return pattern.test(url);
  }

  onPageHide(): void { //隔空传送
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  aboutToAppear(): void {
    this.DownloadToSandbox();
    this.whiteListening()
    //this.immersiveListening();
    let context = getContext(this);

    // 建议调整顺序确保实时参数优先
    const params = router.getParams() as Record<string, string>;
    if (params?.['videoUrl']) {
      this.networkVideoSrc = params['videoUrl'];
    }
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      AppStorage.delete('sharedVideoUrl');
    }
    // 触发视频加载
    this.context.eventHub.on('urlUpdate', (url: string) => {
      this.networkVideoSrc = url
      this.controller.start()
    })

    context.eventHub.on('onBackGround', this.onBackGround);
  }

  aboutToDisappear(): void {
    logger.info('aboutToDisappear invoked.');
    this.whiteDisablingListening()
    //this.immersiveDisablingListening();
    let context = getContext(this);
    context.eventHub.off('onFocus');
    context.eventHub.off('onBackGround');
  }

  private onBackGround = () => {
    this.whiteDisablingListening()
    //this.immersiveDisablingListening();
  }
  // 在类成员变量区域定义箭头函数绑定回调
  private whiteCallback = async (sharableTarget: harmonyShare.SharableTarget): Promise<void> => {
    // 处理分享数据
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      this.controller.start();
      AppStorage.delete('sharedVideoUrl');
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let filePath = this.context?.filesDir + "/pengyipeng.jpg";
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc,
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
      description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
    });
    sharableTarget.share(shareData);
/*
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

      // 1. 使用 rawfile 方案获取资源
      const rawfileName = 'share.png'; // rawfile 目录下的文件名
      const fdResult = await context.resourceManager.getRawFd(rawfileName);

      // 2. 直接使用文件描述符构建 URI
      const fdPath = `fd://${fdResult.fd}`;

      // 3. 构建分享数据
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.networkVideoSrc,
        thumbnailUri: fdPath,
        title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
        description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
      });

      // 4. 执行分享
      sharableTarget.share(shareData);

    } catch (error) {
      console.error("分享缩略图处理失败:", error);
      // 后备方案：不使用缩略图
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let shareData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.networkVideoSrc,
        title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
        description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
      });
      sharableTarget.share(shareData);
    }*/
  }

  // 修改事件监听与解绑逻辑
  private whiteListening() {
    if (this.isNoListening()) {
      harmonyShare.on('knockShare', this.whiteCallback);
      this.whiteStatus = true;
    } else {
      promptAction.showToast({ message: $r('app.string.nopeng') });
    }
  }

  private whiteDisablingListening() {
    harmonyShare.off('knockShare', this.whiteCallback);
    this.whiteStatus = false;
  }

  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    // 直接处理分享数据（假设数据已通过其他方式传递）
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      this.controller.start();
      AppStorage.delete('sharedVideoUrl');
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let filePath = this.context?.filesDir + "/pengyipeng.jpg";
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc,
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
      description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
    });
    sharableTarget.share(shareData);
  }

  /*private immersiveListening() {
    harmonyShare.on('gesturesShare', this.immersiveCallback);
  }

  private immersiveDisablingListening() {
    harmonyShare.off('gesturesShare', this.immersiveCallback);
  }*/

  //本地
  private async callFilePickerSelectImage() {
    let uri = await this.openPhoto();
    if (uri === undefined) {
      hilog.error(0x0000, 'local', "Failed to get uri.");
      return;
    }
    this.networkVideoSrc=uri;
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE,
        maxSelectNumber: 1
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'local', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }

  async getMediaNameByUri(myUri: string) {
    this.myFileName = (myUri.split('/').pop()) as string;
  }

  build() {
    Column() {
      Column()
      {
        Text($r('app.string.sharepngon'))
          .textAlign(TextAlign.Center)
        TextInput({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
          .type(InputType.URL)
          //.backgroundColor('#FF9CCE')
          .width('90%')
          .height(50)
          .margin({ top: 10, bottom: 10 })
          .onChange((sharepng: string) => {
            this.sharepng = sharepng;
            if (this.isValidUrl(sharepng)) {
              this.handleImageUpdate(); // 触发图片更新逻辑
            }
          })
      }
      Text($r('app.string.texton'))
        .textAlign(TextAlign.Center)
        .margin({ top: 5, bottom: 10 })
      Row() {
        Button($r('app.string.scancode'))
        //.globalButtonStyle()
        //.type(ButtonType.Capsule)
          //.backgroundColor(0x66CCFF)//蓝色
          //.backgroundColor('#0044fc')
          .labelStyle({ overflow: TextOverflow.Ellipsis, maxLines: 3, minFontSize: 0 })
          .width('55%')
          .height(50)
          .margin({ right: 10 })
          .backgroundColor(0xFF66CC)
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
                hilog.error(0x0001, '[Scan]',
                  `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                promptAction.showToast({ message: '手动取消或扫码失败（PC/2in1设备暂不支持扫描二维码，请使用其它类型的设备）' });
              });
            } catch (error) {
              //promptAction.showToast({ message: '扫码失败: 读取二维码信息错误； ' + error.message });
              promptAction.showToast({ message: '扫码失败: 启动扫码服务失败' });
              hilog.error(0x0001, '[Scan]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          })
        Button($r('app.string.share'))
        //.type(ButtonType.Capsule)
          .width('40%')
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
      }
      .width('90%')
      .margin({ top: 5, bottom: 10 })

      Row() {
        /*TextInput({ placeholder: $r('app.string.testinput') })
        /*TextArea({
          placeholder: $r('app.string.testinput')
        })
          .width('55%')
          //.height(50)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.networkVideoSrc = 'https://www.hnyqwq.cn/hvideo/' + value + '.mp4';
            AppStorage.set('networkVideoSrc', this.networkVideoSrc);
          })*/
        TextArea({ placeholder: $r('app.string.testinput') })
          //.type(InputType.URL)
          //.backgroundColor('#FF9CCE')
          .width('55%')
          //.height(50)
          .margin({ right: 10 })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })
        PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
          .backgroundColor(0x66CCFF)//蓝色
          .width('40%')
          .height(50)
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

      /*Row() {
        Button($r('app.string.speedtitle'))
          .backgroundColor(0xb87cff)
          .bindMenu([
            {
              value: $r('app.string.1xspeed'),
              action: () => {
                console.info('handle Menu11 select');
                this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
                promptAction.showToast({
                  message: $r('app.string.1xspeedyes')
                })
              }
            },
            {
              value: $r('app.string.125xspeed'),
              action: () => {
                console.info('handle Menu12 select');
                this.curRate = PlaybackSpeed.Speed_Forward_1_25_X;
                promptAction.showToast({
                  message: $r('app.string.125xspeedyes')
                })
              }
            },
            {
              value: $r('app.string.175xspeed'),
              action: () => {
                console.info('handle Menu13 select');
                this.curRate = PlaybackSpeed.Speed_Forward_1_75_X;
                promptAction.showToast({
                  message: $r('app.string.175xspeedyes')
                })
              }
            },
            {
              value: $r('app.string.2xspeed'),
              action: () => {
                console.info('handle Menu14 select');
                this.curRate = PlaybackSpeed.Speed_Forward_2_00_X;
                promptAction.showToast({
                  message: $r('app.string.2xspeedyes')
                })
              }
            },
            {
              value: $r('app.string.075xspeed'),
              action: () => {
                console.info('handle Menu15 select');
                this.curRate = PlaybackSpeed.Speed_Forward_0_75_X;
                promptAction.showToast({
                  message: $r('app.string.075xspeedyes')
                })
              }
            }
          ])
        Button($r('app.string.fullscreen'))
          .backgroundColor(0xb87cff)
          .margin({ left: 10 })
          .onClick(() => {
            this.controller.requestFullscreen(true);
            window.getLastWindow(this.context).then((win) => {
              win.setPreferredOrientation(window.Orientation.LANDSCAPE);
            });
          })
        Button($r('app.string.ImageFittitle'))
          .backgroundColor(0xb87cff)
          .margin({ left: 10 })
          .bindMenu([
            {
              value: $r('app.string.Cover'),
              action: () => {
                console.info('handle Menu21 select');
                this.currentFitMode = ImageFit.Cover;
                promptAction.showToast({ duration: 10000,
                  message: $r('app.string.Coveryes')
                })
              }
            },
            {
              value: $r('app.string.Auto'),
              action: () => {
                console.info('handle Menu22 select');
                this.currentFitMode = ImageFit.Auto;
                promptAction.showToast({ duration: 10000,
                  message: $r('app.string.Autoyes')
                })
              }
            },
            {
              value: $r('app.string.Fill'),
              action: () => {
                console.info('handle Menu23 select');
                this.currentFitMode = ImageFit.Fill;
                promptAction.showToast({ duration: 10000,
                  message: $r('app.string.Fillyes')
                })
              }
            },
            {
              value: $r('app.string.Contain'),
              action: () => {
                console.info('handle Menu24 select');
                this.currentFitMode = ImageFit.Contain;
                promptAction.showToast({ duration: 10000,
                  message: $r('app.string.Containyes')
                })
              }
            }
          ])
      }*/

      // 使用堆叠布局，顶部起始对齐
      Stack({ alignContent: Alignment.TopStart }) {
        // 滚动区域
          Column() {
            Text($r('app.string.nowplaying'))
              .textAlign(TextAlign.Center)
            Text(this.networkVideoSrc)
              .padding({ top: 10 })
              .copyOption(CopyOptions.LocalDevice)
              .textAlign(TextAlign.Center)
              .width('100%')
            Text($r('app.string.nowplayingon'))
              .padding({ top: 10 , left: 24, right: 24 })
              .maxLines(2)
              .fontSize(11)
              .maxFontScale(1.75)
              .width('100%')
              .constraintSize({ minHeight: 16 })
              .fontColor($r('sys.color.font_secondary'))
              .fontFamily('HarmonyHeiTi')
              .textAlign(TextAlign.Center)
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
              .padding({ top: 2 })

            /*Text(this.myFileName)
              .focusable(true)
              .focusOnTouch(true)
              .fontFamily('HarmonyHeiTi-Bold')
              .textAlign(TextAlign.Start)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('Size: ' + JSON.stringify(this.myFileSize) + 'B')
              .focusable(true)
              .focusOnTouch(true)
              .fontFamily('HarmonyHeiTi')
              .textAlign(TextAlign.Start)*/
          }
          .width('90%')  // 控制内容区域宽度
          .alignItems(HorizontalAlign.Center) // 内容水平居中
          .margin({ top: 10 })
          //.height('100%')
      }
    }
    .width('100%')
    //.height(400)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)  // 动态分配剩余空间
  }

  private isNoListening() {
    return !this.whiteStatus;
  }
}

/*
interface DurationObject {
  duration: number;
}

interface TimeObject {
  time: number;
}

interface FullscreenObject {
  fullscreen: boolean;
}*/