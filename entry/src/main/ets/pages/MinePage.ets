import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';
import { commentManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Observed
class SettingMenu {
  public uri?: string;
  public id: string;
  public image: Resource;
  public text: Resource;
  public des: Resource;

  constructor(id: string, image: Resource, text: Resource, des: Resource) {
    this.id = id;
    this.image = image;
    this.text = text;
    this.des = des;
  }
}

@Entry
@Component
export struct MinePage {
  @State inputText: string = ''
  private customDialogComponentId: number = 0
  @State isDialogActive: boolean = false

  aboutToDisappear(): void {  // 显式声明返回类型
    if (this.isDialogActive) {
      this.safeCloseDialog()
    }
  }
  private safeCloseDialog() {
    if (this.customDialogComponentId === 0 || !this.isDialogActive) return
  }
  private iconStr: ResourceStr = $r("app.media.CIcon");
  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('app.media.mine_settings'), $r('app.string.mine1'), $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('app.media.mine_vipsettings'), $r('app.string.mine2'), $r('app.string.void')),
    new SettingMenu('mycollection', $r('app.media.ic_collect'), $r('app.string.mine3'), $r('app.string.void')),
    new SettingMenu('mylike', $r('app.media.mine_like'), $r('app.string.mine4'), $r('app.string.void')),
    new SettingMenu('browsinghistory', $r('app.media.mine_time'), $r('app.string.mine5'), $r('app.string.void'))
  ];
  //设置一镜到底动效
  @Builder
  MyMenu() {
    Menu() {
      MenuItem({ startIcon: this.iconStr, content: $r('app.string.minelongpress'), })
        .onClick(() => {
            let want: Want = {
              "action": "ohos.want.action.viewData",
              "entities": ["entity.system.browsable"],
              uri: 'https://hnyqwq.cn/hvideo',
            }
            let context = getContext(this) as common.UIAbilityContext;
            context.startAbility(want)
            console.info(`MenuItem1 ability succeed`)
        })
      MenuItem({ startIcon: this.iconStr, content: $r('app.string.meow') })
        .onClick(() => {
          let want: Want = {
            "action": "ohos.want.action.viewData",
            "entities": ["entity.system.browsable"],
            uri: 'https://www.chuckfang.com/MeoW/appLinking?channelId=0fd24620b27a4943bfe36e42b71df88d',
          }
          let context = getContext(this) as common.UIAbilityContext;
          context.startAbility(want)
          console.info(`MenuItem2 ability succeed`)
        })
      MenuItem({ startIcon: this.iconStr, content: $r('app.string.5star') })
        .onClick(() => {
          try {
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            commentManager.showCommentDialog(uiContext).then(()=>{
              hilog.info(0, 'TAG', "succeeded in showing commentDialog.");
            }).catch((error: BusinessError<Object>) => {
              hilog.error(0, 'TAG', `showCommentDialog failed, Code: ${error.code}, message: ${error.message}`);
            });
          } catch (error) {
            hilog.error(0, 'TAG', `showCommentDialog failed, Code: ${error.code}, message: ${error.message}`);
          }
        })
    }
  }
  @Builder
  MyPreview() {
    Column() {
      Image($r('app.media.CIcon'))
        .width(200)
        .height(200)
    }
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Text($r('app.string.aboutpage'))
            .fontSize(20)
            .fontColor($r('app.color.font_color_info'))
            .fontWeight(FontWeight.Bold)
        }
        // 顶部用户信息区域 - 保持不变
        Column() {
          Image($r('app.media.CIcon'))
            .width(60)
            .height(60)
            .bindContextMenu(this.MyMenu, ResponseType.LongPress,
              {
                preview: this.MyPreview,
                previewAnimationOptions: {
                  hoverScale: [1.0, 0.95]
                }
              })
          Text($r('app.string.appname'))
            .fontWeight(700)
            .fontSize('14fp')
            .margin({ top: 10 });
          Text('')
            .fontWeight(600)
            .fontSize('12fp')
            .margin({ top: 10 });
        }
        .width('100%')
        .height(222)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        //.backgroundColor($r('app.color.start_window_background'))

        // 设置项列表区域 - 保持不变
        Column() {
          Row() {
            List() {
              ForEach(this.menuGroup,
                (item: SettingMenu) => {
                  ListItem() {
                    SettingItemView({ image: item.image, text: item.text, des: item.des });
                  }
                  .width('100%')
                  .onClick(() => {
                    const context = getContext(this) as common.UIAbilityContext;
                    let uri = '';
                    switch (item.id) {
                      case 'setting':
                        router.pushUrl({ url: 'pages/infoPage' })
                          .catch((e: BusinessError) => {
                            console.error('路由跳转失败', e);
                          });
                        break;
                      case 'vipownsetting':
                        uri = 'https://www.hnyqwq.cn';
                        //uri = 'bilibili://live/21220648';
                        break;
                      case 'mycollection':
                        uri = 'bilibili://space/338142387';
                        break;
                      case 'mylike':
                        uri =
                          //'snssdk1128://user/profile/2118115953227692?refer=web';
                           'snssdk1128://user/profile/618379012226540?refer=web';
                        break;
                      case 'browsinghistory':
                        uri = 'https://blog.hnyqwq.cn';
                        break;
                    }
                    if (uri) {
                      const want: Want = { uri };
                      context.startAbility(want).catch((e: BusinessError) => {
                        console.error(`跳转失败: ${e.code}`, e.message);
                      });
                    }
                  })
                },
                (item: SettingMenu) => item.id.toString());
            }
            .scrollBar(BarState.Auto)
            .divider({
              strokeWidth: $r('app.float.stroke_width'),
              color: $r('app.color.font_color_00000'),
              startMargin: $r('app.integer.layout_size_46'),
              endMargin: $r('app.integer.layout_size_24')
            });
          }
          .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
          .width('90%')
          .borderRadius($r('app.integer.layout_size_24'))
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: $r('app.integer.layout_size_12') })
          //.backgroundColor($r('app.color.font_color_FFFFFF'));
          .backgroundColor($r('app.color.mine'))
        }
        .layoutWeight(1)
        .width('100%');

        // 底部协议信息区域 - 保持不变
        Column() {
          Text() {
            Span($r('app.string.appyhxy'))
              .onClick(() => {
                try {
                  let want: Want = {
                    "action": "ohos.want.action.viewData",
                    "entities": ["entity.system.browsable"],
                    uri: 'https://hnyqwq.cn/hvideo/xhyhxy.html',
                    "type": "text/plain"
                  }
                  let context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want)
                  console.info(`explicit start ability succeed`)
                } catch (error) {
                  console.info(`explicit start ability failed with ${error.code}`)
                }
              })
              .fontColor(Color.Blue)
              .fontSize(12);
            Span($r('app.string.and'))
              .fontSize(12);
            Span($r('app.string.appysxy'))
              .onClick(() => {
                try {
                  let want: Want = {
                    "action": "ohos.want.action.viewData",
                    "entities": ["entity.system.browsable"],
                    uri: 'https://hnyqwq.cn/hvideo/xh.html',
                    "type": "text/plain"
                  }
                  let context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want)
                  console.info(`explicit start ability succeed`)
                } catch (error) {
                  console.info(`explicit start ability failed with ${error.code}`)
                }
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          };

          Text($r('app.string.copyright'))
            .fontSize(12);
          Text() {
            Span('蜀ICP备2025142744号-2A')
              .onClick(() => {
                try {
                  let want: Want = {
                    "action": "ohos.want.action.viewData",
                    "entities": ["entity.system.browsable"],
                    uri: 'https://beian.miit.gov.cn',
                    "type": "text/plain"
                  }
                  let context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want)
                  console.info(`explicit start ability succeed`)
                } catch (error) {
                  console.info(`explicit start ability failed with ${error.code}`)
                }
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          }
        }
        .width('100%')
        .height(60)
        .alignItems(HorizontalAlign.Center)
        .padding(10);
      }
      .width('100%')
      .height('100%')
      .padding({ top: 30 }) // 为标题栏留出空间
    }
    .width('100%')
    .height('100%')
    //.backgroundColor($r('app.color.start_window_background'))
  }
}

@Component
export struct SettingItemView {
  @Prop image: string | Resource;
  @Prop text: string | Resource;
  @Prop des: string | Resource;

  build() {
    Row() {
      Row() {
        Image(this.image)
          .width($r('app.integer.layout_size_22'))
          .height($r('app.integer.layout_size_32'))
          .objectFit(ImageFit.Contain);
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_182431'))
          .margin({ left: $r('app.integer.layout_size_12') })
          .layoutWeight(1)
          .lineHeight($r('app.integer.layout_size_22'));

        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_182431'))
          .lineHeight($r('app.integer.layout_size_19'));
      }
      .width('100%')
      .height($r('app.integer.tabbar_height'))
      .padding({
        left: $r('app.integer.layout_size_22'),
        right: $r('app.integer.layout_size_12')
      })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height($r('app.integer.layout_size_48'))
    .alignSelf(ItemAlign.Center);
  }
}