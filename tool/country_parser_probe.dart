import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

void main() {
  final country = CountryParser.parseCountryCode('CM');
  debugPrint(country.name);
}
