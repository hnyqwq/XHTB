import { HomeImmersive } from '../view/HomeImmersive';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

@Entry
@Component
struct IndexImmersive {
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack();
  @StorageLink('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;

  aboutToAppear(): void {
    console.info('IndexImmersive.ets aboutToAppear - API >= 23');
  }

  build() {
    Column() {
      HomeImmersive()
    }
    .width('100%')
    .height('100%')
  }
}
