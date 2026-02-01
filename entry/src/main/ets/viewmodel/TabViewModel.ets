import { TabDataModel } from '../model/TabDataModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

export class TabViewModel {
  private tabMap: TabDataModel;
  private context: common.UIAbilityContext | undefined;

  constructor() {
    let tabMap: Map<string, string[]> = new Map();
    try {
      // 延迟获取context，避免在模块加载时执行
      this.initContext();
      if (this.context) {
        tabMap.set(this.context.resourceManager.getStringSync($r('app.string.Home').id), []);
        tabMap.set(this.context.resourceManager.getStringSync($r('app.string.Second').id), []);
        tabMap.set(this.context.resourceManager.getStringSync($r('app.string.Mine').id), []);
      } else {
        // 如果context未初始化，使用默认值
        tabMap.set('首页', []);
        tabMap.set('发现', []);
        tabMap.set('我的', []);
      }
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to get string. Cause: %{public}s', JSON.stringify(error) ?? '');
      // 使用默认值
      tabMap.set('首页', []);
      tabMap.set('发现', []);
      tabMap.set('我的', []);
    }
    this.tabMap = new TabDataModel(tabMap);
  }

  private initContext(): void {
    if (!this.context) {
      try {
        const uiContext: UIContext | undefined = AppStorage.get('uiContext');
        if (uiContext) {
          this.context = uiContext.getHostContext() as common.UIAbilityContext;
        }
      } catch (error) {
        hilog.error(0x0000, 'testTag', 'Failed to get context. Cause: %{public}s', JSON.stringify(error) ?? '');
      }
    }
  }

  getTabMap(): TabDataModel {
    return this.tabMap;
  }

  getTabNameOfFirstLevel(index: number): string {
    return this.tabMap.getFirstList()[index];
  }

  getTabNameOfSecondLevel(firstTab: string, index: number): string {
    return this.tabMap.getSecondList(firstTab)[index];
  }
}