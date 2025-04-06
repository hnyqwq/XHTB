@Component
export struct MySubTitle {
   shili: string = '';
   subTitle: string = '';

  build() {
    Column(){
      Text(this.shili)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Text(this.subTitle)
    }
    .margin({ top: 30 })
    .width('100%')
  }
}