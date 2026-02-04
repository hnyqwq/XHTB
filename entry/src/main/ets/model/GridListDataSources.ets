export class GridItemInfo {
  name: ResourceStr = '';
  pageUrl: ResourceStr | string = ''; // 页面路径，可以是 ResourceStr 或 string
  icon: Resource = $r('app.media.ic_grid_item_entrances_icon'); // 默认图标

  constructor(name: ResourceStr, pageUrl: ResourceStr | string = '', icon: Resource = $r('app.media.ic_grid_item_entrances_icon')) {
    this.name = name;
    this.pageUrl = pageUrl;
    this.icon = icon;
  }
}

export class GridData {
  groupName: ResourceStr = '';
  gridItemList: GridItemInfo[] = [];

  constructor(groupName: ResourceStr, gridItemList: GridItemInfo[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

export const featureGridData: GridData = new GridData($r('app.string.sub_title1'),
  [
    new GridItemInfo($r('app.string.sub_title1_value1'), 'XHTB/TextToSpeechPage', $r('app.media.ic_swiper_grid_image2')),
    new GridItemInfo($r('app.string.sub_title1_value2'), 'XHTB/QRCodePage', $r('app.media.ic_swiper_grid_image7')),
    new GridItemInfo($r('app.string.sub_title2_value3'), 'XHTB/DocScan/OCR', $r('app.media.ic_swiper_grid_image8')),/*
    new GridItemInfo($r('app.string.sub_title1_value3'), 'pages/MinePage'),
    new GridItemInfo($r('app.string.sub_title1_value4'), 'pages/infoPage'),
    new GridItemInfo($r('app.string.sub_title1_value5'), 'XHTB/ReadQR'),
    new GridItemInfo($r('app.string.sub_title1_value6')),
    new GridItemInfo($r('app.string.sub_title1_value7'))*/
  ]);

export const
  otherGridDataList: GridData[] = [
    new GridData($r('app.string.sub_title2'),
      [
        new GridItemInfo($r('app.string.sub_title2_value1'), 'XHTB/TextToSpeechPage', $r('app.media.ic_swiper_grid_image2')),
        new GridItemInfo($r('app.string.sub_title2_value2'), 'XHTB/QRCodePage', $r('app.media.ic_swiper_grid_image11')),
        new GridItemInfo($r('app.string.sub_title2_value3'), 'XHTB/DocScan/OCR', $r('app.media.ic_swiper_grid_image8')),
        /*new GridItemInfo($r('app.string.sub_title2_value4'), 'pages/infoPage'),
        new GridItemInfo($r('app.string.sub_title2_value5'), 'XHTB/ReadQR'),
        new GridItemInfo($r('app.string.sub_title2_value6')),
        new GridItemInfo($r('app.string.sub_title2_value7')),
        new GridItemInfo($r('app.string.sub_title2_value8')),
        new GridItemInfo($r('app.string.sub_title2_value9')),
        new GridItemInfo($r('app.string.sub_title2_value10')),
        new GridItemInfo($r('app.string.sub_title2_value11')),
        new GridItemInfo($r('app.string.sub_title2_value12')),
        new GridItemInfo($r('app.string.sub_title2_value13')),
        new GridItemInfo($r('app.string.sub_title2_value14'))*/



      ]),
    new GridData($r('app.string.sub_title3'),
      [
        new GridItemInfo($r('app.string.sub_title3_value1'), 'XHTB/Internet', $r('app.media.ic_swiper_grid_image7'))/*,
        new GridItemInfo($r('app.string.sub_title3_value2'), 'XHTB/Internet', $r('app.media.ic_swiper_grid_image5')),
        new GridItemInfo($r('app.string.sub_title3_value3'), 'pages/MinePage')*/
      ]),


    /*new GridData($r('app.string.sub_title4'),
      [
        new GridItemInfo($r('app.string.sub_title4_value1'), 'XHTB/Metro'),
        /*new GridItemInfo($r('app.string.sub_title4_value2'), 'pages/ReadQR'),
        new GridItemInfo($r('app.string.sub_title4_value3')),
        new GridItemInfo($r('app.string.sub_title4_value4')),
        new GridItemInfo($r('app.string.sub_title4_value5')),
        new GridItemInfo($r('app.string.sub_title4_value6'))
      ]),
    new GridData($r('app.string.sub_title5'),
      [
        new GridItemInfo($r('app.string.sub_title5_value1'), 'pages/DetailPage'),
        new GridItemInfo($r('app.string.sub_title5_value2'), 'pages/HomePage'),
        new GridItemInfo($r('app.string.sub_title5_value3'), 'pages/MinePage'),
        new GridItemInfo($r('app.string.sub_title5_value4'), 'pages/infoPage'),
        new GridItemInfo($r('app.string.sub_title5_value5'), 'pages/ReadQR'),
        new GridItemInfo($r('app.string.sub_title5_value6'))]),
    new GridData($r('app.string.sub_title6'), [
      new GridItemInfo($r('app.string.sub_title6_value1')),
      new GridItemInfo($r('app.string.sub_title6_value2')),
      new GridItemInfo($r('app.string.sub_title6_value3')),
      new GridItemInfo($r('app.string.sub_title6_value4')),
      new GridItemInfo($r('app.string.sub_title6_value5')),
      new GridItemInfo($r('app.string.sub_title6_value6')),
      new GridItemInfo($r('app.string.sub_title6_value7')),
      new GridItemInfo($r('app.string.sub_title6_value8'))]),*/
  ];