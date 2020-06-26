

class UnitType{
  String name;
  int size;
  double speed;

  UnitType( String this.name, double this.speed );

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

    UnitType levy = new UnitType("Screaming Maniac", 1.0);
    add(levy);

    UnitType tanks = new UnitType("Dune Buggy", 2.0);
    add(tanks);

    UnitType saucepan = new UnitType("Weird Guy with a Saucepan", 1.0);
    add(saucepan);

  }

}