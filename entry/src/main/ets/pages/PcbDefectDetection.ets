import { Defect, DetectionResultClass, RawDetectionResultClass, DefectClass} from "../model/DetectionResultsClass"
import image from '@ohos.multimedia.image';
import { PhotoPickerUtils } from '../util/PhotoPickerUtils';
import { ToastUtils } from '../util/ToastUtils';
import { PermissionUtils } from '../util/PermissionUtils';
import { sendDetectRequest, parseDetectionResult} from '../util/DetectionUtils'
import { DateUtil, FileUtil, ImageUtil, LogUtil, ToastUtil, DeviceUtil} from '@pura/harmony-utils';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

AppStorage.setOrCreate('detectionResultHistory',[]);

class DefectColorMapper {
  private colorMap: Map<string, Color>;

  constructor() {
    // 初始化缺陷类型与颜色的映射关系
    this.colorMap = new Map<string, Color>([
      ['Mouse_bite', Color.Blue],
      ['Open_circuit', Color.Pink],
      ['Short', Color.Red],
      ['Spur', Color.Orange],
      ['Spurious_copper', Color.Yellow]
    ]);
  }

  // 获取缺陷对应的颜色，如果未找到则返回默认颜色
  getColor(cls: string): Color {
    return this.colorMap.get(cls) || Color.Red;
  }
}

@Component
@Preview
export struct PcbDefectDetection {
  @State resultPrecision: number = 0;
  @State selectedUri:string = ''
  @State resultPicPixelMap:PixelMap | undefined = undefined
  @State detectionResult: DetectionResultClass | undefined = undefined
  @StorageLink('detectionResultHistory') userList: Array<DetectionResultClass> = [];

  @State srcImgPath: string = ''
  @State windowWidth: number = 0;
  // 检测结果pixelMap
  @State pixWidth: number = 0;
  @State pixHeight: number = 0;
  // 新增的状态变量，用来存储缩放因子和等比例缩放后的高度
  @State scaleNum: number = 1;
  @State scaledHeight: number = 0;

  //表格表头大小
  @State columnWidth1: string = '10%'
  @State columnWidth2: string = '25%'
  @State columnWidth3: string = '50%'
  @State columnWidth4: string = '15%'
  private defectColorMapper: DefectColorMapper = new DefectColorMapper();
  aboutToAppear(){

  }
  build() {

    Scroll() {
      Column() {
        Text('实时检测页')
          .fontFamily('HarmonyHeiTi-Bold').fontSize(24).fontColor(Color.Black).textAlign(TextAlign.Start).lineHeight(33).fontWeight(700).width('100%')

        Column() {
          Text("选择图片")
            .fontFamily('HarmonyHeiTi-Bold').fontSize(18).fontColor(Color.Black).textAlign(TextAlign.Start).lineHeight(33).fontWeight(350).width('100%')

          Image(this.srcImgPath ? this.srcImgPath : $r("app.media.image_placeholder"))
            .width('100%')
            .margin({ top: 19, bottom: 8 })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)

            Button("选择图片/拍照")
              .btnDefaultStyle()
              .fontFamily('HarmonyHeiTi-Bold')
              .fontSize(18)
              .fontColor(Color.Black)
              .fontWeight(350)
              .onClick(async () => {
                PhotoPickerUtils.openGallery(
                  async uri => {
                    this.srcImgPath = uri;
                    let tmpPixelMap = await ImageUtil.createImageSource(this.srcImgPath).createPixelMap({
                      sampleSize: 1,
                      editable: true  // Make the PixelMap editable

                    })

                    this.resultPicPixelMap = tmpPixelMap

                    // 获取 PixelMap 的宽高，并存储在状态中
                    await this.resultPicPixelMap?.getImageInfo().then((imageInfo) => {
                      this.pixWidth = imageInfo.size.width;
                      this.pixHeight = imageInfo.size.height;

                      // 计算缩放因子和等比例缩放后的高度
                      this.scaleNum = this.windowWidth / this.pixWidth;
                      this.scaledHeight = this.pixHeight * this.scaleNum;

                      console.info(`Image Width: ${this.pixWidth}, Image Height: ${this.pixHeight}`);
                      console.info(`Window Width: ${this.windowWidth}`);
                      console.info(`Scale Factor: ${this.scaleNum}`);
                      console.info(`Scaled Height: ${this.scaledHeight}`);
                    }).catch((err:BusinessError) => {
                      console.error("Failed to get image info:", err);
                    });
                  }, errMsg => {
                  ToastUtils.show(errMsg)
                })

              })

            Button("开始预测")
              .btnDefaultStyle()
              .fontFamily('HarmonyHeiTi-Bold')
              .fontSize(18)
              .fontColor(Color.Black)
              .fontWeight(350)
              // 检测按钮点击逻辑
              .onClick(async () => {
                console.info("this.srcImgPath:" + String(this.srcImgPath))
                  if (this.srcImgPath) {
                    // 发送图片到端点，并取回检测数据
                    await sendDetectRequest(this.srcImgPath, (result, error) => {
                    if (error) {
                      console.error("Request failed with error:", error);
                    } else {
                      console.log("Request succeeded with result:", result);
                      this.detectionResult = parseDetectionResult(JSON.parse((result as string)) as RawDetectionResultClass)
                    }
                  });
                  // await this.drawDefectsOnImage()
                }
              })


        }
        .margin({'top': 30})


        // 检测结果框
        Column() {

          Text("检测结果")
            .fontFamily('HarmonyHeiTi-Bold').fontSize(18).fontColor(Color.Black).textAlign(TextAlign.Start).lineHeight(33).fontWeight(350).width('100%')

          //检测结果设置栏
          Row(){
            Text("这里存放更多调整按钮").fontFamily('HarmonyHeiTi-Bold').fontSize(18).fontColor(Color.Black).textAlign(TextAlign.Center).lineHeight(33).fontWeight(350).width('100%')
          }
          .margin({ top: 19})
          .backgroundColor('#D3D3D3')
          .height(33)
          .width('100%')
          .onAreaChange((oldValue, newValue) => {
            this.windowWidth = Number(newValue.width)
          })

          if(this.detectionResult) {
            // 获取 PixelMap 的图像信息

            Shape() {
              if (this.pixWidth > 0 && this.pixHeight > 0) {
                // 设置图片的大小，按宽度缩放，高度等比例调整
                Rect()
                  .width(1)   // 设置宽度为 windowWidth
                  .height(1) // 使用计算后的 scaledHeight
                  .offset({ x: this.windowWidth, y: this.scaledHeight })    // 根据需要调整 offset

                // 绘制缺陷框
                ForEach(this.detectionResult?.results, (defect: Defect, index: number) => {
                  // 使用条件表达式选择缺陷类型的颜色
                  Text(String(defect.cls) + ':' + String(defect.conf.toFixed(2)))
                    .offset({ x: defect.x1 * this.scaleNum, y: defect.y1 * this.scaleNum - 10 }) // 根据缩放因子计算位置
                    .fontColor(this.defectColorMapper.getColor(defect.cls))

                    .fontSize(8)

                  Rect()
                    .width((defect.x2 - defect.x1) * this.scaleNum)  // 根据缩放因子计算宽度
                    .height((defect.y2 - defect.y1) * this.scaleNum) // 根据缩放因子计算高度
                    .offset({ x: defect.x1 * this.scaleNum, y: defect.y1 * this.scaleNum }) // 根据缩放因子计算位置
                    .stroke(this.defectColorMapper.getColor(defect.cls))
                    .strokeWidth(0.5)     // 边框宽度
                    .fillOpacity(0);      // 透明填充，仅显示边框
                });
              }
            }
            .backgroundImage(this.srcImgPath).backgroundImageSize(ImageSize.Contain).width("100%")
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)


            }



          // 缺陷结果列表部分
          Column() {

            // 表头
            Row() {
              Text("编号")
                .width(this.columnWidth1)
                .fontFamily('HarmonyHeiTi')
                .fontSize(12)
                .fontWeight(600)
                .textAlign(TextAlign.Start)
                .header()

              Text("类型")
                .width(this.columnWidth2)
                .fontFamily('HarmonyHeiTi')
                .fontSize(12)
                .fontWeight(600)
                .textAlign(TextAlign.Start)
                .header()

              Text("位置(y1,x1,y2,x2)")
                .width(this.columnWidth3)
                .fontFamily('HarmonyHeiTi')
                .fontSize(12)
                .fontWeight(600)
                .textAlign(TextAlign.Start)
                .header()

              Text("置信度")
                .width(this.columnWidth4)
                .fontFamily('HarmonyHeiTi')
                .fontSize(12)
                .fontWeight(600)
                .textAlign(TextAlign.Start)
                .header()
            }
            .padding({ top: 10, bottom: 10 })
            .backgroundColor('#EDEDED')
            .margin({ top: 5 })
            .borderRadius(8)
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)

            // 列表部分：遍历缺陷检测结果
            if (this.detectionResult) {
              ForEach(this.detectionResult.results, (defect: Defect, index: number) => {
                // 每个缺陷结果的显示，只显示数据，不显示标题
                Row() {
                  // 缺陷编号
                  Text(`${defect.id}`)
                    .width(this.columnWidth1)
                    .fontFamily('HarmonyHeiTi')
                    .fontSize(16)
                    .fontWeight(500)
                    .textAlign(TextAlign.Start)
                    .padding({ right: 10 })
                    .borderStyle(10)

                  // 缺陷类型
                  Text(`${defect.cls}`)
                    .width(this.columnWidth2)
                    .fontFamily('HarmonyHeiTi')
                    .fontSize(10)
                    .fontWeight(500)
                    .textAlign(TextAlign.Start)
                    .padding({ right: 10 })

                  // 位置数据，限制小数位
                  Text(`${defect.x1?.toFixed(this.resultPrecision)}, ${defect.y1?.toFixed(this.resultPrecision)},${defect.x2?.toFixed(this.resultPrecision)}, ${defect.y2?.toFixed(this.resultPrecision)}`)
                    .width(this.columnWidth3)
                    .fontFamily('HarmonyHeiTi')
                    .fontSize(16)
                    .fontWeight(500)
                    .textAlign(TextAlign.Start)
                    .padding({ right: 10 })

                  // 置信度数据，限制小数位
                  Text(`${defect.conf?.toFixed(2)}`)
                    .width(this.columnWidth4)
                    .fontFamily('HarmonyHeiTi')
                    .fontSize(16)
                    .fontWeight(500)
                    .textAlign(TextAlign.Start)
                }
                .padding({ top: 10, bottom: 10 })
                .backgroundColor('#F7F7F7')
                .margin({ top: 5 })
                .borderRadius(8)
              }, (defect: Defect, index: number) => defect.id)
            } else {
              // 如果没有检测结果，显示提示信息
              Text("暂无检测结果")
                .fontFamily('HarmonyHeiTi')
                .fontSize(16)
                .fontWeight(500)
                .textAlign(TextAlign.Center)
                .width('100%')
                .margin({ top: 20 })
            }
          }

        }
        .margin({'top': 30})

      }
      .padding({
        top: 12,
        right: 16,
        bottom: 12,
        left: 16
      })

    }
    .backgroundColor('#F1F3F5')
    .align(Alignment.TopStart)
    .constraintSize({ minHeight: '100%' })
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }
  //

}


@Styles
function btnDefaultStyle() {
  .margin({ top: 9})
  .backgroundColor("#D3D3D3")
  .width('100%')
  .backgroundColor('#D3D3D3')
  .height(33)
  .width('100%')
}
@Styles
function textStyle() {
  .width('95%')
  .padding(10)
  .shadow(ShadowStyle.OUTER_DEFAULT_XS)
  .margin({ top: 5, bottom: 10 })
  .backgroundColor(Color.White)
  .border({ width: 1, color: Color.Grey, radius: 10, style: BorderStyle.Dashed })
}
@Styles
function header() {
  // .shadow(ShadowStyle.OUTER_DEFAULT_XS)
//   .border({
//   width: 2,               // 设置统一的边框宽度
//   color: Color.Black,      // 设置边框颜色
//   style: BorderStyle.Solid // 设置边框样式（实线）
// })
}

