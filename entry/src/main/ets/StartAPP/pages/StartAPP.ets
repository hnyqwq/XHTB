let storage434065498 = new LocalStorage()

@Entry(storage434065498)
@Component
export struct Control_C1 {
  //@State imgLogo: Resource = $r('app.media.fixed_logo_0')
  @LocalStorageProp('backgroundImg') backgroundImg: Resource = $r('app.media.startIcon')
  /*@State redButtonTextY: string = "点击即可打开软件"
  ClickToRedButtonYTarget = () : void => {
    postCardAction(this, {
      "action": "router",
      // Configuring the UIAbility name for jumping.
      'abilityName': 'EntryAbility',
      // Configuring the parameters to be transferred.
      "params": {
        'targetPage': 'page1'
      }
    });
}  */
  ClickToHome = () : void => {
    postCardAction(this, {
      "action": "router",
      // Configuring the UIAbility name for jumping.
      'abilityName': 'EntryAbility',
      // Configuring the parameters to be transferred.
      "params": {
        'targetPage': 'page1'
      }
    });  
}  
  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Column() {
          Row()
            .width('70%')
            .height('25%')
          Row()
            .height('35%')
          Row()
            .height('40%')
        }
        .width('100%')
        .height('58%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceAround)
        /*Button(this.redButtonTextY)
          .fontSize('14')
          .fontWeight(FontWeight.Medium)
          .backgroundColor(Color.Transparent)
          .width('100%')
          .height('36')
          .border({ color: 'white', width: '1' })
          .onClick(this.ClickToRedButtonYTarget)
      }*/
      .padding('8%')
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      /*Image(this.imgLogo)
        .margin({ top: '8%', right: '8%' })
        .width('20')
        .height('20')*/
    }
    .backgroundImage(this.backgroundImg)
    .backgroundImageSize({ width: '100%', height: '100%' })
    .width('100%')
    .height('100%')
    .onClick(this.ClickToHome)
  }
}}