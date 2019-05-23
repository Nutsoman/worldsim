import 'package:CommonLib/Colours.dart';

import '../map/location.dart';

class Nation {
  Set<Location> territory = <Location>{};
  String name;
  Colour mapcolour;

  Nation(this.name, this.mapcolour);

}