shacktags = {
  none: (s) -> "#{s}"
  red: (s) -> "r{#{s}}r"
  green: (s) -> "g{#{s}}g"
  blue: (s) -> "b{#{s}}b"
  yellow: (s) -> "y{#{s}}y"
  olive: (s) -> "e[#{s}]e"
  lime: (s) -> "l[#{s}]l"
  orange: (s) -> "n[#{s}]n"
  pink: (s) -> "p[#{s}]p"
  italics: (s) -> "/[#{s}]/"
  bold: (s) -> "b[#{s}]b"
  quote: (s) -> "q[#{s}]q"
  sample: (s) -> "s[#{s}]s"
  underline: (s) -> "_[#{s}]_"
  strike: (s) -> "-[#{s}]-"
  spoiler: (s) -> "o[#{s}]o"
  code: (s) -> "/{{#{s}}}/"
}

tags = {
  0: shacktags.none
  1: shacktags.blue
  2: shacktags.green
  3: shacktags.orange
  4: shacktags.yellow
  5: shacktags.lime
  6: shacktags.olive
  7: shacktags.pink
  8: shacktags.orange
  'mine': shacktags.red
}

class Cell
  constructor: (@ascii) ->
    @isMine = false
    @count = 0
    @isRevealed = false
  shackStr: ->
    str = ''
    tag = if @isMine then tags['mine'] else tags[@count]
    if @isRevealed 
      return tag if @isMine then @ascii.mine else if @count == 0 then @ascii.empty else @count
    else 
      return tag shacktags.spoiler if @isMine then @ascii.mine else if @count == 0 then @ascii.empty else @count
  str: ->
    return '?' unless @isRevealed
    if @isMine then @ascii.mine else if @count == 0 then @ascii.empty else @count
    


class Minefield
  constructor: ({@width, @height, @mines, @ascii}) ->
    @mines = (@width*@height)/2 if @mines > @width * @height
    @field = []
    for row in [0..@height-1]
      @field[row] = [] 
      for col in [0..@width-1]
        @field[row][col] = new Cell @ascii

  distribute: ->   
    for row in [0..@height-1]
      for col in [0..@width-1]
        @field[row][col].isMine = false
    placed = 0
    while placed < @mines 
      col = 0|Math.random() * @width
      row = 0|Math.random() * @height
      continue if @field[row][col].isMine
      @field[row][col].isMine = true
      placed++

  kernel: (row, col) ->
    rowMin = Math.max(row-1, 0)
    rowMax = Math.min(row+1, @height-1)
    colMin = Math.max(col-1, 0)
    colMax = Math.min(col+1, @width-1)
    k = []
    r = 0
    for row in [rowMin..rowMax]
      for col in [colMin..colMax]
        k.push {row, col}
    return k


  count: ->
    for row in [0..@height-1]
      for col in [0..@width-1]
        kernel = @kernel row, col
        count = 0
        for pos in kernel
          count++ if @field[pos.row][pos.col].isMine
        @field[row][col].count = count

  startReveal: ->
    empties = []
    for row in [0..@height-1]
      for col in [0..@width-1]
        if @field[row][col].count == 0
          empties.push {row, col}
    return unless empties.length > 0
    choice = empties[0|Math.random()*empties.length]
    @reveal choice


  reveal: (pos) ->
    list = [pos]
    while list.length > 0
      {row, col} = list.pop()
      @field[row][col].isRevealed = true
      if @field[row][col].count == 0
        for pos in @kernel row, col
          list.push pos unless @field[pos.row][pos.col].isRevealed
        


  print: ->
    str = ''
    for row in [0..@height-1]
      for col in [0..@width-1]
        str += @field[row][col].str()
      str += '\n'
    return str

  shackPrint: (spaced) ->
    str = '/{{'
    for row in [0..@height-1]
      for col in [0..@width-1]
        str += @field[row][col].shackStr()        
        str += ' ' if spaced
      str += '\n' unless row == @height-1
    str += '}}/'
    return str



express = require 'express'

app = express()
app.get '/', (req, res) ->
  console.log "#{(new Date).toISOString()} #{req.get('X-Real-IP')} #{req.originalUrl}"
  
  ascii = {
    mine: req.query.minechar or '\u2665'
    empty: req.query.emptychar or '\u00b7'
  }
  # beginner 9x9 10, intermediate 16x16 40, advanced 16x30 99

  width = req.query.width or 16
  height = req.query.height or 16
  mines = req.query.mines or 40
  spaced = req.query.spaced=='true' or false

  # big numbers would hurt :(
  width = Math.min(width, 100)
  height = Math.min(height, 100)

  x = new Minefield {width, height, mines, ascii}
  x.distribute()
  x.count()
  x.startReveal()
  res.charset = 'utf-8'
  res.type('text/plain')
  console.log x.shackPrint(spaced).length
  res.send(x.shackPrint(spaced))


app.listen 5771



