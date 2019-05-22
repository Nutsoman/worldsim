import 'dart:html' as prefix0;

import "location.dart";
import 'dart:async';
import 'package:LoaderLib/Loader.dart';
import 'package:CommonLib/Utility.dart';
import 'package:CommonLib/Colours.dart';
import 'dart:html';
import 'dart:typed_data';

import 'location.dart' as prefix1;

class World {
  List<Location> locations = <Location>[];

  static const int nolocation = 0xffff;
  Uint16List  locationlookup;

  World();

  Future<void> loadData(String data, String image) async {
    Map<String,dynamic> location_data = await Loader.getResource(data);
    JsonHandler json = new JsonHandler(location_data);
    List<Map<String,dynamic>> locations = json.getArray("Locations");
    int id = 0;
    for( Map<String,dynamic> location in locations ){
      Location loc = new Location(id,location["population"],location["name"],this,new Colour(location["mapcolour"][0],location["mapcolour"][1],location["mapcolour"][2]));
      this.locations.add(loc);
      id++;
    }
    //print(this.locations.map((Location l)=>l.mapcolour).toList());
    ImageElement mapimage = await Loader.getResource(image);
    processMap(mapimage);

  }

  void processMap(ImageElement mapimage) {
    int w = mapimage.width;
    int h = mapimage.height;
    CanvasElement canvas = new CanvasElement(width:w,height:h);
    CanvasRenderingContext2D ctx = canvas.context2D;
    ctx.drawImage(mapimage, 0, 0);
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

    ctx.fillStyle = "black";

    for ( Location location in locations ) {
      List<int> centre = centredata[location];
      if( centre[2] == 0 ) {
        print("AAAAAARGH $location");
      }
      int x =( centre[0]/centre[2] ).round();
      int y =( centre[1]/centre[2] ).round();
      location.centre = new Point<int>(x,y);

      //Make it black

      ctx.fillRect(location.centre.x-2, location.centre.y-2 , 5, 5);

    }

    document.body.append(canvas);
    canvas.onClick.listen((MouseEvent event) {
      print(event.offset);
      int index = event.offset.y*w+event.offset.x;
      int id = locationlookup[index];
      if( id != nolocation ){
        Location clicked = locations[id];
        print("$clicked ${clicked.neighbours}");
      }

    } );

  }

}