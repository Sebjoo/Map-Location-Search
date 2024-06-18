/*
    Author: Jöö
*/
// All Locations of the Map get pulled automatically from the Arma Config Files, no need to change anything
private _cities = [];
{
    private _cityConfig = _x;
    private _cityName = getText (_cityConfig >> "name");
    private _cityPos = getArray (_cityConfig >> "position");
    _cities pushBack [_cityName, _cityPos];
} forEach ("true" configClasses (configFile >> "CfgWorlds" >> worldName >> "Names"));

cities = _cities;

// If you want to put in locations manually, exclude the upper code and put them in like this
/*cities = [
    ["Kavala", [3687.2, 13033.8, 0]],
    ["Pyrgos", [16524.4, 12588.6, 0]],
    ["Agios", [12411.8, 14687.5, 0]]
];*/