

class UnitType{
  String name;
  int size;
  double speed;

  UnitType( String this.name, int this.size, double this.speed );

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

    UnitType levy = new UnitType("Levy", 100, 1.0);
    add(levy);

  }

}