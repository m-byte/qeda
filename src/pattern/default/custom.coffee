assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

pinNumber = 0
mountingHole = 1
ncPad = 1

copperPads = (pattern, element, suffix = '') ->
  housing = element.housing
  pins = element.pins
  numbers = Object.keys pins
  unless (housing['holeDiameter' + suffix]?) or (housing['padDiameter' + suffix]?) or (housing['padWidth' + suffix]? and housing['padHeight' + suffix]?)
    return false
  hasPads = false
  if housing['holeDiameter' + suffix]?
    holeDiameter = housing['holeDiameter' + suffix]
    padDiameter = housing['padDiameter' + suffix] ? calculator.padDiameter pattern, housing, holeDiameter
    padWidth = housing['padWidth' + suffix] ? padDiameter
    padHeight = housing['padHeight' + suffix] ? padDiameter
    pad =
      type: 'through-hole'
      hole: housing['holeDiameter' + suffix]
      width: padWidth
      height: padHeight
      shape: if (pinNumber is 0) and housing.polarized then 'rectangle' else 'circle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
    if (padWidth < holeDiameter) or (padHeight < holeDiameter)
      pad.type = 'mounting-hole'
      pad.layer = ['topCopper', 'topMask', 'bottomCopper', 'bottomMask']
      pad.width = holeDiameter
      pad.height = holeDiameter
      pad.shape = 'circle'
  else
    padDiameter = housing['padDiameter' + suffix]
    padWidth = housing['padWidth' + suffix] ? padDiameter
    padHeight = housing['padHeight' + suffix] ? padDiameter
    pad =
      type: 'smd'
      width: housing['padWidth' + suffix]
      height: housing['padHeight' + suffix]
      shape: if padDiameter? then 'circle' else 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste']

  if housing['padPosition' + suffix]?
    hasPads = true
    points = pattern.parsePosition housing['padPosition' + suffix]
    for p, i in points
      pad.x = p.x
      pad.y = p.y
      number = if pad.type is 'mounting-hole' then ('MH' + mountingHole++) else (numbers[pinNumber++] ? ('NC' + ncPad++))
      pattern.pad number, pad
      if housing['holeDiameter' + suffix]?
        pad.shape = 'circle'
  else if housing['rowCount' + suffix]? and housing['columnCount' + suffix]?
    hasPads = true
    rowCount = housing['rowCount' + suffix]
    if rowCount is 1
      verticalPitch = 0
    else
      verticalPitch = housing['verticalPitch' + suffix] ? housing['pitch' + suffix]
    rowDXs = pattern.parseArray housing['rowDX' + suffix]
    rowDYs = pattern.parseArray housing['rowDY' + suffix]
    columnCounts = pattern.parseArray housing['columnCount' + suffix]
    horizontalPitch = housing['horizontalPitch' + suffix] ? housing['pitch' + suffix]
    columnDXs = pattern.parseArray housing['columnDX' + suffix]
    columnDYs = pattern.parseArray housing['columnDY' + suffix]
    y = -verticalPitch*(rowCount - 1)/2
    for row in [0..(rowCount - 1)]
      columnCount = columnCounts[row] ? columnCounts[0]
      rowDX = rowDXs[row] ? rowDXs[0]
      rowDY = rowDYs[row] ? rowDYs[0]
      x = -horizontalPitch*(columnCount - 1)/2
      for column in [0..(columnCount - 1)]
        columnDX = columnDXs[column] ? columnDXs[0]
        columnDY = columnDYs[column] ? columnDYs[0]
        pad.x = x + rowDX + columnDX
        pad.y = y + rowDY + columnDY
        number = if pad.type is 'mounting-hole' then ('MH' + mountingHole++) else (numbers[pinNumber++] ? ('NC' + ncPad++))
        pattern.pad number, pad
        if housing['holeDiameter' + suffix]?
          pad.shape = 'circle'
        x += horizontalPitch
      y += verticalPitch

  hasPads

module.exports = (pattern, element) ->
  housing = element.housing
  pattern.name ?= element.group + '_' + element.name.toUpperCase()

  housing.bodyPosition ?= '0, 0'
  bodyPosition = pattern.parsePosition housing.bodyPosition
  housing.basePoint ?= '0, 0'
  basePoint = pattern.parsePosition housing.basePoint
  pattern.center -bodyPosition[0].x + basePoint[0].x, -bodyPosition[0].y + basePoint[0].y

  pinNumber = 0
  mountingHole = 1
  ncPad = 1
  copperPads pattern, element
  i = 1
  loop
    unless copperPads(pattern, element, i++) then break

  pattern.center 0, 0

  copper.mask pattern
  silkscreen.body pattern, housing
  if housing.polarized
    assembly.polarized pattern, housing
  else
    assembly.body pattern, housing
  courtyard.boundary pattern, housing
