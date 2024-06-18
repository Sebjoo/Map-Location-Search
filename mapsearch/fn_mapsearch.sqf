scriptName "fn_mapsearch";
/*
    Author: 7erra https://github.com/7erra/marker_search 
	Edited by: Jöö 

    Description:
    Original script is for adding a searchable list of markers to the map, which got edited to do that function for locations/citys/villages ect. 
	The locations get handled in the cities.sqf, you can pull the info from Armas CFGWorlds itself or input the locations manually.
*/

#define SELF TER_fnc_mapsearch //(compile preprocessfilelinenumbers "mapsearch\fn_mapsearch.sqf")
#define IDC_RSCMAP_MRKGROUP 7300
#define IDC_RSCMAP_MRKSEARCH 7301
#define IDC_RSCMAP_MRKLIST 7302
#define IDC_RSCMAP_MRKSHOW 7303
#define IDC_RSCMAP_MRKBACKGROUND 7304
#define IDC_RSCMAP_MRKENDSEARCH 7305
#define X_GRID (safeZoneX + safeZoneW)
#define Y_GRID (safeZoneY)
#define W_GRID (((safezoneW / safezoneH) min 1.2) / 40)
#define H_GRID ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25)
#define W_GRP (10 * W_GRID)
#define H_GRP (safezoneh - 1.5 * H_GRID)
#define COMMIT_TIME 0.25

if (!hasInterface) exitWith {};

#include "cities.sqf"

_map = finddisplay 12;
_ctrlMap = _map displayctrl 51;
_grpSearch = _map displayctrl IDC_RSCMAP_MRKGROUP;
_edSearch = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKSEARCH;
_lbMarker = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKLIST;
_cbShow = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKSHOW;
_background = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKBACKGROUND;
_btnEndSearch = _grpSearch controlsGroupCtrl IDC_RSCMAP_MRKENDSEARCH;

_fncUpdate = {
    lbclear _lbMarker;
    _filter = ctrltext _edSearch;
    {
        _cityName = _x select 0;
        _cityPos = _x select 1;
        if (tolower _filter in tolower _cityName) then {
            _ind = _lbMarker lbAdd _cityName;
            _lbMarker lbSetData [_ind, str _cityPos];
        };
    } forEach cities;
};
params ["_mode",["_this",[]]];
switch _mode do {
    case "init": {
        TER_fnc_mapsearch = compileFinal preprocessfilelinenumbers "mapsearch\fn_mapsearch.sqf";
        waituntil {!isnull finddisplay 12};
        _map = finddisplay 12;
        _grpSearch = _map ctrlcreate ["RscControlsGroupNoScrollbars", IDC_RSCMAP_MRKGROUP];
        _grpSearch ctrlsetposition [
            X_GRID - W_GRP,
            Y_GRID + 1.5 * H_GRID,
            W_GRP,
            H_GRP
        ];
        _grpSearch ctrlcommit 0;
        _grpSearch ctrladdeventhandler ["MouseEnter", {
            systemchat str _this;
        }];
        _background = _map ctrlcreate ["RscText", IDC_RSCMAP_MRKBACKGROUND, _grpSearch];
        _background ctrlsetposition [0, 0, W_GRP, H_GRP];
        _background ctrlsetbackgroundcolor [0, 0, 0, 0.66];
        _background ctrlcommit 0;
        _cbShow = _map ctrlcreate ["RscCheckbox", IDC_RSCMAP_MRKSHOW, _grpSearch];
        _cbShow ctrlsetposition [
            0.1 * W_GRID,
            0,
            1 * W_GRID,
            1 * H_GRID
        ];
        _cbShow ctrlcommit 0;
        _cbShow ctrlsettooltip "Toggle City Search";
        _cbShow cbsetchecked true;
        _cbShow ctrladdeventhandler ["CheckedChanged", {
            ["toggleVisibility", _this] spawn SELF;
        }];
        _btnEndSearch = _map ctrlCreate ["RscActivePicture", IDC_RSCMAP_MRKENDSEARCH, _grpSearch];
        _btnEndSearch ctrlSetPosition [
            W_GRP - 1 * W_GRID,
            0.1 * H_GRID,
            1 * W_GRID,
            1 * H_GRID
        ];
        _btnEndSearch ctrlCommit 0;
        _btnEndSearch ctrlsettext "\a3\3den\data\Displays\Display3den\search_end_ca.paa";
        _btnEndSearch ctrlAddEventHandler ["ButtonClick", {
            ["endSearch", _this] call SELF;
        }];
        _edSearch = _map ctrlcreate ["RscEdit", IDC_RSCMAP_MRKSEARCH, _grpSearch];
        _edSearch ctrlsetposition [
            1.1 * W_GRID,
            0.1 * H_GRID,
            W_GRP - 2.3 * W_GRID,
            1 * H_GRID
        ];
        _edSearch ctrlcommit 0;
        _edSearch ctrladdeventhandler ["KeyDown", {
            ["keySearch", _this] spawn SELF;
        }];
        _edSearch ctrladdeventhandler ["SetFocus", {
            ["focusSearch", _this] call SELF;
        }];
        _lbMarker = _map ctrlcreate ["RscListbox", IDC_RSCMAP_MRKLIST, _grpSearch];
        _lbMarker ctrlsetposition [
            0.1 * W_GRID,
            1.2 * H_GRID,
            W_GRP - 0.2 * W_GRID,
            H_GRP - 1.3 * H_GRID
        ];
        _lbMarker ctrlcommit 0;
        addmissioneventhandler ["Map", {
            params ["_mapIsOpened", "_mapIsForced"];
            if (_mapIsOpened) then {
                ["mapOpen", []] call SELF;
            };
        }];
        _lbMarker ctrladdeventhandler ["LBSelChanged", {
            ["cityChanged", _this] call SELF;
        }];
    };
    case "mapOpen": {
        [] call _fncUpdate;
        ["updateLoop"] spawn SELF;
    };
	case "cityChanged": {
    params ["_lbMarker", "_ind"];
    _cityPos = call compile (_lbMarker lbData _ind);
    private _fixedScale = 0.05;
    mapanimadd [1, _fixedScale, _cityPos];
    mapanimcommit;
	};

    case "keySearch": {
        params ["_edSearch"];
        if (ctrltext _edSearch == _edSearch getvariable ["prevSearch", ""]) exitwith {};
        _edSearch setvariable ["prevSearch", ctrltext _edSearch];
        [] call _fncUpdate;
    };
	
    case "toggleVisibility": {
        params ["_cbShow", "_checked"];
        _checked = _checked == 1;
        if (_checked) then {
            {
                _x ctrlsetpositionh (H_GRP);
                _x ctrlcommit COMMIT_TIME;
            } foreach [_grpSearch, _background];
            _lbMarker ctrlsetpositionh (H_GRP - 1.3 * H_GRID);
            _lbMarker ctrlcommit COMMIT_TIME;
            _lbMarker ctrlshow true;
        } else {
            {
                _x ctrlsetpositionh (1.2 * H_GRID);
                _x ctrlcommit COMMIT_TIME;
            } foreach [_grpSearch, _background];
            _lbMarker ctrlsetpositionh 0;
            _lbMarker ctrlcommit COMMIT_TIME;
            waituntil {ctrlcommitted _lbMarker};
            _lbMarker ctrlshow false;
        };
    };
	
    case "updateLoop": {
        while {visibleMap} do {
            for "_ind" from 0 to ((lbsize _lbMarker) - 1) do {
                private _cityPos = call compile (_lbMarker lbData _ind);
                private _d = player distance _cityPos;
                _lbMarker lbSetValue [_ind, _d];
                _lbMarker lbSetTextRight [_ind, format ["%1 m", round _d]];
            };
            lbSortByValue _lbMarker;
            uiSleep 1;
        };
    };

    case "endSearch": {
        params ["_btnEndSearch"];
        _edSearch ctrlSetText "";
        [] call _fncUpdate;
    };
};
true