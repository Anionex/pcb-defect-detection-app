import axios,{FormData, AxiosResponse, AxiosProgressEvent, AxiosError} from '@ohos/axios'
import { fileIo as fs } from '@kit.CoreFileKit';
import { RawDetectionResultClass, DetectionResultClass, DefectClass, Defect} from "../model/DetectionResultsClass"
import image from '@ohos.multimedia.image';
import { BusinessError } from '@kit.BasicServicesKit';


interface GeneratedObjectLiteralInterface_2 {
  format: string;
  quality: number;
}

export async function sendDetectRequest(filePath: string, callback?: (result: string | null, error?: Error) => void ) {
  try {
    console.info("enter 1")
    let file = await (fs.open(filePath, fs.OpenMode.READ_ONLY) as Promise<fs.File>);
    const fd = file?.fd;

    console.info("enter 1")
    let stat : fs.Stat | null = null

    stat = await (fs.stat(file.fd) as Promise<fs.Stat>);

    console.info("stat.size:", stat.size)

    let bufferData:ArrayBuffer | undefined ;

    fs.closeSync(file);

    // path为已获得的沙箱路径
    const imageSource = image.createImageSource(filePath);

    // let decodingOptions: GeneratedObjectLiteralInterface_1 = {
    //   editable: true,
    //   desiredPixelFormat: 3,
    // }
    // // 创建pixelMap并进行简单的旋转和缩放
    // const pixelMap = await imageSource.createPixelMap(decodingOptions);

    const imagePackerApi = image.createImagePacker();
    let packOpts: GeneratedObjectLiteralInterface_2 = { format:"image/jpeg", quality:98 };
    await imagePackerApi.packing(imageSource, packOpts).then( data => {
      // data 为打包获取到的文件流，写入文件保存即可得到一张图片
      console.info("get compressed data")
      bufferData = data
    }).catch(() => {console.log("get compressed data error")});


    console.info('Read data length: ' + bufferData?.byteLength);
    //请求部分
    let formData = new FormData();
    // 将 ArrayBuffer 添加到 FormData 中
    formData.append('file', bufferData, { filename: 'test.jpg', type: 'image/jpeg' });

    // 发送 POST 请求
    console.info("send request")
    let response:AxiosResponse = await axios.post<string, AxiosResponse<string>, FormData>(
      'https://infer-app-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/bf6b19fa-50e5-4899-ab49-4148ae9325d7',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
          'X-Apig-AppCode': 'ca003a86d6634dd69a6c88a0068f7e6110d54f7b48794b8d8065bad6b1f5a4d7'
        },
        onUploadProgress: (progressEvent: AxiosProgressEvent): void => {
          if (progressEvent && progressEvent.loaded !== undefined && progressEvent.total !== undefined) {
            console.info(Math.ceil(progressEvent.loaded / progressEvent.total * 100) + '%');
            if(Math.ceil(progressEvent.loaded / progressEvent.total * 100) == 100) {
              console.info("finish data upload")
            }
          } else {
            console.info('0%');
          }
        }
      });

    if (response.status === 200) {
      // 请求成功，状态码为 200，返回对象
      console.info("Request succeeded:", JSON.stringify(response.data));
      if (callback) callback(JSON.stringify(response.data), undefined);  // 返回string数据
    } else {
      // 状态码不是 200，处理非成功状态
      console.warn(`Request succeeded but returned non-200 status: ${response.status}`);
      if (callback) callback(null, new Error(`Non-200 status code: ${response.status}`)); // 返回错误
    }
  }
  catch (error) {
    console.error('Error occurred:', error);

    // 捕获错误后调用回调函数
    if (callback) callback(null, error);
  }

}

// 假设 response.data 的结构与问题中的相同
export function parseDetectionResult(responseData: RawDetectionResultClass): DetectionResultClass {
  const detectionClasses: string[]= responseData.detection_classes;
  const detectionBoxes = responseData.detection_boxes;
  const detectionScores = responseData.detection_scores;

  // 用于存储所有缺陷的数组
  const defects: Defect[] = [];

  // 遍历所有的检测结果，并生成 Defect 对象
  for (let i = 0; i < detectionClasses.length; i++) {
    const clsStr = detectionClasses[i];
    const box = detectionBoxes[i];
    const score = detectionScores[i];

    // 将 string 类型的检测类别转换为 DefectClass 枚举
    let cls: DefectClass;
    switch (clsStr) {
      case 'Mouse_bite':
        cls = DefectClass.MOUSE_BITE;
        break;
      case 'Open_circuit':
        cls = DefectClass.OPEN_CIRCUIT;
        break;
      case 'Short':
        cls = DefectClass.SHORT;
        break;
      case 'Spur':
        cls = DefectClass.SPUR;
        break;
      case 'Spurious_copper':
        cls = DefectClass.SPURIOUS_COPPER;
        break;
      default:
        throw new Error(`未知的缺陷类型: ${clsStr}`);
    }

    // 创建 Defect 实例
    const defect = new Defect(
      `${i}`, // 用索引作为 id
      cls,    // 缺陷类型
      box[0], // x1
      box[1], // y1
      box[2], // x2
      box[3], // y2
      score   // 置信度
    );

    // 将生成的 Defect 对象添加到数组中
    defects.push(defect);
  }

  // 创建 DetectionResultClass 实例，使用从 response 中获取的数据
  const detectionResult = new DetectionResultClass(
    'result1',               // id，假设为 'result1'
    new Date(),               // 当前日期
    '/path/to/image.jpg',     // 假设图片路径来自另一个来源
    defects,                 // 所有的 Defect 对象
    '暂无'                 // 详情描述/备注
  );

  return detectionResult;
}





