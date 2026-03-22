import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';
import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import type { common } from '@kit.AbilityKit';
import { HdsTabs, HdsTabsController, HdsTabsAttribute } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { common as abilityCommon } from '@kit.AbilityKit';

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
    console.warn('Home: hdsMaterial not available:', err);
  }
  return null;
}

@Component
export struct Home {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @StorageLink('isImmersiveTab') isImmersiveTab: boolean = false; // 沉浸式Tab栏设置
  @StorageLink('currentTabIndex') firstLevelIndex: number = 0; // 从AppStorage读取当前Tab索引
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @State secondLevelIndex: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();
  @State customMaterialLevel: number = MaterialLevel.SMOOTH;
  private controller: HdsTabsController | null = null;  // 延迟实例化，避免低API设备闪退
  private preferences: preferences.Preferences | null = null;
  private shortcutNavigateCallback = (url: string) => {
    console.info('Home: 收到快捷方式导航事件, url=', url);
    router.pushUrl({ url: url }).catch((err: Error) => {
      console.error('Failed to navigate to shortcut page:', err);
    });
  };

  aboutToAppear(): void {
    // 订阅快捷方式导航事件
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      context.eventHub.on('shortcutNavigate', this.shortcutNavigateCallback);
    } catch (e) {
      console.error('Home: Failed to subscribe shortcutNavigate event:', e);
    }

    // 检查API版本，只有API >= 23才支持新材质
    const isApi23OrHigher = deviceInfo.sdkApiVersion >= 23;
    console.info('Home: API版本:', deviceInfo.sdkApiVersion, '是否支持新材质:', isApi23OrHigher);

    // 仅在高版本API下实例化HdsTabsController，避免低API设备闪退
    if (isApi23OrHigher) {
      try {
        this.controller = new HdsTabsController();
        // 动态获取hdsMaterial模块
        const hdsMaterial = getHdsMaterialModule();
        if (hdsMaterial) {
          let materialTypes: Array<number> = hdsMaterial.getSystemMaterialTypes();
          console.info('Home: 支持的材质类型:', JSON.stringify(materialTypes), ', length:', materialTypes.length);

          if (materialTypes.length === 0) {
            // 返回空数组，说明设备不支持任何材质类型，使用SMOOTH效果
            this.customMaterialLevel = MaterialLevel.SMOOTH;
            console.info('Home: 设备不支持任何材质类型，使用SMOOTH效果');
          } else if (materialTypes.indexOf(MaterialType.IMMERSIVE) < 0) {
            // 当前设备不支持IMMERSIVE材质类型，则使用SMOOTH效果，以降低卡顿和发热风险
            this.customMaterialLevel = MaterialLevel.SMOOTH;
            console.info('Home: 设备不支持IMMERSIVE材质，使用SMOOTH效果');
          } else {
            // 当前设备支持IMMERSIVE材质类型，使用EXQUISITE效果
            this.customMaterialLevel = MaterialLevel.EXQUISITE;
            console.info('Home: 设备支持IMMERSIVE材质，使用EXQUISITE效果');
          }
        } else {
          console.info('Home: hdsMaterial不可用，使用默认材质');
        }
      } catch (err) {
        console.error('Home: Failed to get system material types:', err);
        // 出错时使用默认值
        this.customMaterialLevel = MaterialLevel.SMOOTH;
      }
    } else {
      console.info('Home: API版本低于23，跳过材质能力查询，使用默认材质');
    }

    // 从Preferences加载沉浸式Tab栏设置
    this.loadImmersiveTabSetting();

    // 初始化当前Tab索引为0(首页),不保存上次的位置
    AppStorage.setOrCreate('currentTabIndex', 0);

    // 如果设置了初始 Tab 索引,则使用该索引
    const initialTabIndex = AppStorage.get<number>('initialTabIndex');
    if (initialTabIndex !== undefined && initialTabIndex !== null) {
      AppStorage.setOrCreate('currentTabIndex', initialTabIndex);
      // 清除标记,避免影响后续导航
      AppStorage.delete('initialTabIndex');
    }

    // 检查是否有快捷方式需要跳转
    const shortCutPage = AppStorage.get<string>('ShortCutPage');
    if (shortCutPage !== undefined && shortCutPage !== null && shortCutPage !== '') {
      console.info('Home: 准备跳转到快捷方式页面, url=', shortCutPage);
      // 延迟执行跳转,确保 Home 组件已经渲染
      setTimeout(() => {
        console.info('Home: 开始跳转到快捷方式页面', shortCutPage);
        router.pushUrl({
          url: shortCutPage
        }).catch((err: Error) => {
          console.error('Failed to navigate to shortcut page:', err);
        });
        // 清除快捷方式标记
        AppStorage.delete('ShortCutPage');
      }, 100);
    }

    // 检查是否有接续的页面需要跳转
    const continuationPageUrl = AppStorage.get<string>('continuationPageUrl');
    if (continuationPageUrl !== undefined && continuationPageUrl !== null && continuationPageUrl !== '') {
      const continuationRouteParams = AppStorage.get<string>('continuationRouteParams');
      let params = undefined;
      if (continuationRouteParams) {
        try {
          params = JSON.parse(continuationRouteParams);
        } catch (e) {
          console.error('Failed to parse continuation route params:', e);
        }
      }

      console.info('Home: 准备跳转到接续页面, url=', continuationPageUrl);

      // 标记这是接续场景
      AppStorage.setOrCreate('isContinuation', true);
      console.info('Home: 设置 isContinuation = true');

      // 接续场景下,清除分栏模式标记,确保返回按钮显示
      AppStorage.delete('SecondPageSplitMode');
      console.info('Home: 清除 SecondPageSplitMode');

      // 延迟执行跳转,确保 Home 组件已经渲染
      setTimeout(() => {
        console.info('Home: 开始跳转到', continuationPageUrl);
        router.pushUrl({
          url: continuationPageUrl,
          params: params
        }).catch((err: Error) => {
          console.error('Failed to navigate to continuation page:', err);
        });
        // 清除接续标记
        AppStorage.delete('continuationPageUrl');
        AppStorage.delete('continuationRouteParams');
      }, 100);
    }
  }

  aboutToDisappear(): void {
    // 取消订阅快捷方式导航事件
    try {
      const context = getContext(this) as abilityCommon.UIAbilityContext;
      context.eventHub.off('shortcutNavigate', this.shortcutNavigateCallback);
    } catch (e) {
      console.error('Home: Failed to unsubscribe shortcutNavigate event:', e);
    }
  }

  async loadImmersiveTabSetting() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.preferences = await preferences.getPreferences(context, 'app_settings');

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
        console.info('Home: API版本低于23，强制使用传统式Tab栏');
      } else if (!hasKey) {
        // 首次运行，默认为false（传统模式）
        savedValue = false;
        await this.preferences.put('isImmersiveTab', false);
        await this.preferences.flush();
        console.info('Home: 首次运行，默认使用传统式Tab栏');
      }

      // 同步到AppStorage
      AppStorage.setOrCreate('isImmersiveTab', savedValue);
    } catch (err) {
      console.error('Failed to load immersive tab setting:', err);
      // 出错时使用默认值false（传统模式）
      AppStorage.setOrCreate('isImmersiveTab', false);
    }
  }

  // Tab 索引持久化相关方法(已禁用)
  /*
  async loadCurrentTabIndex() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      if (!this.preferences) {
        this.preferences = await preferences.getPreferences(context, 'app_settings');
      }

      // 读取保存的Tab索引
      if (this.preferences) {
        const savedIndex = await this.preferences.get('currentTabIndex', 0) as number;
        // 同步到AppStorage
        AppStorage.setOrCreate('currentTabIndex', savedIndex);
      }
    } catch (err) {
      console.error('Failed to load current tab index:', err);
      // 出错时使用默认值
      AppStorage.setOrCreate('currentTabIndex', 0);
    }
  }

  async saveCurrentTabIndex(index: number) {
    try {
      if (this.preferences) {
        await this.preferences.put('currentTabIndex', index);
        await this.preferences.flush();
      }
    } catch (err) {
      console.error('Failed to save current tab index:', err);
    }
  }
  */

  getTabSymbol(index: number): Resource {
    switch (index) {
      case 0:
        return $r('sys.symbol.share');
      case 1:
        return $r('sys.symbol.square_grid_2x2');
      case 2:
        return $r('sys.symbol.person');
      default:
        return $r('sys.symbol.house');
    }
  }

  @Builder
  tabBuilder(name: string, index: number) {
    Column() {
      SymbolGlyph(this.getTabSymbol(index))
        .fontSize(24)
        .fontColor([index === this.firstLevelIndex ? $r('sys.color.brand') : $r('sys.color.icon_secondary')])
      Text(name)
        .fontSize(10)
        .fontWeight(500)
        .fontColor(index === this.firstLevelIndex ? '#0A59F7' : '#999999')
        .margin({ top: 4 })
    }
    .padding({
      bottom: (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') && !this.isImmersiveTab ? 24 : 0,
      left: (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') && !this.isImmersiveTab ? 0 : 0,
      right: (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') && !this.isImmersiveTab ? 0 : 0
    })
    .height(
      (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') && !this.isImmersiveTab ? 100 : '100%'
    )
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    // [Start diff_device_container]
    // entry/src/main/ets/view/Home.ets
    // 根据沉浸式Tab栏开关决定布局样式，同时检查API版本
    // 只有API >= 23才支持沉浸式Tab栏
    if (this.isImmersiveTab && deviceInfo.sdkApiVersion >= 23) {
      // 沉浸式Tab栏样式（悬浮+材质效果）
      if (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') {
        // 平板模式：沉浸式底部Tab栏
        HdsTabs({ controller: this.controller!, index: this.firstLevelIndex }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

          TabContent() {
            SecondPage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

          TabContent() {
            MinePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
        }
        // [StartExclude tab_to_page]
        // 设置barOverlap为true，vertical为false，barPosition为BarPosition.End，可实现页签栏的悬浮样式
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .vertical(false)
        // 设置页签栏悬浮样式
        .barFloatingStyle({
          barBottomMargin: 28,
          gradientMask: { maskColor: '#66F1F3F5', maskHeight: 92 },
          systemMaterialEffect: {
            materialType: MaterialType.ADAPTIVE,
            materialLevel: this.customMaterialLevel
          }
        })
        // [EndExclude tab_to_page]
        .onChange((index: number) => {
          this.firstLevelIndex = index;
          // 保存当前 Tab 索引到 AppStorage,供接续功能使用
          AppStorage.setOrCreate('currentTabIndex', index);
        })
        // [End tab_to_page]
        .scrollable(false)
        .height('100%')
        .width('100%')
      } else {
        // 手机模式：沉浸式底部Tab栏
        HdsTabs({ controller: this.controller!, index: this.firstLevelIndex }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

          TabContent() {
            SecondPage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

          TabContent() {
            MinePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
        }
        // [StartExclude tab_to_page]
        // 设置barOverlap为true，vertical为false，barPosition为BarPosition.End，可实现页签栏的悬浮样式
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .vertical(false)
        // 设置页签栏悬浮样式
        .barFloatingStyle({
          barBottomMargin: 28,
          gradientMask: { maskColor: '#66F1F3F5', maskHeight: 92 },
          systemMaterialEffect: {
            materialType: MaterialType.ADAPTIVE,
            materialLevel: this.customMaterialLevel
          }
        })
        // [EndExclude tab_to_page]
        .onChange((index: number) => {
          this.firstLevelIndex = index;
          // 保存当前 Tab 索引到 AppStorage,供接续功能使用
          AppStorage.setOrCreate('currentTabIndex', index);
        })
        // [End tab_to_page]
        .scrollable(false)
        .height('100%')
        .width('100%')
      }
    } else {
      // 传统式Tab栏样式
      if (this.currentWidthBreakpoint === 'lg' || this.currentWidthBreakpoint === 'xl') {
        // 平板模式：使用左侧垂直Tab栏
        Tabs({
          barPosition: BarPosition.Start,
          index: this.firstLevelIndex
        }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

          TabContent() {
            SecondPage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

          TabContent() {
            MinePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
        }
        .barBackgroundColor($r('app.color.barBackgroundColor'))
        .barWidth(96)
        .barHeight('100%')
        .barMode(BarMode.Scrollable, { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
        .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        .vertical(true)
        .onChange((index: number) => {
          this.firstLevelIndex = index;
          // 保存当前 Tab 索引到 AppStorage,供接续功能使用
          AppStorage.setOrCreate('currentTabIndex', index);
        })
        .scrollable(false)
        .height('100%')
        .width('100%')
      } else {
        // 手机模式：使用传统式底部Tab栏（无悬浮效果）
        Tabs({
          barPosition: BarPosition.End,
          index: this.firstLevelIndex
        }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[0], 0))

          TabContent() {
            SecondPage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[1], 1))

          TabContent() {
            MinePage()
          }
          .tabBar(this.tabBuilder(this.tabData.getFirstList()[2], 2))
        }
        .barPosition(BarPosition.End)
        .vertical(false)
        .onChange((index: number) => {
          this.firstLevelIndex = index;
          // 保存当前 Tab 索引到 AppStorage,供接续功能使用
          AppStorage.setOrCreate('currentTabIndex', index);
        })
        .scrollable(false)
        .height('100%')
        .width('100%')
        // 为底部Tab栏添加安全区避让
        .padding({ bottom: px2vp(this.bottomRectHeight) })
      }
    }
    // [EndExclude diff_device_container]
    // [End diff_device_container]
  }
}