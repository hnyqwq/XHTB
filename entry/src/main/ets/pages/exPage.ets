import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

import userAuth from '@ohos.userIAM.userAuth';
import { promptAction } from '@kit.ArkUI';
const TAG = 'User_Auth';

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
export struct exPage {
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;
  //设置条目信息数组
  @State menuGroup: SettingMenu[] = [
    new SettingMenu('setting', $r('app.media.mine_settings'), '想亲亲你的小脸 =-= ', $r('app.string.void')),
    new SettingMenu('vipownsetting', $r('app.media.mine_vipsettings'), '想摸摸你的小手指 QwQ ', $r('app.string.void')),
    new SettingMenu('mycollection', $r('app.media.ic_collect'), '想看看你的密码 awa ', $r('app.string.void')),
    //new SettingMenu('mylike', $r('app.media.mine_like'), '关注抖音', $r('app.string.void')),
    //new SettingMenu('browsinghistory', $r('app.media.mine_time'), '前往个人博客', $r('app.string.void'))
  ];

  @State message: string = '用户认证'
  @State userAuthResult?: userAuth.UserAuthResult = undefined

  build() {
    Stack() {
      Navigation() {
        Column() {
          Image($r('app.media.CIcon'))
            .width(60)
            .height(60);
          Text('by hnyqwq')
            .fontWeight(700)
            .fontSize('14fp')
            .margin({ top: 10 });
          Text('1.3.2.0（10302000）')
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
                      case 'setting': {// 1
                        const authParam: userAuth.AuthParam = {
                          challenge: new Uint8Array([49,49,49,49,49,49]),
                          authType: [userAuth.UserAuthType.FACE],
                          authTrustLevel: userAuth.AuthTrustLevel.ATL1
                        }
                        const widgetParam: userAuth.WidgetParam = { title: '请认证人脸' }
                        this.startUserAuth(authParam, widgetParam)
                        promptAction.showToast({ duration: 8000, message: '看到啦~ つ♡⊂' })
                        break;}
                      case 'vipownsetting': {// 2
                        const authParam : userAuth.AuthParam = {
                          challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                          authType: [userAuth.UserAuthType.FINGERPRINT],
                          authTrustLevel: userAuth.AuthTrustLevel.ATL1,
                        }
                        const widgetParam :userAuth.WidgetParam = {
                          title: '把你的小手手放在指纹感应区~~'
                        }
                        this.startUserAuth(authParam, widgetParam)
                        promptAction.showToast({duration: 8000,message: '摸到啦~  ⑉･ᴗ･⑉'});
                        break;}
                      case 'mycollection':{ // 3
                        const authParam : userAuth.AuthParam = {
                          challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
                          authType: [userAuth.UserAuthType.PIN],
                          authTrustLevel: userAuth.AuthTrustLevel.ATL2,
                        }
                        const widgetParam :userAuth.WidgetParam = {
                          title: '让我来瞅瞅你的锁屏密码是多少！！'
                        }
                        this.startUserAuth(authParam, widgetParam)
                        promptAction.showToast({duration: 8000,message: '猜到啦~  ⌯\'▾\'⌯'});
                        break;}
                      /*case 'mylike': // 分享功能（需集成分享SDK）
                        uri =
                          'https://m.douyin.com/share/user/MS4wLjABAAAAu-191qiFh5x3NLdZXeT7y8uMMhqaT9ZQCdgpe1H2ZIcEVCCoGrpDeuRb5diMrBmd';
                        break
                        // harmonyShare.share(...);
                        break;
                      case 'browsinghistory': // 第三方清单
                        uri = 'https://hnyqwq.cn/hvideo/list.html';
                        break;*/
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
          /*Text() {
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
          };*/

          Text($r('app.string.copyright'))
            .fontSize(12);
          Text() {
            Span($r('app.string.exunder'))
              .onClick(() => {
                //const want: Want = { uri: `store://appgallery.huawei.com/app/detail?id=com.chuckfang.meow` };
                const want: Want = { uri: `https://www.chuckfang.com/MeoW/appLinking?channelId=9687404a1b84433184ba27f16a57da3e` };
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
      .title($r('app.string.expagetitle'))
      .titleMode(NavigationTitleMode.Mini)
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ top: 50 })
    };
  }startUserAuth (authParam: userAuth.AuthParam, widgetParam: userAuth.WidgetParam) {
  try {
    const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
    userAuthInstance.on('result', {
      onResult: (result) => {
        // 认证成功
        if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
          this.userAuthResult = result
          console.log(TAG, 'userAuthInstance callback result ' + JSON.stringify(result));
          promptAction.showToast({ duration: 10000, message: '认证成功~ ⌯>₃<⌯' });
        }
      }
    })
    userAuthInstance.start()
  } catch (e) {
    promptAction.showToast({
      message: `拉起用户认证失败 ${e.code} ${e.message}`
    })
  }
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