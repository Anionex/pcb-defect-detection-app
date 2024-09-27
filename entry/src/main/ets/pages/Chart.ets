import { DetectionResultClass } from "../model/DetectionResultsClasses";
import { McLineChart, Options } from '@mcui/mccharts'

interface GeneratedTypeLiteralInterface_1 {
  hours: string[];
  defects: number[];
}

@Component
export struct Chart {
  @Prop detectionResultHistory: Array<DetectionResultClass>;
  @State chartOptions: Options = new Options({});

  aboutToAppear() {
    this.updateChartData();
  }

  updateChartData() {
    const hourlyData = this.processHourlyData();
    
    this.chartOptions = new Options({
      xAxis: {
        data: hourlyData.hours
      },
      yAxis: {
        name: '缺陷总数'
      },
      series: [
        {
          name: '每小时缺陷总和',
          data: hourlyData.defects
        }
      ]
    });
  }

  processHourlyData(): GeneratedTypeLiteralInterface_1 {
    const hourlyDefects: Record<number, number> = {};
    this.detectionResultHistory.forEach(result => {
      const hour = new Date(result.date).getHours();
      hourlyDefects[hour] = (hourlyDefects[hour] || 0) + result.results.length;
    });

    const hours = Object.keys(hourlyDefects).sort((a, b) => Number(a) - Number(b));
    const defects = hours.map(hour => hourlyDefects[Number(hour)]);

    return { hours, defects };
  }

  build() {
    NavDestination(){
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
  }

}