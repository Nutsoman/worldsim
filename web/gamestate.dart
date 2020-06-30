import 'dart:html';
import 'dart:math' as Math;

import 'package:CommonLib/Random.dart';

import 'combat/combat.dart';
import 'map/buildings.dart';
import 'map/territory.dart';
import 'map/world.dart';
import 'modifier.dart';
import 'nations/nation.dart';
import 'nations/pops.dart';
import 'ui.dart';
import 'units/UnitTypes.dart';
import 'units/army.dart';

class Gamestate {

  Random random = new Random();

  Calendar calendar;
  World world;

  num then = 0;
  List<double> frametimes = [];
  bool stopLoop = false;

  double simtime = 0.0;
  double simstep = 1.0;
  double frametime = 0.0;
  double framestep = 0.25;

  Point<num> mousepos;
  Point<num> startposition;
  Set<Army> selectedarmies = <Army>{};
  Set<int> keysheld = <int>{};

  _Uiholder ui;

  //State of the Game

  Gamestate(){
    calendar = new Calendar(this,2455,4,28);
    world = new World(this);
  }

  Future<void> initGamestate() async{
    await this.world.loadData("map/location_data.json","nations/nations.json","map/map.png");
    await Modifiers.init();
    await Buildings.init();
    await Poptypes.init();
    await UnitTypes.init();
    Territory.init(this);
    Nation.init(this);
    querySelector("#map").append(world.mapimage);
    ui = new _Uiholder(this);

  }

  void keydown(KeyboardEvent event){
    keysheld.add(event.keyCode);
  }

  void keyup(KeyboardEvent event){
    keysheld.remove(event.keyCode);
  }

  void click(MouseEvent event) {
    print("Click ${event.button}");
    int x = event.offset.x + window.scrollX;
    int y = event.offset.y + window.scrollY;
    if ( event.button == 0 ){
      for ( Nation nation in world.nations ){
        for( Army army in nation.armies ){
          Point<int> pos = army.getPosition();
          int diffx = pos.x-x;
          int diffy = pos.y-y;
          double dist = Math.sqrt(diffx*diffx+diffy*diffy);
          if ( dist < 12 ){
            if ( !keysheld.contains(16) ) {
              this.selectedarmies.clear();
            }
            this.selectedarmies.add(army);
            ui.updateAll();
            return;
          }
        }
      }

      this.selectedarmies.clear();

      int index = world.mapimage.width * y + x;
      int id = world.locationlookup[index];
      if (id != World.nolocation) {
        Territory location = world.locations[id];
        ui.provinceview.open(location);
        ui.topbar.nation = location.owner;
        ui.rightbar.nation = location.owner;
        ui.topbar.update();
        location.calcPopDistribution(location.popweights);
        print(location.lastmonthsgrowth);
      }
      else {
        ui.provinceview.hide();
        ui.topbar.nation = null;
      }
    }
    else if ( event.button == 2 ){
      int index = world.mapimage.width * y + x;
      int id = world.locationlookup[index];
      if ( id != World.nolocation ) {
        bool redraw = false;
        Territory location = world.locations[id];
        for (Army army in selectedarmies) {
          army.moveOrder(location, keysheld.contains(16));
          redraw = true;
        }
        if ( redraw ){
          world.drawMap(0);
        }
      }
    }
    ui.updateAll();
  }

  //TimeyWimey

  void update(num dt) {
    if (dt <= 0.0) { return; }
    simtime += dt;
    frametime += dt;

    while (simtime >= simstep) {
      simtime -= simstep;
      logicUpdate(simstep);
    }

    while (frametime >= framestep) {
      frametime -= framestep;
      frameUpdate(framestep);
    }
  }

  void frameUpdate(num dt){
    world.drawMap(dt);
  }

  void logicUpdate(num dt) {
    //things
    calendar.updateCalendar();
    for( Territory location in world.locations ){
      location.logicUpdate();
    }
    for( final Nation nation in world.nations ){
      nation.logicUpdate();
      for ( final Army army in nation.armies ){
        army.logicUpdate();
      }
    }
    for( UI ui in this.ui.uis ){
      if( ui.visible ){
        ui.update();
      }
    }
    Set<Skirmish> toCull = <Skirmish>{};

    for ( final Skirmish skirmish in world.skirmishes ){
      final bool skirmishOver = skirmish.update();
      if ( skirmishOver ) {
        skirmish.cull(); //garbage collection........... why
        toCull.add(skirmish);
      }
    }

    for ( Skirmish killit in toCull ){
      world.skirmishes.remove(killit);
    }
    toCull.clear();
  }

  void dailyUpdate() {
    for( Territory location in world.locations ){
      location.dailyUpdate();
    }
    for( Nation nation in world.nations ){
      nation.dailyUpdate();
    }
  }

  void monthlyUpdate() {
    for( Territory location in world.locations ){
      location.monthlyUpdate(random);
    }
    for( Nation nation in world.nations ){
      nation.monthlyUpdate(random);
    }
  }

  void gameLoop(num now) {
    if (this.stopLoop) {
      this.stopLoop = false;
      return;
    }
    window.requestAnimationFrame(gameLoop);

    num dt = now - then;
    if (then == 0) {
      dt = 0;
    }
    then = now;

    frametimes.add(dt/1000.0);
    if (frametimes.length > 2.0 / this.simstep) {
      frametimes.removeAt(0);
    }


    this.update(dt/1000.0);

  }
}

class Calendar {
  int year;
  int month;
  int day;
  int tick = 0;
  int tickselapsed = 0;
  Gamestate game;

  Calendar(Gamestate this.game, int this.year, int this.month, int this.day);

  void updateCalendar(){
    tick++;
    tickselapsed++;
    if( tick >= 4 ){
      tick = 0;
      day++;
      game.dailyUpdate();
      if( day >= 30 ){
        day = 0;
        month++;
        game.monthlyUpdate();
        if( month >= 12 ){
          month = 0;
          year++;
        }
      }
    }
  }

  static int duration({int ticks:0, int days:0, int months:0, int years:0}){
    return ticks + 4*(days+30*(months+12*years));
  }

  @override
  String toString(){
    return "${tick+1} ${day+1}.${month+1}.$year";
  }
}

class _Uiholder{
  Element element;
  Provinceview provinceview;
  Rightbar rightbar;
  Topbar topbar;
  CanvasElement drawlayer;
  Gamestate game;

  _Uiholder(Gamestate this.game){
    this.element = querySelector("#UI");
    this.drawlayer = querySelector("#mousedraw");
    document.onResize.listen(resize);
    document.onScroll.listen(resize);
    document.onKeyDown.listen(game.keydown);
    document.onKeyUp.listen(game.keyup);
    querySelector("#container").style..width = "${game.world.mapimage.width}px"..height = "${game.world.mapimage.height}px";

    this.provinceview = new Provinceview(querySelector("#province_view"),game);
    this.rightbar = new Rightbar(querySelector("#rightbar"),game);
    this.topbar = new Topbar(querySelector("#topbar"),game);
    this.element.onClick.listen(game.click);
    this.element.onContextMenu.listen((MouseEvent event){
      event.preventDefault();
      game.click(event);
    });
  }

  void resize(Event event){
    drawlayer.width = window.innerWidth;
    drawlayer.height = window.innerHeight;
    draw();
  }

  void draw(){

  }

  void clear(){
    drawlayer.context2D.clearRect(0, 0, drawlayer.width, drawlayer.height);
  }

  void update(){
    clear();
  }

  void updateAll() {
    for ( UI ui in this.uis ) {
      if ( ui.visible )
        {
          ui.update();
        }
    }
  }

  List<UI> _uis;
  List<UI> get uis {
    _uis ??= <UI>[provinceview,rightbar,topbar];
    return _uis;
  }

}

class TextUtils {

  static String getTextColor(int value){
    String ret;
    if ( value > 0 ){
      ret = "<span class=\"valuegreen\">+${value}</span>";
    }
    else if ( value == 0 ){
      ret = "<span class=\"valueyellow\">+${value}</span>";
    }
    else {
      ret = "<span class=\"valuered\">${value}</span>";
    }
    return ret;
  }

}
