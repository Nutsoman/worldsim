import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../gamestate.dart';
import '../map/territory.dart';
import '../map/world.dart';
import '../modifier.dart';
import '../units/UnitTypes.dart';
import '../units/army.dart';
import 'pops.dart';
import 'package:CommonLib/Random.dart';

class Nation with Modifiable {
  Set<Territory> territory = <Territory>{};
  String name;
  Colour mapcolour;
  double treasury = 0.50;
  World world;
  Territory capital;
  List<Army> armies = <Army>[];
  int globalpopulation = 0;



  @override
  Gamestate get game => world.game;

  Nation(String this.name, Colour this.mapcolour, World this.world);

  static void init(Gamestate game){
    for ( Nation nation in game.world.nations ){
      nation.getNewCapital();
      Army army = nation.createArmy(nation.capital);
      army.addSubUnit(new Subunit(UnitTypes.byname["Levy"]));
    }
  }

  Army createArmy( Territory location ){
    Army army = new Army(this, location);
    this.armies.add(army);
    return army;
  }

  void getNewCapital (){
    if ( this.territory.isNotEmpty ){
      this.capital = game.random.pickFrom(territory);
    }
  }

  void logicUpdate(){

  }

  void dailyUpdate(){

  }

  void monthlyUpdate(Random random) {
    for ( Territory location in territory ) {
      this.treasury += location.income;
    }
    this.cleanupModifiers();
    for ( Territory location in territory ){
      globalpopulation += location.population;
    }

  }
}