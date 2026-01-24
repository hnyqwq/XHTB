/**
 * Navigation路由管理工具
 * 用于管理应用的路由跳转和导航栈
 * 注意: 当前实现主要使用router API,保留Navigation相关代码以便将来迁移
 */

import { router } from '@kit.ArkUI';

// 定义页面路径类型
export type PagePath = string;

/**
 * Navigation路由管理类
 * 提供统一的导航跳转接口
 */
export class NavigationManager {
  private static instance: NavigationManager;
  private navPathStack: NavPathStack | undefined;
  private useNavigation: boolean = false; // 控制是否使用Navigation组件

  private constructor() {}

  /**
   * 获取NavigationManager单例
   */
  public static getInstance(): NavigationManager {
    if (!NavigationManager.instance) {
      NavigationManager.instance = new NavigationManager();
    }
    return NavigationManager.instance;
  }

  /**
   * 设置NavPathStack
   */
  public setNavPathStack(stack: NavPathStack): void {
    this.navPathStack = stack;
  }

  /**
   * 设置是否使用Navigation组件
   * @param use 是否使用Navigation
   */
  public setUseNavigation(use: boolean): void {
    this.useNavigation = use;
  }

  /**
   * 获取NavPathStack
   */
  public getNavPathStack(): NavPathStack | undefined {
    return this.navPathStack;
  }

  /**
   * 页面跳转
   * @param path 页面路径
   * @param params 传递的参数
   */
  public pushPath(path: PagePath, params?: ESObject): void {
    // 当前主要使用router
    console.info(`NavigationManager: 跳转到页面 ${path}`);
    this.routerFallback(path, params);
  }

  /**
   * Router路由实现
   */
  private routerFallback(path: PagePath, params?: ESObject): void {
    // 规范化路径，确保完整路径
    let normalizedPath = path;

    // 如果路径不包含前缀，根据规则添加
    if (!path.startsWith('pages/') && !path.startsWith('XHTB/')) {
      // 检查路径中是否包含斜杠
      if (path.includes('/')) {
        normalizedPath = path; // 保持原路径
      } else {
        normalizedPath = path; // 保持原路径,由GridListDataSources中定义
      }
    }

    router.pushUrl({
      url: normalizedPath,
      params: params
    }).catch((err: Error) => {
      console.error('NavigationManager: 路由跳转失败', err);
    });
  }

  /**
   * 页面替换
   * @param path 页面路径
   * @param params 传递的参数
   */
  public replacePath(path: PagePath, params?: ESObject): void {
    router.replaceUrl({
      url: path,
      params: params
    }).catch((err: Error) => {
      console.error('NavigationManager: 路由替换失败', err);
    });
  }

  /**
   * 返回上一页
   */
  public pop(): void {
    router.back();
  }

  /**
   * 返回到指定页面
   * @param name 页面名称
   * @param params 传递的参数
   */
  public popToName(name: PagePath, params?: ESObject): void {
    console.warn('NavigationManager: popToName暂不支持,使用清空并跳转');
    router.clear();
    router.pushUrl({
      url: 'pages/Index',
      params: params
    }).catch((err: Error) => {
      console.error('NavigationManager: 返回首页失败', err);
    });
  }

  /**
   * 返回到首页
   * @param params 传递的参数
   */
  public popToRoot(params?: ESObject): void {
    router.clear();
    router.pushUrl({
      url: 'pages/Index',
      params: params
    }).catch((err: Error) => {
      console.error('NavigationManager: 返回首页失败', err);
    });
  }

  /**
   * 清空导航栈并跳转到指定页面
   * @param path 页面路径
   * @param params 传递的参数
   */
  public clearAndPush(path: PagePath, params?: ESObject): void {
    router.clear();
    router.pushUrl({
      url: path,
      params: params
    }).catch((err: Error) => {
      console.error('NavigationManager: 清空并跳转失败', err);
    });
  }

  /**
   * 获取当前页面参数
   */
  public getParams(): ESObject | undefined {
    const params: ESObject | null = router.getParams() as ESObject | null;
    return params ? params : undefined;
  }
}

// 导出单例实例
export const navigationManager = NavigationManager.getInstance();
