/**
 * List data constants for all features.
 */
export class ListDataConstants {
  /**
   *Service directory list
   */
  static readonly TITLE_LIST: ResourceStr[] = [
    $r('app.string.sub_title2'),
    $r('app.string.sub_title3')/*,
    $r('app.string.sub_title4'),
    $r('app.string.sub_title5'),
    $r('app.string.sub_title6')*/];


  /**
   *Swiper Menu item name list
   */
  static readonly GRID_COL_LIST: ResourceStr[][] = [
    [
      $r('app.string.sub_title7_value1'),
      $r('app.string.sub_title7_value2'),
      $r('app.string.sub_title7_value3'),
      $r('app.string.sub_title7_value4'),
      $r('app.string.sub_title7_value5'),
      $r('app.string.sub_title7_value6'),
      $r('app.string.sub_title7_value7'),
      $r('app.string.sub_title7_value8')
    ],
    [
      $r('app.string.sub_title8_value1'),
      $r('app.string.sub_title8_value2'),
      $r('app.string.sub_title8_value3'),
      $r('app.string.sub_title8_value4')
    ]
  ];

  /**
   *Swiper Menu item name list
   */
  static readonly SWIPER_IMAGE_LIST: Resource[][] = [
    [ $r('app.media.ic_swiper_grid_image0'),
      $r('app.media.ic_swiper_grid_image1'),
      $r('app.media.ic_swiper_grid_image2'),
      $r('app.media.ic_swiper_grid_image3'),
      $r('app.media.ic_swiper_grid_image4'),
      $r('app.media.ic_swiper_grid_image5'),
      $r('app.media.ic_swiper_grid_image6'),
      $r('app.media.ic_swiper_grid_image7'),
    ],
   [ $r('app.media.ic_swiper_grid_image8'),
     $r('app.media.ic_swiper_grid_image9'),
     $r('app.media.ic_swiper_grid_image10'),
     $r('app.media.ic_swiper_grid_image11')]
  ];

}