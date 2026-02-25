import { Home } from '../view/Home';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

@Entry
@Component
struct Index
{
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack();
  @StorageLink('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;

  aboutToAppear(): void {
    console.info('Index.ets aboutToAppear');
  }

  build()
  {
    Column() {
      Home()
    }
    .width('100%')
    .height('100%')
  }
}