import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../gamestate.dart';
import '../map/location.dart';
import '../map/world.dart';
import '../modifier.dart';

class Nation with Modifiable {
  Set<Location> territory = <Location>{};
  String name;
  Colour mapcolour;
  double treasury = 0.50;
  World world;

  @override
  Gamestate get game => world.game;

  Nation(String this.name, Colour this.mapcolour, World this.world);

  void logicUpdate(){

  }

  void dailyUpdate(){

  }

  void monthlyUpdate(Random random) {
    for ( Location location in territory ) {
      this.treasury += location.income;
    }
    this.cleanupModifiers();
  }

}