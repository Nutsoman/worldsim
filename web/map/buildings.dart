import 'territory.dart';
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
    buildingmod.effects["foodsupply"] = 20;
    Modifiers.add(buildingmod);
    Building pop_building = new Building("Farmland", buildingmod, 50, 40);
    add(pop_building);

    Modifier buildingmultmod = new Modifier("pop_cap_mult_mod", true);
    buildingmultmod.effects["foodsupplymult"] = 0.05;
    Modifiers.add(buildingmultmod);
    Building pop_mult_building = new Building("Granary", buildingmultmod, 100, 120);
    add(pop_mult_building);

  }

}