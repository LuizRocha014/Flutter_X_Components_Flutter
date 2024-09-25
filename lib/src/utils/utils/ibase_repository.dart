import 'package:componentes_lr/src/models/infos_table_database.dart';
import 'package:componentes_lr/src/utils/utils/icontext.dart';

abstract class IBaseRepository<T> {
  late final IContext context;
  late final InfosTableDatabase infosTableDatabase;
  late final T Function(Map<String, dynamic>) fromJson;
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T?> create(Map<String, dynamic> json);
  Future<void> createNoReturn(Map<String, dynamic> json);
  Future<T?> createOrReplace(Map<String, dynamic> json);
  Future<List<T>> createList(Iterable<Map<String, dynamic>> json);
  Future<void> createListNoReturn(Iterable<Map<String, dynamic>> json);
  Future<T?> update(Map<String, dynamic> json);
  Future<bool> delete(String id);
  Future<bool> deleteAll();
}
