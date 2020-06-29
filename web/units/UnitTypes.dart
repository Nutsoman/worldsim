

class UnitType{
  String name;
  double speed;
  double antiarmor;
  double antipersonnel;
  double cohesion;
  double frontage;
  int range;

  UnitType( String this.name, double this.speed, double this.antiarmor, double this.antipersonnel, double this.cohesion, double this.frontage, int this.range );

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

    UnitType levy = new UnitType("Screaming Maniac", 1.0, 0.5, 1, 2, 1, 2);
    add(levy);

    UnitType tanks = new UnitType("Dune Buggy", 2.0, 0.75, 2, 20, 2, 2);
    add(tanks);

    UnitType saucepan = new UnitType("Weird Guy with a Saucepan", 1.0, 1, 0.75, 10, 1, 1);
    add(saucepan);

  }

}