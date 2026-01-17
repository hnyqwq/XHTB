import { Home } from '../view/Home';

@Entry
@Component
struct Index
{
  build()
  {
    Column()
    {
      Home()
    }
    .width('100%')
    .height('100%')
  }
}