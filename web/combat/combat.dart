import 'dart:html';

import 'package:CommonLib/Collection.dart';
import 'package:CommonLib/Colours.dart';
import 'package:CommonLib/Random.dart';

import '../map/territory.dart';
import '../nations/nation.dart';
import '../units/army.dart';
import '../units/UnitTypes.dart';
import 'dart:math';

class Skirmish {
  Territory skirmishLocation;
  List<Side> sides = <Side>[];
  int elapsed = 0;
  Army attacker;
  Army defender;
  List<Front> fronts = <Front>[];

  Skirmish( int this.elapsed, Army this.attacker, Army this.defender, Territory this.skirmishLocation ) {
    List<ConflictHex> hexa = <ConflictHex>[];
    hexa.add( new ConflictHex( skirmishLocation, true ) );
    sides.add( new Side( attacker, hexa, this ));
    List<ConflictHex> hexb = <ConflictHex>[];
    hexb.add( new ConflictHex( skirmishLocation, true ) );
    sides.add( new Side( defender, hexb, this ) );
    skirmishLocation = defender.unitlocation;
    attacker.game.world.skirmishes.add(this);
    for ( Side side in sides ){
      side.initAdjacencies();
    }
    for ( Side side in sides ){
      side.initFronts();
    }
    print( fronts.length );
  }

  bool update() {
    for ( Side side in this.sides ) {
      side.update();
    }

    for ( Front front in fronts ) {
      doCombat( front );
    }

    elapsed++;
    return false;
  }

  void doCombat( Front front ){
    final ConflictHex A = front.a.keys.first;
    final ConflictHex B = front.b.keys.first;
    if( A.deployedWeight <= 0 ){
      return;
    }
    if( B.deployedWeight <= 0 ){ //Two functions because we might want a return type later
      return;
    }
    double Adamage = 0;
    double Adefense = 0;
    double Acohesion = 0;
    for ( final UnitType type in A.deployedHere.keys ){
      Adamage += type.attack * A.deployedHere[type];
      Adefense += type.defense * A.deployedHere[type];
      Acohesion += type.cohesion * A.deployedHere[type];
    }
    Acohesion = A.CurrentCohesion;
    Adamage /= A.deployedWeight;
    Adefense /= A.deployedWeight;

    double Bdamage = 0;
    double Bdefense = 0;
    double Bcohesion = 0;
    for ( final UnitType type in B.deployedHere.keys ){
      Bdamage += type.attack * B.deployedHere[type];
      Bdefense += type.defense * B.deployedHere[type];
      Bcohesion += type.cohesion * B.deployedHere[type];
    }
    Bdamage /= B.deployedWeight;
    Bdefense /= B.deployedWeight;
    Bcohesion = B.CurrentCohesion;

    int Aroll = A.random.nextInt(10);
    int Broll = B.random.nextInt(10);

    const double damageControl = 0.25; //Multiply damage taken by this

    double ACWidth = min( B.location.combatWidth.toDouble(), B.deployedWeight );
    double AfinalDef = (1 - Adefense) * A.location.totalDefenseModifier;
    double AReduction = (((Broll*ACWidth) * Bdamage ) * AfinalDef ) * damageControl;
    A.CurrentCohesion = Acohesion - AReduction;

    double BCWidth = min( A.location.combatWidth.toDouble(), A.deployedWeight );
    double BfinalDef = (1 - Bdefense)* B.location.totalDefenseModifier;
    double BReduction = (((Aroll*BCWidth) * Adamage ) * BfinalDef ) * damageControl;
    B.CurrentCohesion = Bcohesion - BReduction;

    //Casualties and Reliability
    createCasualties( A, AReduction );
    createCasualties( B, BReduction );




  }

  void createCasualties( ConflictHex hex, double damageDealt ){
    //Reliability
    for ( UnitType type in hex.deployedHere.keys ){
      double unitsFailed = hex.deployedHere[type] * hex.random.nextDoubleRange(0, type.failchance );
      unitsFailed.floor();
      hex.damageDeployed(type, unitsFailed );
    }
  }

  void cull() { //Why must I do this...
    for ( Side side in sides ){
      side.cull();
    }
  }

  void registerFront( Front front ){
    fronts.add(front);
  }

}

class Side {
  Map<Army,bool> armies = <Army,bool>{};
  Set<Nation> participants = <Nation>{};
  Nation leader;
  Army initiator;
  Map<UnitType,double> deployableForces = <UnitType,double>{};
  List<ConflictHex> hexes;
  Skirmish parent;

  Side( Army this.initiator, List<ConflictHex> this.hexes, Skirmish this.parent ) {
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

  void initAdjacencies(){
    for ( ConflictHex hex in hexes ){
      hex.updateAdjacencies();
    }
  }

  void initFronts(){
    for ( ConflictHex hex in hexes ){ //Yes this needs to be after
      hex.addFronts();
    }
  }

  void update(){
      bool deploy = false;
      for ( Army army in armies.keys ){
        if ( armies[army] == false ){
          deploy = true;
          for ( Subunit sub in army.subunits.keys ){

            if (!this.deployableForces.containsKey(sub.type)) {
              this.deployableForces[sub.type] = 0;
            }
            this.deployableForces[sub.type] += army.subunits[sub];
          }
          armies[army] = true;
        }
      }
      if ( deploy ){
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
            double multi = assign * hex.contestededges;
            hex.deployedHere[type] += multi;
            hex.deployedWeight += multi;
            hex.MaxCohesion += multi * type.cohesion;
            hex.CurrentCohesion += multi * type.cohesion;
            deployableForces[type] -= multi;
          }
          while ( remainder > 0 ) {
            int hexint = leader.game.random.nextInt( hexes.length );
            ConflictHex randomHex = hexes[hexint];
            randomHex.deployedHere[type] += min( remainder, 1 );
            randomHex.deployedWeight += min( remainder, 1 );
            randomHex.MaxCohesion += min( remainder, 1 ) * type.cohesion;
            randomHex.CurrentCohesion += min( remainder, 1 ) * type.cohesion;
            remainder -= 1;
          }
        }
        deployableForces.clear();
      }
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
  double deployedWeight = 0;
  List<ConflictHex> adjacencies = <ConflictHex>[];
  List<Front> fronts = <Front>[];
  Random random = new Random();
  double MaxCohesion = 0;
  double CurrentCohesion = 0;

  ConflictHex( Territory this.location, bool this.isskirmish ){
    if ( isskirmish ) {
      contestededges = location.neighbours.length;
    }
    requiredToAttack = contestededges * location.combatWidth;
    location.ongoingConflicts.add(this);
  }

  void damageDeployed( UnitType type, double amount ){
    deployedHere[type] -= amount;
    deployedWeight -= amount;
  }

  void killDeployed( UnitType type, double amount ){
    if ( amount <= 0 ) {
      return;
    }
    deployedHere[type] -= amount;
    deployedWeight -= amount;
    double totalWeight = 0;
    for ( Army army in owner.armies.keys ){
      for ( Subunit sub in army.subunits.keys ){
        if ( sub.type == type ){
          totalWeight += army.subunits[sub];
        }
      }
    }
    amount /= totalWeight;
    for ( Army army in owner.armies.keys ){
      for ( Subunit sub in army.subunits.keys ){
        if ( sub.type == type ){
          army.subunits[sub] -= amount * army.subunits[sub];
        }
      }
    }
  }

  void updateAdjacencies(){
    adjacencies.clear();
    for ( Territory neighbor in this.location.neighbours ){
      for ( ConflictHex target in neighbor.ongoingConflicts ){
        if ( target.owner != this.owner && owner.parent.sides.contains( target ) ){ //And are we hostile?
          adjacencies.add( target );
        }
      }
    }
    if ( isskirmish ){
      for ( ConflictHex target in this.location.ongoingConflicts ){
        if ( target.owner != this.owner && owner.parent.sides.contains( target.owner ) ){ //And are we hostile?
          adjacencies.add( target );
        }
      }
    }
  }

  void addFronts(){
    List<ConflictHex> toPurge = <ConflictHex>[];
    for ( ConflictHex target in adjacencies ){
      toPurge.add( target );
      final Map<ConflictHex,bool> us = <ConflictHex,bool>{};
      us[this] = false;
      final Map<ConflictHex,bool> them = <ConflictHex,bool>{};
      them[target] = false; //not attacking - redundant?
      final Front front = new Front( us, them );
      fronts.add(front);
      target.fronts.add(front);
    }
    for ( final ConflictHex target in toPurge ) {
      this.adjacencies.remove( target );
      target.adjacencies.remove( this );
    }
  }

}

class Front {
  Map<ConflictHex, bool> a = <ConflictHex,bool>{};
  Map<ConflictHex, bool> b = <ConflictHex,bool>{};

  Front( Map<ConflictHex, bool> this.a, Map<ConflictHex, bool> this.b ){
    a.keys.first.owner.parent.registerFront( this );
  }

}