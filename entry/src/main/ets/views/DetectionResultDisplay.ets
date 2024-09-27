import { DefectClass, DetectionResultClass, RawDetectionResultClass, DefectNameClass } from "../model/DetectionResultsClasses";
import { DefectColorMapper } from "../model/DefectColorMapper"
import {ImageUtil, LogUtil, getPixelMapSize, getPixelMapSizeSync} from "../util/ImageUtils"
@Component
export struct DetectionResultDisplay {
  resultPrecision: number | undefined = 0;
  @Prop detectionResult: DetectionResultClass;
  private srcImgPath: string | undefined = undefined
  private pixWidth: number = 0;
  private pixHeight: number = 0;
  private scaleNum: number = 1;
  @State scaledHeight: number = 0;
  private defectColorMapper: DefectColorMapper = new DefectColorMapper();
  private windowWidth: number | undefined = undefined
  @State selectedDefects: DefectNameClass[] = [];
  @State availableDefects: DefectNameClass[] = [];

  //settings
  @StorageLink("displayConfThreshold") displayConfThreshold: number = 0.25;
  aboutToAppear() {
    // 初始化可用的缺陷类型和已选择的缺陷类型
    this.availableDefects = Array.from(new Set(this.detectionResult.results.map(defect => defect.cls)));
    this.selectedDefects = [...this.availableDefects];
  }

  build() {
      Column() {
        // 添加复选框区域
        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            ForEach(this.availableDefects, (defectType: DefectNameClass) => {
              Row() {
                Checkbox()
                  .select(this.selectedDefects.includes(defectType))
                  .onChange((value: boolean) => {
                    if (value) {
                      this.selectedDefects.push(defectType);
                    } else {
                      this.selectedDefects = this.selectedDefects.filter(d => d !== defectType);
                    }
                  })
                Text(defectType)
                  .fontSize(14)
                  .margin({ left: 5 })
              }
              .margin(5)
            })
          }
          .padding(10)
        }
        .height(100)
        .width('100%')
        //.backgroundColor('#f0f0f0')
        .borderRadius(8)
        .margin({ bottom: 10 })

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

            ForEach(this.detectionResult!.results.filter(defect => 
              this.selectedDefects.includes(defect.cls) && defect.conf! >= this.displayConfThreshold
            ), (defect: DefectClass) => {
              if (this.selectedDefects.includes(defect.cls)) {
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
              }
            });
          }
          .backgroundImage(this.srcImgPath)
          .backgroundImageSize(ImageSize.Contain)
          .width("100%")
          .shadow(ShadowStyle.OUTER_DEFAULT_XS);
        }

        // 添加置信度阈值滑动条
        Column() {
          Row() {
            Text('置信度阈值:')
              .fontSize(14)
              .fontColor(Color.Black)
            Text(this.displayConfThreshold.toFixed(2))
              .fontSize(14)
              .fontColor(Color.Blue)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 10, bottom: 5 })

          Slider({
            value: this.displayConfThreshold,
            min: 0,
            max: 1,
            step: 0.01,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .onChange((value: number) => {
              this.displayConfThreshold = value;
            })
        }
        .padding(10)
        //.backgroundColor('#f0f0f0')
        .borderRadius(8)
        .margin({ top: 10, bottom: 10 })

        this.DefectResultList();
      }
  }

  @Builder
  DefectResultList() {
    Column() {
      Row() {
        Text("编号")
          .fontFamily('HarmonyHeiTi')
          .fontSize(12)
          .fontWeight(600)
          .width('10%');

        Text("类型")
          .fontFamily('HarmonyHeiTi')
          .fontSize(12)
          .fontWeight(600)
          .width('25%');

        Text("位置(y1,x1,y2,x2)")
          .fontFamily('HarmonyHeiTi')
          .fontSize(12)
          .fontWeight(600)
          .width('50%');

        Text("置信度")
          .fontFamily('HarmonyHeiTi')
          .fontSize(12)
          .fontWeight(600)
          .width('15%');
      }
      .listHeader();

      ForEach(this.detectionResult!.results.filter(defect => 
        this.selectedDefects.includes(defect.cls) && defect.conf! >= this.displayConfThreshold
      ), (defect: DefectClass) => {
        Row() {
          Text(`${parseInt(defect.id.split('_')[3])}`)
            .fontFamily('HarmonyHeiTi')
            .fontSize(16)
            .fontWeight(500)
            .width('10%');

          Text(`${defect.cls}`)
            .fontFamily('HarmonyHeiTi')
            .fontSize(16)
            .fontWeight(500)
            .width('25%');

          Text(`${defect.x1?.toFixed(this.resultPrecision)}, ${defect.y1?.toFixed(this.resultPrecision)}, ${defect.x2?.toFixed(this.resultPrecision)}, ${defect.y2?.toFixed(this.resultPrecision)}`)
            .fontFamily('HarmonyHeiTi')
            .fontSize(16)
            .fontWeight(500)
            .width('50%');

          Text(`${defect.conf?.toFixed(2)}`)
            .fontFamily('HarmonyHeiTi')
            .fontSize(16)
            .fontWeight(500)
            .width('15%');
        }
        .listItem();
      }, (defect: DefectClass) => defect.id);
    }
  }
}

@Styles function listHeader() {
  .padding({ top: 10, bottom: 10 })
  // 使用十六进制颜色代码替代 Color.LightGray
  .backgroundColor('#FFFFFF')
  .margin({ top: 5 })
  .borderRadius(8)
  .shadow(ShadowStyle.OUTER_DEFAULT_XS);
}

@Styles function listItem() {
  .padding({ top: 10, bottom: 10 })
  .backgroundColor("#FFFFFF") // 使用十六进制颜色代码替代 Color.White
  .margin({ top: 5 })
  .borderRadius(8);
}
