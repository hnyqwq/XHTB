import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

import { deviceInfo } from '@kit.BasicServicesKit';

import userAuth from '@ohos.userIAM.userAuth';
import { promptAction } from '@kit.ArkUI';

const TAG = 'User_Auth';

let deviceTypeInfo: string = deviceInfo.deviceType;
// 输出结果：the value of the deviceType is :wearable
console.info('the value of the deviceType is :' + deviceTypeInfo);

let manufactureInfo: string = deviceInfo.manufacture;
// 输出结果：the value of the manufacture is :HUAWEI
console.info('the value of the manufactureInfo is :' + manufactureInfo);

let brandInfo: string = deviceInfo.brand;
// 输出结果：the value of the brand is :HUAWEI
console.info('the value of the device brand is :' + brandInfo);

let marketNameInfo: string = deviceInfo.marketName;
// 输出结果：the value of the marketName is :Mate XX
console.info('the value of the deviceInfo marketName is :' + marketNameInfo);

let productSeriesInfo: string = deviceInfo.productSeries;
// 输出结果：the value of the productSeries is :TAS
console.info('the value of the deviceInfo productSeries is :' + productSeriesInfo);

let productModelInfo: string = deviceInfo.productModel;
// 输出结果：the value of the productModel is :TAS-AL00
console.info('the value of the deviceInfo productModel is :' + productModelInfo);

let productModelAliasInfo: string = deviceInfo.productModelAlias;
console.info('the value of the deviceInfo productModelAlias is :' + productModelAliasInfo);

let softwareModelInfo: string = deviceInfo.softwareModel;
// 输出结果：the value of the softwareModel is :TAS-AL00
console.info('the value of the deviceInfo softwareModel is :' + softwareModelInfo);

let hardwareModelInfo: string = deviceInfo.hardwareModel;
// 输出结果：the value of the hardwareModel is :TASA00CVN1
console.info('the value of the deviceInfo hardwareModel is :' + hardwareModelInfo);

//let serialInfo: string = deviceInfo.serial;
// 输出结果：the value of the serial is :序列号随设备差异
//console.info('the value of the deviceInfo serial is :' + serialInfo);

let bootloaderVersionInfo: string = deviceInfo.bootloaderVersion;
// 输出结果：the value of the bootloaderVersion is :bootloader
console.info('the value of the deviceInfo bootloaderVersion is :' + bootloaderVersionInfo);

let abiListInfo: string = deviceInfo.abiList;
// 输出结果：the value of the abiList is :arm64-v8a
console.info('the value of the deviceInfo abiList is :' + abiListInfo);

let securityPatchTagInfo: string = deviceInfo.securityPatchTag;
// 输出结果：the value of the securityPatchTag is :2021/01/01
console.info('the value of the deviceInfo securityPatchTag is :' + securityPatchTagInfo);

let displayVersionInfo: string = deviceInfo.displayVersion;
// 输出结果：the value of the displayVersion is :XXX X.X.X.X
console.info('the value of the deviceInfo displayVersion is :' + displayVersionInfo);

let incrementalVersionInfo: string = deviceInfo.incrementalVersion;
// 输出结果：the value of the incrementalVersion is :default
console.info('the value of the deviceInfo incrementalVersion is :' + incrementalVersionInfo);

let osReleaseTypeInfo: string = deviceInfo.osReleaseType;
// 输出结果：the value of the osReleaseType is :Release
console.info('the value of the deviceInfo osReleaseType is :' + osReleaseTypeInfo);

let osFullNameInfo: string = deviceInfo.osFullName;
// 输出结果：the value of the osFullName is :OpenHarmony-5.0.0.1
console.info('the value of the deviceInfo osFullName is :' + osFullNameInfo);

let majorVersionInfo: number = deviceInfo.majorVersion;
// 输出结果：the value of the majorVersion is :5
console.info('the value of the deviceInfo majorVersion is :' + majorVersionInfo);

let seniorVersionInfo: number = deviceInfo.seniorVersion;
// 输出结果：the value of the seniorVersion is :0
console.info('the value of the deviceInfo seniorVersion is :' + seniorVersionInfo);

let featureVersionInfo: number = deviceInfo.featureVersion;
// 输出结果：the value of the featureVersion is :0
console.info('the value of the deviceInfo featureVersion is :' + featureVersionInfo);

let buildVersionInfo: number = deviceInfo.buildVersion;
// 输出结果：the value of the buildVersion is :1
console.info('the value of the deviceInfo buildVersion is :' + buildVersionInfo);

let sdkApiVersionInfo: number = deviceInfo.sdkApiVersion;
// 输出结果：the value of the sdkApiVersion is :12
console.info('the value of the deviceInfo sdkApiVersion is :' + sdkApiVersionInfo);

let firstApiVersionInfo: number = deviceInfo.firstApiVersion;
// 输出结果：the value of the firstApiVersion is :3
console.info('the value of the deviceInfo firstApiVersion is :' + firstApiVersionInfo);

let versionIdInfo: string = deviceInfo.versionId;
// 输出结果：the value of the versionId is :wearable/HUAWEI/HUAWEI/TAS/OpenHarmony-5.0.0.1/TAS-AL00/TAS-AL00/12/default/release:nolog
console.info('the value of the deviceInfo versionId is :' + versionIdInfo);

let buildTypeInfo: string = deviceInfo.buildType;
// 输出结果：the value of the buildType is :default
console.info('the value of the deviceInfo buildType is :' + buildTypeInfo);

let buildUserInfo: string = deviceInfo.buildUser;
// 输出结果：the value of the buildUser is :default
console.info('the value of the deviceInfo buildUser is :' + buildUserInfo);

let buildHostInfo: string = deviceInfo.buildHost;
// 输出结果：the value of the buildHost is :default
console.info('the value of the deviceInfo buildHost is :' + buildHostInfo);

let buildTimeInfo: string = deviceInfo.buildTime;
// 输出结果：the value of the buildTime is :default
console.info('the value of the deviceInfo buildTime is :' + buildTimeInfo);

let buildRootHashInfo: string = deviceInfo.buildRootHash;
// 输出结果：the value of the buildRootHash is :default
console.info('the value of the deviceInfo buildRootHash is :' + buildRootHashInfo);

let udid: string = deviceInfo.udid;
// 输出结果：the value of the udid is :9D6AABD147XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXE5536412
console.info('the value of the deviceInfo udid is :' + udid);

let distributionOSName: string = deviceInfo.distributionOSName
// 输出结果：the value of the distributionOSName is :OpenHarmony
console.info('the value of the deviceInfo distributionOSName is :' + distributionOSName);

let distributionOSVersion: string = deviceInfo.distributionOSVersion
// 输出结果：the value of the distributionOSVersion is :5.0.0
console.info('the value of the deviceInfo distributionOSVersion is :' + distributionOSVersion);

let distributionOSApiVersion: number = deviceInfo.distributionOSApiVersion
// 输出结果：the value of the distributionOSApiVersion is :500001
console.info('the value of the deviceInfo distributionOSApiVersion is :' + distributionOSApiVersion);

let distributionOSApiName: string = deviceInfo.distributionOSApiName
console.info('the value of the deviceInfo distributionOSApiName is :' + distributionOSApiName);

let distributionOSReleaseType: string = deviceInfo.distributionOSReleaseType
// 输出结果：the value of the distributionOSReleaseType is :Release
console.info('the value of the deviceInfo distributionOSReleaseType is :' + distributionOSReleaseType);

let odid: string = deviceInfo.ODID;
// 输出结果：the value of the ODID is :1234a567-XXXX-XXXX-XXXX-XXXXXXXXXXXX
console.info('the value of the deviceInfo odid is :' + odid);

let diskSN: string = deviceInfo.diskSN;
// 输出结果：the value of the deviceInfo diskSN is :2502EM400567
console.info('the value of the deviceInfo diskSN is :' + diskSN);

let performanceClass = deviceInfo.performanceClass;
// 输出结果：the value of the deviceInfo performanceClass is :0
console.info('the value of the deviceInfo performanceClass is :' + performanceClass);

@Observed
  //设置条目信息构造
class FirstMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: string; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: string, text: string, des: Resource) {
    this.id = id;
    this.title = title;
    this.text = text;
    this.des = des;
  }
}

@Observed
  //设置条目信息构造
class SecondMenu {
  public uri?: string;
  public id: string; // 唯一id
  public title: string; // 标题文本
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, title: string, text: string, des: Resource) {
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
    new FirstMenu('one', '型号名称', marketNameInfo, $r('app.string.void')),
    new FirstMenu('two', '型号代码', productModelInfo, $r('app.string.void')),
    new FirstMenu('three', 'HarmonyOS 版本', distributionOSVersion, $r('app.string.void')),
    new FirstMenu('four', '', displayVersionInfo, $r('app.string.void')),
  //new FirstMenu('five', '序列号', '前往个人博客', $r('app.string.void'))
  ];
  @State SecondMenuGroup: SecondMenu[] = [
    new SecondMenu('one', '型号名称', marketNameInfo, $r('app.string.void')),
    new SecondMenu('two', '型号代码', productModelInfo, $r('app.string.void')),
    new SecondMenu('three', 'HarmonyOS 版本', distributionOSVersion, $r('app.string.void')),
    new SecondMenu('four', '', displayVersionInfo, $r('app.string.void')),
  //new SecondMenu('five', '序列号', '前往个人博客', $r('app.string.void'))
  ];
  @State message: string = '用户认证'
  @State userAuthResult?: userAuth.UserAuthResult = undefined

  build() {
    Scroll() {
      Column() {
        Navigation() {
          Stack() {
            Row() {
              Image($r('app.media.harmonyos'))
                .width('1100px')
                .height('1500px')
                .margin({ bottom: '3%' }) // 图片下方留白
            }
            .clip(true) // 如这里不设置clip为true，则Row组件的圆角不会限制其中的Image组件，Image组件的四个角会超出Row
            .borderRadius(20)
            Button('检查更新')
            //.type(ButtonType.Capsule)
              .width('50%')
              .height(40)
              .margin({ top: 220 })
              .onClick(() => {
                promptAction.showToast({ message: '切，让你点到爽 (ᗜ ˰ ᗜ)' });
              })

            Column() {
              Image($r('app.media.CIcon'))
                .width(60)
                .height(60)
              Text('hvideo')
                .fontWeight(700)
                .fontSize('14fp')
                .margin({ top: 10 })
              Text('1.3.1.0（10301000）')
                .fontWeight(600)
                .fontSize('12fp')
                .margin({ top: 10 })
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
            .backgroundColor($r('app.color.font_color_FFFFFF'));

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
            /*Text() {
              Span('hvideo用户协议')
                .onClick(() => {
                  const want: Want = { uri: `https://hnyqwq.cn/hvideo/yhxy.html` };
                  const context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want).then(() => { //拉起成功
                    console.info('拉起应用商店成功')
                  }).catch((e: BusinessError) => { // 拉起失败
                    console.info('拉起应用商店失败')
                  });
                })
                .fontColor(Color.Blue)
                .fontSize(12);
              Span('和')
                .fontSize(12);
              Span('hvideo与隐私的声明')
                .onClick(() => {
                  const want: Want = { uri: `https://www.hnyqwq.cn/hvideo/hvideo.html` };
                  const context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want).then(() => { //拉起成功
                    console.info('拉起应用商店成功')
                  }).catch((e: BusinessError) => { // 拉起失败
                    console.info('拉起应用商店失败')
                  });
                })
                .fontColor(Color.Blue)
                .fontSize(12);
            };*/

            Text($r('app.string.copyright'))
              .fontSize(12);
            /*Text() {
              Span($r('app.string.exunder'))
                .onClick(() => {
                  //const want: Want = { uri: `store://appgallery.huawei.com/app/detail?id=com.chuckfang.meow` };
                  const want: Want =
                    { uri: `https://www.chuckfang.com/MeoW/appLinking?channelId=9687404a1b84433184ba27f16a57da3e` };
                  const context = getContext(this) as common.UIAbilityContext;
                  context.startAbility(want).then(() => { //拉起成功
                    console.info('跳转成功')
                  }).catch((e: BusinessError) => { // 拉起失败
                    console.info('跳转失败')
                  });
                })
                .fontColor(Color.Blue)
                .fontSize(12);
            }
            .layoutWeight(1)*/
          }
          .width('100%')
          .height(60);
        }
        .height('100%')
        .title($r('app.string.infopagetitle'))
        .titleMode(NavigationTitleMode.Mini)
        //.backgroundColor($r('app.color.listColor'))
        .backgroundColor($r('app.color.start_window_background'))
        .padding({ top: 50 })
      }
    }
    .scrollable(ScrollDirection.Vertical) // 设置垂直滚动方向
    .height('100%') // 必须设置高度为100%以撑满父容器
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
          .fontColor($r('app.color.font_color_182431'))
          .margin({ left: $r('app.integer.layout_size_5') })
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .lineHeight($r('app.integer.layout_size_22'));
        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_182431'))
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