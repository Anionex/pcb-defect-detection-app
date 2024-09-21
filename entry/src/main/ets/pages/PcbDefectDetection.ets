import { DefectClass, DetectionResultClass, RawDetectionResultClass, DefectNameClass } from "../model/DetectionResultsClasses";
import { PhotoPickerUtils } from '../util/PhotoPickerUtils';
import { ToastUtils } from '../util/ToastUtils';
import { sendDetectRequest, parseDetectionResult } from '../util/DetectionUtils';
import {ImageUtil, LogUtil, getPixelMapSize} from "../util/ImageUtils"
import { DetectionResultDao } from '../model/DetectionResultDao';
import {DetectionResultDisplay} from "../views/DetectionResultDisplay"
import { BusinessError } from '@kit.BasicServicesKit';
import { DefectColorMapper } from "../model/DefectColorMapper"

const STEP_SIZE = 608
const WINDOW_PROCESS_TIME = 350
const OTHER_DELAYS = 0

AppStorage.setOrCreate('maxResultNum', 0)


@Component
export struct PcbDefectDetection {
  @State srcImgPath: string = '';
  @State detectionResult: DetectionResultClass | null = null;
  @State isLoading: boolean = false;
  @State windowWidth: number = 0;
  @State pixWidth: number = 0;
  @State pixHeight: number = 0;
  @State scaleNum: number = 1;
  @State scaledHeight: number = 0;
  @State resultPrecision: number = 2;
  @State progress: number = 0;
  progressTimer: number | undefined;

  private detectionResultDao: DetectionResultDao = new DetectionResultDao();
  private defectColorMapper: DefectColorMapper = new DefectColorMapper();

  aboutToAppear() {
    LogUtil.info('PcbDefectDetection', 'Component is about to appear');
  }
  aboutToDisappear() {
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
    }
  }

  async selectImage(): Promise<void> {
    try {
      const uri: string = await new Promise<string>((resolve, reject) => {
        PhotoPickerUtils.openGallery(
          (uri: string) => resolve(uri),
          (error: string) => reject(new Error(error))
        );
      });
      this.srcImgPath = uri;
      let imageSize: Array<number> = await getPixelMapSize(this.srcImgPath)
      this.pixWidth = imageSize[0];
      this.pixHeight = imageSize[1];
      this.scaleNum = this.windowWidth / this.pixWidth;
      this.scaledHeight = this.pixHeight * this.scaleNum;
      this.detectionResult = null
      LogUtil.info('PcbDefectDetection', `Image selected: ${this.srcImgPath}`);
    } catch (error) {
      LogUtil.error('PcbDefectDetection', 'Failed to select image:', error);
      ToastUtils.show('选择图片失败，请重试');
    }
  }

  async detectAndSave(): Promise<void> {
    if (!this.srcImgPath) {
      ToastUtils.show('请先选择图片');
      return;
    }

    this.isLoading = true;

    this.progress = 0; // 重置进度

    // 启动进度条定时器
    let estimateProcessTime = await this.estimateProcessTime()
    this.progressTimer = setInterval(() => {
      if (this.progress < 100) {
        this.progress += 1;
      } else {
        clearInterval(this.progressTimer);
      }
    }, estimateProcessTime / 100);

    try {
      const result: string = await new Promise<string>((resolve, reject) => {
        sendDetectRequest(this.srcImgPath, (res: string | null, error?: Error) => {
          if (error) reject(error);
          else resolve(res!);
        });
      });
      this.detectionResult = await parseDetectionResult(
        JSON.parse(result) as RawDetectionResultClass,
        this.srcImgPath
      );
      await this.detectionResultDao.insert(this.detectionResult);
      LogUtil.info('PcbDefectDetection', 'Detection result saved successfully');
    } catch (error) {
      LogUtil.error('PcbDefectDetection', 'Failed to detect or save result:', error);
      ToastUtils.show('检测或保存结果失败，请重试');
    } finally {
      this.progress = 100; // 确保进度达到100%
      if (this.progressTimer) {
        clearInterval(this.progressTimer);
      }
      this.isLoading = false;
    }
  }

  async estimateProcessTime(): Promise<number> {
    // 根据图片大小估计处理时间
    let processTime = (Math.ceil(this.pixWidth / STEP_SIZE) + 1) *
      (Math.ceil(this.pixHeight / STEP_SIZE) + 1) *
      WINDOW_PROCESS_TIME +
      OTHER_DELAYS;
    return Number(processTime.toFixed(2)); // 保留两位小数
  }
  build() {
    Column() {

      this.TitleBar()

      Scroll() {
        Column() {
          Text('实时检测页')
            .fontFamily('HarmonyHeiTi-Bold')
            .fontSize(24)
            .fontWeight(700)
            .width('100%')

          this.ImageSelectionSection();
          this.DetectionResultSection();

          Blank().height('30%') //留一点scroll空间防止bug
        }
        .padding({ top: 12, right: 16, bottom: 12, left: 16 });


      }
      .constraintSize({ minHeight: '100%' })
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off);


    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

  }

  @Builder
  TitleBar() {
    Row() {
      Text('实时检测')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
  }

  @Builder
  ImageSelectionSection() {
    Column() {
      Text("选择图片")
        .fontFamily('HarmonyHeiTi-Bold')
        .fontSize(18)
        .fontColor("#000000") 
        .fontWeight(350)
        .width('100%')
      if(this.srcImgPath) {
        Image(this.srcImgPath)
          .width('100%')
          .margin({ top: 19, bottom: 8 })
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      }
      else {
        Column(){
          Blank().width('100%').height('12%')
          Image($r("app.media.ic_gallery"))
            .fillColor('#4A90E2')
            .width('100%')
            .margin({ top: 19, bottom: 8 })
            .size( { width: 152, height: 152 })
          Blank().width('100%').height('12%')
        }.width('100%').shadow(ShadowStyle.OUTER_DEFAULT_XS)
      }
      Button("选择图片/拍照")
        .onClick(() => this.selectImage())
        .btnDefaultStyle()

      Button("开始预测")
        .onClick(() => this.detectAndSave())
        .btnDefaultStyle()
        .enabled(!this.isLoading);
    }
    .margin({ top: 30 })
  }

  @Builder
  DetectionResultSection() {
    Column() {
      Text("检测结果")
        .fontFamily('HarmonyHeiTi-Bold')
        .fontSize(18)
        .fontColor("#000000") // 使用十六进制颜色代码
        .fontWeight(350)
        .width('100%')

      Row() {
        Text("调整设置")
          .backgroundColor('#FFFFFF')
          .fontFamily('HarmonyHeiTi-Bold')
          .fontSize(18)
          .fontColor("#000000") // 使用十六进制颜色代码
          .fontWeight(350)
          .width('100%');
      }
      .margin({ top: 19 })
      .backgroundColor("#F5F5F5")
      .height(33)
      .width('100%')
      .onAreaChange((oldValue, newValue) => {
        this.windowWidth = Number(newValue.width);
      });

      if (this.isLoading) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear }).width(200).height(50)
      } else if (this.detectionResult) {
        DetectionResultDisplay({
          detectionResult: this.detectionResult,
        })

      } else {
        Text("暂无检测结果")
          .fontFamily('HarmonyHeiTi')
          .fontSize(16)
          .fontWeight(500)
          .width('100%')
          .margin({ top: 20 });
      }
    }
    .margin({ top: 30 })


  }

}



@Styles function btnDefaultStyle() {
  .margin({ top: 9 })
  // 使用十六进制颜色代码替代 Color.LightGray
  .width('100%')
  .height(40)
  .backgroundColor('#4A90E2')
  .borderRadius(18)
}


