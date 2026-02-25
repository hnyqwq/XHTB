import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';
import { router } from '@kit.ArkUI';
import { hdsMaterial } from '@hms.hds.hdsMaterial'
import { HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

@Component
export struct Home {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @State firstLevelIndex: number = 0;
  @State secondLevelIndex: number = 0;
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();
  private controller: HdsTabsController = new HdsTabsController();

  aboutToAppear(): void {
    // 如果设置了初始 Tab 索引,则使用该索引
    const initialTabIndex = AppStorage.get<number>('initialTabIndex');
    if (initialTabIndex !== undefined && initialTabIndex !== null) {
      this.firstLevelIndex = initialTabIndex;
      // 清除标记,避免影响后续导航
      AppStorage.delete('initialTabIndex');
    }
    // 保存初始的 Tab 索引到 AppStorage
    AppStorage.setOrCreate('currentTabIndex', this.firstLevelIndex);

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

  build() {
    // [Start diff_device_container]
    // entry/src/main/ets/view/Home.ets
    // PC使用平板布局：注释掉PC特殊适配，保留接口
    // if (this.currentWidthBreakpoint === 'xl') {
    //   // Use SideBarContainer at XL breakpoint.
    //   SideBarContainer(SideBarContainerType.Embed) {
    //     SideBarView({
    //       firstLevelIndex: this.firstLevelIndex,
    //       secondLevelIndex: this.secondLevelIndex,
    //       tabViewModel: this.tabViewModel,
    //       tabData: this.tabData
    //     })
    //
    //     Column() {
    //       Text(this.tabViewModel.getTabNameOfSecondLevel(this.tabViewModel.getTabNameOfFirstLevel(this.firstLevelIndex),
    //         this.secondLevelIndex))
    //         .fontSize('20fp')
    //         .fontWeight(700)
    //         .margin({
    //           left: 32,
    //           top: 16,  // 进一步减少顶部间距
    //           bottom: 4  // 进一步减少底部间距
    //         })
    //       
    //       // 根据不同的firstLevelIndex显示对应的页面内容
    //       if (this.firstLevelIndex === 0) {
    //         HomePage()
    //       } else if (this.firstLevelIndex === 1) {
    //         SencondPage()
    //       } else if (this.firstLevelIndex === 2) {
    //         MinePage()
    //       }
    //     }
    //     .alignItems(HorizontalAlign.Start)
    //   }
    //   .autoHide(false)
    //   .divider({ strokeWidth: 0.3 })
    //   .showControlButton(false)
    //   .sideBarWidth(240)
    //   .minSideBarWidth(240)
    //   .maxSideBarWidth(240)
    // } else {
      // [StartExclude diff_device_container]
      // Use HdsTabs and List at other breakpoints.
      // [Start tab_to_page]
      // entry/src/main/ets/view/Home.ets
      HdsTabs({ controller: this.controller }) {
        TabContent() {
          HomePage()
        }
        .tabBar(new BottomTabBarStyle(this.getTabIcon(0, false), this.tabData.getFirstList()[0]))

        TabContent() {
          SecondPage()
        }
        .tabBar(new BottomTabBarStyle(this.getTabIcon(1, false), this.tabData.getFirstList()[1]))

        TabContent() {
          MinePage()
        }
        .tabBar(new BottomTabBarStyle(this.getTabIcon(2, false), this.tabData.getFirstList()[2]))
      }
      // 设置页签栏基本属性
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
        },
      })
      // [StartExclude tab_to_page]
      .vertical(this.currentWidthBreakpoint === 'lg')
      .onChange((index: number) => {
        this.firstLevelIndex = index;
        // 保存当前 Tab 索引到 AppStorage,供接续功能使用
        AppStorage.setOrCreate('currentTabIndex', index);
      })
      // [End tab_to_page]
      .scrollable(false)
      .height('100%')
      .width('100%')
      // [EndExclude diff_device_container]
      // [End diff_device_container]
  }
}