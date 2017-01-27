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

addvalues = (baseObj, path, values) ->
  obj = baseObj
  paths = path.split('.')
  for path in paths
    if(obj[path.toLowerCase()]?)
      obj = obj[path.toLowerCase()]
    else
      return baseObj;
  for key, value of values when value
     obj[key] = value
  baseObj

parser = new xml2js.Parser({mergeAttrs: true})
fs.readFile path.join(__dirname, 'dictionary/cf11.xml') , (err, data) ->
  exitIfError err
  parser.parseString data, (err, result) ->
    exitIfError err

    # Tag completions
    newTags = {}
    for tag in result.dictionary.tags[0].tag
      newTag =
        parameter: tag.parameter ? []
        help: tag.help[0]
        name: tag.name[0]
        single: tag.single?[0] ? false
        endtagrequired: tag.endtagrequired?[0] ? false
      if typeof newTag.help is "object"
        newTag.help = newTag.help["_"]
      newParams = {}
      for param in newTag.parameter
        newParam =
          required: param.required[0]
          help: param.help[0]
          name: param.name[0]
          type: param.type?[0] ? ""
          default: param.values?[0]?.default?[0] ? ""
        newValues = []
        for value in param.values?[0]?.value ? []
          newValues.push value.option[0]
        newParam.values = newValues
        newParams[newParam.name] = newParam
      newTag.parameter = newParams

      for combination in tag.possiblecombinations?[0]?.combination ? [] when combination.attributename? and newTag.parameter[combination.attributename[0]]?
        clonedTag = clone newTag
        clonedTag.parameter[combination.attributename[0]].required = true
        if combination.required?[0]? and combination.required[0] != ""
          combination.required[0].split(",").forEach((attribute) ->
            clonedTag.parameter[attribute]?.required = true
            )
        newTags["#{newTag.name} (#{combination.attributename[0]})"] = clonedTag
      newTags[newTag.name] = newTag

    result.dictionary.tags = newTags

    # Function completions
    newFunctions = {}
    for funct in result.dictionary.functions[0].function
      continue if funct.name[0].includes('.')
      newFunct =
        parameter: funct.parameter ? []
        help: funct.help[0]
        name: funct.name[0]
        returns: funct.returns[0]
      newParams = {}
      for param in newFunct.parameter
        newParam =
          required: param.required[0]
          help: param.help?[0] ? ""
          name: param.name[0]
          type: param.type?[0] ? ""
        newValues = []
        for value in param.values?[0]?.value ? []
          newValues.push if typeof(value) is "string" then value else value.option[0]
        newParam.values = newValues
        newParams[newParam.name] = newParam
      newFunct.parameter = newParams
      newFunctions[newFunct.name] = newFunct

    result.dictionary.functions = newFunctions

    #Scope completions
    newScopes = {}
    for scope in result.dictionary.cfscopes[0].scopevar
      continue unless scope.scopevar?
      name = scope.name[0].toLowerCase()
      newScopes[name] = {}
      for innerScope in scope.scopevar
        newScope =
          _name: innerScope.name[0]
          _type: ""
          _help: innerScope.help?[0] ? ""
        for innerVar in innerScope.scopevar ? []
          newVar =
            _name: innerVar.name[0]
            _type: ""
            _help: innerVar.help?[0] ? ""
          newScope[newVar._name.toLowerCase()] = newVar
        newScopes[name][newScope._name.toLowerCase()] = newScope

    for scope in result.dictionary.scopes[0].scopes[0].scope
      values =
        _type: scope.type[0]
        _help: scope.help[0]
      newScopes = addvalues(newScopes,scope.value[0],values)

    result.dictionary.scopes = newScopes
    delete result.dictionary.cfscopes

    fs.writeFileSync(path.join(__dirname, 'dictionary/cf11.json'), "#{JSON.stringify(result.dictionary, null, 0)}\n".replace(/\\r\\n\s*/g, " ").replace(/"false"/g, "false").replace(/"true"/g, "true"))
