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

  it "autcompletes tag names without a prefix", ->
    editor.setText('<')
    editor.setCursorBufferPosition([0, 1])

    completions = getCompletions()
    expect(completions.length).toBe 218

    for completion in completions
      expect(completion.snippet.length).toBeGreaterThan 0
      expect(completion.displayText.length).toBeGreaterThan 0
      expect(completion.description.length).toBeGreaterThan 0
      expect(completion.type).toBe 'tag'

  it "autocompletes tag names with a prefix", ->
    editor.setText('cfsc')
    editor.setCursorBufferPosition([0, 4])

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
    editor.setCursorBufferPosition([0, 7])

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
    editor.setCursorBufferPosition([0, 13])

    completions = getCompletions()
    expect(completions.length).toBe 1

    expect(completions[0].rightLabel).toBe '<cfsetting>'
    expect(completions[0].displayText).toBe 'requesttimeout'
    expect(completions[0].type).toBe 'attribute'

    editor.setText('<cfsetting R')
    editor.setCursorBufferPosition([0, 13])

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
    editor.setCursorBufferPosition([0, 10])

    completions = getCompletions()
    expect(completions[0].displayText).toBe 'directory'
    expect(completions[1].displayText).toBe 'dependson'
