import { CapsuleSegmentButtonV2, SegmentButtonV2Items } from '@kit.ArkUI';

@ComponentV2
export struct DeviceSegmentButton {
  @Local selectedIndex: number = 0;
  @Param initialIndex: number = 0;
  @Param onIndexChange: (index: number) => void = () => {};

  private textItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '碰一碰传送预览' },
    { text: '隔空传送预览' },
  ]);

  aboutToAppear(): void {
    // 使用传入的初始索引
    this.selectedIndex = this.initialIndex;
  }

  build() {
    CapsuleSegmentButtonV2({
      items: this.textItems,
      selectedIndex: this.selectedIndex,
      onItemClicked: (index: number) => {
        this.selectedIndex = index;
        this.onIndexChange(index);
      }
    })
      .width('100%')
      .height(40)
  }
}
