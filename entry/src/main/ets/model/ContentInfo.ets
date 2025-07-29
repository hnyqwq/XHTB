export class ContentInfo {
  networkVideoSrc: string | undefined;

  constructor(
    networkVideoSrc: string | undefined,
  ) {
    this.networkVideoSrc = networkVideoSrc;
  }
}

export interface ImageInfo {
  imagePixelMap: PixelMap;
  imageName: string;
}
