import 'dart:html' as prefix0;
import 'dart:math';

import 'map/buildings.dart';
import 'map/location.dart';
import 'dart:html';
import 'gamestate.dart';
import 'map/world.dart';
import 'nations/nation.dart';

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

  void fixClick(){
    this.element.onClick.listen(fixedClick);
  }

  void fixedClick(MouseEvent e){
    e.stopPropagation();
    e.stopImmediatePropagation();
  }

  void update();

}

class Provinceview extends UI {
  Location location;
  Element buildingtext;
  Element buildinggrid;
  Element progressbar;
  Element neighbourlist;
  List<Element> tabbuttons;
  List<Element> tabs;

  Provinceview(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    buildingtext = element.querySelector("#buildingtext");
    buildinggrid = element.querySelector("#buildinggrid");
    progressbar = element.querySelector("#progressbar");
    neighbourlist = element.querySelector("#neighbourlist");

    tabbuttons = <Element>[element.querySelector("#infotabbutton"),element.querySelector("#neighbourtabbutton")];
    tabs = <Element>[element.querySelector("#infotab"),element.querySelector("#neighbourtab")];

    for ( int i = 0; i < tabbuttons.length; i++ ){
      Element button = tabbuttons[i];
      Element tab = tabs[i];
      button.onClick.listen((Event e){
        for( Element ebutton in tabbuttons ){
          if (ebutton == button){
            ebutton.classes.add("activetabbutton");
          }
          else{
            ebutton.classes.remove("activetabbutton");
          }
        }
        for( Element etab in tabs ){
          if (etab == tab){
            etab.style.display = "block";
          }
          else{
            etab.style.display = "none";
          }
        }
      });
    }

    tabbuttons[0].click();

    hide();

    for ( Building building in Buildings.list ){
      Element button = new DivElement()
        ..className = "buildingbutton"
        ..text = building.name;
      buildinggrid.append(button);
      button.onClick.listen((MouseEvent e ){ this.location.startBuilding(building); });
    }

    fixClick();
  }



  void open(Location loc){
    this.location = loc;
    neighbourlist.children.clear();
    for ( Location neighbour in location.neighbours ){
      Element button = new DivElement()
        ..className = "neighbourbutton"
        ..text = neighbour.name;
      neighbourlist.append(button);
      button.onClick.listen((MouseEvent e ){ this.location.buildRoad(neighbour); });
    }
    update();
    show();
    print(loc.modifiers);
  }

  @override
  void update(){
    buildingtext.setInnerHtml("${location.name} <br>Population: ${location.population} / ${location.populationcap}");
    if ( location.underConstruction != null ){
      double progress = (location.constructionProgress / location.underConstruction.buildtime).clamp(0.0, 1.0);
      progressbar.children.first.style.width = "${(progress*100).toStringAsFixed(2)}%";
    }
    else {
      progressbar.children.first.style.width = "0px";
    }
  }


}

class Rightbar extends UI {


  Rightbar(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    fixClick();
  }

  void open(Location loc){
    this.game = game;
    update();
    show();
  }

  @override
  void update(){
    //element.text = "${game.calendar}";
  }


}

class Topbar extends UI {
  Element datetime;
  Element nationinfo;
  Element nationflag;
  Element nationname;

  Nation nation;

  Topbar(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    datetime = element.querySelector("#datetime");
    nationinfo = element.querySelector("#nationinfo");
    nationflag = element.querySelector("#nationflag");
    nationname = querySelector("#nationname");
    fixClick();
  }

  @override
  void update(){
    datetime.text = "${game.calendar}";
    if ( nation != null ) {
      nationinfo.text = "£${nation.treasury.toStringAsFixed(2)}";
      nationflag.style.backgroundColor = nation.mapcolour.toStyleString();
      nationname.text = nation.name;
    }
    else {
      nationinfo.text = "";
      nationflag.style.backgroundColor = "gray";
      nationname.text = "";
    }
  }


}