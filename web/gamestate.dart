import 'dart:html';
import 'dart:html' as prefix0;
import 'map/world.dart';
import 'map/location.dart';
import 'package:CommonLib/Random.dart';
import 'ui.dart';

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

  _Uiholder ui;

  //State of the Game

  Gamestate(){
    calendar = new Calendar(this,2455,4,17);
    world = new World();
  }

  Future<void> initGamestate() async{
    await this.world.loadData("map/location_data.json","nations/nations.json","map/map.png");
    querySelector("#map").append(world.mapimage);
    ui = new _Uiholder();
    ui.element = querySelector("#UI");
    ui.element.onClick.listen(click);
    querySelector("#container").style..width = "${world.mapimage.width}px"..height = "${world.mapimage.height}px";

    ui.provinceview = new Provinceview(querySelector("#province_view"),this);
    ui.rightbar = new Rightbar(querySelector("#rightbar"),this);
  }

  void click(MouseEvent event) {
    int x = event.offset.x+window.scrollX;
    int y = event.offset.y+window.scrollY;
    int index = world.mapimage.width*y+x;
    int id = world.locationlookup[index];
    if( id != World.nolocation ){
      Location location = world.locations[id];
      ui.provinceview.open(location);
    }
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
    for( UI ui in this.ui.uis ){
      if( ui.visible ){
        ui.update();
      }
    }

  }

  void dailyUpdate() {
    for( Location location in world.locations ){
      if( location.population > 0 && random.nextInt(100) < 100 ) {
        location.population++;
      }
      location.updateValues();
    }
  }

  void monthlyUpdate() {
    for( Location location in world.locations ){
      if( location.population > 0 && random.nextInt(100) < 100 ) {
        location.population++;
      }
      location.updateValues();
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
  Gamestate game;

  Calendar(Gamestate this.game, int this.year, int this.month, int this.day);

  void updateCalendar(){
    tick++;
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
    print(this);
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





  List<UI> _uis;
  List<UI> get uis {
    _uis ??= <UI>[provinceview,rightbar];
    return _uis;
  }

}
