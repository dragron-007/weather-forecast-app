import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class WeatherModel {
  @HiveField(0)
  final String city;
  @HiveField(1)
  final Map<String, dynamic> currentWeather;
  @HiveField(2)
  final Map<String, dynamic> forecast;

  WeatherModel(this.city, this.currentWeather, this.forecast);
}
