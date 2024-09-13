import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

export class DatabaseManager {
  private static instance: DatabaseManager;
  private db: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  async initDatabase(context: Context): Promise<void> {
    if (this.db) return;

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'PcbDetection.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.db = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.createTables();
      console.info('数据库初始化成功');
    } catch (err) {
      console.error(`数据库初始化失败: ${err.message}`);
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) throw new Error('数据库未初始化');

    const CREATE_DETECTION_RESULT_TABLE = `
      CREATE TABLE IF NOT EXISTS DETECTION_RESULT (
        ID TEXT PRIMARY KEY,
        DATE INTEGER,
        IMAGE_PATH TEXT,
        DETAILS TEXT
      )`;

    const CREATE_DEFECT_TABLE = `
      CREATE TABLE IF NOT EXISTS DEFECT (
        ID TEXT PRIMARY KEY,
        DETECTION_RESULT_ID TEXT,
        CLASS TEXT,
        X1 REAL,
        Y1 REAL,
        X2 REAL,
        Y2 REAL,
        CONF REAL,
        FOREIGN KEY (DETECTION_RESULT_ID) REFERENCES DETECTION_RESULT(ID)
      )`;

    await this.db.executeSql(CREATE_DETECTION_RESULT_TABLE);
    await this.db.executeSql(CREATE_DEFECT_TABLE);
  }

  getDatabase(): relationalStore.RdbStore {
    if (!this.db) throw new Error('数据库未初始化');
    return this.db;
  }
}