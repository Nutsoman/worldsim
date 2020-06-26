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
    Modifier buildingmod = new Modifier("defensiveness_mod", true);
    buildingmod.effects["defensiveness"] = 0.05;
    Modifiers.add(buildingmod);
    Building pop_building = new Building("Defenses", buildingmod, 0, 0);
    add(pop_building);
  }

}