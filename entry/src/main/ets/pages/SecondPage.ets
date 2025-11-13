import { router } from '@kit.ArkUI';
import { CommonConstants, ScrollPosition } from '../constants/CommonConstants';
import { ListDataConstants } from '../constants/ListDataConstants';
import GridComponent from '../model/GridComponent';
import { featureGridData, GridData, otherGridDataList } from '../model/GridListDataSources';

@Entry
@Component
export struct SecondPage {
  //0 for scrolling to the top of the list, 1 for the middle value, and 2 for scrolling to the bottom of the list.
  @State listPosition: number = ScrollPosition.start;
  //0 for scrolling to the top of the page, 1 for the middle value, and 2 for scrolling to the bottom of the page.
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
      .margin({ top: 10 })
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
      .height($r('app.float.page_title_height'))

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
            // Triggers when the start position is reached.
            .onReachStart(() => {
              this.listPosition = ScrollPosition.start;
            })
            // Triggers when the end position is reached.
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
              // When sliding to the middle of the list
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
    .backgroundColor($r('app.color.color_info'))
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
