export class RawDetectionResultClass {
  detection_classes: string[];
  detection_boxes: number[][];
  detection_scores: number[];

  constructor(
    detection_classes: string[],
    detection_boxes: number[][],
    detection_scores: number[]
  ) {
    this.detection_classes = detection_classes;
    this.detection_boxes = detection_boxes;
    this.detection_scores = detection_scores;
  }
}

export enum DefectClass {
  MOUSE_BITE = 'Mouse_bite',
  OPEN_CIRCUIT = 'Open_circuit',
  SHORT = 'Short',
  SPUR = 'Spur',
  SPURIOUS_COPPER = 'Spurious_copper'
}

export class Defect {
  id: string;
  cls: DefectClass;
  y1: number | 0; // 适应api的格式
  x1: number | 0;
  y2: number | 0;
  x2: number | 0;
  conf: number | 0;

  // 构造函数，接收所有属性并初始化
  constructor(
    id: string,
    cls: DefectClass,
    y1: number | 0 = 0,
    x1: number | 0 = 0,
    y2: number | 0 = 0,
    x2: number | 0 = 0,
    conf: number | 0 = 0
  ) {
    this.id = id;
    this.cls = cls;
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.conf = conf;
  }
}

export class DetectionResultClass {
  id: string;
  date: Date;
  imagePath: string | 0;
  results: Defect[];
  details: string | 0;

  // 构造函数，接收部分属性并初始化
  constructor(
    id: string,
    date: Date = new Date(),  // 默认为当前日期
    imagePath: string | 0 = 0,
    results: Defect[] = [],   // 默认为空数组
    details: string | 0 = 0
  ) {
    this.id = id;
    this.date = date;
    this.imagePath = imagePath;
    this.results = results;
    this.details = details;
  }


}
