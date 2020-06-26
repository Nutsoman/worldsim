import 'dart:math';

import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../gamestate.dart';
import '../modifier.dart';
import '../nations/nation.dart';
import '../nations/pops.dart';
import '../units/army.dart';
import 'buildings.dart';
import 'world.dart';

class Territory with Modifiable {
  final int id;
  int population;
  double income;
  String name;
  Colour mapcolour;
  Set<Territory> neighbours = <Territory>{};
  Map<Territory,int> neighbourdist = <Territory,int>{};
  Point<int> centre;
  Nation owner;
  double growthrate = 1.05;
  int surplusfood = 0;
  Building underConstruction;
  double constructionProgress;
  Map<Building,int> buildings = <Building,int>{};
  List<Territory> roadDestinations = <Territory>[];
  int left = 1000000;
  int right = -1;
  int top = 1000000;
  int bottom = -1;
  Map<Poptype, int> popweights;
  Map<Poptype, int> lastmonthsgrowth = <Poptype, int>{};
  Map<Poptype, double> poptypepercentage = <Poptype,double>{};
  double baseDefenseModifier;
  double totalDefenseModifier;
  Set<Army> localArmies = <Army>{};
  Set<Army> seenBy = <Army>{};

  final World world;

  Territory( int this.id, int this.population, String this.name, World this.world, Colour this.mapcolour, double this.baseDefenseModifier );

  static void init(Gamestate game){
    for ( Territory location in game.world.locations ){
      location.updateValues();
    }
    for ( Territory location in game.world.locations ){
      location.initPoptypes();
      location.dailyUpdate();
    }
  }

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
      final String colored = TextUtils.getTextColor(lastmonthsgrowth[pop]);
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
  }

  void calcModifiers() {
    double defensiveness = getModValue("defensiveness");
    totalDefenseModifier = baseDefenseModifier + defensiveness;
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
        calcModifiers();

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
    if ( owner != null ){
      for (Poptype pop in popweights.keys) {
        int i = ((game.random.nextInt(3)+getModValue("${pop.name}_growth")+owner.getModValue("${pop.name}_growth")+(surplusfood-population)*0.05)*poptypepercentage[pop]).floor();
        popweights[pop] += i;
        lastmonthsgrowth[pop] = i;
      }
    }
    updateValues();
  }

  void startBuilding(Building building){
      if ( underConstruction == null ) {
        underConstruction = building;
        constructionProgress = 0;
      }
  }

  void buildRoad(Territory neighbour){
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