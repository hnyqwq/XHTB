import { TabDataModel } from '../model/TabDataModel';
import { hilog } from '@kit.PerformanceAnalysisKit';

const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context = uiContext!.getHostContext()!;

export class TabViewModel {
  private tabMap: TabDataModel;

  constructor() {
    let tabMap: Map<string, string[]> = new Map();
    try {
      tabMap.set(context.resourceManager.getStringSync($r('app.string.Home').id), []);
      tabMap.set(context.resourceManager.getStringSync($r('app.string.Second').id), []);
      tabMap.set(context.resourceManager.getStringSync($r('app.string.Mine').id), []);
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to get string. Cause: %{public}s', JSON.stringify(error) ?? '');
    }
    this.tabMap = new TabDataModel(tabMap);
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