import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
// 导入默认界面需要的日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { textRecognition } from '@kit.CoreVisionKit'
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

import { DocScanPage } from '../DocScan/DocScanPage';

import {
  createCollaborationServiceMenuItems,
  CollaborationServiceStateDialog,
  CollaborationServiceFilter
} from '@kit.ServiceCollaborationKit';

import { cameraPicker as picker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { navigationManager } from '../../common/NavigationManager';
import { BackButton } from '../../common/BackButton';
import { GlobalInfoModel } from '../../common/GlobalInfoModel';

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct OCR {
  context: common.Context = getContext(this);
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @State networkVideoSrc: string = '';
  private imageSource: image.ImageSource | undefined = undefined;
  @State chooseImage: PixelMap | undefined = undefined;
  @State dataValues: string = '';
  @State picture: PixelMap | undefined = undefined;
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack()
  @Builder
  PageMap(name: string) {
    if (name === 'documentScanner') {
      DocScanPage()
    }
  }
  // 将原独立函数改造为组件方法
  /*private async xj() {
    try {
      let pickerProfile: picker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };

      interface PickerResult {
        uris?: string[];
      }

      // 直接使用组件内的上下文
      let pickerResult = await picker.pick(this.context,
        [picker.PickerMediaType.PHOTO], pickerProfile) as PickerResult;

      // 解析pickerResult中的媒体数据
      if (pickerResult.uris && pickerResult.uris.length > 0) {
        const uri: string = pickerResult.uris[0]; // 只取第一个 URI
        this.loadImage(uri); // 复用现有图片加载方法
      }
    } catch (error) {
      let err = error as BusinessError;
      console.error(`pick failed: ${err.code}`);
    }
  }*/

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

  private async loadImage(uri: string) {
    try {
      // 释放之前的资源
      if (this.chooseImage) {
        this.chooseImage.release();
      }
      if (this.imageSource) {
        this.imageSource.release();
      }

      // 加载新图片
      let fileSource = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      this.imageSource = image.createImageSource(fileSource.fd);
      this.chooseImage = await this.imageSource.createPixelMap();

      // 触发UI更新
      this.dataValues = ''; // 清空OCR识别结果
    } catch (error) {
      hilog.error(0x0000, 'OCRDemo', `Image load failed: ${JSON.stringify(error)}`);
    }
  }

  @Builder
  MyTestMenu() {
    Menu() {
      /*MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.takephotos'),
        builder: (): void => {
          this.xj();
        }
      })*/
      MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.pickphotos'),
        builder: (): void => {
          this.selectImage();
        }
      })
      /*MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.pickphotos'),
        builder: (): void => {
          DocScanPage()
        }
      })*/
      /*MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.pickphotos'),
        builder: (): void => {
          this.recogniZAction();
        }
      })*/
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL], 1)
    }
  }

  scroller: Scroller = new Scroller() // 初始化数据数组（用于生成滚动内容）

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

  build() {
    Column() {
      Row() {
        BackButton()
      }
      .width('100%')
      .height(56)
      .padding({ top: (this.globalInfoModel?.statusBarHeight ?? 0) })

      Row() {
        CollaborationServiceStateDialog({
          onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
            bufferType, buffer)
        })
        Button($r('app.string.pick'))
          .type(ButtonType.Capsule)
          .fontColor(Color.White)
          .width('20%')
          .margin({ right: 10 })
          .height(50)
          .backgroundColor(0xffd143)
          .bindMenu(this.MyTestMenu)
        /*if (this.picture) {
          Image(this.picture)
            .borderStyle(BorderStyle.Dotted)
            .borderWidth(1)
            .objectFit(ImageFit.Contain)
            .height('80%')
            .onComplete((event) => {
              if (event != undefined) {
                hilog.info(0x0000, 'testTag', 'onComplete %{public}s', event.loadingStatus);
              }
            })
        }*/
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
      }
      .padding({ top: 50 })


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
              .objectFit(ImageFit.Auto)
            //.aspectRatio(16 / 9) // 根据视频长宽比自动计算高度
            //.constraintSize({ maxWidth: 900, minWidth: 0 })
          }
          .width('100%')
          //.height('%') // 填满Scroll容器
          //.margin({ bottom: 290 }) // 手机底部安全边距
          //.margin({ bottom: 580 }) // 平板底部安全边距
          //.margin({ bottom: 600 }) // 底部安全边距
          .margin({ bottom: $r('app.float.safe_area_bottom') })
        }
        .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
        .scrollBar(BarState.On) // 滚动条常驻显示
        .scrollBarColor(Color.Gray) // 滚动条颜色
        .scrollBarWidth(5) // 滚动条宽度
        //.backgroundColor(0xffd143)
        .friction(0.6) // 设置滚动摩擦系数（影响滚动惯性）
        .edgeEffect(EdgeEffect.None)
        .flexGrow(1) // 自动填充剩余空间
        .layoutWeight(1) // 添加layoutWeight确保padding生效
      }
    }
  }

  doInsertPicture(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    if (stateCode != 0) {
      return;
    }
    if (bufferType == "general.image") {
      let imageSource = image.createImageSource(buffer);
      imageSource.createPixelMap().then((pixelMap) => {
        this.chooseImage = pixelMap; // 直接赋值给目标变量
      })
    }
  }
}
