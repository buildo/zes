# import sketch here
originalLayers = Framer.Importer.load "imported/my sketch project"

# utility functions

show = (_layer) ->
	_layer.states.switch "on"

hide = (_layer) ->
	_layer.states.switch "off"

getSubLayer = (_layer, _name) ->
	for l in _layer.subLayers
		if l.name == _name
			return l

getSubLayerContaining = (_layer, _name) ->
	for l in _layer.subLayers
		if l.name.indexOf(_name) > -1
			return l

getAllSubLayersContaining = (_layer, _name) ->
	out = []
	for l in _layer.subLayers
		if l.name.indexOf(_name) > -1
			out.push l
	out

collapsible = (_opened, _closed, _opened_target, _closed_target, _onChange) ->
	_opened_target.style.cursor = 'pointer'
	_opened_target.on Events.Click, ->
		hide _opened
		show _closed
		_onChange("closed")	 if _onChange
	_closed_target.style.cursor = 'pointer'
	_closed_target.on Events.Click, ->
		hide _closed
		show _opened
		_onChange("opened") if _onChange

togglable = (_opened, _target) ->
	_target.style.cursor = 'pointer'
	_target.on Events.Click, ->
		_opened.states.next(["on", "off"])

tabs = (_targets, _panels) ->
	zipped = _.zip(_targets, _panels)
	zipped.forEach (s) ->
		s[0].style.cursor = 'pointer'
		s[0].on Events.Click, ->
			_panels.map((p) -> hide p)
			_targets.map((t) ->
				getSubLayer(t, '__active').visible = false
				getSubLayer(t, '__inactive').visible = true
			)
			show s[1]
			getSubLayer(s[0], '__active').visible = true
			getSubLayer(s[0], '__inactive').visible = false
			getSubLayer(s[0], '__hover')?.visible = false

	_targets.map((t) ->
		if getSubLayer(t, '__hover')
			t.on Events.MouseOver, ->
				if getSubLayer(t, '__inactive').visible
					getSubLayer(t, '__inactive').visible = false
					getSubLayer(t, '__hover').visible = true
			t.on Events.MouseOut, ->
				if getSubLayer(t, '__hover').visible
					getSubLayer(t, '__inactive').visible = true
					getSubLayer(t, '__hover').visible = false
	)

hover = (t) ->
	t.on Events.MouseOver, ->
		getSubLayerContaining(t, '__inactive')?.visible = false
		getSubLayerContaining(t, '__hover')?.visible = true
	t.on Events.MouseOut, ->
		getSubLayerContaining(t, '__hover')?.visible = false
		getSubLayerContaining(t, '__inactive')?.visible = true

printHierarchy = (p, l=0) ->
	for c in p.subLayers
		print Array(l*2).join("...."), c
		printHierarchy(c, l+1)

shows = (target, panel) ->
	target.on Events.Click, ->
		panel.visible = true

hides = (target, panel) ->
	target.on Events.Click, ->
		panel.visible = false

makeScrollable = (panel, x, y) ->
	scroll = ScrollComponent.wrap(panel)
	scroll.scrollHorizontal = x
	scroll.scrollVertical = y

# generic setup
v = false
window.layers = {}
window.layerActions = {}
# first import all layers that begin with an underscore..
for _name, _layer of originalLayers
	_layer.style.cursor = 'pointer'
	if _name.substring(0, 1) == "_" and _name.substring(1, 1) != "_"
		_layer.states.add
			off: {visible: false}
			on: {visible: true}
		baseName = _name.split(",_")[0]
		window[baseName] = _layer
		window.layers[baseName] = _layer
# then autoapply basic actions..
for _name, _layer of originalLayers
	nameSections = _name.split(",_")
	for section in nameSections
		if section.indexOf("toggle=") > -1
			layerToToggle = section.match(/toggle=(_[\w_]+)/)[1]
			togglable(layers[layerToToggle], _layer)
		if section.indexOf("__mouse") > -1
			hover(_layer)
		if section.indexOf("__tabs") > -1
			targets = []
			panels = []
			ls = getAllSubLayersContaining(_layer, 'panel=')
			for l in ls
				panelName = l.name.match(/panel=(_[\w_]+)/)[1]
				targets.push l
				panels.push layers[panelName]
			tabs(targets, panels)
		if section.indexOf("show=") > -1
			panelName = section.match(/show=(_[\w_]+)/)[1]
			if v then print "show", _layer, layers[panelName]
			shows(_layer, layers[panelName])
		if section.indexOf("hide=") > -1
			panelName = section.match(/hide=(_[\w_]+)/)[1]
			if v then print "hide", _layer, layers[panelName]
			hides(_layer, layers[panelName])
		if section.indexOf("scroll=") > -1
			directions = section.match(/scroll=([xy]+)/)[1]
			makeScrollable(_layer, directions.indexOf("x") > -1, directions.indexOf("y") > -1)
