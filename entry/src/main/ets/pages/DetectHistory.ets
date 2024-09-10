import { Defect, DetectionResultClass, DefectClass } from "../model/DetectionResultsClass";
import image from '@ohos.multimedia.image';
import { PhotoPickerUtils } from '../util/PhotoPickerUtils';
import { ToastUtils } from '../util/ToastUtils';
import { PermissionUtils } from '../util/PermissionUtils';
import { sendDetectRequest, parseDetectionResult } from '../util/DetectionUtils';
import { DateUtil, FileUtil, ImageUtil, LogUtil, ToastUtil, DeviceUtil } from '@pura/harmony-utils';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// 随机生成 1000 到 3000 之间的坐标值
function getRandomCoordinate(): number {
  return Math.floor(Math.random() * (3000 - 1000 + 1)) + 1000;
}

// 定义生成虚拟 Defect 数据的方法
function generateDefect(id: string, cls: DefectClass): Defect {
  return new Defect(id, cls, getRandomCoordinate(), getRandomCoordinate(), getRandomCoordinate(), getRandomCoordinate(), Number(Math.random().toFixed(2)));
}

@Component
@Preview
export struct DetectHistory {
  // 定义一个虚拟检测结果数组
  @State detectionResults: DetectionResultClass[] = [
    new DetectionResultClass(
      '1',
      new Date('2023-08-15'),
      'path/to/image1.jpg',
      [
        generateDefect('1', DefectClass.MOUSE_BITE),
        generateDefect('2', DefectClass.OPEN_CIRCUIT)
      ],
      '检测到2个缺陷'
    ),
    new DetectionResultClass(
      '2',
      new Date('2023-08-16'),
      'path/to/image2.jpg',
      [
        generateDefect('3', DefectClass.SHORT)
      ],
      '检测到1个缺陷'
    ),
    new DetectionResultClass(
      '3',
      new Date('2023-08-17'),
      'path/to/image3.jpg',
      [
        generateDefect('4', DefectClass.SPUR),
        generateDefect('5', DefectClass.SPURIOUS_COPPER)
      ],
      '检测到2个缺陷'
    )
  ];

  printReport() {
    // 这里可以加入生成或打印报表的具体逻辑
    console.log("报表已生成并准备打印...");
    ToastUtils.show('报表正在打印');
  }

  build() {
    Scroll() {
      Column() {

        Row() {
          Text('检测历史页')
            .fontFamily('HarmonyHeiTi-Bold')
            .fontSize(24)
            .fontColor(Color.Black)
            .textAlign(TextAlign.Start)
            .lineHeight(33)
            .fontWeight(700)
            .margin({bottom:20})
          Blank()
          Button('打印报表')
            .fontSize(16)
            .backgroundColor(Color.Blue)
            .fontColor(Color.White)
            .onClick(() => {
              // 点击按钮时调用 printReport 方法
              this.printReport();
            })
            .padding({
              top: 12,
              bottom: 12,
              left: 24,
              right: 24
            })
        }.width('100%')
          .borderRadius(8)

        FilterComponent()

        // 表头
        Row() {
          Text('检测编码')
            .fontSize(18)
            .fontColor(Color.Gray)
            .width('25%')

          Text('日期')
            .fontSize(18)
            .fontColor(Color.Gray)
            .width('25%')

          Text('总缺陷数')
            .fontSize(18)
            .fontColor(Color.Gray)
            .width('25%')

          Text('操作')
            .fontSize(18)
            .fontColor(Color.Gray)
            .width('25%')
            .textAlign(TextAlign.Start)
        }
        .padding({ top: 10, bottom: 10 })
        .border({ width: 1, color: Color.Gray })

        // 遍历检测结果并展示数据
        ForEach(this.detectionResults, (result: DetectionResultClass) => {
          Row() {
            // 显示检测 ID
            Text(result.id)
              .fontSize(16)
              .fontColor(Color.Black)
              .width('25%')

            // 显示检测日期
            Text(result.date.toLocaleDateString())
              .fontSize(16)
              .fontColor(Color.Black)
              .width('25%')

            // 显示检测缺陷总数
            Text(`${result.results.length}`)
              .fontSize(16)
              .fontColor(Color.Black)
              .width('25%')

            // 详情按钮
            Text('详情')
              .fontSize(16)
              .fontColor(Color.Blue)
              .width('25%')
              .onClick(() => {
                // 这里可以添加详情页面的跳转逻辑
                ToastUtils.show(`显示详情：${result.id}`);
              })
          }
          .padding({ top: 10, bottom: 10 })
          .border({ width: 1, color: Color.Gray })
        })
      }
      .padding({ top: 12, right: 16, bottom: 12, left: 16 })
    }
    .backgroundColor('#F1F3F5')
    .align(Alignment.TopStart)
    .constraintSize({ minHeight: '100%' })
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }
}

@Component
export struct FilterComponent {
  @State selectedDate: string = '';  // 存储选择的日期
  @State selectedDefectCount: string = '';  // 存储选择的缺陷个数
  @State minDefects: number = 0;  // 最小缺陷个数
  @State maxDefects: number = 10;  // 最大缺陷个数

  // 筛选逻辑，可以传递给父组件用于筛选数据
  applyFilter() {
    const dateFilter = this.selectedDate;
    const minCount = this.minDefects;
    const maxCount = this.maxDefects;

    // 可以将筛选条件返回给父组件或者调用筛选数据的方法
    console.log(`筛选条件: 日期 = ${dateFilter}, 缺陷个数: ${minCount} - ${maxCount}`);
    ToastUtils.show(`正在筛选：日期 = ${dateFilter}, 缺陷个数: ${minCount} - ${maxCount}`);
  }

  build() {
    Column() {
      // 筛选框标题
      Text('筛选条件')
        .fontSize(18)
        .fontColor(Color.Black)
        .margin({ bottom: 8 })

      // 日期筛选框
      Row() {
        Text('日期:')
          .fontSize(16)
          .fontColor(Color.Gray)

        TextInput({ placeholder: '选择日期', text: this.selectedDate })
          .onChange((value: string) => {
            this.selectedDate = value;  // 更新选择的日期
          })
          .margin({ left: 8 })
          .width('70%')
      }
      .margin({ bottom: 16 })

      // 缺陷个数范围选择
      Row() {
        Text('缺陷个数:')
          .fontSize(16)
          .fontColor(Color.Gray)

        // 最小缺陷数选择框
        TextInput({ placeholder: '最小', text: String(this.minDefects) })
          .onChange((value: string) => {
            this.minDefects = parseInt(value) || 0;  // 更新最小缺陷数
          })
          .margin({ left: 8 })
          .width('30%')


        Text('-')
          .fontSize(16)
          .margin({ left: 8, right: 8 })

        // 最大缺陷数选择框
        TextInput({ placeholder: '最大', text:  String(this.maxDefects)})
          .onChange((value: string) => {
            this.maxDefects = parseInt(value) || 10;  // 更新最大缺陷数
          })
          .width('30%')
      }
      .margin({ bottom: 16 })

      // 应用筛选按钮
      Text('应用筛选')
        .fontSize(16)
        .backgroundColor(Color.Gray)
        .fontColor(Color.White)
        .onClick(() => {
          this.applyFilter();  // 点击按钮时调用筛选逻辑
        })
        .padding({ top: 12, bottom: 12, left: 24, right: 24 })
        .borderRadius(8)
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#F1F3F5')
  }
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