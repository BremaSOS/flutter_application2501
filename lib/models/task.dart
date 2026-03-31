import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String mataPelajaran;

  @HiveField(2)
  late String deskripsi;

  @HiveField(3)
  late DateTime deadline;

  @HiveField(4)
  late DateTime dibuatPada;

  Task({
    required this.id,
    required this.mataPelajaran,
    required this.deskripsi,
    required this.deadline,
    required this.dibuatPada,
  });
}