// 위치 데이터 로컬 저장소
// 오프라인 상태에서 위치 데이터를 저장하고 관리

import 'package:driver_app/data/models/location_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocationDatabase {
  static const String _databaseName = 'location_database.db';
  static const int _databaseVersion = 1;
  
  // 테이블 및 컬럼 이름
  static const String tableLocations = 'locations';
  static const String columnId = 'id';
  static const String columnBusId = 'busId';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnSpeed = 'speed';
  static const String columnHeading = 'heading';
  static const String columnAccuracy = 'accuracy';
  static const String columnTimestamp = 'timestamp';
  
  // 싱글톤 패턴 구현
  static final LocationDatabase _instance = LocationDatabase._internal();
  factory LocationDatabase() => _instance;
  LocationDatabase._internal();
  
  static Database? _database;
  
  // 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  // 데이터베이스 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableLocations (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnBusId TEXT NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnSpeed REAL,
        $columnHeading REAL,
        $columnAccuracy REAL,
        $columnTimestamp INTEGER NOT NULL
      )
    ''');
    
    // 인덱스 생성 (쿼리 최적화)
    await db.execute(
      'CREATE INDEX idx_busid_timestamp ON $tableLocations ($columnBusId, $columnTimestamp)'
    );
  }
  
  // 위치 데이터 저장
  Future<int> saveLocation(LocationData location) async {
    final db = await database;
    return await db.insert(
      tableLocations,
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // 버스 ID로 위치 데이터 조회
  Future<List<LocationData>> getLocations(String busId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableLocations,
      where: '$columnBusId = ?',
      whereArgs: [busId],
      orderBy: '$columnTimestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return LocationData.fromMap(maps[i]);
    });
  }
  
  // 버스 ID로 위치 데이터 삭제
  Future<int> deleteLocations(String busId) async {
    final db = await database;
    return await db.delete(
      tableLocations,
      where: '$columnBusId = ?',
      whereArgs: [busId],
    );
  }
  
  // 저장된 레코드 수 제한
  Future<void> limitStoredLocations(int maxCount) async {
    final db = await database;
    
    // 전체 레코드 수 확인
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableLocations')
    ) ?? 0;
    
    if (count > maxCount) {
      // 가장 오래된 레코드부터 삭제
      final deleteCount = count - maxCount;
      await db.execute('''
        DELETE FROM $tableLocations
        WHERE $columnId IN (
          SELECT $columnId FROM $tableLocations
          ORDER BY $columnTimestamp ASC
          LIMIT $deleteCount
        )
      ''');
    }
  }
  
  // 모든 위치 데이터 삭제
  Future<int> deleteAllLocations() async {
    final db = await database;
    return await db.delete(tableLocations);
  }
  
  // 가장 최근 위치 조회
  Future<LocationData?> getLatestLocation(String busId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableLocations,
      where: '$columnBusId = ?',
      whereArgs: [busId],
      orderBy: '$columnTimestamp DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return LocationData.fromMap(maps.first);
    }
    
    return null;
  }
}