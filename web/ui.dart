import 'map/location.dart';
import 'dart:html';
import 'gamestate.dart';
import 'map/world.dart';

abstract class UI {
  bool visible = true;
  Element element;
  Gamestate game;

  void show(){
    element.style.display = "block";
    visible = true;
  }

  void hide(){
    element.style.display = "none";
    visible = false;
  }

  void update();

}

class Provinceview extends UI {
  Location location;

  Provinceview(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    hide();

  }

  void open(Location loc){
    this.location = loc;
    update();
    show();
  }

  @override
  void update(){
    element.text = "${location.name} : ${location.population}";
  }


}

class Rightbar extends UI {


  Rightbar(Element element, Gamestate game){
    this.element = element;
    this.game = game;

  }

  void open(Location loc){
    this.game = game;
    update();
    show();
  }

  @override
  void update(){
    element.text = "${game.calendar}";
  }


}