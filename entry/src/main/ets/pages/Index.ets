import { HomePage } from './HomePage';
import { SecondPage } from './SecondPage';
import { MinePage } from './MinePage';

@Entry
@Component
export struct Index {
  private controller: TabsController = new TabsController();
  @State currentTabIndex: number = 0

  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.controller
    }) {
      // 第一个Tab
      TabContent() {
        HomePage()
      }.tabBar({
        icon: this.currentTabIndex === 0 ?
        $r('app.media.home_active') :
        $r('app.media.home'),
        text: '主页'
      })

      // 第二个Tab（OCR页）
      TabContent() {
        SecondPage()
      }.tabBar({
        icon: this.currentTabIndex === 1 ?
        $r('app.media.ocr_active') :
        $r('app.media.ocr'),
        text: 'OCR'
      })

      // 第三个Tab
      TabContent() {
        MinePage()
      }.tabBar({
        icon: this.currentTabIndex === 2 ?
        $r('app.media.mine_active') :
        $r('app.media.mine'),
        text: '我的'
      })
    }
    .onChange((index: number) => {
      this.currentTabIndex = index
    })
    .width('100%')
    .height('100%')
    //.backgroundColor('#F5F5F5')
    .backgroundColor($r('app.color.listColor'));
  }
}