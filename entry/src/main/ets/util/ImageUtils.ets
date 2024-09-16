import { ImageUtil, LogUtil } from '@pura/harmony-utils';


export async function getPixelMapSize(srcImgPath: string):   Promise<[number, number]> {
  if(!srcImgPath) return [0,0]
  const pixelMap = await ImageUtil.createImageSource(srcImgPath).createPixelMap({ sampleSize: 1, editable: true });
  const imageInfo = await pixelMap.getImageInfo();
  let pixWidth = imageInfo.size.width;
  let pixHeight = imageInfo.size.height;
  return [pixWidth, pixHeight]
}

export function getPixelMapSizeSync(srcImgPath: string):   [number, number] {
  if(!srcImgPath) return [0,0]
  const pixelMap = ImageUtil.createImageSource(srcImgPath).createPixelMapSync({ sampleSize: 1, editable: true });
  const imageInfo = pixelMap.getImageInfoSync()
  let pixWidth = imageInfo.size.width;
  let pixHeight = imageInfo.size.height;
  return [pixWidth, pixHeight]
}

export { ImageUtil, LogUtil};
