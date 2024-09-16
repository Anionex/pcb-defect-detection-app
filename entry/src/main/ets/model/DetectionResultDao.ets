import { relationalStore } from '@kit.ArkData';
import { DefectNameClass, DefectClass, DetectionResultClass } from './DetectionResultsClasses';
import { DatabaseManager } from './DatabaseManager';

// 定义 ValuesBucket 类型
type ValueType = number | string | Uint8Array | null;
type ValuesBucket = Record<string, ValueType>;

// 更新 DetectionResultValues 和 DefectValues 接口
interface DetectionResultValues extends ValuesBucket {
  ID: string;
  DATE: number;
  IMAGE_PATH: string | null;
  DETAILS: string | null;
}

interface DefectValues extends ValuesBucket {
  ID: string;
  DETECTION_RESULT_ID: string;
  CLASS: string;
  X1: number;
  Y1: number;
  X2: number;
  Y2: number;
  CONF: number;
}

// 安全查询辅助函数
async function safeQuery(
  store: relationalStore.RdbStore,
  predicates: relationalStore.RdbPredicates,
  columns: string[] | null
): Promise<relationalStore.ResultSet | null> {
  console.info('Executing query with predicates:', predicates, 'and columns:', columns);
  try {
    const result = await store.query(predicates, columns);
    if (result === undefined) {
      console.error('Query returned undefined');
      return null;
    }
    return result;
  } catch (error) {
    console.error('Error during query execution:', error);
    return null;
  }
}

export class DetectionResultDao {
  private store: relationalStore.RdbStore;

  constructor() {
    console.info('Initializing DetectionResultDao and acquiring database instance.');
    this.store = DatabaseManager.getInstance().getDatabase();
  }

  async insert(result: DetectionResultClass): Promise<void> {
    console.info('Inserting detection result:', result);
    const resultValues: DetectionResultValues = {
      ID: result.id,
      DATE: result.date.getTime(),
      IMAGE_PATH: result.imagePath || null,
      DETAILS: result.details || null,
    };

    try {
      await this.store.insert('DETECTION_RESULT', resultValues);
      console.info('Inserted DETECTION_RESULT with ID:', result.id);

      for (const defect of result.results) {
        console.info('Inserting defect:', defect);
        const defectValues: DefectValues = {
          ID: defect.id,
          DETECTION_RESULT_ID: result.id,
          CLASS: defect.cls,
          X1: defect.x1 ?? 0,
          Y1: defect.y1 ?? 0,
          X2: defect.x2 ?? 0,
          Y2: defect.y2 ?? 0,
          CONF: defect.conf ?? 0,
        };
        await this.store.insert('DEFECT', defectValues);
        console.info('Inserted DEFECT with ID:', defect.id);
      }
    } catch (error) {
      console.error('Failed to insert detection result:', error);
    }
  }

  async getById(id: string): Promise<DetectionResultClass | null> {
    console.info('Fetching detection result by ID:', id);
    const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
    predicates.equalTo('ID', id);

    try {
      const resultSet = await safeQuery(this.store, predicates, ['ID', 'DATE', 'IMAGE_PATH', 'DETAILS']);
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const result = new DetectionResultClass(
          resultSet.getString(resultSet.getColumnIndex('ID')),
          new Date(resultSet.getLong(resultSet.getColumnIndex('DATE'))),
          resultSet.getString(resultSet.getColumnIndex('IMAGE_PATH')) || undefined,
          [],
          resultSet.getString(resultSet.getColumnIndex('DETAILS')) || undefined
        );
        console.info('Detected DetectionResult:', result);

        const defectPredicates = new relationalStore.RdbPredicates('DEFECT');
        defectPredicates.equalTo('DETECTION_RESULT_ID', id);
        const defectResultSet = await safeQuery(this.store, defectPredicates, null);

        if (defectResultSet) {
          while (defectResultSet.goToNextRow()) {
            const defect = new DefectClass(
              defectResultSet.getString(defectResultSet.getColumnIndex('ID')),
              defectResultSet.getString(defectResultSet.getColumnIndex('CLASS')) as DefectNameClass,
              defectResultSet.getDouble(defectResultSet.getColumnIndex('Y1')),
              defectResultSet.getDouble(defectResultSet.getColumnIndex('X1')),
              defectResultSet.getDouble(defectResultSet.getColumnIndex('Y2')),
              defectResultSet.getDouble(defectResultSet.getColumnIndex('X2')),
              defectResultSet.getDouble(defectResultSet.getColumnIndex('CONF'))
            );
            console.info('Fetched defect:', defect);
            result.results.push(defect);
          }
          defectResultSet.close();
          console.info('All defects fetched for DetectionResult ID:', id);
        }

        resultSet.close();
        return result;
      }
      console.info('No DetectionResult found with ID:', id);
      return null;
    } catch (error) {
      console.error('Failed to get detection result by ID:', error);
      return null;
    }
  }

  async update(result: DetectionResultClass): Promise<void> {
    console.info('Updating detection result:', result);
    const resultValues: DetectionResultValues = {
      ID: result.id,
      DATE: result.date.getTime(),
      IMAGE_PATH: result.imagePath || null,
      DETAILS: result.details || null,
    };

    try {
      const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
      predicates.equalTo('ID', result.id);
      await this.store.update(resultValues, predicates);
      console.info('Updated DETECTION_RESULT with ID:', result.id);

      // 删除旧的 Defect 记录
      const defectPredicates = new relationalStore.RdbPredicates('DEFECT');
      defectPredicates.equalTo('DETECTION_RESULT_ID', result.id);
      await this.store.delete(defectPredicates);
      console.info('Deleted old DEFECT records for DetectionResult ID:', result.id);

      // 插入新的 Defect 记录
      for (const defect of result.results) {
        console.info('Inserting updated defect:', defect);
        const defectValues: DefectValues = {
          ID: defect.id,
          DETECTION_RESULT_ID: result.id,
          CLASS: defect.cls,
          X1: defect.x1 ?? 0,
          Y1: defect.y1 ?? 0,
          X2: defect.x2 ?? 0,
          Y2: defect.y2 ?? 0,
          CONF: defect.conf ?? 0,
        };
        await this.store.insert('DEFECT', defectValues);
        console.info('Inserted updated DEFECT with ID:', defect.id);
      }
    } catch (error) {
      console.error('Failed to update detection result:', error);
    }
  }

  async delete(id: string): Promise<void> {
    console.info('Deleting detection result with ID:', id);
    try {
      const resultPredicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
      resultPredicates.equalTo('ID', id);

      const defectPredicates = new relationalStore.RdbPredicates('DEFECT');
      defectPredicates.equalTo('DETECTION_RESULT_ID', id);

      await this.store.delete(defectPredicates);
      console.info('Deleted DEFECT records for DetectionResult ID:', id);

      await this.store.delete(resultPredicates);
      console.info('Deleted DETECTION_RESULT with ID:', id);
    } catch (error) {
      console.error('Failed to delete detection result:', error);
    }
  }

  async getAll(): Promise<DetectionResultClass[]> {
    console.info('Fetching all detection results.');
    const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');

    try {
      const resultSet = await safeQuery(this.store, predicates, null);
      const results: DetectionResultClass[] = [];

      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getString(resultSet.getColumnIndex('ID'));
          console.info('Processing DetectionResult ID:', id);
          const result = await this.getById(id);
          if (result) {
            results.push(result);
            console.info('Added DetectionResult to results:', id);
          }
        }
        resultSet.close();
        console.info('All detection results have been fetched.');
      }
      return results;
    } catch (error) {
      console.error('Failed to get all detection results:', error);
      return [];
    }
  }

  /**
   * 获取 DETECTION_RESULT 表中的记录总数。
   * @returns 返回检测结果的总数。
   */
  async getCount(): Promise<number> {
    console.info('Fetching count of detection results.');
    const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');

    try {
      // 假设 relationalStore 支持使用聚合函数，如 COUNT(*)
      // 并且可以为聚合结果指定别名，如 'count'
      const resultSet = await safeQuery(this.store, predicates, ['COUNT(*) AS count']);

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const countColumnIndex = resultSet.getColumnIndex('count');
        const count = resultSet.getLong(countColumnIndex);
        resultSet.close();
        console.info('Total detection results count:', count);
        return count;
      }

      console.info('No detection results found.');
      return 0;
    } catch (error) {
      console.error('Failed to get detection results count:', error);
      return 0;
    }
  }

  async getFilteredResults(startDate?: Date, endDate?: Date, minDefects?: number, maxDefects?: number): Promise<DetectionResultClass[]> {
    const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
    
    if (startDate) {
      startDate.setHours(0, 0, 0, 0);
      predicates.and().greaterThanOrEqualTo('DATE', startDate.getTime());
    }
    
    if (endDate) {
      endDate.setHours(23, 59, 59, 999);
      predicates.and().lessThanOrEqualTo('DATE', endDate.getTime());
    }

    try {
      const resultSet = await safeQuery(this.store, predicates, null);
      const results: DetectionResultClass[] = [];

      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getString(resultSet.getColumnIndex('ID'));
          const result = await this.getById(id);
          if (result) {
            const defectCount = result.results.length;
            if ((minDefects === undefined || defectCount >= minDefects) &&
                (maxDefects === undefined || defectCount <= maxDefects)) {
              results.push(result);
            }
          }
        }
        resultSet.close();
        console.info('筛选后的检测结果已获取');
      }
      return results;
    } catch (error) {
      console.error('获取筛选后的检测结果失败:', error);
      return [];
    }
  }

  async getNewID(): Promise<string> {
    console.info('正在生成新的检测结果ID');
    const predicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
    predicates.orderByDesc('ID');
    predicates.limitAs(1);

    try {
      const resultSet = await safeQuery(this.store, predicates, ['ID']);
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const lastID = resultSet.getString(resultSet.getColumnIndex('ID'));
        resultSet.close();

        const lastNumber = parseInt(lastID.split('_')[1]);
        const newNumber = lastNumber + 1;
        const newID = `result_${newNumber}`;

        console.info('生成的新ID:', newID);
        return newID;
      } else {
        console.info('数据库为空,返回初始ID');
        return 'result_1';
      }
    } catch (error) {
      console.error('生成新ID时出错:', error);
      return 'result_error';
    }
  }

  async getResultsByDateRange(startDate: Date, endDate: Date): Promise<DetectionResultClass[]> {
    console.info('按日期范围获取检测结果');
    return this.getFilteredResults(startDate, endDate);
  }

  async getResultsByDefectCount(minDefects: number, maxDefects: number): Promise<DetectionResultClass[]> {
    console.info('按缺陷数量获取检测结果');
    return this.getFilteredResults(undefined, undefined, minDefects, maxDefects);
  }

  async deleteById(id: string): Promise<boolean> {
    console.info('正在删除ID为', id, '的检测结果');
    try {
      // 首先删除关联的缺陷记录
      const defectPredicates = new relationalStore.RdbPredicates('DEFECT');
      defectPredicates.equalTo('DETECTION_RESULT_ID', id);
      await this.store.delete(defectPredicates);
      console.info('已删除与检测结果关联的缺陷记录');

      // 然后删除检测结果记录
      const resultPredicates = new relationalStore.RdbPredicates('DETECTION_RESULT');
      resultPredicates.equalTo('ID', id);
      const deletedRows = await this.store.delete(resultPredicates);
      
      if (deletedRows > 0) {
        console.info('成功删除ID为', id, '的检测结果');
        return true;
      } else {
        console.info('未找到ID为', id, '的检测结果');
        return false;
      }
    } catch (error) {
      console.error('删除检测结果时出错:', error);
      return false;
    }
  }
}
