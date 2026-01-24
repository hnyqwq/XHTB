import { CommonConstants } from '../constants/CommonConstants';
import { navigationManager } from '../common/NavigationManager';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { router } from '@kit.ArkUI';

@Component
export default struct GridItemComponent {
  itemName: ResourceStr = '';
  itemImage: Resource = $r('app.media.ic_grid_item_entrances_icon');
  @State isPressed: boolean = false;
  // 页面路径参数，支持 ResourceStr 或 string 类型
  pageUrl: ResourceStr | string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @StorageProp('SecondPageSplitMode') secondPageSplitMode: boolean = false;

  build() {

    GridItem() {
      Column() {
        Image(this.itemImage)
          .width($r('app.float.grid_item_image_size'))
          .height($r('app.float.grid_item_image_size'))
        Text(this.itemName)
          .fontSize($r('app.float.grid_item_name_font_size'))
          .textAlign(TextAlign.Center)
          .margin({ top: $r('app.float.grid_item_name_top_margin') })
          .height($r('app.float.grid_item_name_height'))
      }
      .height(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.isPressed ? $r('app.color.pressed_color') : Color.Transparent)
      .borderRadius($r('app.float.grid_item_border_radius'))
    }
    .height($r('app.float.grid_item_height'))
    .onClick(() => {
      console.info(`========== GridItem点击开始 ==========`);
      console.info(`Clicked on ${this.itemName}`);
      // 如果设置了页面路径，则进行跳转
      if (this.pageUrl !== '') {
        // 确保 pageUrl 是 string 类型
        let url: string = '';
        if (typeof this.pageUrl === 'string') {
          url = this.pageUrl;
        } else {
          // Resource类型，尝试转换为字符串
          url = this.pageUrl.toString();
        }

        console.info(`url类型: ${typeof this.pageUrl}, url值: ${url}`);
        console.info(`secondPageSplitMode: ${this.secondPageSplitMode}`);

        // 检查是否在分栏模式
        const useSplitLayout = this.secondPageSplitMode;

        console.info(`GridItem点击: url=${url}, secondPageSplitMode=${this.secondPageSplitMode}, useSplitLayout=${useSplitLayout}`);

        if (useSplitLayout) {
          // 分栏模式：更新AppStorage而不是跳转
          AppStorage.setOrCreate('SecondPageRightPage', url);
          console.info(`✅ 分栏模式: 更新右侧页面为 ${url}`);
        } else {
          // 普通模式：使用NavigationManager进行页面跳转
          console.info(`❌ 普通模式: 跳转到 ${url}`);
          navigationManager.pushPath(url);
        }
        console.info(`========== GridItem点击结束 ==========`);
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }

  // 从 URL 中提取页面名称
  private extractPageName(url: string): string {
    // 从路径中提取最后一个非空片段
    const parts = url.split('/');
    const lastPart = parts[parts.length - 1].replace('.ets', '');
    // 如果是 XHTB/XXXPage 格式，提取 XXXPage
    if (url.includes('XHTB/')) {
      return lastPart;
    }
    return lastPart;
  }
}