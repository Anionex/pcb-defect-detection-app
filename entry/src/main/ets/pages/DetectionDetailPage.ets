import { DefectClass, DetectionResultClass } from "../model/DetectionResultsClasses";
import { DateUtil } from '@pura/harmony-utils';
import {DetectionResultDisplay} from "../views/DetectionResultDisplay"
import { getPixelMapSize } from '../util/ImageUtils';

@Component
export struct DetectionDetailPage {
  @Prop result: DetectionResultClass;
  private windowWidth:number | undefined = undefined
  build() {
    NavDestination() {
      Scroll(){
        Column() {
          Text(`检测编码: ${this.result.id}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 10 })

          Text(`检测日期: ${DateUtil.getFormatDateStr(this.result.date)}`)
            .fontSize(16)
            .margin({ bottom: 10 })

          Text(`总缺陷数: ${this.result.results.length}`)
            .fontSize(16)
            .margin({ bottom: 20 })
            .onAreaChange((oldValue, newValue) => {
              this.windowWidth = Number(newValue.width);
            });

          // List() {
          //   ForEach(this.result.results, (defect: DefectClass) => {
          //     ListItem() {
          //       Column() {
          //         Text(`缺陷类型: ${defect.cls}`)
          //           .fontSize(16)
          //           .margin({ bottom: 5 })
          //         Text(`位置: (${defect.x1?.toFixed(2)}, ${defect.y1?.toFixed(2)}) - (${defect.x2?.toFixed(2)}, ${defect.y2?.toFixed(2)})`)
          //           .fontSize(14)
          //           .margin({ bottom: 5 })
          //         Text(`置信度: ${defect.conf?.toFixed(2)}`)
          //           .fontSize(14)
          //       }
          //       .padding(10)
          //       .width('100%')
          //       .backgroundColor('#F0F0F0')
          //       .borderRadius(8)
          //     }
          //     .margin({ bottom: 10 })
          //   })
          // }
          // .width('100%')

          DetectionResultDisplay({
            detectionResult: this.result,
          })
        }
        .padding(16)
      }
      .constraintSize({ minHeight: '100%' })
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off);
    }
    .title('检测详情')
  }
}