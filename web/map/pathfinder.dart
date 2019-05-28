import 'territory.dart';
import 'dart:math' as Math;

abstract class Pathfinder{




  static List<Territory> reconpath(Map<Territory,Territory> camefrom, Territory current){
    List<Territory> totalpath = <Territory>[current];
    while ( camefrom.containsKey(current) ){
      current = camefrom[current];
      totalpath.add(current);
    }
    return totalpath;
  }

  static List<Territory> pathfind(Territory start, Territory end){
    Set<Territory> closed = <Territory>{};
    Set<Territory> open = <Territory>{start};
    Map<Territory, Territory> camefrom = <Territory,Territory>{};
    Map<Territory,int> gscore = <Territory,int>{start:0};
    Map<Territory,int> fscore = <Territory,int>{start:heuristic(start,end)};
    while ( open.isNotEmpty ) {
      int f = 1000000;
      Territory current;
      for (Territory territory in open) {
        if (fscore.containsKey(territory)) {
          if (fscore[territory] < f) {
            f = fscore[territory];
            current = territory;
          }
        }
      }
      if ( current == end ){
        return reconpath(camefrom, current);
      }
      open.remove(current);
      closed.add(current);
      for ( Territory neighbour in current.neighbours ){
        if ( closed.contains(neighbour) ){
          continue;
        }
        int tentativegscore = gscore[current] + current.neighbourdist[neighbour];
        if ( !open.contains(neighbour) ){
          open.add(neighbour);
        }
        else if ( tentativegscore >= gscore[neighbour] ) {
          continue;
        }
        camefrom[neighbour] = current;
        gscore[neighbour] = tentativegscore;
        fscore[neighbour] = tentativegscore + heuristic(neighbour, end);
      }
    }
    return null;
  }

  static int heuristic(Territory a, Territory b){
    int diffx = a.centre.x - b.centre.x;
    int diffy = a.centre.y - b.centre.y;
    return Math.sqrt(diffx * diffx + diffy * diffy).round();
  }

}
