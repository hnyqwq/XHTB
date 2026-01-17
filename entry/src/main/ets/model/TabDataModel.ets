export class TabDataModel {
  private tabMap: Map<string, string[]>;

  constructor(tabMap: Map<string, string[]>) {
    this.tabMap = tabMap;
  }

  getTabMap(): Map<string, string[]> {
    return this.tabMap;
  }

  getFirstList(): string[] {
    let firstList: string[] = [];
    let index: number = 0;
    this.tabMap.forEach((_value: string[], key: string) => {
      firstList[index] = key;
      index++;
    }, (value: string[], key: string) => JSON.stringify(value) + key);
    return firstList;
  }

  getSecondList(firstTab: string): string[] {
    if (this.tabMap.has(firstTab) && this.tabMap.get(firstTab)) {
      return this.tabMap.get(firstTab)!;
    } else {
      return [];
    }
  }
}