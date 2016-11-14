# Run this to update the modify xml CF data to a js friendly format
# package.json file.

path = require 'path'
fs = require 'fs'
xml2js = require 'xml2js'
clone = require 'clone'

exitIfError = (error) ->
  if error?
    console.error(error.message)
    return process.exit(1)

parser = new xml2js.Parser({mergeAttrs: true})
fs.readFile path.join(__dirname, 'dictionary/cf11.xml') , (err, data) ->
  exitIfError err
  parser.parseString data, (err, result) ->
    exitIfError err
    newTags = {}
    for tag in result.dictionary.tags[0].tag
      tag.parameter = [] unless tag.parameter?
      tag.help = tag.help[0]
      if typeof tag.help is "object"
        tag.help = tag.help["_"]
      tag.name = tag.name[0]
      tag.single = tag.single?[0] ? false
      tag.endtagrequired = tag.endtagrequired?[0] ? false
      newParams = {}
      for param in tag.parameter
        param.required = param.required[0]
        param.help = param.help[0]
        param.name = param.name[0]
        param.type = param.type?[0] ? ""
        param.default = param.values?[0]?.default?[0] ? ""
        newValues = []
        for value in param.values?[0]?.value ? []
          newValues.push value.option[0]
        param.values = newValues
        newParams[param.name] = param
      tag.parameter = newParams

      for combination in tag.possiblecombinations?[0]?.combination ? [] when combination.attributename? and tag.parameter[combination.attributename[0]]?
        clonedTag = clone tag
        clonedTag.parameter[combination.attributename[0]].required = true
        if combination.required?[0]? and combination.required[0] != ""
          combination.required[0].split(",").forEach((attribute) ->
            clonedTag.parameter[attribute]?.required = true
            )
        newTags["#{tag.name} (#{combination.attributename[0]})"] = clonedTag

      newTags[tag.name] = tag
    result.dictionary.tags = newTags
    fs.writeFileSync(path.join(__dirname, 'dictionary/cf11.json'), "#{JSON.stringify(result.dictionary, null, 0)}\n".replace(/\\r\\n\s*/g, " ").replace(/"false"/g, "false").replace(/"true"/g, "true"))
