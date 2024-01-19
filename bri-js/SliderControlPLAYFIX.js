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
        rezoom: null
    },

    initialize: function(options) {
        L.Util.setOptions(this, options);
        this._layer = this.options.layer;
    },

    setPosition: function(position) {
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

    onAdd: function(map) {
        this.options.map = map;

        // Create a control sliderContainer with a jquery ui slider
        var sliderContainer = L.DomUtil.create('div', 'slider', this._container);
        $(sliderContainer).append('<div id="leaflet-slider" style="width:200px"><div class="ui-slider-handle"></div><div id="slider-timestamp" style="width:200px; margin-top:13px; background-color:#FFFFFF; text-align:center; border-radius:5px;"></div></div>');
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

        //If a layer has been provided: calculate the min and max values for the slider
        if (this._layer) {
            var index_temp = 0;
            this._layer.eachLayer(function(layer) {
                options.layers[index_temp] = layer;
                ++index_temp;
            });
            options.maxValue = index_temp - 1;
            this.options = options;
        } else {
            console.log("Error: You have to specify a layer via new SliderControl({layer: your_layer});");
        }
        return sliderContainer;
    },

    onRemove: function(map) {
        //Delete all markers which where added via the slider and remove the slider div
        for (i = this.options.minValue; i < this.options.maxValue; i++) {
            map.removeLayer(this.options.layers[i]);
        }
        $('#leaflet-slider').remove();
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
        $("#leaflet-slider").slider({
            value: _options.value,
            values: _options.values,
            min: _options.minValue,
            max: _options.maxValue,
            slide: this.slide
        });
        if (!_options.range && _options.alwaysShowDate) {
            $('#slider-timestamp').html(_options.layers[index_start].options.time.substr(0, 19));
        }
        for (i = _options.minValue; i <= index_start; i++) {
            _options.map.addLayer(_options.layers[i]);
        }
    }
});

L.control.sliderControl = function (options) {
    return new L.Control.SliderControl(options);
};