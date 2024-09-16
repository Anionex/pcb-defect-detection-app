import { DetectionResultClass } from "../model/DetectionResultsClasses";
import { DetectionResultDao } from '../model/DetectionResultDao';
import { ToastUtils } from '../util/ToastUtils';
import { DateUtil, PickerUtil, FileUtil } from '@pura/harmony-utils';
import type { BusinessError } from '@ohos.base';
import {DetectionDetailPage} from "./DetectionDetailPage"
@Component
@Preview
export struct DetectHistory {
  @State detectionResultHistory: Array<DetectionResultClass> = [];
  @State isRefreshing: boolean = false;
  private detectionResultDao: DetectionResultDao = new DetectionResultDao();
  @Provide('detectHistoryPageStack') detectHistoryPageStack: NavPathStack = new NavPathStack();
  @State currentHistoryIndex: number = -1;

  aboutToAppear() {
    this.loadDetectionResults();
  }

  @Builder
  PageMap(name: string) {
    if (name === 'DetectionDetailPage') {
      DetectionDetailPage({result: this.detectionResultHistory[this.currentHistoryIndex]});
    }
  }

  build() {
    Navigation(this.detectHistoryPageStack){
      Column() {
        // 标题栏
        this.TitleBar()

        // 主要内容区域
        Scroll() {
          Column() {
            // 筛选组件
            FilterComponent({
              onFilterApplied: (startDate, endDate, minCount, maxCount) => {
                this.loadDetectionResults(startDate, endDate, minCount, maxCount);
              }
            })

            // 检测历史列表
            this.DetectionList()
          }
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .navBarWidth(288) //这个bar是什么东西？
  }

  @Builder
  TitleBar() {
    Row() {
      Text('检测历史')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Blank()
      Button('打印报表')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#4A90E2')
        .onClick(() => this.printReport())
        .height(36)
        .borderRadius(18)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
  }

  @Builder
  DetectionList() {
    List() {
      ForEach(this.detectionResultHistory, (result: DetectionResultClass, index: number) => {
        ListItem() {
          this.DetectionItem(result, index)
        }
        .animation({ duration: 700, curve: Curve.EaseInOut })
      })
    }
    .divider({ strokeWidth: 0.5, color: '#E0E0E0', startMargin: 10, endMargin: 10 })
  }

  @Builder
  DetectionItem(result: DetectionResultClass, index: number) { //此处的index为显示次序而不是result id
    Row() {
      Column() {
        Text(result.id)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text(DateUtil.getFormatDateStr(result.date))
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(`${result.results.length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A90E2')
        Text('缺陷数')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Center)
      .width(80)

      Button('详情')
        .fontSize(14)
        .fontColor('#4A90E2')
        .backgroundColor('transparent')
        .borderRadius(16)
        .borderWidth(1)
        .borderColor('#4A90E2')
        .height(32)
        .onClick(() => {
          ToastUtils.show(`显示详情：${result.id}`);
          this.currentHistoryIndex = index
          this.detectHistoryPageStack.replacePath({ name: 'DetectionDetailPage' });
        })

      Button('删除')
        .fontSize(14)
        .fontColor('#FF4D4F')
        .backgroundColor('transparent')
        .borderRadius(16)
        .borderWidth(1)
        .borderColor('#FF4D4F')
        .height(32)
        .margin({ left: 8 })
        .onClick(() => {
          AlertDialog.show({
            title: '确认删除',
            message: '您确定要删除这条记录吗？',
            primaryButton: {
              value: '取消',
              action: () => {
                console.info('取消删除');
              }
            },
            secondaryButton: {
              value: '删除',
              action: () => {
                this.deleteDetectionResult(result.id);
              }
            }
          })
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
    .margin({ bottom: 4 })
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

  generateCSV(): string {
    // 添加 UTF-8 BOM
    let csvContent = "\uFEFF";
    csvContent += "检测编码,日期,总缺陷数\n";
    this.detectionResultHistory.forEach(result => {
      csvContent += `${result.id},${DateUtil.getFormatDateStr(result.date)},${result.results.length}\n`;
    });
    return csvContent;
  }

  async printReport() {
    try {
      //检测报告_${DateUtil.getFormatDateStr(DateUtil.getTodayTime())
      const fileName = `tmp.csv`;
      const csvContent = this.generateCSV();

      PickerUtil.saveDocument([fileName]).then((uris) => {
        if (uris && uris.length > 0) {
          const uri = uris[0];
          console.log('文件将保存到:', uri);

          FileUtil.writeEasy(uri, csvContent)
            .then(() => {
              console.log('文件保存成功');
              ToastUtils.show('报表已保存');
            })
            .catch((err:string) => {
              console.error('写入文件失败:', err);
              ToastUtils.show('保存报表失败');
            });
        } else {
          console.error('未获取到保存路径');
          ToastUtils.show('保存报表失败');
        }
      }).catch((err: BusinessError) => {
        console.error('选择保存路径失败:', JSON.stringify(err));
        ToastUtils.show('保存报表失败');
      });
    } catch (error) {
      console.error('生成CSV文件失败:', error);
      ToastUtils.show('生成报表失败');
    }
  }

  async deleteDetectionResult(id: string) {
    try {
      const success = await this.detectionResultDao.deleteById(id);
      if (success) {
        ToastUtils.show('记录删除成功');
        // 重新加载数据以更新列表
        this.loadDetectionResults();
      } else {
        ToastUtils.show('记录删除失败');
      }
    } catch (error) {
      console.error('删除记录时出错:', error);
      ToastUtils.show('删除记录时发生错误');
    }
  }
}

@Component
struct FilterComponent {
  @State selectedStartDate: string = '';
  @State selectedEndDate: string = '';
  @State minDefects: number = 0;
  @State maxDefects: number = 10;
  @State isExpanded: boolean = false;
  onFilterApplied: (startDate: string, endDate: string, minCount: number, maxCount: number) => void = () => {};

  @Builder
  FilterContent() {
    Column() {
      this.DatePicker('开始日期', this.selectedStartDate, (date) => this.selectedStartDate = date)
      this.DatePicker('结束日期', this.selectedEndDate, (date) => this.selectedEndDate = date)
      this.DefectCountInput()
      this.ApplyFilterButton()
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .animation({ duration: 300, curve: Curve.EaseInOut })
  }

  @Builder
  DatePicker(label: string, date: string, onSelect: (date: string) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
      Blank()
      Button(date || '选择日期')
        .fontSize(14)
        .fontColor(date ? '#333333' : '#999999')
        .backgroundColor('transparent')
        .borderRadius(16)
        .borderWidth(1)
        .borderColor('#E0E0E0')
        .height(32)
        .onClick(() => {
          DatePickerDialog.show({
            start: new Date('2023-1-1'),
            end: new Date(),
            selected: date ? new Date(date) : undefined,
            onAccept: (value: DatePickerResult) => {
              onSelect(`${value.year}-${value.month! + 1}-${value.day}`);
            }
          })
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  DefectCountInput() {
    Row() {
      Text('缺陷个数:')
        .fontSize(16)
        .fontColor('#333333')
      TextInput({ placeholder: '最小值', text: String(this.minDefects) })
        .width(80)
        .height(32)
        .margin({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.minDefects = parseInt(value) || 0;
        })
      Text('-')
        .fontSize(16)
        .fontColor('#333333')
      TextInput({ placeholder: '最大值', text: String(this.maxDefects) })
        .width(80)
        .height(32)
        .margin({ left: 8 })
        .onChange((value: string) => {
          this.maxDefects = parseInt(value) || 10;
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  ApplyFilterButton() {
    Button('应用筛选')
      .width('100%')
      .height(40)
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#4A90E2')
      .borderRadius(20)
      .onClick(() => {
        this.onFilterApplied(this.selectedStartDate, this.selectedEndDate, this.minDefects, this.maxDefects);
      })
  }

  build() {
    Column() {
      Row() {
        Text('筛选条件')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.isExpanded })
          .onChange((isOn: boolean) => {
            animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
              this.isExpanded = isOn;
            })
          })
      }
      .width('100%')
      .padding({ top: 16, bottom: 16, left: 16, right: 16 })
      .backgroundColor('#FFFFFF')


      if (this.isExpanded) {
        this.FilterContent()
      }
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 })
    .margin({ bottom: 16 })
  }
}


