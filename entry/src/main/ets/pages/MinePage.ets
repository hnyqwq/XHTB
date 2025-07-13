@Observed
  //设置条目信息构造
class SettingMenu {
  public id: string; // 唯一id
  public image: Resource; // 菜单图标
  public text: string; // 菜单文本
  public des: Resource; //后缀文本

  constructor(id: string, image: Resource, text: string, des: Resource) {
    this.id = id;
    this.image = image;
    this.text = text;
    this.des = des;
  }
}

@Entry
@Component
struct AboutPage {
  //设置条目信息数组
  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('app.media.mine_settings'), '官网', $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('app.media.mine_vipsettings'), 'XXXX', $r('app.string.void')),
    new SettingMenu('mycollection', $r('app.media.ic_collect'), '微信公众号', $r('app.string.void')),
    new SettingMenu('mylike', $r('app.media.mine_like'), '分享我们', $r('app.string.void')),
    new SettingMenu('browsinghistory', $r('app.media.mine_time'), '第三方共享信息清单', $r('app.string.void'))
  ];

  build() {
    Stack() {
      Navigation() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(60)
            .height(60);

          Text('App Name')
            .fontWeight(700)
            .fontSize('14fp')
            .margin({ top: 10 });
          Text('Description')
            .fontWeight(600)
            .fontSize('12fp')
            .margin({ top: 10 });
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Column() {
          Row() {
            List() {
              ForEach(this.menuGroup,
                (item: SettingMenu) => {
                  ListItem() {
                    SettingItemView({ image: item.image, text: item.text, des: item.des });
                  }
                  .width('100%');
                },
                (item: SettingMenu) => item.id.toString());
            }
            .divider({
              strokeWidth: $r('app.float.stroke_width'),
              color: $r('app.color.font_color_00000'),
              startMargin: $r('app.integer.layout_size_46'),
              endMargin: $r('app.integer.layout_size_24')
            });
          }
          .padding({ bottom: $r('app.integer.layout_size_5'), top: $r('app.integer.layout_size_5') })
          .width('90%')
          .borderRadius($r('app.integer.layout_size_24'))
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: $r('app.integer.layout_size_12') })
          .backgroundColor($r('app.color.font_color_FFFFFF'));
        }
        .width('100%')
        .layoutWeight(1);

        Column() {
          Text() {
            Span('XXX用户协议')
              .fontColor(Color.Blue)
              .fontSize(12);
            Span('和')
              .fontSize(12);
            Span('XXX与隐私的声明')
              .fontColor(Color.Blue)
              .fontSize(12);
          };

          Text('版权所有◎ 2011-2019 华为技术有限公司保留一切权利')
            .fontSize(12);
          Text('技术支持:00000x')
            .fontSize(12);
        }
        .width('100%')
        .height(60);
      }
      .height('100%')
      .title('关于页')
      .titleMode(NavigationTitleMode.Mini)
      .backgroundColor($r('app.color.listColor'));
    };
  }
}

@Component
  //设置条目布局
export struct SettingItemView {
  private image: string | Resource = ''; // 图标
  private text: string | Resource = ''; // 设置名称
  private des: string | Resource = ''; //后面的文本

  build() {
    Row() {
      Row() {
        Image(this.image)
          .width($r('app.integer.layout_size_22'))
          .height($r('app.integer.layout_size_32'))
          .objectFit(ImageFit.Contain);
        Text(this.text)
          .fontSize($r('app.integer.layout_size_16'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_182431'))
          .margin({ left: $r('app.integer.layout_size_12') })
          .layoutWeight(1)
          .lineHeight($r('app.integer.layout_size_22'));

        Text(this.des)
          .opacity($r('app.float.opacity'))
          .fontSize($r('app.integer.layout_size_14'))
          .fontWeight(400)
          .fontFamily('HarmonyHeiTi')
          .fontColor($r('app.color.font_color_182431'))
          .lineHeight($r('app.integer.layout_size_19'));
      }
      .width('100%')
      .height($r('app.integer.tabbar_height'))
      .padding({
        left: $r('app.integer.layout_size_22'),
        right: $r('app.integer.layout_size_12')
      })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height($r('app.integer.layout_size_48'))
    .alignSelf(ItemAlign.Center);
  }
}