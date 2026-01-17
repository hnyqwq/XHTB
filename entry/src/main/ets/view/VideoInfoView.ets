import { BreakpointType } from '../common/utils/Breakpoint';
import { VideoViewModel } from '../viewmodel/VideoViewModel';

@Component
export struct VideoInfoView {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = 'sm';
  @Link firstLevelIndex: number;
  @Link secondLevelIndex: number;
  private videoViewModel = new VideoViewModel();
  private iteration: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  build() {
    Grid() {
      ForEach(this.iteration, () => {
        GridItem() {
          Column() {
            Image(this.videoViewModel.getVideo(this.secondLevelIndex))
              .objectFit(ImageFit.Fill)
              .width('100%')
              .borderRadius(12)

            Row()
              .height(16)
              .width('50%')
              .borderRadius(12)
              .backgroundColor('#1A000000')
              .margin({
                top: new BreakpointType(10, 10, 12, 11).getValue(this.currentWidthBreakpoint),
                bottom: 6
              })

            Row()
              .height(14)
              .width('100%')
              .borderRadius(12)
              .backgroundColor('#0D000000')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }, (item: number, index: number) => index + JSON.stringify(item))
    }
    .visibility(this.firstLevelIndex === 0 ? Visibility.Visible : Visibility.None)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .columnsTemplate(new BreakpointType('1fr 1fr', '1fr 1fr 1fr', '1fr 1fr 1fr 1fr', '1fr 1fr 1fr')
      .getValue(this.currentWidthBreakpoint))
    .width('100%')
    .rowsGap(new BreakpointType(12, 16, 16, 16).getValue(this.currentWidthBreakpoint))
    .columnsGap(new BreakpointType(16, 12, 16, 16).getValue(this.currentWidthBreakpoint))
    .padding({
      left: new BreakpointType(16, 24, 36, 24).getValue(this.currentWidthBreakpoint),
      right: new BreakpointType(16, 24, 36, 24).getValue(this.currentWidthBreakpoint),
      top: 12,
      bottom: new BreakpointType(6, 6, 20, 20).getValue(this.currentWidthBreakpoint)
    })
  }
}