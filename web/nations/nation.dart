import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../gamestate.dart';
import '../map/location.dart';
import '../map/world.dart';
import '../modifier.dart';
import 'pops.dart';
import 'package:CommonLib/Random.dart';

class Nation with Modifiable {
  Set<Location> territory = <Location>{};
  String name;
  Colour mapcolour;
  double treasury = 0.50;
  World world;

  int globalpopulation = 0;

  Map<Poptype, double> popweights;

  @override
  Gamestate get game => world.game;

  Nation(String this.name, Colour this.mapcolour, World this.world);

  void initPoptypes(){
    Map<Poptype, double> weights = <Poptype, double>{};
    for ( Poptype poptype in Poptypes.list ){
      weights[poptype] = poptype.size;
      Modifier mod = new Modifier("${poptype.name}_growth", true);
      mod.effects["${poptype.name}_growth"] = 0.01;
      Modifiers.add(mod);
    }
    this.popweights = weights;
  }

  void calcPopDistribution( Map<Poptype,double> weights ) {
    double total = 0;
    for ( Poptype pop in weights.keys ){
      weights[pop] *= 1+this.getModValue("${pop.name}_growth");
      total += weights[pop];
    }
    for ( Poptype pop in weights.keys ) {
      if ( weights[pop] != 0 ){
        weights[pop] /= total;
      }
    }
    this.popweights = weights;
  }

  String getPopWeights( Map<Poptype,double> weights ) {
    StringBuffer sb = new StringBuffer();
    sb.write("Population Information<br>");
    for ( Poptype pop in weights.keys ){
      sb.write(pop.name);
      sb.write(": ");
      sb.write((weights[pop]*100));
      sb.write("%");
      sb.write("<br>");
    }
    return sb.toString();
  }

  void logicUpdate(){

  }

  void dailyUpdate(){

  }

  void monthlyUpdate(Random random) {
    for ( Location location in territory ) {
      this.treasury += location.income;
    }
    this.cleanupModifiers();
    for ( Location location in territory ){
      globalpopulation += location.population;
    }

  }
}