fs = require 'fs'
path = require 'path'
tagProvider = require './tagProvider'

module.exports =
  activate: ->
    fs.readFile path.resolve(__dirname, '../dictionary', 'cf11.json'), (error, content) =>
      if error?
        atom.notifications.addError "Failed to load completions"
        tagProvider = null
      else
        completions = JSON.parse(content)
        tagProvider.tags = completions.tags

  getProvider: -> tagProvider
