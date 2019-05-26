import 'dart:math';

import '../gamestate.dart';
import '../modifier.dart';
import 'buildings.dart';
import 'world.dart';
import 'package:CommonLib/Colours.dart';
import '../nations/nation.dart';

class Location with Modifiable {
  final int id;
  int population;
  double income;
  String name;
  Colour mapcolour;
  Set<Location> neighbours = <Location>{};
  Point<int> centre;
  Nation owner;
  double growthrate = 1.05;
  int populationcap = 0;
  Building underConstruction;
  double constructionProgress;
  Map<Building,int> buildings = <Building,int>{};
  List<Location> roadDestinations = <Location>[];
  int left = 1000000;
  int right = -1;
  int top = 1000000;
  int bottom = -1;

  final World world;

  Location( int this.id, int this.population, String this.name, World this.world, Colour this.mapcolour );

  void updateValues() {
    income = population*0.1;
    double popcap = getModValue("populationcap");
    populationcap = 10 + popcap.floor();
  }

  @override
  Gamestate get game => world.game;

  void logicUpdate() {
    if ( underConstruction != null ){
      if ( constructionProgress >= underConstruction.buildtime ) {
        if ( !buildings.containsKey(underConstruction) ){
          buildings[underConstruction] = 0;
        }
        buildings[underConstruction]++;
        this.addModifierObj(underConstruction.mod);
        underConstruction = null;
        updateValues();

      }
      else {
        constructionProgress += 1;
      }
    }
  }

  void dailyUpdate() {
    this.updateValues();
  }

  void monthlyUpdate(Random random) {
    if( this.population > 0 ) {
      if ( this.population < populationcap ) {
        int popincrease = ( this.population * this.growthrate ).ceil();
        this.population = popincrease;
        this.updateValues();
      }
      else {
        if (random.nextInt(100) < 20) {
          this.population--;
        }
      }
    }
    this.cleanupModifiers();
  }

  void startBuilding(Building building){
      if ( underConstruction == null ){
        if ( this.owner != null && this.owner.treasury >= building.cost ){
          this.owner.treasury -= building.cost;
          underConstruction = building;
          constructionProgress = 0;
        }
      }
  }

  void buildRoad(Location neighbour){
    if ( !roadDestinations.contains(neighbour) && !neighbour.roadDestinations.contains(this) ){
      roadDestinations.add(neighbour);
      world.drawMap(0);
    }
  }

  @override
  String toString() {
    return "$id $name";
  }
}