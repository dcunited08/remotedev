RemotedevView = require './remotedev-view'

module.exports =
  remotedevView: null

  activate: (state) ->
    @remotedevView = new RemotedevView(state.remotedevViewState)

  deactivate: ->
    @remotedevView.destroy()

  serialize: ->
    remotedevViewState: @remotedevView.serialize()
