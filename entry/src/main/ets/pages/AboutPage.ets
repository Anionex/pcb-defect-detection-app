@Component
export struct AboutPage {
  build() {
    NavDestination() {
      Scroll(){
        Column() {
          Image($r('app.media.foreground'))
            .width(100)
            .height(100)
            .borderRadius(20)
            .margin({ top: 50, bottom: 20 })

          Text('慧眼识瑕')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })

          Text('版本 1.0.0')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ bottom: 30 })

          Text('这是一款用于检测PCB缺陷的应用。支持实时检测、历史数据展示和管理等功能，旨在提高PCB生产质量控制效率。')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 20, left: 20, right: 20 })

          Button('访问GitHub')
            .onClick(() => {
              // 添加跳转到GitHub页面的逻辑
            })
            .margin({ bottom: 10 })

          // Text('关于开发者')
          //   .fontSize(14)
          //   .fontColor(Color.Gray)
          //   .margin({ top: 20 })
          //
          // Text('暨南大学计算机专业大二在读，喜欢不一样的东西。')
          //   .fontSize(14)
          //   .textAlign(TextAlign.Center)
          //   .margin({ bottom: 20, left: 20, right: 20 })

          Text('开发者：anion (Anionex)')
            .fontSize(14)
            .fontColor(Color.Gray)
            .margin({ top: 20 })

          Text('版权所有 © 2024 anion')
            .fontSize(12)
            .fontColor(Color.Gray)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor("#F5F5F5")
      }
      .backgroundColor('#F1F3F5')
      .constraintSize({ minHeight: '100%' })
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .title('关于')
  }
}