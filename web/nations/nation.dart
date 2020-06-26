import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../gamestate.dart';
import '../map/territory.dart';
import '../map/world.dart';
import '../modifier.dart';
import '../units/UnitTypes.dart';
import '../units/army.dart';

class Nation with Modifiable {
  Set<Territory> territory = <Territory>{};
  String name;
  Colour mapcolour;
  double treasury = 0.50;
  World world;
  Territory capital;
  List<Army> armies = <Army>[];
  int globalpopulation = 0;
  Territory startzone;



  @override
  Gamestate get game => world.game;

  Nation(String this.name, Colour this.mapcolour, World this.world);

  static void init(Gamestate game){
    for ( Nation nation in game.world.nations ){
      nation.getNewCapital();
      Army army = nation.createArmy(nation.startzone);
      double amount = game.random.nextDouble( 500.0 );
      army.addSubUnit(new Subunit(UnitTypes.byname["Screaming Maniac"]), amount.ceilToDouble() );
      double amount2 = game.random.nextDouble( 100.0 );
      army.addSubUnit(new Subunit(UnitTypes.byname["Dune Buggy"]), amount2.ceilToDouble() );
      if ( amount2 > 75.0 ) {
        army.addSubUnit(new Subunit(UnitTypes.byname["Weird Guy with a Saucepan"]), 1.0 );
      }
      army.onEnterTerritory(); //setup required
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