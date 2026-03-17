import { TabItem } from './TabItem';

export function initTabData(): TabItem[] {
  let tabDataArray: TabItem[] = [];
  TabItemData.forEach((item: TabItem) => {
    tabDataArray.push(new TabItem(item.id, item.name, item.icon, item.symbol));
  })
  return tabDataArray;
}

const TabItemData: TabItem[] = [
  new TabItem(0, $r('app.string.Internet1'), $r('app.media.CIcon'), $r('sys.symbol.star')),
  new TabItem(1, $r('app.string.Internet5'), $r('app.media.CIcon'), $r('sys.symbol.qrcode')),
  new TabItem(2, $r('app.string.Internet2'), $r('app.media.CIcon'), $r('sys.symbol.heart')),
  new TabItem(3, $r('app.string.Internet3'), $r('app.media.CIcon'), $r('sys.symbol.gearshape')),
  new TabItem(4, $r('app.string.Internet4'), $r('app.media.CIcon'), $r('sys.symbol.clock')),
  new TabItem(5, $r('app.string.Internet6'), $r('app.media.CIcon'), $r('sys.symbol.wifi_router')),
  new TabItem(6, $r('app.string.Internet7'), $r('app.media.CIcon'), $r('sys.symbol.speaker_wave_2'))
];