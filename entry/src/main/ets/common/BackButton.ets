import { navigationManager } from './NavigationManager';
import { router } from '@kit.ArkUI';

/**
 * 通用返回按钮组件
 * 在分栏模式下不显示,在普通模式下显示
 */
@Component
export struct BackButton {
  @StorageProp('SecondPageSplitMode') secondPageSplitMode: boolean = false;
  @StorageProp('isContinuation') isContinuation: boolean = false;

  build() {
    // 只在非分栏模式下显示返回按钮
    if (!this.secondPageSplitMode) {
      SymbolGlyph($r('sys.symbol.chevron_left_circle')) // 自定义返回图标
        .fontSize(35)
        .fontColor([$r('app.color.font_primary')])
        .margin({ left: 20 }) // 左侧留白
        .onClick(() => {
          console.info('BackButton onClick: isContinuation=', this.isContinuation);

          // 接续场景下，使用 router.replaceUrl 返回到首页
          // 否则使用 navigationManager.pop() 正常返回
          if (this.isContinuation) {
            router.replaceUrl({
              url: 'pages/Index'
            }).catch((err: Error) => {
              console.error('Failed to return to Index:', err);
            });
            // 清除接续标记
            AppStorage.delete('isContinuation');
          } else {
            navigationManager.pop();
          }
        })
    }
  }
}
