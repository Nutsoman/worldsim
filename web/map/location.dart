import 'dart:math';

import 'world.dart';
import 'package:CommonLib/Colours.dart';

class Location {
  final int id;
  int population;
  double income;
  String name;
  Colour mapcolour;
  Set<Location> neighbours = <Location>{};
  Point<int> centre;

  final World world;

  Location( int this.id, int this.population, String this.name, World this.world, Colour this.mapcolour );



  @override
  String toString() {
    return "$id $name";
  }
}