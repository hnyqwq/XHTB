import { Home } from '../view/Home';
import { navigationManager } from '../common/NavigationManager';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

@Entry
@Component
struct Index
{
  // 创建NavPathStack用于管理路由栈(虽然目前主要使用router,但保留以备将来使用)
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack();
  @StorageLink('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;

  aboutToAppear(): void {
    // 将NavPathStack设置到NavigationManager
    // 注意: 当前实现主要使用router,NavPathStack暂不启用
    // 如果将来需要使用Navigation,可以在这里初始化
    console.info('Index: 页面初始化,主要使用router进行路由');
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