rally = require 'rally'
express = require 'express'
fs = require 'fs'

rally ioPort: 3001
store = rally.store
app = express.createServer()
app.use express.favicon()

# rally.js returns a browserify bundle of the rally client side code and the
# socket.io client side code
script = ''
rally.js (js) -> script = js + fs.readFileSync 'client.js'
style = fs.readFileSync 'style.css'

app.get '/script.js', (req, res) ->
  res.send script, 'Content-Type': 'application/javascript'

app.get '/', (req, res) ->
  res.redirect '/lobby'

app.get '/:room', (req, res) ->
  room = req.params.room
  return res.redirect '/lobby' unless /^[-\w ]+$/.test room
  _room = room.toLowerCase().replace /[_ ]/g, '-'
  return res.redirect _room if _room != room
  # Subscribe optionally accepts a model as an argument. If no model is
  # specified, it will create a new model object
  store.subscribe "rooms.#{room}.**", 'rooms.*.players', (err, model) ->
    initModel model, room
    # model.json waits for any pending model operations to complete and then
    # returns the data for initialization on the client
    model.json (json) ->
      res.send """
      <!DOCTYPE html>
      <title>Letters game</title>
      <style>#{style}</style>
      <link href=http://fonts.googleapis.com/css?family=Anton rel=stylesheet>
      <div id=back>
        <div id=page>
          <p id=info>
          <div id=rooms>
            <p>Rooms:
            <ul id=roomlist></ul>
          </div>
          <div id=board></div>
        </div>
      </div>
      <script src=/script.js defer></script>
      <script>window.onload=function(){rally.init(#{json})}</script>
      """

initModel = (model, room) ->
  model.set '_roomName', room
  model.set '_room', model.ref "rooms.#{room}"
  return if model.get '_room.letters'
  colors = ['red', 'yellow', 'blue', 'orange', 'green']
  letters = {}
  for row in [0..4]
    for col in [0..25]
      letters[row * 26 + col] =
        color: colors[row]
        value: String.fromCharCode(65 + col)
        position:
          left: col * 24 + 72
          top: row * 32 + 8
  model.set '_room.letters', letters

# Clear any existing data, then initialize
store.flush (err) ->
  incr = (path, byNum) ->
    store.retry (atomic) ->
      atomic.get path, (val = 0) ->
        atomic.set path, val + byNum
  
  rally.sockets.on 'connection', (socket) ->
    socket.on 'join', (room) ->
      playersPath = "rooms.#{room}.players"
      incr playersPath, 1
      socket.on 'disconnect', ->
        incr playersPath, -1
  app.listen 3000
  console.log "Go to http://localhost:3000/lobby"
  console.log "Go to http://localhost:3000/powder-room"
