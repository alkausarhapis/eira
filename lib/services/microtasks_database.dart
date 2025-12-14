import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/microtask_model.dart';

class MicrotasksDatabase {
  static final MicrotasksDatabase instance = MicrotasksDatabase._init();
  static Database? _database;

  MicrotasksDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eira_microtasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE microtasks (
        id TEXT PRIMARY KEY,
        judul_target TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        emoji TEXT NOT NULL,
        status TEXT NOT NULL,
        time_taken_seconds INTEGER NOT NULL,
        microtasks_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertMicrotask(MicroTaskModel microtask) async {
    final db = await database;

    final microtasksJson = jsonEncode(
      microtask.microtasks
          .map(
            (item) => {
              'task': item.task,
              'restTimeSeconds': item.restTimeSeconds,
              'isCompleted': item.isCompleted,
            },
          )
          .toList(),
    );

    await db.insert('microtasks', {
      'id': microtask.id,
      'judul_target': microtask.judulTarget,
      'deskripsi': microtask.deskripsi,
      'emoji': microtask.emoji,
      'status': microtask.status,
      'time_taken_seconds': microtask.timeTaken.inSeconds,
      'microtasks_json': microtasksJson,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MicroTaskModel>> getAllMicrotasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'microtasks',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      final microtasksData = jsonDecode(maps[i]['microtasks_json']) as List;
      final microtasksList = microtasksData
          .map(
            (item) => MicroTaskItem(
              task: item['task'] as String,
              restTimeSeconds: item['restTimeSeconds'] as int,
              isCompleted: item['isCompleted'] as bool,
            ),
          )
          .toList();

      return MicroTaskModel(
        id: maps[i]['id'],
        judulTarget: maps[i]['judul_target'],
        deskripsi: maps[i]['deskripsi'],
        emoji: maps[i]['emoji'],
        status: maps[i]['status'],
        timeTaken: Duration(seconds: maps[i]['time_taken_seconds']),
        microtasks: microtasksList,
      );
    });
  }

  Future<MicroTaskModel?> getMicrotask(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'microtasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final microtasksData = jsonDecode(maps[0]['microtasks_json']) as List;
    final microtasksList = microtasksData
        .map(
          (item) => MicroTaskItem(
            task: item['task'] as String,
            restTimeSeconds: item['restTimeSeconds'] as int,
            isCompleted: item['isCompleted'] as bool,
          ),
        )
        .toList();

    return MicroTaskModel(
      id: maps[0]['id'],
      judulTarget: maps[0]['judul_target'],
      deskripsi: maps[0]['deskripsi'],
      emoji: maps[0]['emoji'],
      status: maps[0]['status'],
      timeTaken: Duration(seconds: maps[0]['time_taken_seconds']),
      microtasks: microtasksList,
    );
  }

  Future<void> updateMicrotask(MicroTaskModel microtask) async {
    final db = await database;

    final microtasksJson = jsonEncode(
      microtask.microtasks
          .map(
            (item) => {
              'task': item.task,
              'restTimeSeconds': item.restTimeSeconds,
              'isCompleted': item.isCompleted,
            },
          )
          .toList(),
    );

    await db.update(
      'microtasks',
      {
        'judul_target': microtask.judulTarget,
        'deskripsi': microtask.deskripsi,
        'emoji': microtask.emoji,
        'status': microtask.status,
        'time_taken_seconds': microtask.timeTaken.inSeconds,
        'microtasks_json': microtasksJson,
      },
      where: 'id = ?',
      whereArgs: [microtask.id],
    );
  }

  Future<void> deleteMicrotask(String id) async {
    final db = await database;
    await db.delete('microtasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllMicrotasks() async {
    final db = await database;
    await db.delete('microtasks');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
