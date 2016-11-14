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

  it "same results are returned rather prepended with cf or <", ->
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
