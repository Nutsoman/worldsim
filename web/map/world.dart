import 'dart:html' as prefix0;
import 'dart:math';
import 'package:CommonLib/Random.dart' as Common;

import '../gamestate.dart';
import "location.dart";
import 'dart:async';
import 'package:LoaderLib/Loader.dart';
import 'package:CommonLib/Utility.dart';
import 'package:CommonLib/Colours.dart';
import 'dart:html';
import 'dart:typed_data';
import '../nations/nation.dart';

import 'location.dart' as prefix1;

class World {
  List<Location> locations = <Location>[];
  Map<String,Location> locationsbyname = <String,Location>{};
  List<Nation> nations = <Nation>[];

  static const int nolocation = 0xffff;
  Uint16List  locationlookup;

  CanvasElement maptexture;
  CanvasElement mapimage;

  final Gamestate game;

  World(Gamestate this.game);

  Future<void> loadData(String data, String nationdata, String image) async {
    //Load Location Data
    Map<String,dynamic> location_data = await Loader.getResource(data);
    JsonHandler json = new JsonHandler(location_data);
    List<Map<String,dynamic>> locations = json.getArray("Locations");
    int id = 0;
    for( Map<String,dynamic> location in locations ){
      Location loc = new Location(id,location["population"],location["name"],this,new Colour(location["mapcolour"][0],location["mapcolour"][1],location["mapcolour"][2]));
      this.locations.add(loc);
      locationsbyname[loc.name] = loc;
      id++;
    }

    //Load Nation Data
    Map<String,dynamic> nation_data = await Loader.getResource(nationdata);
    JsonHandler jsonnation = new JsonHandler(nation_data);
    List<Map<String,dynamic>> nations = jsonnation.getArray("Nations");
    for( Map<String,dynamic> nation in nations ){
      Nation nat = new Nation(nation["name"],new Colour(nation["mapcolour"][0],nation["mapcolour"][1],nation["mapcolour"][2]),this);
      this.nations.add(nat);
      List<dynamic> locationids = nation["territory"];
      for ( String lid in locationids ){
        nat.territory.add(this.locationsbyname[lid]);
        this.locationsbyname[lid].owner = nat;
      }
    }

    for( Location location in this.locations ){
      if ( location.owner == null ){
        Common.Random rando = new Common.Random(location.id);
        Colour colour = new Colour.hsv(rando.nextDouble(), rando.nextDouble(0.5)+0.5, rando.nextDouble(0.75)+0.25);
        Nation nat = new Nation(location.name,colour,this);
        this.nations.add(nat);
        nat.territory.add(location);
        location.owner = nat;
      }
    }

    //Run Init
    ImageElement mapimage = await Loader.getResource(image);
    processMap(mapimage);

  }

  void processMap(ImageElement image) {
    int w = image.width;
    int h = image.height;
    mapimage = new CanvasElement(width:w,height:h);
    CanvasRenderingContext2D ctx = mapimage.context2D;
    ctx.drawImage(image, 0, 0);
    Uint16List ref = new Uint16List(w*h);
    Map<int,Location> lookup = <int,Location>{};
    for( Location location in locations ) {
      int key = location.mapcolour.toImageDataInt32();
      lookup[key] = location;
    }
    ImageData img = ctx.getImageData(0, 0, w, h);
    Uint32List pixels = img.data.buffer.asUint32List();
    for( int i = 0; i < pixels.length; i++ ){
      int pixel = pixels[i];
      if( lookup.containsKey(pixel) ){
        ref[i] = lookup[pixel].id;
      }
      else{
        ref[i] = nolocation;
      }
    }
    this.locationlookup = ref;

    //CalcCentre
    //Setup Neighbours

    Map<Location,List<int>> centredata = <Location,List<int>>{};

    for ( Location location in locations ){
      centredata[location] = <int>[0,0,0];
    }

    for( int y = 0; y < h; y++ ){
      for( int x = 0; x < w; x++ ){
        int i = y*w+x;
        int id = ref[i];
        if(id == nolocation){
          continue;
        }

        bool checkright = x < w-1;
        bool checkdown = y < h-1;
        Location location = locations[id];

        List<int> centre = centredata[location];

        centre[0] += x;
        centre[1] += y;
        centre[2] ++;

        if ( x < location.left ){
          location.left = x;
        }
        if ( x > location.right ){
          location.right = x;
        }
        if ( y < location.top ){
          location.top = y;
        }
        if ( y > location.bottom ){
          location.bottom = y;
        }

        if(checkright){
          int otherid = ref[i+1];
          if(otherid != nolocation && otherid != id){
            Location otherlocation = locations[otherid];
            location.neighbours.add(otherlocation);
            otherlocation.neighbours.add(location);
          }
        }

        if(checkdown){
          int otherid = ref[i+w];
          if(otherid != nolocation && otherid != id){
            Location otherlocation = locations[otherid];
            location.neighbours.add(otherlocation);
            otherlocation.neighbours.add(location);
          }
        }

        if(checkright && checkdown){
          int otherid = ref[i+w+1];
          if(otherid != nolocation && otherid != id){
            Location otherlocation = locations[otherid];
            location.neighbours.add(otherlocation);
            otherlocation.neighbours.add(location);
          }
        }

      }

    }

    for ( Location location in locations ) {
      List<int> centre = centredata[location];
      if( centre[2] == 0 ) {
        print("AAAAAARGH $location");
      }
      int x =( centre[0]/centre[2] ).round();
      int y =( centre[1]/centre[2] ).round();
      location.centre = new Point<int>(x,y);

    }

    maptexture = new CanvasElement(width:w,height:h);
    redrawMapTexture();

  }

  void drawMap(double dt){
    CanvasRenderingContext2D image = mapimage.context2D;
    int w = mapimage.width;
    int h = mapimage.height;
    image.clearRect(0, 0, w, h);
    image.drawImage(maptexture, 0, 0);

    image.fillStyle = "black";

    for ( Location location in locations ) {
      //Make it black
      double citysize = smoothCap(sqrt(location.population)*2, 20, 12, 2);
      double radius = (citysize-1)/2;
      image.fillRect(location.centre.x-radius, location.centre.y-radius , citysize, citysize);
      for( Location neighbour in location.neighbours ) {
        if ( location.roadDestinations.contains(neighbour) ) {
          image.beginPath();
          image.moveTo(location.centre.x, location.centre.y);
          image.bezierCurveTo( location.centre.x, location.centre.y, neighbour.centre.x - 10, neighbour.centre.y + 10, neighbour.centre.x, neighbour.centre.y);
          image.stroke();
        }
      }
    }

  }

  void redrawMapTexture() {

    int w = maptexture.width;
    int h = maptexture.height;

    Uint16List ref = locationlookup;

    CanvasRenderingContext2D texture = maptexture.context2D;
    ImageData tex = texture.getImageData(0, 0, w, h);
    Uint32List texpix = tex.data.buffer.asUint32List();
    for( int y = 0; y < h; y++ ) {
      for (int x = 0; x < w; x++) {
        int i = y * w + x;
        if( ref[i] == nolocation ){
          texpix[i] = 0xffff8060;
        }
        else{
          Location location = locations[ref[i]];
          if( (x > 0 && ref[i-1] != nolocation && ref[i-1] != ref[i]) || (x < w-1 && ref[i+1] != nolocation && ref[i+1] != ref[i]) || (y > 0 && ref[i-w] != nolocation && ref[i-w] != ref[i]) || (y < h-1 && ref[i+w] != nolocation && ref[i+w] != ref[i]) ){
            if ( location.owner != null ){
              texpix[i] = (location.owner.mapcolour*0.5).toImageDataInt32();
            }
            else{
              texpix[i] = 0xff308040;
            }
          }
          else {
            if ( location.owner != null ){
              texpix[i] = location.owner.mapcolour.toImageDataInt32();
            }
            else {
              texpix[i] = 0xff60ff80;
            }
          }
        }
      }
    }
    texture.putImageData(tex, 0, 0);
  }

}