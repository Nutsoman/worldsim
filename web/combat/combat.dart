import 'dart:html';

import 'package:CommonLib/Colours.dart';

import '../map/territory.dart';
import '../nations/nation.dart';
import '../units/army.dart';
import '../units/UnitTypes.dart';
import 'dart:math';

class Skirmish {
  Territory skirmishLocation;
  Set<Side> sides = <Side>{};
  int elapsed = 0;
  Army attacker;
  Army defender;

  Skirmish( int this.elapsed, Army this.attacker, Army this.defender, Territory this.skirmishLocation ) {
    List<ConflictHex> hexa = <ConflictHex>[];
    hexa.add( new ConflictHex( skirmishLocation, true ) );
    sides.add( new Side( attacker, hexa ));
    List<ConflictHex> hexb = <ConflictHex>[];
    hexb.add( new ConflictHex( skirmishLocation, true ) );
    sides.add( new Side( defender, hexb ) );
    skirmishLocation = defender.unitlocation;
    attacker.game.world.skirmishes.add(this);
  }

  bool update() {
    for ( Side side in this.sides ) {
      side.update();
    }

    elapsed++;
    return false;
  }

  void cull() { //Why must I do this...
    for ( Side side in sides ){
      side.cull();
    }
  }

}

class Side {
  Map<Army,bool> armies = <Army,bool>{};
  Set<Nation> participants = <Nation>{};
  Nation leader;
  Army initiator;
  Map<UnitType,double> deployableForces = <UnitType,double>{};
  List<ConflictHex> hexes;

  Side( Army this.initiator, List<ConflictHex> this.hexes ) {
    leader = initiator.owner;
    addArmy( initiator );
    for ( ConflictHex hex in hexes ) {
      hex.owner = this;
    }
  }

  void cull(){
    for ( Army army in armies.keys ){
      army.incombat = null;
    }
    for ( ConflictHex hex in hexes ){
      hex.location.ongoingConflicts.remove(hex);
    }
  }

  void update(){
      for ( Army army in armies.keys ){
        if ( armies[army] == false ){
          for ( Subunit sub in army.subunits.keys ){

            if (!this.deployableForces.containsKey(sub.type)) {
              this.deployableForces[sub.type] = 0;
            }
            this.deployableForces[sub.type] += army.subunits[sub];
            /*double addedCohesion = sub.type.cohesion * army.subunits[sub];
            currentCohesion += addedCohesion;
            maxCohesion += addedCohesion;*/
          }
          armies[army] = true;
        }
      }
      int totalEdges = 0;
      for ( ConflictHex hex in hexes ) {
        totalEdges += hex.contestededges;
      }
      for ( UnitType type in deployableForces.keys ){
        double remainder = deployableForces[type] % totalEdges;
        double assign = ( deployableForces[type] - remainder ) / totalEdges;
        for ( ConflictHex hex in hexes ) {
          if ( !hex.deployedHere.containsKey(type) ){
            hex.deployedHere[type] = 0;
          }
          hex.deployedHere[type] += assign * hex.contestededges;
          deployableForces[type] -= assign * hex.contestededges;
        }
        while ( remainder > 0 ) {
          int hexint = leader.game.random.nextInt( hexes.length );
          ConflictHex randomHex = hexes[hexint];
          randomHex.deployedHere[type] += min( remainder, 1 );
          remainder -= 1;
        }
      }
      deployableForces.clear();
  }

  void addArmy( Army target ) {
    armies[target] = false;
    participants.add(target.owner);
    target.incombat = this;
  }

}

class ConflictHex {
  Side owner;
  Territory location;
  int contestededges = 0;
  bool isskirmish;
  int requiredToAttack;
  Map<UnitType, double> deployedHere = <UnitType, double>{};

  ConflictHex( Territory this.location, bool this.isskirmish ){
    if ( isskirmish ) {
      contestededges = location.neighbours.length;
    }
    requiredToAttack = contestededges * location.combatWidth;
    location.ongoingConflicts.add(this);
  }

}