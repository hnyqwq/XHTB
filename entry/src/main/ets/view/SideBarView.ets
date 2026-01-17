import { TabDataModel } from '../model/TabDataModel';
import { TabViewModel } from '../viewmodel/TabViewModel';

@Component
export struct SideBarView {
  @Link firstLevelIndex: number;
  @Link secondLevelIndex: number;
  @Link tabViewModel: TabViewModel;
  @Link tabData: TabDataModel;
  @State isShow: boolean = true;

  build() {
    // [Start side_bar_view]
    // entry/src/main/ets/view/SideBarView.ets
    Column() {
      // [StartExclude side_bar_view]
      Row({ space: 8 }) {
        Image($r('app.media.CIcon'))
          .height(24)
        Text($r('app.string.EntryAbility_label'))
          .fontSize('16fp')
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 8 })
      .height(56)
      // [EndExclude side_bar_view]
      Column({ space: 2 }) {
        ForEach(this.tabData.getFirstList(), (item: string, index: number) => {
          Column() {
            Row() {
              Row({ space: 8 }) {
                // [StartExclude side_bar_view]
                Image(index === this.firstLevelIndex ? $r('app.media.mine_active') :
                  $r('app.media.mine'))
                  .width(24)
                  .height(24)
                // [EndExclude side_bar_view]
                Text(item)
                  .fontSize('16fp')
                  .fontWeight(index === this.firstLevelIndex ? FontWeight.Bold : FontWeight.Medium)
              }

              if (this.tabData.getSecondList(item).length > 0) {
                Image((index === this.firstLevelIndex && this.isShow) ?
                  $r('app.media.chevron_up') : $r('app.media.arrow_down'))
                  .width(20)
                  .height(20)
              }
            }
            // [StartExclude side_bar_view]
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .height(40)
            .padding({
              left: 8
            })
            // [EndExclude side_bar_view]
            Column({ space: 2 }) {
              ForEach(this.tabData.getSecondList(item), (item: string, index: number) => {
                Row() {
                  Text(item)
                    // [StartExclude side_bar_view]
                    .fontSize('16fp')
                    .fontWeight(index === this.secondLevelIndex ? FontWeight.Bold : FontWeight.Medium)
                    .margin({ left: 40 })
                  // [EndExclude side_bar_view]
                }
                // [StartExclude side_bar_view]
                .width('100%')
                .height(40)
                .borderRadius(8)
                .backgroundColor(index === this.secondLevelIndex ? '#1A0A59F7' : '#00FFFFFF')
                // [EndExclude side_bar_view]
                .onClick(() => {
                  this.secondLevelIndex = index;
                })
              }, (item: string, index: number) => index + item)
            }
            .visibility((index === this.firstLevelIndex && this.isShow) ? Visibility.Visible : Visibility.None)
          }
          .alignItems(HorizontalAlign.Start)
          .onClick(() => {
            if (this.firstLevelIndex === index) {
              this.isShow = !this.isShow;
            }
            this.firstLevelIndex = index;
          })
        }, (item: string, index: number) => index + item)
      }
      .alignItems(HorizontalAlign.Start)
    }
    // [End side_bar_view]
    // [StartExclude side_bar_view]
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#0D000000')
    .padding({
      left: 16,
      right: 16
    })
    .height('100%')
    .width('100%')
  }
}
// [EndExclude side_bar_view]
