import { common, OpenLinkOptions, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import Logger from '../utils/Logger';
import { navigationManager } from '../common/NavigationManager';

let logger = Logger.getLogger('[ShareUIPage]');

@Entry
@Component
struct SystemShare {
  localStorage = this.getUIContext().getSharedLocalStorage();

  @State message: ResourceStr = $r('app.string.shareinfo');
  @State textContent: string = '';
  @State htmlLink: string = '';
  @State imageUri: string[] = [];
  @State videoUri: string[] = [];
  @State pixelMaps: (image.PixelMap | null)[] = [];
  @State shareType: string = 'general'; // general, text, hyperlink, image, video
  private want: Want | undefined = this.localStorage?.get<Want>('ShareUIAbilityWant');
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';

  aboutToAppear(): void {
    systemShare.getSharedData(this.want).then((data: systemShare.SharedData) => {
      let records: systemShare.SharedRecord[] = data.getRecords();
      logger.info(`getSharedData success, records count: ${records.length}`);

      let tempImageUris: string[] = [];
      let tempVideoUris: string[] = [];

      records.forEach((record: systemShare.SharedRecord) => {
        logger.info(`Record UTD: ${record.utd}, URI: ${record.uri}, Content: ${record.content}`);
        switch (true) {
          case record.utd === utd.UniformDataType.TEXT:
            record.content && (this.textContent = record.content);
            this.shareType = 'text';
            break;
          case record.utd === utd.UniformDataType.HYPERLINK:
            record.content && (this.htmlLink = record.content);
            this.shareType = 'hyperlink';
            break;
          case this.belongsToImage(record.utd):
            if (record.uri) {
              tempImageUris.push(record.uri);
              logger.info(`Image added, current count: ${tempImageUris.length}`);
            }
            this.shareType = 'image';
            break;
          case this.belongsToVideo(record.utd):
            if (record.uri) {
              tempVideoUris.push(record.uri);
              logger.info(`Video added, current count: ${tempVideoUris.length}`);
            }
            this.shareType = 'video';
            break;
          default:
            break;
        }
      });

      this.imageUri = tempImageUris;
      this.videoUri = tempVideoUris;
      logger.info(`Final counts - Images: ${this.imageUri.length}, Videos: ${this.videoUri.length}`);
    }).catch((error: BusinessError) => {
      logger.error(`getSharedData error. Code: ${error?.code}, message: ${error?.message}`);
    });
  }

  getShareTypeText(): ResourceStr {
    switch (this.shareType) {
      case 'text':
        return $r('app.string.text_share');
      case 'hyperlink':
        return $r('app.string.link_share');
      case 'image':
        return $r('app.string.image_share');
      case 'video':
        return $r('app.string.video_share');
      default:
        return $r('app.string.shareinfo');
    }
  }

  belongsToImage(recordUtd: string): boolean {
    // 检查是否以 general 开头且为图片类型
    const imageTypes = ['general.jpeg', 'general.png', 'general.gif', 'general.bmp', 'general.webp', 'general.heic'];
    if (imageTypes.includes(recordUtd)) {
      return true;
    }
    // 原有的 UTD 层级检查
    let typeObj: utd.TypeDescriptor = utd.getTypeDescriptor(recordUtd);
    let result = typeObj.belongsTo(utd.UniformDataType.IMAGE);
    return result;
  }

  belongsToVideo(recordUtd: string): boolean {
    // 检查是否以 general 开头且为视频类型
    const videoTypes = ['general.mpeg-4', 'general.mp4', 'general.avi', 'general.mov', 'general.mkv'];
    if (videoTypes.includes(recordUtd)) {
      return true;
    }
    // 原有的 UTD 层级检查
    let typeObj: utd.TypeDescriptor = utd.getTypeDescriptor(recordUtd);
    let result = typeObj.belongsTo(utd.UniformDataType.VIDEO);
    return result;
  }

  @Builder
  ShareContent() {
    if (this.textContent) {
      Text("Not Support Text")
      Text(this.textContent)
        .fontSize(20)
        .margin({ top: 20 })
    }

    if (this.htmlLink) {
      Text(this.htmlLink)
        .padding({ top: 10 , bottom : 10 , left : 10 , right : 10 })
        .copyOption(CopyOptions.LocalDevice)
        .textAlign(TextAlign.Center)//.margin({ right: 10 })
        .width('100%')
        .fontSize(20)
        .onClick(() => {
          const uiContext: UIContext = this.getUIContext();
          const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
          let openLinkOptions: OpenLinkOptions = {
            appLinkingOnly: false
          };
          context.openLink(this.htmlLink, openLinkOptions)
            .then(() => {
              logger.info('open link success.');
            }).catch((err: BusinessError) => {
            logger.error(`open link failed. Code is ${err.code}, message is ${err.message}`);
          })
        })
    }

    if (this.imageUri.length > 0) {
      Text(`图片数量: ${this.imageUri.length}`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 10 , bottom : 5 })
      Grid() {
        ForEach(this.imageUri, (uri: string, index: number) => {
          GridItem() {
            Image(uri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
          }
          .aspectRatio(1)
        }, (uri: string, index: number) => `${index}-${uri}`)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .padding({ left: 10, right: 10 })
    }

    if (this.videoUri.length > 0) {
      Text(`视频数量: ${this.videoUri.length}`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 10 , bottom : 5 })
      List({ space: 8 }) {
        ForEach(this.videoUri, (uri: string, index: number) => {
          ListItem() {
            Row() {
              Video({
                src: uri,
                previewUri: this.pixelMaps[index] || undefined
              })
                .width(120)
                .height(90)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .controls(true)
                .autoPlay(false)
                .loop(false)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
        }, (uri: string, index: number) => `${index}-${uri}`)
      }
      .width('100%')
      .padding({ left: 10, right: 10 })
      .scrollBar(BarState.Auto)
    }
  }

  build() {
    Row() {
      Column() {
        Text(this.getShareTypeText())
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 10 })

        Scroll() {
          Column() {
            this.ShareContent();
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)

        Row()
        {
          Button($r('app.string.back'))
            .type(ButtonType.Capsule)
            .backgroundColor('#0D9FFB')
            .onClick(() => {
              const uiContext: UIContext = this.getUIContext();
              const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
              context.terminateSelf().catch((error: BusinessError) => {
                logger.error(`context.terminateSelf error. Code: ${error?.code}, message: ${error?.message}`);
              })
            })
          Button($r('app.string.toshare'))
            .backgroundColor(0xFF66CC)
            .margin({ left: 10 })
            .onClick(() => {
              if (this.videoUri.length > 0) {
                this.networkVideoSrc = this.videoUri[0];
              } else if (this.htmlLink) {
                this.networkVideoSrc = this.htmlLink;
              }
              navigationManager.pushPath('pages/Index');
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 10, bottom: 20 })
      }
      .width('100%')
      .height('100%')
    }
  }
}