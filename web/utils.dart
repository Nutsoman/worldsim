import 'dart:math';

extension NumUtils on num {

  double getRounded( [int places = 2] ) {
    double multiplier = pow(10, places);
    num ret = this * multiplier;
    ret.round();
    ret /= multiplier;
    return ret;
  }

}