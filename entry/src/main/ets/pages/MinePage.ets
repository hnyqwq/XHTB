import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

@Observed
  //设置条目信息构造
class SettingMenu {
  public uri?: string;
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
export struct MinePage {
  //设置条目信息数组
  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('app.media.mine_settings'), '前往官网', $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('app.media.mine_vipsettings'), '神秘功能', $r('app.string.void')),
    new SettingMenu('mycollection', $r('app.media.ic_collect'), '关注哔哩哔哩', $r('app.string.void')),
    new SettingMenu('mylike', $r('app.media.mine_like'), '关注抖音', $r('app.string.void')),
    new SettingMenu('browsinghistory', $r('app.media.mine_time'), '前往个人博客', $r('app.string.void'))
  ];

  build() {
    Stack() {
      Navigation() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(60)
            .height(60);
          Text('hvideo')
            .fontWeight(700)
            .fontSize('14fp')
            .margin({ top: 10 });
          Text('1.3.0.2（10300002）')
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
                  .width('100%')
                  .onClick(() => { // 添加点击事件
                    const context = getContext(this) as common.UIAbilityContext;
                    let uri = '';
                    switch (item.id) {
                      case 'setting': // 官网
                        uri = 'https://hnyqwq.cn';
                        break;
                      case 'vipownsetting':
                        // 应用内页面跳转
                        router.pushUrl({ url: 'pages/exPage' })
                          .catch((e: BusinessError) => {
                            console.error('路由跳转失败', e);
                          });
                        break;
                      case 'mycollection': // 微信公众号
                        uri = 'bilibili://space/338142387';
                        break;
                      case 'mylike': // 分享功能（需集成分享SDK）
                        uri =
                          'https://m.douyin.com/share/user/MS4wLjABAAAAu-191qiFh5x3NLdZXeT7y8uMMhqaT9ZQCdgpe1H2ZIcEVCCoGrpDeuRb5diMrBmd';
                        break
                        // harmonyShare.share(...);
                        break;
                      case 'browsinghistory': // 第三方清单
                        uri = 'https://blog.hnyqwq.cn';
                        break;
                    }
                    if (uri) {
                      const want: Want = { uri };
                      context.startAbility(want).catch((e: BusinessError) => {
                        console.error(`跳转失败: ${e.code}`, e.message);
                      });
                    }
                  })
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
            Span('hvideo用户协议')
              .onClick(() => {
                const want: Want = { uri: `https://hnyqwq.cn/hvideo/yhxy.html` };
                const context = getContext(this) as common.UIAbilityContext;
                context.startAbility(want).then(() => { //拉起成功
                  console.info('拉起应用商店成功')
                }).catch((e: BusinessError) => { // 拉起失败
                  console.info('拉起应用商店失败')
                });
              })
              .fontColor(Color.Blue)
              .fontSize(12);
            Span('和')
              .fontSize(12);
            Span('hvideo与隐私的声明')
              .onClick(() => {
                const want: Want = { uri: `https://www.hnyqwq.cn/hvideo/hvideo.html` };
                const context = getContext(this) as common.UIAbilityContext;
                context.startAbility(want).then(() => { //拉起成功
                  console.info('拉起应用商店成功')
                }).catch((e: BusinessError) => { // 拉起失败
                  console.info('拉起应用商店失败')
                });
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          };

          Text('版权所有◎ 2025 保留一切权利')
            .fontSize(12);
          Text() {
            Span('前往下载AppTest')
              .onClick(() => {
                const want: Want = { uri: `store://appgallery.huawei.com/app/detail?id=com.huawei.hmsapp.apptest` };
                const context = getContext(this) as common.UIAbilityContext;
                context.startAbility(want).then(() => { //拉起成功
                  console.info('拉起应用商店成功')
                }).catch((e: BusinessError) => { // 拉起失败
                  console.info('拉起应用商店失败')
                });
              })
              .fontColor(Color.Blue)
              .fontSize(12);
          };
        }
        .width('100%')
        .height(60);
      }
      .height('100%')
      .title($r('app.string.aboutpage'))
      //.titleMode(NavigationTitleMode.Mini)
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