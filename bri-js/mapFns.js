/* global layerGroup, map, PMTFVlegend,
getTableData, getLegend, sidebarContentController, intialTableData,
dataT, showmeHistogram, addHistInput, checkies, showdown */
let dlist;
/* === MY DATA ON GITHUB === */
const mapvars = {
  PMTFV: "https://raw.githubusercontent.com/aidanpcole/EXPOSOME_IRELAND_UK/main/data/DataForMap/UK_IRELAND_simple.geojson",
  OZONE: "https://raw.githubusercontent.com/aidanpcole/EXPOSOME_IRELAND_UK/main/data/DataForMap/UK_IRELAND_simple.geojson",
  NOTWO: "https://raw.githubusercontent.com/aidanpcole/EXPOSOME_IRELAND_UK/main/data/DataForMap/UK_IRELAND_simple.geojson",
  LIGHT: "https://raw.githubusercontent.com/aidanpcole/EXPOSOME_IRELAND_UK/main/data/DataForMap/UK_IRELAND_simple.geojson",
  SOURCE: "https://raw.githubusercontent.com/aidanpcole/EXPOSOMEDASHBOARD/main/data/DataForMap/pm25_quants.geojson"
};

//const pointLayers = ["coolingCenters", "emergencyP", "pools", "parks", "hosp"]; // i think this needs to be a dictionary
const polygonLayers = ["PMTFV","OZONE","NOTWO","LIGHT","SOURCE"]; // with string name and var



let tableData;

// =================== Functions ==========///
function onEachFeaturePMTFV(feature, layer) {
// use feature.properties to construct popup html
  let popupContent = '<table class="popupTable"><th><h3>District Stats</h3></th>';
  for (let p of Object.keys(feature.properties)) {
    popupContent += `<tr><td>${p}</td><td>${feature.properties[p]}</td></tr>`;
  }
  popupContent += '</table>';
  layer.bindPopup(popupContent);
  // var HVIScore = `<h2> Heat Vulnerability Score: ${feature.properties.rTotalVulScore} </h2>`;
  // layer.bindPopup(HVIScore);
}

function onEachFeatureOZONE(feature, layer) {
// use feature.properties to construct popup html
  let popupContent = '<table class="popupTable"><th><h3>District Stats</h3></th>';
  for (let p of Object.keys(feature.properties)) {
    popupContent += `<tr><td>${p}</td><td>${feature.properties[p]}</td></tr>`;
  }
  popupContent += '</table>';
  layer.bindPopup(popupContent);
  // var HVIScore = `<h2> Heat Vulnerability Score: ${feature.properties.rTotalVulScore} </h2>`;
  // layer.bindPopup(HVIScore);
}

function onEachFeatureNOTWO(feature, layer) {
// use feature.properties to construct popup html
  let popupContent = '<table class="popupTable"><th><h3>District Stats</h3></th>';
  for (let p of Object.keys(feature.properties)) {
    popupContent += `<tr><td>${p}</td><td>${feature.properties[p]}</td></tr>`;
  }
  popupContent += '</table>';
  layer.bindPopup(popupContent);
  // var HVIScore = `<h2> Heat Vulnerability Score: ${feature.properties.rTotalVulScore} </h2>`;
  // layer.bindPopup(HVIScore);
}

function onEachFeatureLIGHT(feature, layer) {
// use feature.properties to construct popup html
  let popupContent = '<table class="popupTable"><th><h3>District Stats</h3></th>';
  for (let p of Object.keys(feature.properties)) {
    popupContent += `<tr><td>${p}</td><td>${feature.properties[p]}</td></tr>`;
  }
  popupContent += '</table>';
  layer.bindPopup(popupContent);
  // var HVIScore = `<h2> Heat Vulnerability Score: ${feature.properties.rTotalVulScore} </h2>`;
  // layer.bindPopup(HVIScore);
}



// === Style  === //
function style(feature) {
  return {
    fillColor: '#fff9db',
    weight: 0.9,
    opacity: 0.9,
    color: "gray",
    fillOpacity: 0.1,
    colorOpacity: 0.9,
  };
}


// === realted styles for mapping ==//

const stylevars = {
  PMTFV: style,
  OZONE: style,
  NOTWO: style,
  LIGHT: style,
  SOURCE: style,
};

const bindingsvars = {
  PMTFV: onEachFeaturePMTFV,
  OZONE: onEachFeatureOZONE,
  NOTWO: onEachFeatureNOTWO,
  LIGHT: onEachFeatureLIGHT,
  SOURCE: onEachFeaturePMTFV,
};



/// .addTo(map) used to be .addTo(layerGroup) used to have ", bindings" after styleType 
function updateMap(url, styleType) {
			map.eachLayer(function(layer) {
  	if (!!layer.toGeoJSON) {
    map.removeLayer(layer);
  	}
		});
  fetch(url)
    .then(resp => resp.json())
    .then(data => {
      dlist = data;
      L.geoJSON(data, {
        style: styleType,
///use to have onEachFeature: bindings here 
      }).addTo(map);
    });
}






function initializeMap() { 
  console.log("INITIALIZEMAP FN");
  updateMap(mapvars.PMTFV, stylevars.PMTFV); /// used to have ", onEachFeaturePMTFV" after stylevars.PMTFV
  sidebarContentController("filter-slide");
}

function check(box) {
  let b = box;
  b.checked = true;
}

function uncheck(box) {
  let b = box;
  b.checked = false;
}

function disable(box) {
  let b = box;
  b.enabled = false;
}
// === Determine & Update Map From Check boxes == //
function determineMap() {
		map.eachLayer(function(layer) {
  	if (!!layer.toGeoJSON) {
    map.removeLayer(layer);
  	}
		});
  console.log("IN DETERMINE MAP");
  let names = [];
  checkies.forEach(c => {
    if (c.checked === true) {
      let n = c.id;
      names.push(n);
    }
  });
  names.forEach(name => {
//    if (pointLayers.includes(name)) {
//      if (name === "parks") {
//        updateMappointParks(mapvars[name], name, emptyCallback);
//      }
//      if (name === "emergencyP") {
//        updateMappointEmergency(mapvars[name], name, emptyCallback);
//      }
//      updateMappointPCH(mapvars[name], name, emptyCallback);
//    }
    if (polygonLayers.includes(name)) {
      updateMap(mapvars[name], stylevars[name]);   /// used to have ", bindingsvars[name]" after stylevars[name]
    }
  });
}

//checkies 3 and onward not incorporated in original
function anyChecked() {

  let trues = [];

  let l1 = checkies[0];
  let l2 = checkies[1];
  let l3 = checkies[2];
  let l4 = checkies[3];
  let l5 = checkies[4];

  let cs = [l1, l2, l3, l4, l5];
//  if (cs[3].checked) {
//    console.log("includes resources");
//    check(l5);
//    check(l6);
//    check(l7);
//    check(l8);
//    check(l9);
//  }

  cs.forEach(c => {
    if (c.checked === true) {
      trues.push("y");
    }
  });
  return trues;
}

function onCheck() {
  console.log("checkbox checked!");
  let trues = anyChecked();
  console.log(trues);
  if (trues.length > 0) {
    determineMap();
    determineTime();
  }
}



//function resourceCheck() {
//  if (!checkies[3].checked) {
//    console.log("resources unchecked");
//    uncheck(checkies[4]);
//    uncheck(checkies[5]);
//    uncheck(checkies[6]);
//    uncheck(checkies[7]);
//    uncheck(checkies[8]);
//    layerGroup.clearLayers();
//  }
//  onCheck();
//}

function PMTFVCheck() {
  if (checkies[0].checked) {
  	document.querySelector('#PMTFV').onclick = (e) => {
  		e.preventDefault();
  	}
    uncheck(checkies[1]);
    uncheck(checkies[2]);
    uncheck(checkies[3]);
    uncheck(checkies[4]);
    disable(checkies[1]);
    disable(checkies[2]);
    disable(checkies[3]);
    disable(checkies[4]);
  	document.querySelector('#OZONE').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#NOTWO').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#LIGHT').onclick = (e) => {
  		return true;
  	}
  }
  // onCheck();
}

function OZONECheck() {
  if (checkies[1].checked) {
  	document.querySelector('#OZONE').onclick = (e) => {
  		e.preventDefault();
  	}
    uncheck(checkies[0]);
    uncheck(checkies[2]);
    uncheck(checkies[3]);
    uncheck(checkies[4]);
    disable(checkies[0]);
    disable(checkies[2]);
    disable(checkies[3]);
    disable(checkies[4]);
  	document.querySelector('#PMTFV').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#NOTWO').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#LIGHT').onclick = (e) => {
  		return true;
  	}
  }
  // onCheck();
}

function NOTWOCheck() {
  if (checkies[2].checked) {
  	document.querySelector('#NOTWO').onclick = (e) => {
  		e.preventDefault();
  	}
    uncheck(checkies[0]);
    uncheck(checkies[1]);
    uncheck(checkies[3]);
    uncheck(checkies[4]);
    disable(checkies[0]);
    disable(checkies[1]);
    disable(checkies[3]);
    disable(checkies[4]);
  	document.querySelector('#PMTFV').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#OZONE').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#LIGHT').onclick = (e) => {
  		return true;
  	}
  }
  // onCheck();
}

function LIGHTCheck() {
  if (checkies[3].checked) {
  	document.querySelector('#LIGHT').onclick = (e) => {
  		e.preventDefault();
  	}
    uncheck(checkies[0]);
    uncheck(checkies[1]);
    uncheck(checkies[2]);
    uncheck(checkies[4]);
    disable(checkies[0]);
    disable(checkies[1]);
    disable(checkies[2]);
    disable(checkies[4]);
  	document.querySelector('#PMTFV').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#OZONE').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#NOTWO').onclick = (e) => {
  		return true;
  	}
  }
  // onCheck();
}

function SOURCECheck() {
  if (checkies[4].checked) {
  	document.querySelector('#SOURCE').onclick = (e) => {
  		e.preventDefault();
  		e.stopPropagation
  		return false;
  	}
    uncheck(checkies[0]);
    uncheck(checkies[1]);
    uncheck(checkies[2]);
    uncheck(checkies[3]);
    disable(checkies[0]);
    disable(checkies[1]);
    disable(checkies[2]);
    disable(checkies[3]);
  	document.querySelector('#PMTFV').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#OZONE').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#NOTWO').onclick = (e) => {
  		return true;
  	}
  	document.querySelector('#LIGHT').onclick = (e) => {
  		return true;
  	}
  }
  // onCheck();
}














