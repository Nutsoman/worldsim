import 'dart:html';
import 'dart:async';
import 'map/world.dart';

Future<void> main() async {
  World world = new World();
  await world.loadData("map/location_data.json","map/map.png");
}
