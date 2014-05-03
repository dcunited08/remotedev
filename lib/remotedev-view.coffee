{View} = require 'atom'

module.exports =
class RemotedevView extends View
  @content: ->
    @div class: 'remotedev overlay from-top', =>
      @div "The Remotedev package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "remotedev:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "RemotedevView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
