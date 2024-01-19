L.Control.SliderControl = L.Control.extend({
    options: {
        position: 'topright',
        layers: null,
        maxValue: -1,
        minValue: 0,
        showAllOnStart: false,
        markers: null,
        range: false,
        follow: false,
        alwaysShowDate: false,
        orderMarkers: true,
        sameDate: false,
        orderDesc: false, 
        rezoom: null
    },

    initialize: function(options) {
        L.Util.setOptions(this, options);
        this._layer = this.options.layer;
        L.extend(this, L.Mixin.Events);
    },


    onAdd: function(map) {
        this.options.map = map;

        // Create a control sliderContainer with a jquery ui slider
        this.container = L.DomUtil.create('div','',this._container);
        this.sliderBoxContainer = L.DomUtil.create('div','slider',this.container);
      	var sliderContainer = L.DomUtil.create('div','',this.sliderBoxContainer);
      	L.DomUtil.create('div','ui-slider-handle',sliderContainer);
      	this.timestampContainer = L.DomUtil.create('div','ui-slider-handle',this.container);
        $(sliderContainer).append('<div id="leaflet-slider" style="width:200px"></div>')
        this.timestampContainer.id = "slider-timestamp";
        this.timestampContainer.style.cssText = "width:200px; margin-top:13px; background-color:#FFFFFF; text-align:center; border-radius:5px;";
        //Prevent map panning/zooming while using the slider
        $(sliderContainer).mousedown(function() {
            map.dragging.disable();
        });
        $(document).mouseup(function() {
            map.dragging.enable();
            //Hide the slider timestamp if not range and option alwaysShowDate is set on false
            if (options.range || !options.alwaysShowDate) {
                $('#slider-timestamp').html('');
            }
        });

        var options = this.options;
        this.options.layers = [];

        function compare( a, b ) {
            var valA = null;
            var valB = null;

            if(a.features && a.features.properties && a.feature.properties[options.timeAttribute]){
                valA = a.feature.properties[options.timeAttribute];
            }else if(a.options[options.timeAttribute]){
                valA = a.options[options.timeAttribute];
            }
            if(b.features && b.features.properties && b.feature.properties[options.timeAttribute]){
                valB = b.feature.properties[options.timeAttribute];
            }else if(b.options[options.timeAttribute]){
                valB = b.options[options.timeAttribute];
            }
            if(valA && valB) {
                if (valA < valB) {
                    return -1;
                }
                if (valA > valB) {
                    return 1;
                }
            }
            return 0;
        }

        //If a layer has been provided: calculate the min and max values for the slider
        if (this._layer) {
            var index_temp = 0;
            var templayers = [];
            this._layer.eachLayer(function(layer) {
                templayers.push(layer);
            });
            
            if (options.orderMarkers) {
            	templayers = templayers.sort(compare);
            	
            	if (options.orderDesc) {
            		templayers = templayers.reverse();
            	}
            }
            
            var that = this; 
            templayers.forEach(function (layer) {
            	options.layers[index_temp] = layer;
            	++index_temp
            });
            
            options.maxValue = index_temp - 1;
            this.options = options;
        } else {
            console.log("Error: You have to specify a layer via new SliderControl({layer: your_layer});");
        }
        return this.container;
    },

    onRemove: function(map) {
        //Delete all markers which where added via the slider and remove the slider div
        for (i = this.options.minValue; i < this.options.maxValue; i++) {
            map.removeLayer(this.options.layers[i]);
        }
        this.container.remove();
        //maybe need to add clear timestamp? 
    },

    slide: function(e, ui) {
        var map = _options.map;
        var fg = L.featureGroup();
        if (!!_options.layers[ui.value]) {
            // If there is no time property, this line has to be removed (or exchanged with a different property)
            if (_options.layers[ui.value].feature !== undefined) {
                if (_options.layers[ui.value].feature.properties.time) {
                    if (_options.layers[ui.value]) $('#slider-timestamp').html(_options.layers[ui.value].feature.properties.time.substr(0, 19));
                } else {
                    console.error("You have to have a time property");
                }
            } else {
                // set by leaflet Vector Layers
                if (_options.layers[ui.value].options.time) {
                    if (_options.layers[ui.value]) $('#slider-timestamp').html(_options.layers[ui.value].options.time.substr(0, 19));
                } else {
                    console.error("You have to have a time property");
                }
            }

            var i;
            // clear markers
            for (i = _options.minValue; i <= _options.maxValue; i++) {
                if (_options.layers[i]) map.removeLayer(_options.layers[i]);
            }
            if (_options.range) {
                // jquery ui using range
                for (i = ui.values[0]; i <= ui.values[1]; i++) {
                    if (_options.layers[i]) {
                        map.addLayer(_options.layers[i]);
                        fg.addLayer(_options.layers[i]);
                    }
                }
            } else if (_options.follow) {
                for (i = ui.value - _options.follow + 1; i <= ui.value; i++) {
                    if (_options.layers[i]) {
                        map.addLayer(_options.layers[i]);
                        fg.addLayer(_options.layers[i]);
                    }
                }
            } else {
                for (i = _options.minValue; i <= ui.value; i++) {
                    if (_options.layers[i]) {
                        map.addLayer(_options.layers[i]);
                        fg.addLayer(_options.layers[i]);
                    }
                }
            }
        };
        if (_options.rezoom) {
            map.fitBounds(fg.getBounds(), {
                maxZoom: _options.rezoom
            });
        }
    },

    startSlider: function() {
        _options = this.options;
        var index_start = _options.minValue;
        if (_options.showAllOnStart) {
            index_start = _options.maxValue;
            console.log(index_start);
            if (_options.range) _options.values = [_options.minValue, _options.maxValue];
            else _options.value = _options.maxValue;
        }
        $('#leaflet-slider').slider({
            range: _options.range,
            value: _options.value,
            values: _options.values,
            min: _options.minValue,
            max: _options.maxValue,
            step: 1,
            slide: this.slide
        });
        if (!_options.range && _options.alwaysShowDate) {
            $('#slider-timestamp').html(_options.layers[index_start].options.time.substr(0, 19));
        }
        for (i = _options.minValue; i <= index_start; i++) {
            _options.map.addLayer(_options.layers[i]);
        }
    },


    clearTimestamp: function(){
        //Hide the slider timestamp if not range and option alwaysShowDate is set on false
        if (!this.options.alwaysShowDate) {
            this.timestampContainer.innerHTML = "";
            this.timestampContainer.style.display = "none";
        }
    },

    extractTimestamp: function(time, options) {
        if (options.isEpoch) {
            time = (new Date(parseInt(time))).toString(); // this is local time
        }
        return time.substr(options.startTimeIdx, options.startTimeIdx + options.timeStrLength);
    },

    setPosition: function (position) {
        var map = this._map;

        if (map) {
            map.removeControl(this);
        }

        this.options.position = position;

        if (map) {
            map.addControl(this);
        }
        this.startSlider();
        return this;
    },

});

L.control.sliderControl = function (options) {
    return new L.Control.SliderControl(options);
};
