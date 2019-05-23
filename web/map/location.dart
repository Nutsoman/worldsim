import 'dart:math';

import 'world.dart';
import 'package:CommonLib/Colours.dart';
import '../nations/nation.dart';

class Location {
  final int id;
  int population;
  double income;
  String name;
  Colour mapcolour;
  Set<Location> neighbours = <Location>{};
  Point<int> centre;
  Nation owner;

  final World world;

  Location( int this.id, int this.population, String this.name, World this.world, Colour this.mapcolour );

  void updateValues() {
    income = population*0.1;
  }

  @override
  String toString() {
    return "$id $name";
  }
}