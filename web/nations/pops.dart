import '../gamestate.dart';
import '../map/world.dart';
import '../modifier.dart';

class Poptype with Modifiable {
  double size;
  String name;
  World world;

  @override
  Gamestate get game => world.game;

  Poptype(String this.name, double this.size) {

  }
}


abstract class Poptypes {
  static final List<Poptype> list = <Poptype>[];
  static final Map<String,Poptype> byname = <String,Poptype>{};

  static void add(Poptype poptype) {
    list.add(poptype);
    byname[poptype.name] = poptype;
  }

  static Future<void> init() async {

    //Generate Poptypes

    Poptype elite = new Poptype("Aristocrats", 0.1);
    add(elite);

    Poptype priests = new Poptype("Priests", 0.1);
    add(priests);

    Poptype tradesmen = new Poptype("Tradesmen", 0.2);
    add(tradesmen);

    Poptype soldiers = new Poptype("Soldiers", 0.3);
    add(soldiers);

    Poptype serfs = new Poptype("Serfs", 0.3);
    add(serfs);

  }

}
