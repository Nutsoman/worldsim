

class UnitType{
  String name;
  double speed;
  double attack;
  double defense;
  double cohesion;
  double failchance;

  UnitType( String this.name, double this.speed, double this.attack, double this.defense, double this.cohesion, double this.failchance );

}

abstract class UnitTypes {

  static final List<UnitType> list = <UnitType>[];
  static final Map<String,UnitType> byname = <String,UnitType>{};

  static void add(UnitType unittype) {
    list.add(unittype);
    byname[unittype.name] = unittype;
  }

  static Future<void> init() async {

    //Generate Poptypes

    UnitType levy = new UnitType("Screaming Maniac", 1.0, 1.0, 0.05, 1, 0 );
    add(levy);

    UnitType tanks = new UnitType("Dune Buggy", 2.0, 4.0, 0.25, 5, 0.1 );
    add(tanks);

    UnitType saucepan = new UnitType("Weird Guy with a Saucepan", 1.0, 10.0, 0.5, 10, 0.1 );
    add(saucepan);

  }

}