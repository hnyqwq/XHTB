export class BreakpointType<T> {
  sm: T;
  md: T;
  lg: T;
  xl: T;

  constructor(sm: T, md: T, lg: T, xl: T) {
    this.sm = sm;
    this.md = md;
    this.lg = lg;
    this.xl = xl;
  }

  getValue(currentWidthBreakpoint: string): T {
    let result: T;
    if (currentWidthBreakpoint === 'sm') {
      result = this.sm;
    } else if (currentWidthBreakpoint === 'md') {
      result = this.md;
    } else if (currentWidthBreakpoint === 'lg') {
      result = this.lg;
    } else {
      result = this.xl;
    }
    return result;
  }
}