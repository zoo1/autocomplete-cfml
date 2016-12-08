fs = require 'fs'
path = require 'path'
tagProvider = require './tagProvider'
functionProvider = require './functionProvider'

module.exports =
  activate: ->
    fs.readFile path.resolve(__dirname, '../dictionary', 'cf11.json'), (error, content) ->
      if error?
        atom.notifications.addError "Failed to load completions"
        tagProvider = null
      else
        completions = JSON.parse(content)
        tagProvider.tags = completions.tags
        functionProvider.functions = completions.functions

  getProvider: -> [tagProvider, functionProvider]
