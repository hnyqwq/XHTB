export class VideoDataModel {
  private videoMap: Map<number, Resource>;

  constructor(videoMap: Map<number, Resource>) {
    this.videoMap = videoMap;
  }

  getVideoMap(): Map<number, Resource> {
    return this.videoMap;
  }

  getVideo(index: number): Resource {
    return this.videoMap.get(index)!;
  }
}