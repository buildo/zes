# import sketch here
originalLayers = Framer.Importer.load "imported/my sketch project"

# utility functions

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

getFirstParentWithName = (_layer) ->
	parent = _layer.superLayer
	parentName = parent.name.split(",_")[0]
	if layers[parentName]?
		parent
	else
		getFirstParentWithName(parent)

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
# 	return
	if window.v then print "toggle", _target, _opened
	_target.style.cursor = 'pointer'
	_target.on Events.Click, ->
		_opened.visible = !_opened.visible

tabs = (_targets, _panels) ->
# 	return
	if v then print "tabs", _targets, _panels
	zipped = _.zip(_targets, _panels)
	zipped.forEach (s) ->
		s[0].style.cursor = 'pointer'
		s[0].on Events.Click, ->
			_panels.map((p) -> p.visible = false)
			_targets.map((t) ->
				getSubLayerContaining(t, '__active')?.visible = false
				getSubLayerContaining(t, '__inactive')?.visible = true
			)
			s[1].visible = true
			getSubLayerContaining(s[0], '__active')?.visible = true
			getSubLayerContaining(s[0], '__inactive')?.visible = false
			getSubLayerContaining(s[0], '__hover')?.visible = false

	_targets.map((t) ->
		if getSubLayerContaining(t, '__hover')
			t.on Events.MouseOver, ->
				if not getSubLayerContaining(t, '__active')?.visible
					if getSubLayerContaining(t, '__inactive')?.visible
						getSubLayerContaining(t, '__inactive')?.visible = false
					getSubLayerContaining(t, '__hover')?.visible = true
			t.on Events.MouseOut, ->
				if getSubLayerContaining(t, '__hover')?.visible
					getSubLayerContaining(t, '__inactive')?.visible = true
					getSubLayerContaining(t, '__hover')?.visible = false
	)

hover = (t) ->
# 	return
	t.style.cursor = 'pointer'
	t.on Events.MouseOver, ->
		getSubLayerContaining(t, '__inactive')?.visible = false
		getSubLayerContaining(t, '__hover')?.visible = true
	t.on Events.MouseOut, ->
		getSubLayerContaining(t, '__hover')?.visible = false
		getSubLayerContaining(t, '__inactive')?.visible = true

printHierarchy = (p, l=0) ->
	for c in p.subLayers
		print Array(l*2).join("..."), c
		printHierarchy(c, l+1)

shows = (target, panel) ->
# 	return
	if window.v then print "shows", target.name, panel.name
	target.style.cursor = 'pointer'
	target.on Events.Click, ->
		if window.v then print "showing", target.name, panel.name
		panel.visible = true

hides = (target, panel) ->
# 	return
	if window.v then print "hides", target.name, panel.name
	target.style.cursor = 'pointer'
	target.on Events.Click, ->
		if window.v then print "hiding", target.name, panel.name
		panel.visible = false

makeScrollable = (panel, x, y) ->
	return
	scroll = ScrollComponent.wrap(panel)
	scroll.scrollHorizontal = x
	scroll.scrollVertical = y

goTo = (target, destinationLayer) ->
	layerToHide = getFirstParentWithName(target)
	if window.v then print "goes to", target.name, destinationLayer.name, "and hides", layerToHide.name
	target.style.cursor = 'pointer'
	target.on Events.Click, ->
		layerToHide.visible = false
		destinationLayer.visible = true

resetVisibilities = ->
	if section.indexOf("__hide") > -1
			_layer.visible = false

printClick = (layer) ->
	layer.on Events.Click, ->
		print ">>>> CLICK >>>>>", layer


# generic setup
window.v = false
window.layers = {}
window.layerActions = {}
# first import all layers that begin with an underscore..
for _name, _layer of originalLayers
	if _name.substring(0, 1) == "_" and _name.substring(1, 1) != "_"
		baseName = _name.split(",_")[0]
		window[baseName] = _layer
		window.layers[baseName] = _layer
# then autoapply basic actions..
for _name, _layer of originalLayers
	nameSections = _name.split(",_")
	for section in nameSections
		if section.indexOf("toggle=") > -1
			layerToToggle = section.match(/toggle=(_[\d\w_]+)/)[1]
			togglable(layers[layerToToggle], _layer)
		if section.indexOf("__mouse") > -1
			hover(_layer)
		if section.indexOf("__tabs") > -1
			targets = []
			panels = []
			ls = getAllSubLayersContaining(_layer, 'panel=')
			for l in ls
				panelName = l.name.match(/panel=(_[\d\w_]+)/)[1]
				targets.push l
				panels.push layers[panelName]
			tabs(targets, panels)
		if section.indexOf("__hide") > -1
			_layer.visible = false
			if v then print("__hide", _layer)
		if section.indexOf("show=") > -1
			panelName = section.match(/show=(_[\d\w_]+)/)[1]
			if v then print "show", _layer, layers[panelName]
			shows(_layer, layers[panelName])
		if section.indexOf("hide=") > -1
			panelName = section.match(/hide=(_[\d\w_]+)/)[1]
			hides(_layer, layers[panelName])
		if section.indexOf("scroll=") > -1
			directions = section.match(/scroll=([xy]+)/)[1]
			makeScrollable(_layer, directions.indexOf("x") > -1, directions.indexOf("y") > -1)
		if section.indexOf("goto=") > -1
			destinationLayer = section.match(/goto=(_[\d\w_]+)/)[1]
			goTo(_layer, layers[destinationLayer])
