/* global layerGroup, map, PMTFVlegend,
getTableData, getLegend, sidebarContentController, intialTableData,
dataT, showmeHistogram, addHistInput, checkies, showdown */
let dlist;
/* === MY DATA ON GITHUB === */
const mapvars = {
  TWTEN: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2010pm25.geojson",
  TWELE: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2011pm25.geojson",
  TWTWE: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2012pm25.geojson",
  TWTHI: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2013pm25.geojson",
  TWFOU: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2014pm25.geojson",
  TWFIF: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2015pm25.geojson",
  TWSIX: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2016pm25.geojson",
  TWSEV: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2017pm25.geojson",
  TWEIG: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2018pm25.geojson",
  TWNIN: "https://raw.githubusercontent.com/aidanpcole/India-Timelapse/main/data/DataForMap/simpletimes2019pm25.geojson",
  PMTFV: "https://raw.githubusercontent.com/aidanpcole/Raster-Timelapse/main/data/DataForMap/simplecensusdistricts2019.geojson"
};

//const pointLayers = ["coolingCenters", "emergencyP", "pools", "parks", "hosp"]; // i think this needs to be a dictionary
const polygonLayers = ["TWTEN", "TWELE", "TWTWE", "TWTHI", "TWFOU", "TWFIF", "TWSIX", "TWSEV", "TWEIG", "TWNIN", "PMTFV"]; // with string name and var



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


// === Style  === //
function style(feature) {
  return {
    fillColor: '#fff9db',
    weight: 0.5,
    opacity: 0.7,
    color: "gray",
    fillOpacity: 0.5,
    colorOpacity: 0.1,
  };
}


// === realted styles for mapping ==//

const stylevars = {
  PMTFV: style,
};

const bindingsvars = {
  PMTFV: onEachFeaturePMTFV,
};


/// .addTo(map) used to be .addTo(layerGroup)
function updateMap(url, styleType, bindings) {
  fetch(url)
    .then(resp => resp.json())
    .then(data => {
      dlist = data;
      L.geoJSON(data, {
        style: styleType,
        onEachFeature: bindings
      }).addTo(layerGroup);
    });
}

function initializeMap() {
  console.log("INITIALIZEMAP FN");
  updateMap(mapvars.PMTFV, stylevars.PMTFV, onEachFeaturePMTFV);
  sidebarContentController("story-slide");
}
