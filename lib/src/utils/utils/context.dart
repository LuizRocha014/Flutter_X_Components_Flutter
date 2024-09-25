// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:componentes_lr/src/models/infos_table_database.dart';
import 'package:componentes_lr/src/models/widgets/bottom_sheet_popup.dart';
import 'package:componentes_lr/src/utils/utils/file_util.dart';
import 'package:componentes_lr/src/utils/utils/migrations/base_migration.dart';
import 'package:componentes_lr/src/utils/utils/routes.dart';
import 'package:componentes_lr/src/utils/utils/storage.dart';
import 'package:componentes_lr/src/utils/utils/transaction_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Context implements IContext {
  final String nameDatabase;
  final String? password;
  final int version;
  final List<InfosTableDatabase> tables;
  final List<BaseMigration> migrations;
  late final Database database;
  final TransactionManager _transactionManager = TransactionManager();

  //Singleton
  static Context? _instance;

  factory Context({
    required String nameDatabase,
    String? password,
    required int version,
    required List<InfosTableDatabase> tables,
    List<BaseMigration> migrations = const [],
  }) {
    _instance ??= Context.nonFactoryConstructor(
      nameDatabase: nameDatabase,
      password: password,
      version: version,
      tables: tables,
      migrations: migrations,
    );
    return _instance!;
  }
  Context.nonFactoryConstructor({
    required String nameDatabase,
    String? password,
    required int version,
    required List<InfosTableDatabase> tables,
    List<BaseMigration> migrations = const [],
  }) : this._internal(
          nameDatabase: nameDatabase,
          password: password,
          version: version,
          tables: tables,
          migrations: migrations,
        );

  Context._internal({
    required this.nameDatabase,
    required this.password,
    required this.version,
    required this.tables,
    required this.migrations,
  });

  //Getters

  Future<String> get pathDatabase async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/$nameDatabase.db";
  }

  @override
  Future<Database> initializeDatabase({String? path}) async {
    path ??= await pathDatabase;
    log(path, name: "Banco de Dados");
    final database = await openDatabase(
      path,
      version: version,
      onCreate: _createDb,
      onUpgrade: _updgradeDb,
      password: password ?? null,
    );
    this.database = database;
    return database;
  }

  Future<void> _updgradeDb(Database db, int oldVersion, int newVersion) async {
    try {
      for (int version = oldVersion; version <= newVersion; version++) {
        final migration = migrations.firstWhereOrNull((m) => m.version == version);
        if (migration != null) {
          await migration.executaMigrations(db);
          log("Migration executada para versão $version", name: "SQLITE");
        } else {
          log("Nenhuma migration encontrada para versão $version", name: "SQLITE");
        }
      }
    } catch (e) {
      log("Erro ao gerar migration: $e");
    }
  }

  Future<void> _createDb(Database db, int newVersion) async {
    for (final table in tables) {
      try {
        final script = table.createTable;
        log(script, name: "CREATE TABLE ${table.tableName}");
        await db.execute(script);
      } catch (e) {
        log(
          "Erro ao executar CREATE TABLE IF NOT EXISTS na tabela ${table.tableName}: $e",
          name: "LOG - Erro Ocorrido",
        );
      }
    }
  }

  @override
  Future<int> deleteDbValues() async {
    int qntErros = 0;
    for (final table in tables) {
      try {
        final script = "DELETE FROM ${table.tableName}";
        log(script);
        await database.execute(script);
      } catch (e) {
        qntErros++;
        log(
          "Erro ao executar DELETE FROM na tabela ${table.tableName}: $e",
          name: "LOG - Erro Ocorrido",
        );
      }
    }
    return qntErros;
  }

  @override
  Future<bool> exportDatabase(BuildContext context, {bool senhaBanco = true}) async {
    try {
      if (!context.mounted) return false;
      if (senhaBanco) {
        await openDefaultPopUp(
          context,
          tituloConfirmar: "Ok",
          titulo: "Senha Banco de Dados",
          children: [
            SelectableText((await secureStorage.readSecureStorage("SenhaBancoDeDados")).toString()),
          ],
          onTapBotaoConfirmar: () => context.pop(),
        );
      }

      await exportFile(File(await pathDatabase), '${nameDatabase}_${DateTime.now().millisecondsSinceEpoch}', 'db');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteDb() async {
    try {
      await deleteDatabase(await pathDatabase);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) {
    return _transactionManager
        .runTransaction<List<Map<String, Object?>>>(() async => await database.rawQuery(sql, arguments));
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return _transactionManager.runTransaction<int>(
      () async => await database.insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.replace,
      ),
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return _transactionManager.runTransaction<int>(
      () async => await database.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      ),
    );
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    return _transactionManager.runTransaction<int>(() async => await database.rawDelete(sql, arguments));
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) {
    return _transactionManager.runTransaction<int>(() async => await database.rawUpdate(sql, arguments));
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) {
    return _transactionManager.runTransaction<void>(() async => await database.execute(sql, arguments));
  }

  @override
  Future<void> transaction<T>(Future<T> Function(Transaction txn) action) {
    return _transactionManager.runTransaction<void>(() async => await database.transaction(action));
  }
}

extension TransactionInsert on Transaction {
  Future<int> insertReplace(
    String table,
    Map<String, Object?> values,
  ) {
    return database.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
