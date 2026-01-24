import { navigationManager } from './NavigationManager';

/**
 * 通用返回按钮组件
 * 在分栏模式下不显示,在普通模式下显示
 */
@Component
export struct BackButton {
  @StorageProp('SecondPageSplitMode') secondPageSplitMode: boolean = false;

  build() {
    // 只在非分栏模式下显示返回按钮
    if (!this.secondPageSplitMode) {
      SymbolGlyph($r('sys.symbol.chevron_left_circle')) // 自定义返回图标
        .fontSize(35)
        .margin({ left: 20 }) // 左侧留白
        .onClick(() => {
          navigationManager.pop();
        })
    }
  }
}
