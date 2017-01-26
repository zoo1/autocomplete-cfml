fs = require 'fs'
path = require 'path'
providers = []
providers[0] = require './provider/function'
providers[1] = require './provider/scope'
providers[2] = require './provider/tag'

module.exports =
  activate: ->
    fs.readFile path.resolve(__dirname, '../dictionary', 'cf11.json'), (error, content) ->
      if error?
        atom.notifications.addError "Failed to load completions"
        tagProvider = null
      else
        completions = JSON.parse(content)
        providers[0].functions = completions.functions
        providers[1].scopes = completions.scopes
        providers[2].tags = completions.tags

  getProvider: -> providers
