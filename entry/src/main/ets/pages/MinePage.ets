import { common, Want, bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationManager } from '../common/NavigationManager';
import { commentManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

@Observed
class SettingMenu {
  public uri?: string;
  public webUrl?: string;  // 备用网页链接
  public id: string;
  public symbol: Resource;
  public text: Resource;
  public des: Resource;

  constructor(id: string, symbol: Resource, text: Resource, des: Resource, uri?: string, webUrl?: string) {
    this.id = id;
    this.symbol = symbol;
    this.text = text;
    this.des = des;
    this.uri = uri;
    this.webUrl = webUrl;
  }
}

@Entry
@Component
export struct MinePage {
  @State inputText: string = ''
  private customDialogComponentId: number = 0
  @State isDialogActive: boolean = false
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('isImmersiveTab')
  isImmersiveTab: boolean = false;

  aboutToDisappear(): void {  // 显式声明返回类型
    if (this.isDialogActive) {
      this.safeCloseDialog()
    }
  }
  private safeCloseDialog() {
    if (this.customDialogComponentId === 0 || !this.isDialogActive) return
  }

  /**
   * 打开URL（支持URL Scheme和网页链接）
   * @param url - 目标URL（可以是URL Scheme或网页链接）
   * @param webUrl - 备用网页链接（当URL Scheme无法打开时使用）
   */
  private openUrl(url: string, webUrl?: string, context?: common.UIAbilityContext): void {
    const ctx = context || getContext(this) as common.UIAbilityContext;
    
    // HTTP/HTTPS 直接打开网页
    if (url.startsWith('http://') || url.startsWith('https://')) {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };
      ctx.startAbility(want).catch((e: BusinessError) => {
        console.error(`网页跳转失败: ${e.code}`, e.message);
      });
      return;
    }
    
    // URL Scheme：判断是否可打开
    try {
      const canOpen: boolean = bundleManager.canOpenLink(url);
      if (canOpen) {
        // 拉起目标应用
        ctx.openLink(url, { appLinkingOnly: false }).catch(() => {
          // 拉起失败，使用备用网页
          if (webUrl) {
            this.openWebUrl(webUrl, ctx);
          }
        });
      } else {
        // 应用未安装，使用备用网页
        if (webUrl) {
          this.openWebUrl(webUrl, ctx);
        } else {
          console.warn(`无法打开URL: ${url}，且无备用网页`);
        }
      }
    } catch (e) {
      console.error(`URL跳转异常:`, e);
      if (webUrl) {
        this.openWebUrl(webUrl, ctx);
      }
    }
  }

  /**
   * 打开网页链接
   */
  private openWebUrl(url: string, context: common.UIAbilityContext): void {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want).catch((e: BusinessError) => {
      console.error(`网页跳转失败: ${e.code}`, e.message);
    });
  }

  private iconStr: ResourceStr = $r("app.media.CIcon");
  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('sys.symbol.gearshape'), $r('app.string.mine1'), $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('sys.symbol.person_badge_plus'), $r('app.string.mine2'), $r('app.string.void'),
      'https://appgallery.huawei.com/apptest/8q2ifpJx0Qz'),
    new SettingMenu('mycollection', $r('sys.symbol.star'), $r('app.string.mine3'), $r('app.string.void'),
      'bilibili://space/338142387', 'https://space.bilibili.com/338142387'),
    new SettingMenu('mylike', $r('sys.symbol.heart'), $r('app.string.mine4'), $r('app.string.void'),
      'snssdk1128://user/profile/618379012226540?refer=web', 'https://www.douyin.com/user/MS4wLjABAAAAxFrsP4LK-iS49UNXIoHz_dwT1JU3FRHrvrKLs7HigGg'),
    new SettingMenu('browsinghistory', $r('sys.symbol.clock'), $r('app.string.mine5'), $r('app.string.void'),
      'https://blog.hnyqwq.cn')
  ];
  //设置一镜到底动效
  @Builder
  MyMenu() {
    Menu() {
      /*MenuItem({ startIcon: this.iconStr, content: $r('app.string.minelongpress'), })
        .onClick(() => {
            let want: Want = {
              "action": "ohos.want.action.viewData",
              "entities": ["entity.system.browsable"],
              uri: 'https://hnyqwq.cn/hvideo',
            }
            let context = getContext(this) as common.UIAbilityContext;
            context.startAbility(want)
            console.info(`MenuItem1 ability succeed`)
        })*/
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
                    SettingItemView({ symbol: item.symbol, text: item.text, des: item.des });
                  }
                  .width('100%')
                  .onClick(() => {
                    const context = getContext(this) as common.UIAbilityContext;
                    // 设置页特殊处理，使用应用内路由
                    if (item.id === 'setting') {
                      navigationManager.pushPath('pages/infoPage');
                      return;
                    }
                    // 有 URI 则进行跳转
                    if (item.uri) {
                      this.openUrl(item.uri, item.webUrl, context);
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
          .margin({ top: 20, bottom: 30 })
          //.backgroundColor($r('app.color.font_color_FFFFFF'));
          .backgroundColor($r('app.color.mine'))
        }
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
                    uri: 'https://app.hnyqwq.cn/hvideo/xhyhxy.html',
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
                    uri: 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1745950820647618944',
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
        .height(80)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 10, right: 10 });
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ top: 30 + px2vp(this.topRectHeight), bottom: px2vp(this.bottomRectHeight) + (this.isImmersiveTab ? 84 : 0) })
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    //.backgroundColor($r('app.color.start_window_background'))
  }
}

@Component
export struct SettingItemView {
  @Prop symbol: Resource;
  @Prop text: string | Resource;
  @Prop des: string | Resource;

  build() {
    Row() {
      Row() {
        SymbolGlyph(this.symbol)
          .fontSize($r('app.integer.layout_size_22'))
          .fontColor([$r('sys.color.icon_primary')]);
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('sys.color.font_primary'))
          .margin({ left: $r('app.integer.layout_size_12') })
          .layoutWeight(1)
          .lineHeight($r('app.integer.layout_size_22'));

        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('sys.color.font_secondary'))
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