import { DetectionResultClass } from "../model/DetectionResultsClasses";
import { DetectionResultDao } from '../model/DetectionResultDao';
import { ToastUtils } from '../util/ToastUtils';
import { DateUtil, PickerUtil, FileUtil } from '@pura/harmony-utils';
import type { BusinessError } from '@ohos.base';
import {DetectionDetailPage} from "./DetectionDetailPage"
import {Chart} from "./Chart"
@Component
@Preview
export struct DetectHistory {
  @State detectionResultHistory: Array<DetectionResultClass> = [];
  @State isRefreshing: boolean = false;
  private detectionResultDao: DetectionResultDao = new DetectionResultDao();
  @Provide('detectHistoryPageStack') detectHistoryPageStack: NavPathStack = new NavPathStack();
  @State currentHistoryIndex: number = -1;
  @State selectedItems: Set<string> = new Set()
  @State isSelectMode: boolean = false

  aboutToAppear() {
    this.loadDetectionResults();
  }

  build() {
    Navigation(this.detectHistoryPageStack){
      Column() {
        // 标题栏
        this.TitleBar()

        // 主要内容区域
        Refresh({ refreshing: this.isRefreshing, offset: 30, friction: 70 }) {
          Stack() {
            Scroll() {
              Column() {
                // 筛选组件
                FilterComponent({
                  onFilterApplied: (startDate, endDate, minCount, maxCount) => {
                    this.loadDetectionResults(startDate, endDate, minCount, maxCount);
                  }
                })

                // 多选操作栏
                this.MultiSelectBar()

                // 检测历史列表
                this.DetectionList()
              }
              .padding({ top: 16, bottom: 16, left: 16, right: 16 })
            }
            .backgroundColor('#F1F3F5')
            .constraintSize({ minHeight: '100%' })
            .edgeEffect(EdgeEffect.Spring)
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .align(Alignment.TopStart)
          }
.width('100%')
.height('100%')
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
          }, 1000)
        })
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      //设置从页面顶部往下排列组件

    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .navBarWidth(288) //这个bar是什么东西？

  }

  @Builder
  PageMap(name: string) {
    if (name == 'DetectionDetailPage') {
      DetectionDetailPage({result: this.detectionResultHistory[this.currentHistoryIndex]});
    }
    if(name == 'Chart') {
      Chart({detectionResultHistory: this.detectionResultHistory})
    }
  }

  @Builder
  TitleBar() {
    Row() {
      Text('检测历史')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Blank()
      Image($r('app.media.ic_chart'))
        .width(24)
        .height(24)
        .margin({ right: 16 })
        .onClick(() => {
          ToastUtils.show(`显示图表`);
          this.detectHistoryPageStack.replacePath({ name: 'Chart' });
        })
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
      if (this.isSelectMode) {
        Checkbox()
          .select(this.selectedItems.has(result.id))
          .onChange((value: boolean) => {
            if (value) {
              this.selectedItems.add(result.id)
            } else {
              this.selectedItems.delete(result.id)
            }
          })
      }
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
          if (!this.isSelectMode) {
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
          } else {
            if (this.selectedItems.has(result.id)) {
              this.selectedItems.delete(result.id)
            } else {
              this.selectedItems.add(result.id)
            }
          }
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
    .margin({ bottom: 4 })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (!this.isSelectMode) {
            this.isSelectMode = true
            this.selectedItems.add(result.id)
          }
        })
    )
  }

  @Builder
  MultiSelectBar() {
    if (this.isSelectMode) {
      Row() {
        Button('取消').btnDefaultStyle().height(30)
          .onClick(() => {
            this.isSelectMode = false
            this.selectedItems.clear()
          })

        Blank()
        Button('全选').btnDefaultStyle().height(30)
          .onClick(() => {
            if (this.selectedItems.size === this.detectionResultHistory.length) {
              this.selectedItems.clear()
            } else {
              this.selectedItems = new Set(this.detectionResultHistory.map(item => item.id))
            }
          })
        Button('删除').btnDefaultStyle().height(30)
          .onClick(() => {
            this.deleteSelectedItems()
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F0F0F0')
    }
  }

  async loadDetectionResults(startDate?: string, endDate?: string, minDefects?: number, maxDefects?: number) {
    try {
      this.isRefreshing = true; // 开始刷新
      if (startDate || endDate || minDefects !== undefined || maxDefects !== undefined) {
        const start = startDate ? new Date(startDate) : undefined;
        const end = endDate ? new Date(endDate) : undefined;
        this.detectionResultHistory = await this.detectionResultDao.getFilteredResults(start, end, minDefects, maxDefects);
      } else {
        this.detectionResultHistory = await this.detectionResultDao.getAll();
        // 翻转结果, 让最近结果在顶端
        this.detectionResultHistory.reverse();
      }
      // 同步数据库操作可以在这里添加
      await this.syncWithDatabase();
    } catch (error) {
      console.error("加载检测历史失败:", error);
      ToastUtils.show('加载检测历史失败');
    } finally {
      this.isRefreshing = false; // 结束刷新
    }
  }

  async syncWithDatabase() {
    // 在这里实现与数据库的同步逻辑
    // 例如:
    // await this.detectionResultDao.syncWithRemoteDatabase();
    console.log('数据已与数据库同步');
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

  async deleteSelectedItems() {
    AlertDialog.show({
      title: '确认删除',
      message: `您确定要删除选中的 ${this.selectedItems.size} 条记录吗？`,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('取消删除');
        }
      },
      secondaryButton: {
        value: '删除',
        action: async () => {
          try {
            for (let id of this.selectedItems) {
              await this.detectionResultDao.deleteById(id);
            }
            ToastUtils.show(`成功删除 ${this.selectedItems.size} 条记录`);
            this.loadDetectionResults();
            this.isSelectMode = false;
            this.selectedItems.clear();
          } catch (error) {
            console.error('批量删除记录时出错:', error);
            ToastUtils.show('删除记录时发生错误');
          }
        }
      }
    })
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

@Styles function btnDefaultStyle() {
  .margin({ top: 9 })
  // 使用十六进制颜色代码替代 Color.LightGray
  .backgroundColor('#4A90E2')
  .borderRadius(18)
}
