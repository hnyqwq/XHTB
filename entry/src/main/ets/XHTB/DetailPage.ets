import { router } from '@kit.ArkUI';

@Entry
@Component
struct DetailPage {
  @State pageTitle: string = '详情页'

  build() {
    Column() {
      Row() {
        Button('返回')
          .onClick(() => {
            router.back()
          })
        
        Text(this.pageTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)

      Column() {
        Text('这是详情页面')
          .fontSize(24)
        
        Text('您可以通过不同的按钮进入此页面')
          .fontSize(16)
          .fontColor('#666')
          .margin({ top: 20 })
      }
      .width('100%')
      .height('80%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}