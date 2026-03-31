import 'package:hive/hive.dart';

part 'roster.g.dart';

@HiveType(typeId: 0)
class Roster extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String mataPelajaran;

  @HiveField(2)
  late String hari;

  @HiveField(3)
  late String jamMulai; // format "HH:mm"

  @HiveField(4)
  late String jamSelesai; // format "HH:mm"

  Roster({
    required this.id,
    required this.mataPelajaran,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });
}