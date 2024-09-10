@Component
@Preview
export struct Settings {
  build() {
    Scroll() {
      Column() {
        Text('更多设置页')
          .fontFamily('HarmonyHeiTi-Bold')
          .fontSize(24)
          .fontColor(Color.Black)
          .textAlign(TextAlign.Start)
          .lineHeight(33)
          .fontWeight(700)
          .width('100%')

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
}