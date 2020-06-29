import 'dart:html';

import '../combat/combat.dart';
import '../gamestate.dart';
import '../map/pathfinder.dart';
import '../map/territory.dart';
import '../nations/nation.dart';
import 'UnitTypes.dart';

class Army {
  Map<Subunit, double> subunits = <Subunit, double>{};
  Nation owner;
  Territory unitlocation;
  Territory unitdestination;
  double speed;
  double moveprogress;
  Gamestate game;
  List<Territory> path;
  bool get haspath => path != null && path.isNotEmpty;
  static const double basespeed = 16;
  Set<Territory> reconTargets = <Territory>{};
  Side incombat;

  Army( Nation this.owner, Territory this.unitlocation ){
    game = owner.game;
  }

  void logicUpdate(){
    if ( unitdestination != null ){
      if ( unitlocation == unitdestination){
        unitdestination = null;
      }
      else if ( incombat == null ) {
        moveprogress += (speed * basespeed) / unitlocation.neighbourdist[unitdestination];
        if (moveprogress >= 1) {
          unitlocation.localArmies.remove(this);
          unitlocation = unitdestination;
          onEnterTerritory();
          unitdestination = null;
          _processMoveOrder();
        }
      }
    }
  }

  void onEnterTerritory() {
    unitlocation.localArmies.add(this);
    updateRecon();
    startCombats();
  }

  void startCombats() {
    for ( Territory scan in reconTargets ) {
      if ( scan.localArmies.isNotEmpty ) {
        for ( Army target in scan.localArmies ) {
          if ( target != this && target.incombat == null ) {
            new Skirmish( 0, this, target, target.unitlocation );
          }
          else if ( target.incombat != null && target.owner == this.owner )
          {
            target.incombat.addArmy(this);
          }
        }
      }
    }
  }

  void lockForCombat( Side side ) {
    incombat = side;
  }

  void move(Territory dest) {
    if ( unitdestination != null ){
      return;
    }
    moveprogress = 0;
    unitdestination = dest;
  }

  void updateRecon() {
    for ( Territory territory in reconTargets ) {
      territory.seenBy.remove( this );
    }
    reconTargets.clear();
    reconTargets.add( this.unitlocation );
    for ( Territory territory in this.unitlocation.neighbours ) {
      reconTargets.add( territory );
    }
    for ( Territory territory in reconTargets ) {
      territory.seenBy.add( this );
    }
    owner.world.redrawMapTexture(); //expensive :(
  }

  void updateValues(){
    double i = 10000;
    for ( Subunit sub in subunits.keys ){
      if ( sub.type.speed < i ){
        i = sub.type.speed;
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

  void addSubUnit( Subunit subunit, double amount ){
    print( subunit.type.name );
    this.subunits[subunit] = amount;
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