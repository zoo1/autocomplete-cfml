describe "CFML tag autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-cfml')
    waitsForPromise -> atom.packages.activatePackage('language-cfml')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-cfml').mainModule.getProvider()

    waitsFor -> Object.keys(provider.tags).length > 0
    waitsForPromise -> atom.workspace.open('test.cfm')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "returns the same results regardless if prepended with cf or <", ->
    editor.setText('cfelseif')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].displayText).toBe 'cfelseif'

    editor.setText('<cfelseif')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].displayText).toBe 'cfelseif'

    editor.setText('elseif')
    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].displayText).toBe 'cfelseif'

  it "returns no completions when at the start of a end tag", ->
    editor.setText('</')
    expect(getCompletions().length).toBe 0

    editor.setText('</cf')
    expect(getCompletions().length).toBe 0

    editor.setText('</cflo')
    expect(getCompletions().length).toBe 0

  it "returns no completions when not at the start of a tag or cf", ->
    editor.setText('')
    expect(getCompletions().length).toBe 0

    editor.setText(',')
    expect(getCompletions().length).toBe 0

    editor.setText('/')
    expect(getCompletions().length).toBe 0

    editor.setText(' ')
    expect(getCompletions().length).toBe 0

    editor.setText('<cfdump />')
    expect(getCompletions().length).toBe 0

    editor.setText('<cfdump />')
    editor.setCursorBufferPosition([0, 0])
    expect(getCompletions().length).toBe 0

  it "returns no completions when in a limited scope without a prefix", ->
    editor.setText('<cfquery >  </cfquery>')
    editor.setCursorBufferPosition([0, 11])
    expect(getCompletions().length).toBe 0

    editor.setText('<script>  </script>')
    editor.setCursorBufferPosition([0, 9])
    expect(getCompletions().length).toBe 0

    editor.setText('<style>  </style>')
    editor.setCursorBufferPosition([0, 8])
    expect(getCompletions().length).toBe 0

    editor.setText('<cfquery > <c </cfquery>')
    editor.setCursorBufferPosition([0, 13])
    expect(getCompletions().length).toBe 0

  it "autocompletes limit scope tag names with a prefix", ->
    editor.setText('<cfquery > cfqu </cfquery>')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].displayText).toBe 'cfqueryparam'
    expect(completions[0].type).toBe 'tag'

    editor.setText('<script> cfi </script>')
    editor.setCursorBufferPosition([0, 12])

    completions = getCompletions()
    expect(completions.length).toBe 1
    expect(completions[0].displayText).toBe 'cfif'
    expect(completions[0].type).toBe 'tag'

  it "autcompletes tag names without a prefix", ->
    editor.setText('<')
    expect(getCompletions().length).toBe 218

    editor.setText('<c')
    expect(getCompletions().length).toBe 218

    editor.setText('<cf')
    expect(getCompletions().length).toBe 218

    editor.setText('cf')
    completions = getCompletions()
    expect(completions.length).toBe 218

    for completion in completions
      expect(completion.snippet.length).toBeGreaterThan 0
      expect(completion.displayText.length).toBeGreaterThan 0
      expect(completion.description.length).toBeGreaterThan 0
      expect(completion.type).toBe 'tag'

  it "autocompletes tag names with a prefix", ->
    editor.setText('cfsc')

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].displayText).toBe 'cfschedule'
    expect(completions[0].type).toBe 'tag'
    expect(completions[1].displayText).toBe 'cfscript'

  it "autocompletes attribute names without a prefix", ->
    editor.setText('<cflock  >')
    editor.setCursorBufferPosition([0, 8])

    completions = getCompletions()
    expect(completions.length).toBe 5

    for completion in completions
      expect(completion.rightLabel).toBe '<cflock>'
      expect(completion.snippet.length).toBeGreaterThan 0
      expect(completion.displayText.length).toBeGreaterThan 0
      expect(completion.description.length).toBeGreaterThan 0
      expect(completion.type).toBe 'attribute'

    editor.setText('<cfdump ')

    completions = getCompletions()
    expect(completions.length).toBe 12

    for completion in completions
      expect(completion.rightLabel).toBe '<cfdump>'
      expect(completion.snippet.length).toBeGreaterThan 0
      expect(completion.displayText.length).toBeGreaterThan 0
      expect(completion.description.length).toBeGreaterThan 0
      expect(completion.type).toBe 'attribute'

  it "autocompletes attribute names with a prefix", ->
    editor.setText('<cfsetting r')

    completions = getCompletions()
    expect(completions.length).toBe 1

    expect(completions[0].rightLabel).toBe '<cfsetting>'
    expect(completions[0].displayText).toBe 'requesttimeout'
    expect(completions[0].type).toBe 'attribute'

    editor.setText('<cfsetting R')

    completions = getCompletions()
    expect(completions.length).toBe 1

    expect(completions[0].rightLabel).toBe '<cfsetting>'
    expect(completions[0].displayText).toBe 'requesttimeout'
    expect(completions[0].type).toBe 'attribute'

    editor.setText('<cfsetting R />')
    editor.setCursorBufferPosition([0, 13])

    completions = getCompletions()
    expect(completions.length).toBe 1

    expect(completions[0].rightLabel).toBe '<cfsetting>'
    expect(completions[0].displayText).toBe 'requesttimeout'
    expect(completions[0].type).toBe 'attribute'

    editor.setText('<cfcache d')

    completions = getCompletions()
    expect(completions[0].displayText).toBe 'directory'
    expect(completions[1].displayText).toBe 'dependson'

  it "autocompletes attribute values without a prefix", ->
    editor.setText('<cfhttp url="" method="" />')
    editor.setCursorBufferPosition([0, 23])

    completions = getCompletions()
    expect(completions.length).toBe 7

    expect(completions[0].text).toBe 'get'
    expect(completions[0].type).toBe 'value'
    expect(completions[1].text).toBe 'post'
    expect(completions[2].text).toBe 'put'

    editor.setText('<cfhttp url="" method=""')
    editor.setCursorBufferPosition([0, 23])

    completions = getCompletions()
    expect(completions.length).toBe 7

    expect(completions[0].text).toBe 'get'
    expect(completions[1].text).toBe 'post'
    expect(completions[2].text).toBe 'put'

    editor.setText('<cfhttp url="" method="')

    completions = getCompletions()
    expect(completions.length).toBe 7

    expect(completions[0].text).toBe 'get'
    expect(completions[1].text).toBe 'post'
    expect(completions[2].text).toBe 'put'

    editor.setText('<cfhttp url="" method=\'\'')
    editor.setCursorBufferPosition([0, 23])

    completions = getCompletions()
    expect(completions.length).toBe 7

    expect(completions[0].text).toBe 'get'
    expect(completions[1].text).toBe 'post'
    expect(completions[2].text).toBe 'put'

    editor.setText('<cfhttp url="" method=\'')

    completions = getCompletions()
    expect(completions.length).toBe 7

    expect(completions[0].text).toBe 'get'
    expect(completions[1].text).toBe 'post'
    expect(completions[2].text).toBe 'put'

  it "autocompletes attribute values with a prefix", ->
    editor.setText('<cfparam name="" type="a" />')
    editor.setCursorBufferPosition([0, 24])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'any'
    expect(completions[0].type).toBe 'value'
    expect(completions[1].text).toBe 'array'

    editor.setText('<cfparam name="" type="a"')
    editor.setCursorBufferPosition([0, 24])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'any'
    expect(completions[0].type).toBe 'value'
    expect(completions[1].text).toBe 'array'

    editor.setText('<cfparam name="" type="A"')
    editor.setCursorBufferPosition([0, 24])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'any'
    expect(completions[0].type).toBe 'value'
    expect(completions[1].text).toBe 'array'

    editor.setText('<cfparam name="" type=\'A\'')
    editor.setCursorBufferPosition([0, 24])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'any'
    expect(completions[0].type).toBe 'value'
    expect(completions[1].text).toBe 'array'
