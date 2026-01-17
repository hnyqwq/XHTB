/**
 * Loading status enum.
 */
export enum LoadingStatus {
  IDLE = 'idle',
  OFF = 'off',
  LOADING = 'loading',
  SUCCESS = 'success',
  FAILED = 'failed',
  NO_NETWORK = 'no_network',
}

/**
 * GridRow column.
 */
export enum ColumnEnum {
  SM = 4,
  MD = 8,
  LG = 12,
}

/**
 * Module name.
 */

export enum ModuleNameEnum {
  COMPONENT_LIST = 'componentListView',
  COMPONENT_DETAIL = 'componentDetailView',
  CODE_PREVIEW = 'codePreview',
  ARTICLE_DETAIL = 'articleDetail',
}

/**
 * Web component scroll direction
 */
export enum ScrollDirectionEnum {
  UP = 'up',
  DOWN = 'down'
}

export enum ProductSeriesEnum {
  HPR = 'HPR', // fordable PC
  VDE = 'VDE',
}