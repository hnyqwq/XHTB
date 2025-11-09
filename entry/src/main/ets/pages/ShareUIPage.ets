import { common, OpenLinkOptions, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import Logger from '../utils/Logger';
import router from '@ohos.router';

//点光源效果
import { hdsEffect } from '@kit.UIDesignKit';

let logger = Logger.getLogger('[ShareUIPage]');

@Entry
@Component
struct SystemShare {
  localStorage = this.getUIContext().getSharedLocalStorage();

  @State message: ResourceStr = $r('app.string.appname');
  @State textContent: string = '';
  @State htmlLink: string = '';
  @State imageUri: string = '';
  @State videoUri: string = '';
  @State pixelMap: image.PixelMap | null = null;
  private want: Want | undefined = this.localStorage?.get<Want>('ShareUIAbilityWant');
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';

  //点光源效果
  @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  @State lightSourceType: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;

  aboutToAppear(): void {
    systemShare.getSharedData(this.want).then((data: systemShare.SharedData) => {
      let records: systemShare.SharedRecord[] = data.getRecords();
      records.forEach(async (record: systemShare.SharedRecord) => {
        switch (record.utd) {
          case utd.UniformDataType.TEXT:
            record.content && (this.textContent = record.content);
            break;
          case utd.UniformDataType.HYPERLINK:
            record.content && (this.htmlLink = record.content);
            break;
          default:
            break;
        }
      });
    }).catch((error: BusinessError) => {
      logger.error(`getSharedData error. Code: ${error?.code}, message: ${error?.message}`);
    });
  }

  @Builder
  ShareContent() {
    Text($r('app.string.shareinfo'))
      .fontSize(28)
      .margin({ top: 20 })

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
        .visualEffect(new hdsEffect.HdsEffectBuilder()
          .shaderEffect({
            effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
            animation: {
              duration: 4000,
              iterations: -1,
              autoPlay: true,
              onFinish: () => {
                console.info('Succeeded in finishing');
              }
            },
            controller: this.controller,
            params: {
              firstEdgeFlowLight: {
                startPos: 0,
                endPos: 1.0,
                color: '#ff8a00',
              },
              secondEdgeFlowLight: {
                startPos: 0.5,
                endPos: 1.5,
                color: '#f3c52a',
              }
            }
          })
          .buildEffect())
    }

    if (this.imageUri) {
      Text("Not Support Image")
      Image(this.imageUri)
        .width(200)
        .height(200)
    }

    if (this.videoUri) {
      Text("Not Support Video")
      Video({
        src: this.videoUri,
        previewUri: this.pixelMap
      })
        .width(200)
        .height(200)
    }
  }

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)

        this.ShareContent();

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
              this.networkVideoSrc = this.htmlLink;
              router.pushUrl({ url: 'pages/Index' })
                .catch((e: BusinessError) => {
                  console.error('路由跳转失败', e);
                });
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .shaderEffect({
                effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                animation: {
                  duration: 4000,
                  iterations: -1,
                  autoPlay: true,
                  onFinish: () => {
                    console.info('Succeeded in finishing');
                  }
                },
                controller: this.controller,
                params: {
                  firstEdgeFlowLight: {
                    startPos: 0,
                    endPos: 1.0,
                    color: '#FF66CC',
                  },
                  secondEdgeFlowLight: {
                    startPos: 0.5,
                    endPos: 1.5,
                    color: '#b87cff',
                  }
                }
              })
              .buildEffect())
        }
      }
      .width('100%')
    }
    .height('100%')
  }
}