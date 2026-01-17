import { TabDataModel } from '../model/TabDataModel';
import { VideoInfoView } from './VideoInfoView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

@Component
export struct TopTabView {
  @State secondLevelIndex: number = 0;
  @Link firstLevelIndex: number;
  @Link tabData: TabDataModel;
  @State statusBarHeight: number = 0;
  private firstLevel: string = this.getFirstLevel();

  aboutToAppear(): void {
    // 获取状态栏高度
    try {
      window.getLastWindow(getContext(this)).then((windowClass: window.Window) => {
        const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = px2vp(avoidArea.topRect.height);
      }).catch((error: Error) => {
        hilog.error(0x0000, 'testTag', 'Failed to get status bar height: %{public}s', JSON.stringify(error) ?? '');
        this.statusBarHeight = 32; // 默认值
      });
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to get status bar height: %{public}s', JSON.stringify(error) ?? '');
      this.statusBarHeight = 32; // 默认值
    }
  }

  getFirstLevel() {
    let res: string = '';
    try {
      res = this.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.app_name').id);
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to get string. Cause: %{public}s', JSON.stringify(error) ?? '');
    }
    return res;
  }

  build() {
    // [Start top_tab_view]
    // entry/src/main/ets/view/TopTabView.ets
    Column() {
      List() {
        ForEach(this.tabData.getSecondList(this.firstLevel), (item: string, index: number) => {
          ListItem() {
            Text(item)
              .fontSize(index === this.secondLevelIndex ? '24fp' : '18fp')
              .fontWeight(index === this.secondLevelIndex ? 700 : 500)
              .fontColor(index === this.secondLevelIndex ? '#E6000000' : '#99000000')
              .width(index === this.secondLevelIndex ? 65 : 50)
              .textAlign(TextAlign.Center)
              .lineHeight(index === this.secondLevelIndex ? 33 : 25)
              .borderRadius(4)
              // [StartExclude top_tab_view]
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            // [EndExclude top_tab_view]
          }
          // [StartExclude top_tab_view]
          .align(Alignment.Center)
          .margin({
            top: index === this.secondLevelIndex ? 12 : 18,
            bottom: index === this.secondLevelIndex ? 11 : 13
          })
          // [EndExclude top_tab_view]
          .onClick(() => {
            this.secondLevelIndex = index;
          })
        }, (item: string, index: number) => index + item)
      }
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
      .padding({ left: 24 })
      .height(56)
      .width('100%')

      VideoInfoView({
        firstLevelIndex: this.firstLevelIndex,
        secondLevelIndex: this.secondLevelIndex
      })
    }
    .height('100%')
    .width('100%')
    .padding({
      top: this.statusBarHeight + 30
    })
    // [End top_tab_view]
  }
}