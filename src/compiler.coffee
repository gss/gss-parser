if window?
  parser      = require './parser'
else
  parser      = require '../lib/parser'
vfl           = require 'vfl-compiler'
vgl           = require 'vgl-compiler'
ErrorReporter = require 'error-reporter'

parse = (source) ->
  results = null

  try
    results = parser.parse source
  catch error
    errorReporter = new ErrorReporter source
    {message, line:lineNumber, column:columnNumber} = error
    errorReporter.reportError message, lineNumber, columnNumber

  return results

vflHook = (name,terms,commands=[]) ->
  newCommands = []
  o = vfl.parse("@#{name} #{terms}")
  for s in o.statements
    newCommands = newCommands.concat(parse(s).commands)
  if commands.length > 0 and o.selectors.length > 0
    ruleSet = ""
    for selector, i in o.selectors
      prefix = ''
      # to prepend ::scope inside parans
      if selector[0] is "("
        prefix = "("
        selector = selector.substr(1,selector.length-1)
      # prepend selector with ::scope unless
      if selector.indexOf("&") isnt 0
        if selector.indexOf("::") isnt 0
          if selector.indexOf('"') isnt 0
            prefix += "::scope "
          
      ruleSet += prefix + selector 
      if i isnt o.selectors.length - 1
        ruleSet += ", "
      
    ruleSet += " {}"
    
    #console.log '========================'
    #console.log ruleSet
    #console.log '//////////////////////'
    
    nestedCommand = parse(ruleSet).commands[0] 
    #nestedCommand = parse(o.selectors.join(", ") + " {}").commands[0]
    nestedCommand[2] = commands
    newCommands.push nestedCommand
  return {commands:newCommands}

vglHook = (name,terms,commands=[]) ->
  newCommands = []
  statements = vgl.parse("@#{name} #{terms}")
  for s in statements
    newCommands = newCommands.concat(parse(s).commands)
  return {commands:commands.concat(newCommands)}

parser.hooks =

  directives:

    'h'             : vflHook
    'v'             : vflHook
    'horizontal'    : vflHook
    'vertical'      : vflHook

    'grid-template' : vglHook
    'grid-rows'     : vglHook
    'grid-cols'     : vglHook


# A wrapper module for the parser generated by PEG.
#
# @note Provides a way to handle errors consistently regardless of if the error
# originated from PEG or was thrown manually as part the parsing expression for
# a rule.
#
module.exports =

  # Parse CCSS to produce an AST.
  #
  # @param source [String] A CCSS expression.
  # @return [Array] The AST which represents `source`.
  #
  parse: parse