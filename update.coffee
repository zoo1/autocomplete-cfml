# Run this to update the modify xml CF data to a js friendly format
# package.json file.

path = require 'path'
fs = require 'fs'
xml2js = require 'xml2js'

exitIfError = (error) ->
  if error?
    console.error(error.message)
    return process.exit(1)

parser = new xml2js.Parser()
fs.readFile path.join(__dirname, 'dictionary/cf11.xml') , (err, data) ->
  exitIfError err
  parser.parseString data, (err, result) ->
    exitIfError err
    newTags = {}
    for tag in result.dictionary.tags[0].tag
      tag.parameter = [] unless tag.parameter?
      tag.help = tag.help[0]
      tag[k] = v for k,v of tag['$']
      delete tag['$']
      newParams = {}
      for param,index in tag.parameter
        tag.parameter[index][k] = v for k,v of param['$']
        delete tag.parameter[index]['$']
        newParams[param.name] = tag.parameter[index]
      tag.parameter = newParams
      newTags[tag.name] = tag
    result.dictionary.tags = newTags
    fs.writeFileSync(path.join(__dirname, 'dictionary/cf11.json'), "#{JSON.stringify(result.dictionary, null, 0)}\n".replace(/\\r\\n\s*/g," ").replace(/"false"/g,"false").replace(/"true"/g,"true"))
