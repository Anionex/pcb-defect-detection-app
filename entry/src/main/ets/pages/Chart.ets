import { DetectionResultClass } from "../model/DetectionResultsClasses";
import { McLineChart, Options } from '@mcui/mccharts'
import { DefectColorMapper } from "../model/DefectColorMapper"

class DefectTypeData {
  Mouse_bite: number[] = [];
  Open_circuit: number[] = [];
  Short: number[] = [];
  Spur: number[] = [];
  Spurious_copper: number[] = [];
}

class HourlyData {
  hours: string[] = [];
  defects: number[] = [];
  defectTypes: DefectTypeData = new DefectTypeData();
  startHour: number = 0;
}

interface GeneratedTypeLiteralInterface_1 {
  color: string;
}

class SeriesItem {
  name: string = '';
  data: number[] = [];color:string;
  lineStyle?: GeneratedTypeLiteralInterface_1;
}

@Component
export struct Chart {
  @Prop detectionResultHistory: Array<DetectionResultClass>;
  @State chartOptions: Options = new Options({});
  private defectColorMapper: DefectColorMapper = new DefectColorMapper();

  aboutToAppear() {
    this.updateChartData();
  }

  updateChartData() {
    const hourlyData = this.processHourlyData();
    const defectTypes = ['Mouse_bite', 'Open_circuit', 'Short', 'Spur', 'Spurious_copper'];

    const series: SeriesItem[] = [];
    series.push({
      name: '每小时缺陷总和',
      data: hourlyData.defects
    });

    defectTypes.forEach(type => {
      series.push({
        name: type,
        data: this.getDefectTypeData(hourlyData.defectTypes, type),
        color: "#ffffff",
        lineStyle: {
          color: this.defectColorMapper.getColor(type) // 颜色玄学问题还没搞定
        }
      });
    });

    this.chartOptions = new Options({
      xAxis: {
        data: hourlyData.hours
      },
      yAxis: {
        name: '缺陷数量'
      },
      series: series
    });
  }

  getDefectTypeData(defectTypes: DefectTypeData, type: string): number[] {
    switch (type) {
      case 'Mouse_bite': return defectTypes.Mouse_bite;
      case 'Open_circuit': return defectTypes.Open_circuit;
      case 'Short': return defectTypes.Short;
      case 'Spur': return defectTypes.Spur;
      case 'Spurious_copper': return defectTypes.Spurious_copper;
      default: return [];
    }
  }

  processHourlyData(): HourlyData {
    const hourlyData = new HourlyData();
    const defectTypes = ['Mouse_bite', 'Open_circuit', 'Short', 'Spur', 'Spurious_copper'];
    const now = new Date();
    const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    // getTimee是获取的是当前时间的毫秒
    hourlyData.startHour = now.getHours();

    console.info(String(now))
    console.info("24h ago: " + String(twentyFourHoursAgo))
    console.info("startHour: " + hourlyData.startHour)

    defectTypes.forEach(type => {
      this.initializeDefectTypeArray(hourlyData.defectTypes, type);
    });

    this.detectionResultHistory.forEach(result => {
      const resultDate = new Date(result.date);
      console.info("resultDateH:" + resultDate.getHours())
      if (resultDate >= twentyFourHoursAgo && resultDate <= now) {
        const index = 23 - (hourlyData.startHour - resultDate.getHours())
        result.results.forEach(defect => {
          if (defectTypes.includes(defect.cls)) {
            this.incrementDefectCount(hourlyData.defectTypes, defect.cls, index);
          }
        });
      }
    });

    hourlyData.hours = this.generateHours(hourlyData.startHour);
    hourlyData.defects = this.calculateTotalDefects(hourlyData.defectTypes);

    return hourlyData;
  }

  initializeDefectTypeArray(defectTypes: DefectTypeData, type: string): void {
    switch (type) {
      case 'Mouse_bite': defectTypes.Mouse_bite = new Array(24).fill(0); break;
      case 'Open_circuit': defectTypes.Open_circuit = new Array(24).fill(0); break;
      case 'Short': defectTypes.Short = new Array(24).fill(0); break;
      case 'Spur': defectTypes.Spur = new Array(24).fill(0); break;
      case 'Spurious_copper': defectTypes.Spurious_copper = new Array(24).fill(0); break;
    }
  }

  incrementDefectCount(defectTypes: DefectTypeData, type: string, hour: number): void {
    switch (type) {
      case 'Mouse_bite': defectTypes.Mouse_bite[hour]++; break;
      case 'Open_circuit': defectTypes.Open_circuit[hour]++; break;
      case 'Short': defectTypes.Short[hour]++; break;
      case 'Spur': defectTypes.Spur[hour]++; break;
      case 'Spurious_copper': defectTypes.Spurious_copper[hour]++; break;
    }
  }

  generateHours(startHour: number): string[] {
    const hours: string[] = [];
    for (let i = 0; i < 24; i++) {
      const hour = (startHour - i + 24) % 24;
      hours.unshift(hour.toString().padStart(2, '0'));
    }
    return hours;
  }

  calculateTotalDefects(defectTypes: DefectTypeData): number[] {
    const total: number[] = new Array(24).fill(0);
    for (let i = 0; i < 24; i++) {
      total[i] = defectTypes.Mouse_bite[i] + defectTypes.Open_circuit[i] +
      defectTypes.Short[i] + defectTypes.Spur[i] + defectTypes.Spurious_copper[i];
    }
    return total;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text('缺陷统计图表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 20 })

          McLineChart({
            options: this.chartOptions
          })
            .width('100%')
            .height('300vp')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F1F3F5')
      }
      .backgroundColor('#F1F3F5')
      .constraintSize({ minHeight: '100%' })
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }.title("统计")
  }
}