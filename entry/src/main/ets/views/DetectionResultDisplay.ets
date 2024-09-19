import { DefectClass, DetectionResultClass, RawDetectionResultClass, DefectNameClass } from "../model/DetectionResultsClasses";
import { DefectColorMapper } from "../model/DefectColorMapper"
import {ImageUtil, LogUtil, getPixelMapSize, getPixelMapSizeSync} from "../util/ImageUtils"
@Component
export struct DetectionResultDisplay {
  @Prop detectionResult: DetectionResultClass;
  private srcImgPath: string | undefined = undefined
  private pixWidth: number = 0;
  private pixHeight: number = 0;
  private scaleNum: number = 1;
  @State scaledHeight: number = 0;
  private defectColorMapper: DefectColorMapper = new DefectColorMapper();
  private windowWidth: number | undefined = undefined

  build() {
      Column() {
        Blank().width('100%').height(1)
          .onSizeChange( (oldValue, newValue) => {
            this.windowWidth = Number(newValue.width);

            // 求scaleNum和scaledHeight
            this.srcImgPath = this.detectionResult.imagePath!
            console.info( "srcImgPath:" + this.srcImgPath)
            let imageSize: Array<number> =  getPixelMapSizeSync(this.srcImgPath!)
            this.pixWidth = imageSize[0];
            this.pixHeight = imageSize[1];
            console.log( "pixWidth:" + this.pixWidth + "  pixHeight:" + this.pixHeight)

            this.scaleNum = this.windowWidth / this.pixWidth!;
            this.scaledHeight = this.pixHeight! * this.scaleNum; //更新之后会立即渲染shape
            console.log( "display windowWidth:" + this.windowWidth + "  scaledHeight:" + this.scaledHeight)

          });
        if(this.scaledHeight){
          Shape() {
            Rect().width(1).height(1)
              .offset({ x: this.windowWidth, y: this.scaledHeight });

            ForEach(this.detectionResult!.results, (defect: DefectClass) => {
              Text(`${defect.cls}:${defect.conf!.toFixed(2)}`)
                .offset({ x: defect.x1! * this.scaleNum, y: defect.y1! * this.scaleNum - 10 })
                .fontColor(this.defectColorMapper.getColor(defect.cls))
                .fontSize(8) // 添加字体大小
                .fontWeight(400) // 添加字体粗细

              Rect()
                .width((defect.x2! - defect.x1!) * this.scaleNum)
                .height((defect.y2! - defect.y1!) * this.scaleNum)
                .offset({ x: defect.x1! * this.scaleNum, y: defect.y1! * this.scaleNum })
                .stroke(this.defectColorMapper.getColor(defect.cls))
                .strokeWidth(0.5)
                .fillOpacity(0);
            });
          }
          .backgroundImage(this.srcImgPath)
          .backgroundImageSize(ImageSize.Contain)
          .width("100%")
          .shadow(ShadowStyle.OUTER_DEFAULT_XS);
        }

      }
  }
}