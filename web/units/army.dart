import 'dart:html';
import '../gamestate.dart';
import '../map/pathfinder.dart';
import '../map/territory.dart';
import '../nations/nation.dart';
import 'UnitTypes.dart';

class Army {
  List<Subunit> subunits = <Subunit>[];
  Nation owner;
  Territory unitlocation;
  Territory unitdestination;
  double speed;
  double moveprogress;
  Gamestate game;
  List<Territory> path;
  bool get haspath => path != null && path.isNotEmpty;
  static const double basespeed = 16;

  Army( Nation this.owner, Territory this.unitlocation ){
    game = owner.game;
  }

  void logicUpdate(){
    if ( unitdestination != null ){
      if ( unitlocation == unitdestination){
        unitdestination = null;
      }
      else {
        moveprogress += (speed * basespeed) / unitlocation.neighbourdist[unitdestination];
        if (moveprogress >= 1) {
          unitlocation = unitdestination;
          unitdestination = null;
          _processMoveOrder();
        }
      }
    }
  }

  void move(Territory dest) {
    if ( unitdestination != null ){
      return;
    }
    moveprogress = 0;
    unitdestination = dest;
  }

  void updateValues(){
    double i = 10000;
    for ( Subunit subunit in subunits ){
      if ( subunit.type.speed < i ){
        i = subunit.type.speed;
      }
    }
    this.speed = i;
  }

  void moveOrder(Territory location,[bool additive = false]){
    List<Territory> route;
    if ( additive && this.haspath ){
      route = this.path;
      List<Territory> addedroute = Pathfinder.pathfind(route.first, location);
      route = addedroute..addAll(route);
    }
    else {
      if ( unitdestination != null ) {
        route = Pathfinder.pathfind(unitdestination, location);
      }
      else {
        route = Pathfinder.pathfind(unitlocation, location);
      }
    }
    path = route;
    _processMoveOrder();
  }

  void _processMoveOrder(){
    if ( haspath && unitdestination == null ){
      Territory next = path.removeLast();
      if ( next == unitlocation ){
        _processMoveOrder();
      }
      move(next);
    }
  }

  Point<int> getPosition(){
    int x = unitlocation.centre.x;
    int y = unitlocation.centre.y;
    if ( unitdestination != null ){
      int destx = unitdestination.centre.x;
      int desty = unitdestination.centre.y;
      double diffx = (destx-x)*moveprogress;
      double diffy = (desty-y)*moveprogress;
      x = (x+diffx).round();
      y = (y+diffy).round();
    }
    return new Point<int>(x,y);
  }

  void addSubUnit( Subunit subunit ){
    subunits.add(subunit);
    subunit.army = this;
    this.updateValues();
  }

  void removeSubUnit( Subunit subunit ){
    subunits.remove(subunit);
    subunit.army = null;
  }

}

class Subunit{
  Army army;
  UnitType type;

  Subunit( UnitType this.type );



}