import 'location.dart';
import '../modifier.dart';

class Building {
  final String name;
  final Modifier mod;
  final double cost;
  final int buildtime;

  Building( String this.name, Modifier this.mod, double this.cost, int this.buildtime );

}

abstract class Buildings {
  static final List<Building> list = <Building>[];
  static final Map<String,Building> byname = <String,Building>{};

  static void add(Building building) {
    list.add(building);
    byname[building.name] = building;
  }

  static Future<void> init() async {
    Modifier buildingmod = new Modifier("pop_building_mod", true);
    buildingmod.effects["populationcap"] = 2;
    Modifiers.add(buildingmod);
    Building pop_building = new Building("pop_building", buildingmod, 0.1, 5);
    add(pop_building);
  }

}