import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_block_model.dart';

class BlockedAppsDatabase {
  static final BlockedAppsDatabase instance = BlockedAppsDatabase._init();
  static Database? _database;

  BlockedAppsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('blocked_apps.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blocked_apps (
        package_name TEXT PRIMARY KEY,
        app_name TEXT NOT NULL,
        limit_millis INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        unblock_time INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> insertBlockedApp(BlockedAppModel app) async {
    final db = await database;
    await db.insert('blocked_apps', {
      'package_name': app.packageName,
      'app_name': app.appName,
      'limit_millis': app.blockDurationMillis,
      'start_time': DateTime.now().millisecondsSinceEpoch,
      'unblock_time': app.blockedUntil,
      'is_active': app.isBlocked ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BlockedAppModel>> getBlockedApps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('blocked_apps');

    return List.generate(maps.length, (i) {
      return BlockedAppModel(
        packageName: maps[i]['package_name'],
        appName: maps[i]['app_name'],
        blockedUntil: maps[i]['unblock_time'],
        timeSpentSnapshot: 0,
        isBlocked: maps[i]['is_active'] == 1,
        blockDurationMillis: maps[i]['limit_millis'],
      );
    });
  }

  Future<List<BlockedAppModel>> getActiveBlockedApps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blocked_apps',
      where: 'is_active = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return BlockedAppModel(
        packageName: maps[i]['package_name'],
        appName: maps[i]['app_name'],
        blockedUntil: maps[i]['unblock_time'],
        timeSpentSnapshot: 0,
        isBlocked: maps[i]['is_active'] == 1,
        blockDurationMillis: maps[i]['limit_millis'],
      );
    });
  }

  Future<BlockedAppModel?> getBlockedApp(String packageName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blocked_apps',
      where: 'package_name = ?',
      whereArgs: [packageName],
    );

    if (maps.isEmpty) return null;

    return BlockedAppModel(
      packageName: maps[0]['package_name'],
      appName: maps[0]['app_name'],
      blockedUntil: maps[0]['unblock_time'],
      timeSpentSnapshot: 0,
      isBlocked: maps[0]['is_active'] == 1,
      blockDurationMillis: maps[0]['limit_millis'],
    );
  }

  Future<void> updateBlockedApp(BlockedAppModel app) async {
    final db = await database;
    await db.update(
      'blocked_apps',
      {
        'app_name': app.appName,
        'limit_millis': app.blockDurationMillis,
        'start_time': DateTime.now().millisecondsSinceEpoch,
        'unblock_time': app.blockedUntil,
        'is_active': app.isBlocked ? 1 : 0,
      },
      where: 'package_name = ?',
      whereArgs: [app.packageName],
    );
  }

  Future<void> deleteBlockedApp(String packageName) async {
    final db = await database;
    await db.delete(
      'blocked_apps',
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> deactivateBlockedApp(String packageName) async {
    final db = await database;
    await db.update(
      'blocked_apps',
      {'is_active': 0},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> cleanupExpiredBlocks() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete(
      'blocked_apps',
      where: 'unblock_time <= ?',
      whereArgs: [now],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
