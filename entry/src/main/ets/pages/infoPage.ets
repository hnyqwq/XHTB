import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationManager } from '../common/NavigationManager';
import dataPreferences from '@ohos.data.preferences';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';
import { bundleManager } from '@kit.AbilityKit';

import { deviceInfo } from '@kit.BasicServicesKit';

import { promptAction } from '@kit.ArkUI';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

// 定义材质相关的接口
interface IMaterialLevel {
  EXQUISITE: number;
  GENTLE: number;
  SMOOTH: number;
  ADAPTIVE: number;
}

interface IMaterialType {
  NONE: number;
  ADAPTIVE: number;
  IMMERSIVE: number;
}

// 定义材质相关的常量
const MaterialLevel: IMaterialLevel = {
  EXQUISITE: 0,
  GENTLE: 1,
  SMOOTH: 2,
  ADAPTIVE: 3
};

const MaterialType: IMaterialType = {
  NONE: 0,
  ADAPTIVE: 1,
  IMMERSIVE: 2
};

// 定义hdsMaterial接口
interface IHdsMaterialModule {
  MaterialLevel: IMaterialLevel;
  MaterialType: IMaterialType;
  getSystemMaterialTypes: () => Array<number>;
}

// 辅助函数：安全获取hdsMaterial模块
function getHdsMaterialModule(): IHdsMaterialModule | null {
  try {
    const gThis: ESObject = globalThis;
    const hdsMat: ESObject | null | undefined = gThis['hdsMaterial'] as ESObject | null | undefined;
    if (hdsMat) {
      return hdsMat as IHdsMaterialModule;
    }
  } catch (err) {
    console.warn('infoPage: hdsMaterial not available:', err);
  }
  return null;
}

// 获取应用信息
let bundleName = '';
let versionCode = 0;
let versionName = '';
try {
  const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  bundleName = bundleInfo.name;
  versionCode = bundleInfo.versionCode;
  versionName = bundleInfo.versionName;
} catch (err) {
  const error = err as BusinessError;
  console.error(`Failed to get bundle info. Code: ${error.code}, message: ${error.message}`);
  // 提供默认值
  bundleName = 'com.example.app';
  versionCode = 1;
  versionName = '1.0.0';
}

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

let distributionOSApiName: string = deviceInfo.distributionOSApiName
console.info('the value of the deviceInfo distributionOSApiName is :' + distributionOSApiName);

let performanceClass = deviceInfo.performanceClass;
// 输出结果：the value of the deviceInfo performanceClass is :0
console.info('the value of the deviceInfo performanceClass is :' + performanceClass);

let chipType: string = deviceInfo.chipType;
// 输出结果：the value of the deviceInfo chipType is :kirin9000s
console.info('the value of the deviceInfo chipType is :' + chipType);

let sdkApiVersion: number = deviceInfo.sdkApiVersion;
// 输出结果：the value of the deviceInfo sdkApiVersion is :12
console.info('the value of the deviceInfo sdkApiVersion is :' + sdkApiVersion);

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
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  @State isImmersiveTab: boolean = false; // 沉浸式Tab栏样式状态（包含底部Tab栏和顶部材质效果）
  @State showNewYearCard: boolean = false; // 春节卡片开关状态，默认关闭
  @State supportedMaterialTypes: string = ''; // 支持的材质类型
  @State supportedMaterialLevel: string = ''; // 支持的材质等级
  @State allMaterialTypes: string = ''; // 所有材质类型枚举
  @State allMaterialLevels: string = ''; // 所有材质等级枚举
  @State isHdsMaterialAvailable: boolean = true; // 标记hdsMaterial是否可用
  private preferences: dataPreferences.Preferences | null = null;
  private scroller: Scroller = new Scroller();
  //设置条目信息数组
  @State FirstMenuGroup: FirstMenu[] = [
    new FirstMenu('one', $r('app.string.info1'), marketNameInfo, $r('app.string.void')),
    new FirstMenu('two', $r('app.string.info2'), productModelInfo, $r('app.string.void')),
    new FirstMenu('three',$r('app.string.info3'),distributionOSVersion, $r('app.string.void')),
    new FirstMenu('four',$r('app.string.info4'),fullVersionsr, $r('app.string.void'))
  ];

  // 系统能力信息数组
  @State SystemCapabilityMenuGroup: FirstMenu[] = [
    new FirstMenu('six',$r('app.string.info5') ,versionSegsr, $r('app.string.void')),
    new FirstMenu('api_name', $r('app.string.api_name'), distributionOSApiName, $r('app.string.void')),
    new FirstMenu('api_version', $r('app.string.api_version'), sdkApiVersion.toString(), $r('app.string.void')),
    new FirstMenu('cpu_model', $r('app.string.info6'), chipType, $r('app.string.void')),
    new FirstMenu('performance_level', $r('app.string.performance_level'), this.getPerformanceLevelText(), $r('app.string.void'))
  ];

  // 获取设备能力定级文本
  private getPerformanceLevelText(): string {
    switch (deviceInfo.performanceClass) {
      case 0:
        return 'CLASS_LEVEL_HIGH';
      case 1:
        return 'CLASS_LEVEL_MEDIUM';
      case 2:
        return 'CLASS_LEVEL_LOW';
      default:
        return 'UNKNOWN';
    }
  }

  aboutToAppear(): void {
    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'pages/infoPage');
    AppStorage.delete('currentRouteParams');

    // 设置所有材质类型枚举说明
    this.allMaterialTypes = 'NONE(无材质效果) | ADAPTIVE(自适应系统材质) | IMMERSIVE(沉浸式材质)';

    // 设置所有材质等级枚举说明
    this.allMaterialLevels = 'EXQUISITE(精美) | GENTLE(轻柔) | SMOOTH(流畅) | ADAPTIVE(系统自适应)';

    // 检查API版本，只有API >= 23才支持新材质
    const isApi23OrHigher = deviceInfo.sdkApiVersion >= 23;
    console.info('infoPage: API版本:', deviceInfo.sdkApiVersion, '是否支持新材质:', isApi23OrHigher);

    // 仅在高版本API下检查材质能力
    if (isApi23OrHigher) {
      try {
        // 动态获取hdsMaterial模块
        const hdsMaterial = getHdsMaterialModule();
        if (hdsMaterial) {
          let materialTypes: Array<number> = hdsMaterial.getSystemMaterialTypes();
          console.info(`infoPage: getSystemMaterialTypes successed, types: ${JSON.stringify(materialTypes)}, length: ${materialTypes.length}`);

          // 格式化材质类型显示
          if (materialTypes.length === 0) {
            // 返回空数组，说明设备不支持任何材质类型
            this.supportedMaterialTypes = '无（系统返回空数组 什么bug我在查...）';
            this.supportedMaterialLevel = '-';
            console.info('infoPage: 设备不支持任何材质类型');
          } else {
            const types = materialTypes.map(type => {
              switch (type) {
                case MaterialType.NONE:
                  return 'NONE';
                case MaterialType.ADAPTIVE:
                  return 'ADAPTIVE';
                case MaterialType.IMMERSIVE:
                  return 'IMMERSIVE';
                default:
                  return `UNKNOWN(${type})`;
              }
            });
            this.supportedMaterialTypes = types.join(', ');

            // 根据支持的材质类型推荐材质等级
            if (materialTypes.includes(MaterialType.IMMERSIVE)) {
              this.supportedMaterialLevel = 'EXQUISITE, GENTLE, SMOOTH';
            } else if (materialTypes.includes(MaterialType.ADAPTIVE)) {
              this.supportedMaterialLevel = 'SMOOTH';
            } else {
              this.supportedMaterialLevel = '-';
            }
          }
        } else {
          console.info('infoPage: hdsMaterial不可用');
        }
      } catch (err) {
        let message = (err as BusinessError).message;
        let code = (err as BusinessError).code;
        console.error(`infoPage: getSystemMaterialTypes failed, code: ${code}, message: ${message}`);
        // hdsMaterial模块不可用时，禁用沉浸式Tab栏
        this.isHdsMaterialAvailable = false;
        this.isImmersiveTab = false;
        this.supportedMaterialTypes = '获取失败';
        this.supportedMaterialLevel = '-';
      }
    } else {
      console.info('infoPage: API版本低于23，跳过材质能力查询');
    }

    // 加载沉浸式tab栏设置
    this.loadImmersiveTabSetting();
    // 加载春节卡片设置
    this.loadNewYearCardSetting();
  }

  async loadImmersiveTabSetting() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.preferences = await dataPreferences.getPreferences(context, 'app_settings');

      // 检查是否已经设置过
      const hasKey = await this.preferences.has('isImmersiveTab');

      // 读取保存的值
      let savedValue = false;
      if (hasKey) {
        savedValue = await this.preferences.get('isImmersiveTab', false) as boolean;
      }

      // 检查API版本，只有API >= 23才支持新材质
      const isApi23OrHigher = deviceInfo.sdkApiVersion >= 23;

      // 如果API版本低于23，强制设置为false（传统模式）
      if (!isApi23OrHigher) {
        savedValue = false;
        console.info('infoPage: API版本低于23，强制使用传统式Tab栏');
      } else if (!hasKey) {
        // 首次运行，默认为false（传统模式）
        savedValue = false;
        await this.preferences.put('isImmersiveTab', false);
        await this.preferences.flush();
        console.info('infoPage: 首次运行，默认使用传统式Tab栏');
      }

      // 读取保存的值
      this.isImmersiveTab = savedValue;
      // 同步到AppStorage，供Home页面使用
      AppStorage.setOrCreate('isImmersiveTab', this.isImmersiveTab);
    } catch (err) {
      console.error('Failed to load loadImmersiveTabSetting setting:', err);
    }
  }

  async loadNewYearCardSetting() {
    try {
      if (!this.preferences) {
        const context = getContext(this) as common.UIAbilityContext;
        this.preferences = await dataPreferences.getPreferences(context, 'app_settings');
      }

      // 检查是否已经设置过,如果没有则设置默认值为false
      const hasKey = await this.preferences.has('showNewYearCard');
      if (!hasKey) {
        await this.preferences.put('showNewYearCard', false);
        await this.preferences.flush();
      }

      // 读取保存的值
      this.showNewYearCard = await this.preferences.get('showNewYearCard', false) as boolean;
      // 同步到AppStorage，供Home页面使用
      AppStorage.setOrCreate('showNewYearCard', this.showNewYearCard);
    } catch (err) {
      console.error('Failed to load new year card setting:', err);
    }
  }

  async saveImmersiveTabSetting(value: boolean) {
    try {
      if (this.preferences) {
        await this.preferences.put('isImmersiveTab', value);
        await this.preferences.flush();
        this.isImmersiveTab = value;
        // 同步到AppStorage，供Home页面使用
        AppStorage.setOrCreate('isImmersiveTab', value);
      }
    } catch (err) {
      console.error('Failed to save immersive tab setting:', err);
    }
  }

  async saveNewYearCardSetting(value: boolean) {
    try {
      if (this.preferences) {
        await this.preferences.put('showNewYearCard', value);
        await this.preferences.flush();
        this.showNewYearCard = value;
        // 同步到AppStorage，供Home页面使用
        AppStorage.setOrCreate('showNewYearCard', value);
        console.info('Saved new year card setting:', value);
      }
    } catch (err) {
      console.error('Failed to save new year card setting:', err);
    }
  }

  getTabStyleDescription(): string {
    return this.isImmersiveTab ? '沉浸式（悬浮+材质）' : '传统式（分离效果）';
  }

  getNewYearCardDescription(): string {
    return this.showNewYearCard ? '显示' : '隐藏';
  }

  build() {
    Column() {
      // 检查API版本，只有API >= 23才支持新材质
      if (this.isImmersiveTab && this.isHdsMaterialAvailable && deviceInfo.sdkApiVersion >= 23) {
        // 沉浸式模式：使用高版本 Material Design 3 API
        this.immersiveNavigation()
      } else {
        // 传统模式：不使用高版本 API
        this.traditionalNavigation()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  @Builder
  immersiveNavigation() {
    HdsNavigation() {
      Scroll(this.scroller) {
        this.pageContent()
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .titleBar({
      content: {
        title: {
          mainTitle: $r('app.string.infopagetitle'),
        },
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
          },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('sys.color.font_primary') },
            menuStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') },
            backIconStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
          },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('sys.color.font_primary') },
            menuStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') },
            backIconStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') }
          }
        },
        systemMaterialEffect: {
          materialLevel : MaterialLevel.EXQUISITE,
          materialType : MaterialType.IMMERSIVE
        }
      },
      enableHoverMode: true,
      avoidLayoutSafeArea: true,
    })
    .bindToScrollable([this.scroller])
    .hideBackButton(false)
    .titleMode(HdsNavigationTitleMode.MINI)
    .mode(NavigationMode.Stack)
  }

  @Builder
  traditionalNavigation() {
    HdsNavigation() {
      Scroll(this.scroller) {
        this.pageContent()
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .titleBar({
      content: {
        title: {
          mainTitle: $r('app.string.infopagetitle'),
        },
      },
      style: {
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background'),
          },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('sys.color.font_primary') },
            menuStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') },
            backIconStyle: { backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary') }
          }
        }
      },
      enableHoverMode: true,
      avoidLayoutSafeArea: true,
    })
    .bindToScrollable([this.scroller])
    .hideBackButton(false)
    .titleMode(HdsNavigationTitleMode.MINI)
    .mode(NavigationMode.Stack)
  }

  @Builder
  pageContent() {
      Column() {
          Blank().height(120).width('100%')
          Stack() {
            Row() {
              Image($r('app.media.harmonyos'))
                //.width('1100px')
                .height('1500px')
                .width('90%')
                .margin({ left: '5%', right: '5%' })
                .margin({ bottom: '3%' }) // 图片下方留白
                .draggable(false)
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
                .draggable(false)
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

          // 沉浸式Tab栏样式开关（包含底部Tab栏和顶部材质效果）
          Row() {
            Row() {
              Text('沉浸式界面样式')
                .fontSize($r('app.integer.layout_size_16'))
                .fontWeight(400)
                .fontFamily('HarmonyOS Sans')
                .fontColor($r('app.color.font_color_info'))
                .margin({ left: $r('app.integer.layout_size_5') })
                .layoutWeight(1)
                .lineHeight($r('app.integer.layout_size_22'));
              if (deviceInfo.sdkApiVersion >= 23) {
                Text(this.getTabStyleDescription())
                  .fontSize($r('app.integer.layout_size_14'))
                  .fontColor($r('app.float.opacity'))
                  .opacity(0.6)
                  .margin({ right: 8 });
                Toggle({ type: ToggleType.Switch, isOn: this.isImmersiveTab })
                  .selectedColor('#0A59F7')
                  .onChange((isOn: boolean) => {
                    this.saveImmersiveTabSetting(isOn);
                  })
              } else {
                Text($r('app.string.23_only_support'))
                  .fontSize(14)
                  .fontColor($r('sys.color.font_tertiary'))
                  .margin({ right: 8 })
              }
            }
            .width('100%')
            .height($r('app.integer.tabbar_height'))
            .padding({
              left: $r('app.integer.layout_size_22'),
              right: $r('app.integer.layout_size_12')
            })
            .alignItems(VerticalAlign.Center);
          }
          .width('90%')
          .height($r('app.integer.layout_size_48'))
          .alignSelf(ItemAlign.Center)
          .margin({
            top: $r('app.integer.layout_size_12'),
            bottom: $r('app.integer.layout_size_12')
          })
          .borderRadius($r('app.integer.layout_size_24'))
          .backgroundColor($r('app.color.info'));

          // 材质能力信息（仅当沉浸式Tab栏打开时显示）
          /*if (this.isImmersiveTab) {
            Column() {
              // 第一行：MaterialType 材质类型枚举
              Column() {
                Row() {
                  Text('MaterialType 材质类型枚举')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.font_color_info'))
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 6 })

                Text(this.allMaterialTypes)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_secondary'))
                  .opacity(0.8)
                  .width('100%')

                Divider()
                  .color($r('app.color.font_color_00000'))
                  .strokeWidth(1)
                  .margin({ top: 6, bottom: 6 })

                Row() {
                  Text('当前设备支持:')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.font_color_info'))
                    .margin({ right: 8 })
                  Text(this.supportedMaterialTypes)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_primary'))
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding({
                left: $r('app.integer.layout_size_22'),
                right: $r('app.integer.layout_size_12'),
                top: 8,
                bottom: 8
              })

              Divider()
                .color($r('app.color.font_color_00000'))
                .strokeWidth(1)
                .margin({ left: 0, right: 0 })

              // 第二行：MaterialLevel 材质等级枚举
              Column() {
                Row() {
                  Text('MaterialLevel 材质等级枚举')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.font_color_info'))
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 6 })

                Text(this.allMaterialLevels)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_secondary'))
                  .opacity(0.8)
                  .width('100%')

                Divider()
                  .color($r('app.color.font_color_00000'))
                  .strokeWidth(1)
                  .margin({ top: 6, bottom: 6 })

                Row() {
                  Text('当前设备支持:')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.font_color_info'))
                    .margin({ right: 8 })
                  Text(this.supportedMaterialLevel)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_primary'))
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding({
                left: $r('app.integer.layout_size_22'),
                right: $r('app.integer.layout_size_12'),
                top: 8,
                bottom: 8
              })
            }
            .width('90%')
            .alignSelf(ItemAlign.Center)
            .borderRadius($r('app.integer.layout_size_24'))
            .backgroundColor($r('app.color.info'))
            .margin({ bottom: $r('app.integer.layout_size_12') })
          }*/

          // 系统能力信息
          Column() {
            Row() {
              List() {
                ForEach(this.SystemCapabilityMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text })
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
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.info'));
          }

          Column() {
            Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text })
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
              bottom: $r('app.integer.layout_size_12')
            })
            .backgroundColor($r('app.color.info'));

            /*Row() {
              List() {
                ForEach(this.FirstMenuGroup, (item: FirstMenu) => {
                  ListItem() {
                    SettingItemView({ text: item.title, des: item.text })
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
          .width('100%');

          // 春节卡片开关
          Row() {
            Row() {
              Text($r('app.string.show_newyear_card'))
                .fontSize($r('app.integer.layout_size_16'))
                .fontWeight(400)
                .fontFamily('HarmonyOS Sans')
                .fontColor($r('app.color.font_color_info'))
                .margin({ left: $r('app.integer.layout_size_5') })
                .layoutWeight(1)
                .lineHeight($r('app.integer.layout_size_22'));
              Text(this.getNewYearCardDescription())
                .fontSize($r('app.integer.layout_size_14'))
                .fontColor($r('app.float.opacity'))
                .opacity(0.6)
                .margin({ right: 8 });
              Toggle({ type: ToggleType.Switch, isOn: this.showNewYearCard })
                .selectedColor('#0A59F7')
                .onChange((isOn: boolean) => {
                  this.saveNewYearCardSetting(isOn);
                })
            }
            .width('100%')
            .height($r('app.integer.tabbar_height'))
            .padding({
              left: $r('app.integer.layout_size_22'),
              right: $r('app.integer.layout_size_12')
            })
            .alignItems(VerticalAlign.Center);
          }
          .width('90%')
          .height($r('app.integer.layout_size_48'))
          .alignSelf(ItemAlign.Center)
          .margin({
            bottom: $r('app.integer.layout_size_12')
          })
          .borderRadius($r('app.integer.layout_size_24'))
          .backgroundColor($r('app.color.info'));

          Column() {
            Text($r('app.string.appname'))
              .fontSize(12);
            Text(baoming)
              .fontSize(12);
          }
          .width('100%')
          .height(60)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: $r('app.integer.layout_size_12') })
          .padding({ bottom: px2vp(this.bottomRectHeight) })
        }
        .width('100%')
        .padding({ bottom: 20 })
  }
}

@Component
//设置条目布局
struct SettingItemView {
  @Prop text: string | Resource = ''; // 设置名称
  @Prop des: string | Resource = ''; //后面的文本

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