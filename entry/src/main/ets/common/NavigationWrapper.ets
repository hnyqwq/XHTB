/**
 * Navigation包装组件
 * 用于将普通页面组件包装为NavDestination
 */
import { navigationManager } from './NavigationManager';

/**
 * NavDestination装饰器包装函数
 * 将普通组件转换为NavDestination
 */
export function wrapAsNavDestination() {
  return function(target: any) {
    // 这里可以添加额外的处理逻辑
    // 实际使用时,需要在页面组件上直接使用@NavDestination装饰器
  };
}

/**
 * 获取当前NavDestination的上下文
 * 在NavDestination组件中使用
 */
export function getNavContext(): NavDestinationContext | undefined {
  return (this as any).getUIContext().getNavContext();
}
