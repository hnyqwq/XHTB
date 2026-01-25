import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';
import { SideBarView } from './SideBarView';
import { TopTabView } from './TopTabView';
import { VideoInfoView } from './VideoInfoView';
import { HomePage } from '../pages/HomePage';
import { SecondPage } from '../pages/SecondPage';
import { MinePage } from '../pages/MinePage';

@Component
export struct Home {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @State firstLevelIndex: number = 0;
  @State secondLevelIndex: number = 0;
  @State tabViewModel: TabViewModel = new TabViewModel();
  @State tabData: TabDataModel = this.tabViewModel.getTabMap();

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
    .padding({ bottom: 24 })
    .height(this.currentWidthBreakpoint === 'lg' ? 100 : '100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
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
      // Use Tabs and List at other breakpoints.
      // [Start tab_to_page]
      // entry/src/main/ets/view/Home.ets
      Tabs({
        barPosition: this.currentWidthBreakpoint === 'lg' ? BarPosition.Start : BarPosition.End,
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
      // [StartExclude tab_to_page]
      .barBackgroundColor($r('app.color.barBackgroundColor'))
      .barWidth(this.currentWidthBreakpoint === 'lg' ? 96 : '100%')
      .barHeight(this.currentWidthBreakpoint === 'lg' ? '100%' : 76)
      .barMode(this.currentWidthBreakpoint === 'lg' ? BarMode.Scrollable : BarMode.Fixed,
        { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
      .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      // [EndExclude tab_to_page]
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