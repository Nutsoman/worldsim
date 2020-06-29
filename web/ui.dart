import 'dart:html';

import 'combat/combat.dart';
import 'gamestate.dart';
import 'map/buildings.dart';
import 'map/territory.dart';
import 'nations/nation.dart';
import 'units/UnitTypes.dart';
import 'units/army.dart';
import 'utils.dart';

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
  Territory location;
  Element buildingtext;
  Element buildinggrid;
  Element progressbar;
  Element provincetitle;
  List<Element> tabbuttons;
  List<Element> tabs;

  Provinceview(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    buildingtext = element.querySelector("#buildingtext");
    provincetitle = element.querySelector("#provincetitle");
    buildinggrid = element.querySelector("#buildinggrid");
    progressbar = element.querySelector("#progressbar");

    tabbuttons = <Element>[element.querySelector("#infotabbutton")];
    tabs = <Element>[element.querySelector("#infotab")];

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



  void open(Territory loc){
    this.location = loc;
    update();
    show();
    print(loc.modifiers);
  }

  @override
  void update(){
    provincetitle.setInnerHtml("Hex ${location.name}");
    String ret = "Defense: ${location.totalDefenseModifier.getRounded()}<br><br>";
    if ( !location.localArmies.isEmpty && location.ongoingConflicts.isEmpty ) {
      ret += "Units Present:<br>";
      for ( Army army in location.localArmies ) {
        ret += "${ army.owner.name }<br>";
      }
    }
    if ( location.ongoingConflicts.isNotEmpty ){
      ret += "Force Distribution:<br><br>";
      for ( ConflictHex hex in location.ongoingConflicts ){
        ret += "${hex.owner.leader.name}:<br>";
        for ( UnitType type in hex.deployedHere.keys ){
          ret += "${type.name}: ${hex.deployedHere[type].getRounded()}<br>";
        }
      }
    }
    buildingtext.setInnerHtml( ret );
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
  Element popinfo;
  Element popclasses;
  Nation nation;


  Rightbar(Element element, Gamestate game){
    this.element = element;
    this.game = game;
    popinfo = element.querySelector("#popinfo");
    popclasses = element.querySelector("#classes");
    fixClick();
  }

  void open(Territory loc){
    this.game = game;
    update();
    show();
  }

  @override
  void update(){
    //popinfo.text = "Army Information";
    String ret = "";
    for ( Army army in game.selectedarmies ){
     ret += "<br>${ army.owner.name }<br>";
     for ( Subunit sub in army.subunits.keys )
       {
         ret += "${ sub.type.name }: ";
         ret += "${ army.subunits[sub] }";
         ret += "<br>";
       }
    }
    popinfo.setInnerHtml( ret );
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