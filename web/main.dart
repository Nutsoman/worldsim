import 'dart:async';

import 'gamestate.dart';
import 'map/world.dart';


World world;

Future<void> main() async {
  Gamestate game = new Gamestate();
  await game.initGamestate();
  game.gameLoop(0);
}

