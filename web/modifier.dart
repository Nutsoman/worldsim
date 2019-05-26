import 'gamestate.dart';

class Modifier {
  final String name;
  final Map<String,double> effects = <String,double>{};
  final bool canstack;

  Modifier(String this.name, [bool this.canstack = false]);

}

abstract class Modifiers {
  static final List<Modifier> list = <Modifier>[];
  static final Map<String,Modifier> byname = <String,Modifier>{};

  static void add(Modifier modifier) {
    list.add(modifier);
    byname[modifier.name] = modifier;
  }

  static Future<void> init() async {
    Modifier pop_exp = new Modifier("pop_exp");
    pop_exp.effects["populationcap"] = 10;
    add(pop_exp);
  }

}



//Active Modifiers

class ModifierList {
  Map<Modifier,List<int>> data = <Modifier,List<int>>{};

  double getvalue(String target, Gamestate game){
    double value = 0;
    int date = game.calendar.tickselapsed;
    Iterable<Modifier> mods = data.keys.where((Modifier m)=>m.effects.containsKey(target));
    for ( Modifier mod in mods ) {
      List<int> durations = data[mod];
      for ( int i in durations ){
        if ( i < 0 || i >= date ) {
          value += mod.effects[target];
        }
      }
    }
    return value;
  }

  void add(Modifier mod, [int expires = -1]) {
    List<int> durations;
    if ( !data.containsKey(mod) ){
      durations = <int>[];
      data[mod] = durations;
    }
    else {
      durations = data[mod];
    }
    if ( mod.canstack ){
      durations.add(expires);
    }
    else {
      if ( durations.isEmpty ){
        durations.add(expires);
      }
      else {
        int current = durations[0];
        if ( expires == -1 || ( current != -1 && expires > current ) ){
          durations[0] = expires;
        }
      }
    }
  }

  int count(Modifier mod, Gamestate game){
    if ( !data.containsKey(mod) ){
      return 0;
    }
    int date = game.calendar.tickselapsed;
    int n = 0;
    List<int> durations = data[mod];
    if ( durations.isEmpty ){
      return 0;
    }
    for ( int duration in durations ){
      if ( duration < date ) {
        n++;
      }
    }
    return n;
  }

  void remove(Modifier mod, Gamestate game){
    if ( !data.containsKey(mod) ){
      return;
    }
    int date = game.calendar.tickselapsed;
    List<int> durations = data[mod];
    if ( durations.isEmpty ){
      return;
    }
    List<int> ids = <int>[];
    for ( int i = 0; i < durations.length; i++ ){
      if ( durations[i] < date ){
        ids.add(i);
      }
    }
    if ( ids.isEmpty ) {
      return;
    }
    if ( ids.length > 1 ) {
      ids.sort((int ida, int idb){
        int moda = durations[ida];
        int modb = durations[idb];
        bool permaa = moda < 0;
        bool permab = modb < 0;
        if ( permaa && permab ){
          return 0;
        }
        else if ( permaa ){
          return 1;
        }
        else if ( permab ) {
          return -1;
        }
        else {
          return moda.compareTo(modb);
        }
      });
    }
    durations.removeAt(ids[0]);
  }

  void cleanup(Gamestate game) {
    Set<Modifier> modifierstoremove = <Modifier>{};
    int date = game.calendar.tickselapsed;
    for ( Modifier mod in data.keys ){
      List<int> durations = data[mod];
      if ( durations.isEmpty ){
        modifierstoremove.add(mod);
      }
      else {
        List<int> idstoremove = <int>[];
        for ( int i = 0; i < durations.length; i++ ){
          if ( durations[i] >= 0 && durations[i] < date ){
            idstoremove.add(i);
          }
        }
        for ( int i = idstoremove.length - 1; i >= 0; i-- ){
          durations.removeAt(idstoremove[i]);
        }
        if ( durations.isEmpty ){
          modifierstoremove.add(mod);
        }
      }
    }
    for ( Modifier mod in modifierstoremove ){
      data.remove(mod);
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("[ ");
    bool first = true;
    for ( Modifier mod in data.keys ){
      if ( data[mod].isEmpty ){
       continue;
      }
      if (first) {
        first = false;
      }
      else {
       sb.write(", ");
      }
      sb.write(mod.name);
      sb.write(" x");
      sb.write(data[mod].length);
    }
    sb.write(" ]");
    return sb.toString();
  }

}

mixin Modifiable {
  ModifierList modifiers = new ModifierList();

  Gamestate get game;

  double getModValue(String target) => modifiers.getvalue(target, game);
  void cleanupModifiers() => modifiers.cleanup(game);
  void addModifierObj(Modifier mod, {int ticks:0, int days:0, int months:0, int years:0}){
    int duration = Calendar.duration(ticks:ticks, days:days, months:months, years:years);
    int expires = duration == 0 ? -1 : game.calendar.tickselapsed + duration;
    modifiers.add(mod, expires);
  }
  void addModifier(String mod, {int ticks:0, int days:0, int months:0, int years:0}) => addModifierObj( Modifiers.byname[mod], ticks:ticks, days:days, months:months, years:years );
  int countModifier(String name) => countModifierObj(Modifiers.byname[name]);
  int countModifierObj(Modifier mod) => modifiers.count(mod, game);
  bool hasModifier(String name, [int count = 1]) => countModifier(name) >= count;
  bool hasModifierObj( Modifier mod, [int count = 1] ) => countModifierObj(mod) >= count;



}