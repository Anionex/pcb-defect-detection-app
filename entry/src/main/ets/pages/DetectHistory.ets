import { DetectionResultClass } from "../model/DetectionResultsClass";
import { DetectionResultDao } from '../model/DetectionResultDao';
import { ToastUtils } from '../util/ToastUtils';
import { DateUtil } from '@pura/harmony-utils';

@Component
@Preview
export struct DetectHistory {
  @State detectionResultHistory: Array<DetectionResultClass> = [];
  @State isRefreshing: boolean = false;
  private detectionResultDao: DetectionResultDao = new DetectionResultDao();

  aboutToAppear() {
    this.loadDetectionResults();
  }

  async loadDetectionResults(startDate?: string, endDate?: string, minDefects?: number, maxDefects?: number) {
    try {
      if (startDate || endDate || minDefects !== undefined || maxDefects !== undefined) {
        const start = startDate ? new Date(startDate) : undefined;
        const end = endDate ? new Date(endDate) : undefined;
        this.detectionResultHistory = await this.detectionResultDao.getFilteredResults(start, end, minDefects, maxDefects);
      } else {
        this.detectionResultHistory = await this.detectionResultDao.getAll();
      }
    } catch (error) {
      console.error("加载检测历史失败:", error);
      ToastUtils.show('加载检测历史失败');
    }
  }

  printReport() {
    console.log("报表已生成并准备打印...");
    ToastUtils.show('报表正在打印');
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing, offset: 30, friction: 70 }) {
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

          FilterComponent({
            onFilterApplied: (startDate: string, endDate: string, minCount: number, maxCount: number) => {
              this.loadDetectionResults(startDate, endDate, minCount, maxCount);
            }
          })

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
          ForEach(this.detectionResultHistory, (result: DetectionResultClass) => {
            Row() {
              Text(result.id)
                .fontSize(16)
                .fontColor(Color.Black)
                .width('25%')

              Text(DateUtil.getFormatDateStr(result.date))
                .fontSize(16)
                .fontColor(Color.Black)
                .width('25%')

              Text(`${result.results.length}`)
                .fontSize(16)
                .fontColor(Color.Black)
                .width('25%')

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
    .onStateChange((refreshStatus: RefreshStatus) => {
      if (refreshStatus == RefreshStatus.Refresh) {
        this.loadDetectionResults();
      }
    })
    .onRefreshing(() => {
      console.log('开始刷新');
      setTimeout(() => {
        this.isRefreshing = false;
        console.log('刷新完成');
      }, 1000);
    })
  }
}

@Component
struct FilterComponent {
  @State selectedStartDate: string = '';
  @State selectedEndDate: string = '';
  @State minDefects: number = 0;
  @State maxDefects: number = 10;
  onFilterApplied: (startDate: string, endDate: string, minCount: number, maxCount: number) => void = () => {};

  build() {
    Column() {
      Text('筛选条件')
        .fontSize(18)
        .fontColor(Color.Black)
        .margin({ bottom: 8 })

      Row() {
        Text('开始日期:')
          .fontSize(16)
          .fontColor(Color.Gray)

        Button(this.selectedStartDate || '选择开始日期')
          .onClick(() => {
            DatePickerDialog.show({
              start: new Date('2023-1-1'),
              end: new Date(),
              selected: this.selectedStartDate ? new Date(this.selectedStartDate) : undefined,
              onAccept: (value: DatePickerResult) => {
                this.selectedStartDate = `${value.year}-${value.month! + 1}-${value.day}`;
              }
            })
          })
          .margin({ left: 8 })
          .width('70%')
      }
      .margin({ bottom: 16 })

      Row() {
        Text('结束日期:')
          .fontSize(16)
          .fontColor(Color.Gray)

        Button(this.selectedEndDate || '选择结束日期')
          .onClick(() => {
            DatePickerDialog.show({
              start: new Date('1970-1-1'),
              end: new Date(),
              selected: this.selectedEndDate ? new Date(this.selectedEndDate) : undefined,
              onAccept: (value: DatePickerResult) => {
                this.selectedEndDate = `${value.year}-${value.month! + 1}-${value.day}`;
              }
            })
          })
          .margin({ left: 8 })
          .width('70%')
      }
      .margin({ bottom: 16 })

      Row() {
        Text('缺陷个数:')
          .fontSize(16)
          .fontColor(Color.Gray)

        TextInput({ placeholder: '最小', text: String(this.minDefects) })
          .onChange((value: string) => {
            this.minDefects = parseInt(value) || 0;
          })
          .margin({ left: 8 })
          .width('30%')

        Text('-')
          .fontSize(16)
          .margin({ left: 8, right: 8 })

        TextInput({ placeholder: '最大', text: String(this.maxDefects) })
          .onChange((value: string) => {
            this.maxDefects = parseInt(value) || 10;
          })
          .width('30%')
      }
      .margin({ bottom: 16 })

      Button('应用筛选')
        .fontSize(16)
        .backgroundColor(Color.Blue)
        .fontColor(Color.White)
        .onClick(() => {
          this.onFilterApplied(this.selectedStartDate, this.selectedEndDate, this.minDefects, this.maxDefects);
        })
        .padding({ top: 12, bottom: 12, left: 24, right: 24 })
        .borderRadius(8)
    }
  }
}