@Observed
export class GlobalInfoModel {
  public foldExpanded: boolean = false;
  public currentBreakpoint: BreakpointTypeEnum = BreakpointTypeEnum.MD;
  public naviIndicatorHeight: number = 0;
  public statusBarHeight: number = 0;
  public decorHeight: number = 0;
  public deviceHeight: number = 0;
  public deviceWidth: number = 0;
  // 智感握持开关状态
  public holdingHandEnabled: boolean = false;
}

export enum BreakpointTypeEnum {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl',
}