import 'dart:math';

import '../gamestate.dart';
import '../modifier.dart';
import '../nations/pops.dart';
import 'buildings.dart';
import 'world.dart';
import 'package:CommonLib/Colours.dart';
import '../nations/nation.dart';
import 'package:CommonLib/Random.dart';

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
  int surplusfood = 0;
  Building underConstruction;
  double constructionProgress;
  Map<Building,int> buildings = <Building,int>{};
  List<Location> roadDestinations = <Location>[];
  int left = 1000000;
  int right = -1;
  int top = 1000000;
  int bottom = -1;
  Map<Poptype, int> popweights;
  Map<Poptype, int> lastmonthsgrowth = <Poptype, int>{};
  Map<Poptype, double> poptypepercentage = <Poptype,double>{};


  final World world;

  Location( int this.id, int this.population, String this.name, World this.world, Colour this.mapcolour );

  void initPoptypes(){
    Random random = new Random();
    Map<Poptype, int> weights = <Poptype, int>{};
    for ( Poptype poptype in Poptypes.list ){
      int i = random.nextIntRange(200, 3000);
      weights[poptype] = (i*poptype.size).floor();
      Modifier mod = new Modifier("${poptype.name}_growth", true);
      mod.effects["${poptype.name}_growth"] = 1;
      Modifiers.add(mod);
      this.surplusfood += weights[poptype];
    }
    for ( Poptype pop in Poptypes.list ) {
      lastmonthsgrowth[pop] = 0;
      poptypepercentage[pop] = pop.size;
    }
    this.surplusfood += random.nextIntRange(100, 800);
    this.popweights = weights;
  }

  String getPopWeights( Map<Poptype,int> weights ) {
    StringBuffer sb = new StringBuffer();
    sb.write("<table>");
    for ( Poptype pop in weights.keys ){
      final String colored = Utils.getTextColor(lastmonthsgrowth[pop]);
      sb.write("<tr>");
      sb.write("<td>${pop.name}</td>");
      sb.write("<td>${weights[pop]}</td>");
      sb.write("<td>${colored}</td>");
      sb.write("</tr>");
    }
    sb.write("</table>");
    return sb.toString();
  }

  void calcPopDistribution( Map<Poptype,int> weights ) {

  }

  void updateValues() {
    income = population*0.1;
    double popcap = getModValue("populationcap");
    surplusfood = surplusfood + popcap.floor();
    //Pops

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
    int popcalc = 0;
    if ( popweights.isNotEmpty ) {
      for ( Poptype pop in popweights.keys ){
        popcalc += popweights[pop];
      }
      this.population = popcalc;
    }
  }

  void dailyUpdate() {
    this.updateValues();

  }

  void monthlyUpdate(Random random) {
    this.cleanupModifiers();
    if ( population < surplusfood && owner != null ){
      for (Poptype pop in popweights.keys) {
        if ( population < surplusfood ){
          int i = ((game.random.nextInt(3)+getModValue("${pop.name}_growth")+owner.getModValue("${pop.name}_growth")+(surplusfood-population)*0.05)*poptypepercentage[pop]).floor();
          popweights[pop] += i;
          lastmonthsgrowth[pop] = i;
        }
      }
    }
    else if ( population > surplusfood && owner != null ){
      for (Poptype pop in popweights.keys) {
        if ( population > surplusfood ) {
          int i = -1-(((surplusfood-population)-(popweights[pop]*0.1))*poptypepercentage[pop]).floor();
          popweights[pop] += i;
          lastmonthsgrowth[pop] = i;
        }
      }
    }
    updateValues();
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