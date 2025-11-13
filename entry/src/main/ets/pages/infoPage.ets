import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

import { deviceInfo } from '@kit.BasicServicesKit';

import { AppUtil } from '@pura/harmony-utils';
import { promptAction } from '@kit.ArkUI';

let bundleName = AppUtil.getBundleName();
let versionCode = AppUtil.getVersionCode();
let versionName = AppUtil.getVersionName();
let baoming = `${bundleName}`
let banbenhao = `${versionName}（${versionCode}）`

let marketNameInfo: string = deviceInfo.marketName;
// 输出结果：the value of the marketName is :Mate XX
console.info('the value of the deviceInfo marketName is :' + marketNameInfo);

let productModelInfo: string = deviceInfo.productModel;
// 输出结果：the value of the productModel is :TAS-AL00
console.info('the value of the deviceInfo productModel is :' + productModelInfo);

let displayVersionInfo: string = deviceInfo.displayVersion;
// 输出结果：the value of the displayVersion is :XXX X.X.X.X
console.info('the value of the deviceInfo displayVersion is :' + displayVersionInfo);

let distributionOSVersion: string = deviceInfo.distributionOSVersion
// 输出结果：the value of the distributionOSVersion is :5.0.0
console.info('the value of the deviceInfo distributionOSVersion is :' + distributionOSVersion);

let bbh = displayVersionInfo.match(/0\s([\d.]+)/);
let bbhsr = (bbh && bbh[1]) || '';//6.0.0.35

let seg = displayVersionInfo.split(' ');
let fullVersion = seg.length > 1 ? seg : '';
let fullVersionsr = (fullVersion && fullVersion[1]) || '';//6.0.0.35(SP..C..R..P..patch..log)

let versionSeg = displayVersionInfo.match(/\s([^C]*)C?/);
let versionSegs = (versionSeg && versionSeg[1]) || '';
let versionSegsr = versionSegs.replaceAll('(',' ')//6.0.0.35 SP

@Observed
  //设置条目信息构造
class FirstMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: Resource; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: Resource, text: string, des: Resource) {
    this.id = id;
    this.title = title;
    this.text = text;
    this.des = des;
  }
}

@Entry
@Component
export struct infoPage {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  //设置条目信息数组
  @State FirstMenuGroup: FirstMenu[] = [
    new FirstMenu('one', $r('app.string.info1'), marketNameInfo, $r('app.string.void')),
    new FirstMenu('two', $r('app.string.info2'), productModelInfo, $r('app.string.void')),
    new FirstMenu('three',$r('app.string.info3'),distributionOSVersion, $r('app.string.void')),
    new FirstMenu('four',$r('app.string.info4'),fullVersionsr, $r('app.string.void')),
    new FirstMenu('five',$r('app.string.info5') ,versionSegsr, $r('app.string.void'))
  ];

  build() {
    Scroll() {
      Column() {
        Column() {
          Row()
          {
            Text('󰃚') // 自定义返回图标
              .fontSize(35)
              .margin({ left: 20 }) // 左侧留白
              .onClick(() => {
                  router.back();
                })
            Text($r('app.string.infopagetitle'))
              .fontSize(20)
              .fontColor($r('app.color.font_color_info'))
              .fontWeight(FontWeight.Bold)
              //.layoutWeight(1)  // 占据剩余空间
              .position({ x: '50%', y: '2.5%' }) // 基于组件自身宽高定位
              .translate({ x: '-50%', y: '-50%' }) // 偏移补偿
          }
          .width('100%')          // 占满父容器宽度
          .justifyContent(FlexAlign.Start) // 主轴线左对齐
        }
        .padding({ bottom: 20 })
          Stack() {
            Row() {
              Image($r('app.media.harmonyos'))
                //.width('1100px')
                .height('1500px')
                .width('90%')
                .margin({ left: '5%', right: '5%' })
                .margin({ bottom: '3%' }) // 图片下方留白
            }
            .clip(true) // 如这里不设置clip为true，则Row组件的圆角不会限制其中的Image组件，Image组件的四个角会超出Row
            .borderRadius(20)

            Button('检查更新')
            //.type(ButtonType.Capsule)
              .width(200)
              .height(40)
              .margin({ top: 220 })
              .onClick(() => {
                let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
                try {
                  updateManager.checkAppUpdate(context)
                    .then((checkResult: updateManager.CheckUpdateResult) => {
                      hilog.info(0, 'TAG', "Succeeded in checking Result updateAvailable:" + checkResult.updateAvailable);
                      try {
                        updateManager.showUpdateDialog(context)
                          .then((resultCode: updateManager.ShowUpdateResultCode) => {
                            hilog.info(0, 'TAG', "Succeeded in showing UpdateDialog resultCode:" + resultCode);
                          })
                          .catch((error: BusinessError) => {
                            hilog.error(0, 'TAG', `showUpdateDialog onError.code is ${error.code}, message is ${error.message}`);
                          });
                      } catch (error) {
                        hilog.error(0, 'TAG', `showUpdateDialog onError.code is ${error.code}, message is ${error.message}`);
                      }
                    }).catch((error: BusinessError) => {
                    hilog.error(0, 'TAG', `checkAppUpdate onError.code is ${error.code}, message is ${error.message}`);
                  });
                } catch (error) {
                  hilog.error(0, 'TAG', `checkAppUpdate onError.code is ${error.code}, message is ${error.message}`);
                }
                promptAction.showToast({ message: '我没分批，让你点到爽 (ᗜ ˰ ᗜ)' });
              })

            Column() {
              Image($r('app.media.CIcon'))
                .width(60)
                .height(60)
              /*Text(versionSegsr)
                .fontWeight(700)
                .fontSize('16fp')
                .margin({ top: 10 })*/
              Text(banbenhao)
                .fontWeight(600)
                .fontSize('20fp')
                .margin({ top: 10 })
                .opacity(0.7)
                .fontColor($r('app.color.version_color_182431'))
            }
            .alignItems(HorizontalAlign.Center)

          }
          .width('100%')
          .height(300)

          Column() {
            Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text });
                  }
                  .width('100%')
                },
                  (item: FirstMenu) => item.id.toString());
              }
              .divider({
                strokeWidth: $r('app.float.stroke_width'),
                color: $r('app.color.font_color_00000'),
                startMargin: $r('app.integer.layout_size_24'),
                endMargin: $r('app.integer.layout_size_24')
              });
            }
            .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
            .width('90%')
            .borderRadius($r('app.integer.layout_size_24'))
            .alignItems(VerticalAlign.Center)
            .margin({
              top: $r('app.integer.layout_size_12'), // 增加顶部间距
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.info'));

            /*Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text });
                  }
                  .width('100%')
                },
                  (item: FirstMenu) => item.id.toString());
              }
              .divider({
                strokeWidth: $r('app.float.stroke_width'),
                color: $r('app.color.font_color_00000'),
                startMargin: $r('app.integer.layout_size_12'),
                endMargin: $r('app.integer.layout_size_24')
              });
            }
            .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
            .width('90%')
            .borderRadius($r('app.integer.layout_size_24'))
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: $r('app.integer.layout_size_12') })
            .backgroundColor($r('app.color.font_color_FFFFFF'));*/
          }
          .width('100%')
          .layoutWeight(1);

          Column() {
            Text($r('app.string.appname'))
              .fontSize(12);
            Text(baoming)
              .fontSize(12);
            /*Text($r('app.string.copyright'))
              .fontSize(12);*/
          }
          .width('100%')
          .height(60)
          .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      //.backgroundColor($r('app.color.start_window_background'))
      .padding({ top: 10 }) // 为标题栏留出空间
    }
    .scrollable(ScrollDirection.Vertical)
    .height('100%')
  }
}


@Component
  //设置条目布局
export struct SettingItemView {
  private text: string | Resource = ''; // 设置名称
  private des: string | Resource = ''; //后面的文本

  build() {
    Row() {
      Row() {
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyOS Sans')
          .fontColor($r('app.color.font_color_info'))
          .margin({ left: $r('app.integer.layout_size_5') })
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .lineHeight($r('app.integer.layout_size_22'));
        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_info'))
          .margin({ right: $r('app.integer.layout_size_12') })
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