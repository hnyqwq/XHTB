import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';
import { router } from '@kit.ArkUI';
import { hdsMaterial } from '@hms.hds.hdsMaterial'
import { HdsTabs, HdsTabsController, HdsTabsAttribute } from '@kit.UIDesignKit';
import { preferences } from '@kit.ArkData';
import type { common } from '@kit.AbilityKit';

@Component
export struct Home {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @StorageLink('isImmersiveTab') isImmersiveTab: boolean = false; // 沉浸式Tab栏设置
  @StorageLink('currentTabIndex') firstLevelIndex: number = 0; // 从AppStorage读取当前Tab索引
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @State secondLevelIndex: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();
  private controller: HdsTabsController = new HdsTabsController();
  private preferences: preferences.Preferences | null = null;

  aboutToAppear(): void {
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

  async loadImmersiveTabSetting() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.preferences = await preferences.getPreferences(context, 'app_settings');

      // 读取保存的值
      if (this.preferences) {
        const savedValue = await this.preferences.get('isImmersiveTab', false) as boolean;
        // 同步到AppStorage
        AppStorage.setOrCreate('isImmersiveTab', savedValue);
      }
    } catch (err) {
      console.error('Failed to load immersive tab setting:', err);
      // 出错时使用默认值
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

  getTabIcon(index: number, isSelected: boolean): Resource {
    switch (index) {
      case 0:
        return isSelected ? $r('app.media.home_active') : $r('app.media.home');
      case 1:
        return isSelected ? $r('app.media.ocr_active') : $r('app.media.ocr');
      case 2:
        return isSelected ? $r('app.media.mine_active') : $r('app.media.mine');
      default:
        return $r('app.media.home');
    }
  }

  @Builder
  tabBuilder(name: string, index: number) {
    Column() {
      Image(this.getTabIcon(index, index === this.firstLevelIndex))
        .width(24)
        .height(24)
        .fillColor(index === this.firstLevelIndex ? '#0A59F7' : '#999999')
      Text(name)
        .fontSize(10)
        .fontWeight(500)
        .fontColor(index === this.firstLevelIndex ? '#0A59F7' : '#999999')
        .margin({ top: 4 })
    }
    .padding({ bottom: this.currentWidthBreakpoint === 'lg' ? 24 : 0 })
    .height(this.currentWidthBreakpoint === 'lg' ? 100 : '100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    // [Start diff_device_container]
    // entry/src/main/ets/view/Home.ets
    // 根据沉浸式Tab栏开关决定布局样式
    if (this.isImmersiveTab) {
      // 沉浸式底部Tab栏样式（悬浮+材质效果）
      HdsTabs({ controller: this.controller, index: this.firstLevelIndex }) {
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
        //barWidth: { smallWidth: 200, mediumWidth: 300, largeWidth: 400 },
        barBottomMargin: 28,
        gradientMask: { maskColor: '#66F1F3F5', maskHeight: 92 },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
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
      // 传统式Tab栏样式
      if (this.currentWidthBreakpoint === 'lg') {
        // 平板模式（lg breakpoint）：使用左侧垂直Tab栏
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
        HdsTabs({ controller: this.controller, index: this.firstLevelIndex }) {
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