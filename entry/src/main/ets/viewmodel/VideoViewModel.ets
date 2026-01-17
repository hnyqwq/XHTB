import { VideoDataModel } from '../model/VideoDataModel';

export class VideoViewModel {
  private videoMap: VideoDataModel;

  constructor() {
    let videoMap: Map<number, Resource> = new Map();
    this.videoMap = new VideoDataModel(videoMap);
  }

  getVideo(index: number): Resource {
    return this.videoMap.getVideo(index);
  }
}