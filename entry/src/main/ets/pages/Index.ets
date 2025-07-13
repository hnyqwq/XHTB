import { HomePage } from './HomePage';
import { SecondPage } from './SecondPage';
import { MinePage } from './MinePage';

@Entry
@Component
export struct Index {
  private controller: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() {
        HomePage()
      }.tabBar({
        //icon: $r('app.media.home'),
        text: '主页'
      })

      TabContent() {
        SecondPage()
      }.tabBar({
        //icon: $r('app.media.list'),
        text: '第二页'
      })

      TabContent() {
        MinePage()
      }.tabBar({
        //icon: $r('app.media.profile'),
        text: '我的'
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}