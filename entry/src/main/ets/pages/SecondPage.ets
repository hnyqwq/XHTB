import { CommonConstants, ScrollPosition } from '../constants/CommonConstants';
import { ListDataConstants } from '../constants/ListDataConstants';
import GridComponent from '../model/GridComponent';
import { featureGridData, GridData, otherGridDataList } from '../model/GridListDataSources';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { navigationManager } from '../common/NavigationManager';
import { TextToSpeechPage } from '../XHTB/TextToSpeechPage';
import { QRCodePage } from '../XHTB/QRCodePage';
import { Internet } from '../XHTB/Internet';
import { OCR } from '../XHTB/DocScan/OCR';

@Component
struct SecondPageContent {
  //0 for scrolling to the top of list, 1 for middle value, and 2 for scrolling to the bottom of list.
  @State listPosition: number = ScrollPosition.start;
  //0 for scrolling to the top of page, 1 for middle value, and 2 for scrolling to the bottom of page.
  @State scrollPosition: number = ScrollPosition.start;
  @State currentIndex: number = 0;
  private scrollerForScroll: Scroller = new Scroller();
  private scrollerForList: Scroller = new Scroller();
  private scrollerForTitle: Scroller = new Scroller();

  build() {
    Column() {
      Row() {
        Text($r('app.string.page_title'))
          .fontSize($r('app.float.page_title_font_size'))
          .fontWeight(FontWeight.Bold)
      }
      .margin({ top: 10, bottom: 10 })
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.page_title_height'))
      .padding({ top: (AppStorage.get<GlobalInfoModel>('GlobalInfoModel')?.statusBarHeight ?? 0) })

      Stack({ alignContent: Alignment.Top }) {
        Scroll(this.scrollerForScroll) {
          Column() {
            GridComponent({ gridData: featureGridData })
            this.myBuilder();
            List({ scroller: this.scrollerForList }) {
              ForEach(otherGridDataList, (item: GridData, index: number) => {
                GridComponent({ gridData: item, isLastItem: index === otherGridDataList.length - 1 })
              }, (item: GridData,index:number) =>index+JSON.stringify(item))
            }
            .padding({ bottom: $r('app.float.list_bottom_padding') })
            .width(CommonConstants.FULL_PERCENT)
            .edgeEffect(EdgeEffect.None)
            .scrollBar(BarState.Off)
            // Triggers when start position is reached.
            .onReachStart(() => {
              this.listPosition = ScrollPosition.start;
            })
            // Triggers when end position is reached.
            .onReachEnd(() => {
              this.listPosition = ScrollPosition.end;
            })
            // Obtains the index value of the first subcomponent in the display area of the List component.
            .onScrollIndex((start: number) => {
              this.currentIndex = start
              this.scrollerForTitle.scrollToIndex(this.currentIndex);
            })
            .onScrollFrameBegin((offset: number) => {
              if (this.currentIndex === ListDataConstants.TITLE_LIST.length - 1 && offset > 0) {
                return { offsetRemain: 0 }
              }
              // When sliding to middle of list
              if (!((this.listPosition === ScrollPosition.start && offset < 0) ||
                (this.listPosition === ScrollPosition.end && offset > 0))) {
                this.listPosition = ScrollPosition.center;
              }
              // If the page has scrolled to the bottom, the list is not at the top or the list has a positive offset
              if (this.scrollPosition === ScrollPosition.end &&
                (this.listPosition != ScrollPosition.start || offset > 0)) {
                return { offsetRemain: offset };
              } else {
                this.scrollerForScroll.scrollBy(0, offset)
                return { offsetRemain: offset };
              }
            })
            .width(CommonConstants.FULL_PERCENT)
            .height("calc(100% - 56vp)")
          }
        }
        .scrollBar(BarState.Off)
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .onWillScroll((yOffset: number) => {
          // If the page is not at the top or bottom, it is in the middle.
          if (!((this.scrollPosition === ScrollPosition.start && yOffset < 0)
            || (this.scrollPosition === ScrollPosition.end && yOffset > 0))) {
            this.scrollPosition = ScrollPosition.center;
          }
        })
        .onScrollEdge((side: Edge) => {
          if (side === Edge.Top) {
            // Page is at the top
            this.scrollPosition = ScrollPosition.start;
          } else if (side === Edge.Bottom) {
            // Page is at the bottom
            this.scrollPosition = ScrollPosition.end;
          }
        })
        .onScrollFrameBegin(offset => {
          if (this.scrollPosition === ScrollPosition.end) {
            return { offsetRemain: 0 };
          } else {
            return { offsetRemain: offset };
          }
        })
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
    }
    .backgroundColor($r('app.color.White'))
  }

  @Builder
  myBuilder() {
    Row() {
      List({ space: CommonConstants.LIST_SPACE_SIZE, scroller: this.scrollerForTitle }) {
        ForEach(ListDataConstants.TITLE_LIST, (item: string, index) => {
          ListItem() {
            Column() {
              Text(item)
                .fontColor(this.currentIndex === index ? $r('app.color.isChick_title_color') :
                  $r('app.color.noChick_title_color'))
                .fontSize($r('app.float.title_list_item_font_size'))
                .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: $r('app.float.title_list_top_margin') })

              if (this.currentIndex === index) {
                Divider()
                  .color($r('app.color.isChick_title_color'))
                  .strokeWidth(CommonConstants.DIVIDER_STROKE_WIDTH)
                  .width($r('app.float.divider_width'))
                  .margin({ top: $r('app.float.divider_top_margin') })
              }
            }
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.scrollerForList.scrollToIndex(index);
              this.scrollerForScroll.scrollEdge(Edge.Bottom);
              this.scrollerForTitle.scrollToIndex(index);
              this.currentIndex = index;
            })
          }
        }, (item: string, index: number) => index + JSON.stringify(item))
      }
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.title_list_height'))
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .margin({ top: $r('app.float.title_list_top_margin') })
    .padding({ left: $r('app.float.title_list_padding'), right: $r('app.float.title_list_padding') })
  }
}



@Entry
@Component
export struct SecondPage {
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageLink('SecondPageRightPage') currentRightPage: string = '';
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'sm';
  @State useSplitLayout: boolean = false;

  aboutToAppear() {
    // 根据屏幕宽度决定使用分栏布局还是垂直布局
    // lg及以上使用分栏布局(lg>=840vp)
    this.useSplitLayout = this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl';
    // 设置全局标志,告诉GridItemComponent当前在SecondPage分栏模式
    AppStorage.setOrCreate<boolean>('SecondPageSplitMode', this.useSplitLayout);
    console.info(`========== SecondPage初始化 ==========`);
    console.info(`currentBreakpoint: ${this.currentBreakpoint}`);
    console.info(`useSplitLayout: ${this.useSplitLayout}`);
    console.info(`设置SecondPageSplitMode=${this.useSplitLayout}`);
    console.info(`========== SecondPage初始化结束 ==========`);
  }

  build() {
    if (this.useSplitLayout) {
      // 分栏布局：左边是原内容，右边是跳转的页面
      Row() {
        // 左侧：原来SecondPage的内容
        Column() {
          SecondPageContent()
        }
        .width('40%')
        .height('100%')
        .border({ width: { right: 1 }, color: $r('app.color.listColor') })

        // 右侧：显示跳转的页面内容
        Column() {
          if (this.currentRightPage === '') {
            // 未选择时显示占位内容
            Column() {
              Text('请从左侧选择一个功能')
                .fontSize(18)
                .fontColor($r('app.color.font_color_182431'))
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            // 直接渲染页面组件
            this.pageBuilder()
          }
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.White'))
    } else {
      // 垂直布局：原来的完整页面
      SecondPageContent()
    }
  }

  // 右侧页面构建器
  @Builder
  pageBuilder() {
    // 这里需要根据currentRightPage动态加载对应的页面组件
    // 由于HarmonyOS的限制,我们需要使用条件渲染
    if (this.currentRightPage === 'XHTB/TextToSpeechPage') {
      TextToSpeechPage()
    } else if (this.currentRightPage === 'XHTB/QRCodePage') {
      QRCodePage()
    } else if (this.currentRightPage === 'XHTB/DocScan/OCR') {
      OCR()
    } else if (this.currentRightPage === 'XHTB/Internet') {
      Internet()
    }
  }
}
