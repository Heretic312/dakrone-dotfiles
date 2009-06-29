" Author:  Eric Van Dewoestine
"
" Description: {{{
"   Common language functionality (validation, completion, etc.) abstracted
"   into re-usable functions.
"
" License:
"
" Copyright (C) 2005 - 2009  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Script Variables {{{
  let s:update_command = '-command <lang>_src_update -p "<project>" -f "<file>"'
  let s:validate_command = '-command <type>_validate -p "<project>" -f "<file>"'
" }}}

" CodeComplete(command, findstart, base) {{{
" Handles code completion.
function! eclim#lang#CodeComplete(command, findstart, base)
  if a:findstart
    " update the file before vim makes any changes.
    call eclim#util#ExecWithoutAutocmds('silent update')

    if !eclim#project#util#IsCurrentFileInProject(0) || !filereadable(expand('%'))
      return -1
    endif

    " locate the start of the word
    let line = getline('.')

    let start = col('.') - 1

    "exceptions that break the rule
    if line[start] =~ '\.'
      let start -= 1
    endif

    while start > 0 && line[start - 1] =~ '\w'
      let start -= 1
    endwhile

    return start
  else
    if !eclim#project#util#IsCurrentFileInProject(0) || !filereadable(expand('%'))
      return []
    endif

    let offset = eclim#util#GetOffset() + len(a:base)
    let project = eclim#project#util#GetCurrentProjectName()
    let filename = eclim#project#util#GetProjectRelativeFilePath(expand('%:p'))

    let command = a:command
    let command = substitute(command, '<project>', project, '')
    let command = substitute(command, '<file>', filename, '')
    let command = substitute(command, '<offset>', offset, '')
    let command = substitute(command, '<encoding>', eclim#util#GetEncoding(), '')

    let completions = []
    let results = split(eclim#ExecuteEclim(command), '\n')
    if len(results) == 1 && results[0] == '0'
      return
    endif

    let open_paren = getline('.') =~ '\%' . col('.') . 'c\s*('
    let close_paren = getline('.') =~ '\%' . col('.') . 'c\s*(\s*)'

    for result in results
      let word = substitute(result, '\(.\{-}\)|.*', '\1', '')
      let menu = substitute(result, '.\{-}|\(.\{-}\)|.*', '\1', '')
      let info = substitute(result, '.\{-}|.\{-}|\(.\{-}\)', '\1', '')
      let info = eclim#html#util#HtmlToText(info)

      " strip off close paren if necessary.
      if word =~ ')$' && close_paren
        let word = strpart(word, 0, strlen(word) - 1)
      endif

      " strip off open paren if necessary.
      if word =~ '($' && open_paren
        let word = strpart(word, 0, strlen(word) - 1)
      endif

      let dict = {
          \ 'word': word,
          \ 'menu': menu,
          \ 'info': info,
        \ }

      call add(completions, dict)
    endfor

    return completions
  endif
endfunction " }}}

" FindDefinition(command, singleResultAction, context) {{{
" Finds the defintion of the element under the cursor.
function eclim#lang#FindDefinition(command, singleResultAction, context)
  if !eclim#project#util#IsCurrentFileInProject(1)
    return
  endif

  " update the file.
  call eclim#util#ExecWithoutAutocmds('silent update')

  let project = eclim#project#util#GetCurrentProjectName()
  let file = eclim#project#util#GetProjectRelativeFilePath(expand("%:p"))
  let position = eclim#util#GetCurrentElementPosition()
  let offset = substitute(position, '\(.*\);\(.*\)', '\1', '')
  let length = substitute(position, '\(.*\);\(.*\)', '\2', '')

  let search_cmd = a:command
  let search_cmd = substitute(search_cmd, '<project>', project, '')
  let search_cmd = substitute(search_cmd, '<file>', file, '')
  let search_cmd = substitute(search_cmd, '<offset>', offset, '')
  let search_cmd = substitute(search_cmd, '<length>', length, '')
  let search_cmd = substitute(search_cmd, '<context>', a:context, '')
  let search_cmd = substitute(search_cmd, '<encoding>', eclim#util#GetEncoding(), '')

  let result =  eclim#ExecuteEclim(search_cmd)
  let results = split(result, '\n')
  if len(results) == 1 && results[0] == '0'
    return
  endif

  if !empty(results)
    call eclim#util#SetLocationList(eclim#util#ParseLocationEntries(results))

    " if only one result and it's for the current file, just jump to it.
    " note: on windows the expand result must be escaped
    if len(results) == 1 && results[0] =~ escape(expand('%:p'), '\') . '|'
      if results[0] !~ '|1 col 1|'
        lfirst
      endif

    " single result in another file.
    elseif len(results) == 1 && a:singleResultAction != "lopen"
      let entry = getloclist(0)[0]
      call eclim#util#GoToBufferWindowOrOpen
        \ (bufname(entry.bufnr), a:singleResultAction)
      call eclim#util#SetLocationList(eclim#util#ParseLocationEntries(results))
      call eclim#display#signs#Update()

      call cursor(entry.lnum, entry.col)
    else
      lopen
    endif
  else
    call eclim#util#EchoInfo("Element not found.")
  endif
endfunction " }}}

" Search(command, singleResultAction, argline) {{{
" Executes a search.
function! eclim#lang#Search(command, singleResultAction, argline)
  if !eclim#project#util#IsCurrentFileInProject(1)
    return
  endif

  let argline = a:argline
  if argline == ''
    call eclim#util#EchoError('You must supply a search pattern.')
    return
  endif

  " check if pattern supplied without -p.
  if argline !~ '^\s*-[a-z]'
    let argline = '-p ' . argline
  endif

  let project = eclim#project#util#GetCurrentProjectName()

  let search_cmd = a:command
  let search_cmd = substitute(search_cmd, '<project>', project, '')
  let search_cmd = substitute(search_cmd, '<args>', argline, '')
  " quote the search pattern
  let search_cmd =
    \ substitute(search_cmd, '\(.*-p\s\+\)\(.\{-}\)\(\s\|$\)\(.*\)', '\1"\2"\3\4', '')
  let result =  eclim#ExecuteEclim(search_cmd)
  let results = split(result, '\n')
  if len(results) == 1 && results[0] == '0'
    return
  endif

  if !empty(results)
    call eclim#util#SetLocationList(eclim#util#ParseLocationEntries(results))
    " if only one result and it's for the current file, just jump to it.
    " note: on windows the expand result must be escaped
    if len(results) == 1 && results[0] =~ escape(expand('%:p'), '\') . '|'
      if results[0] !~ '|1 col 1|'
        lfirst
      endif

    " single result in another file.
    elseif len(results) == 1 && a:singleResultAction != "lopen"
      let entry = getloclist(0)[0]
      call eclim#util#GoToBufferWindowOrOpen
        \ (bufname(entry.bufnr), a:singleResultAction)
      call eclim#util#SetLocationList(eclim#util#ParseLocationEntries(results))
      call eclim#display#signs#Update()

      call cursor(entry.lnum, entry.col)
    else
      lopen
    endif
  else
    let searchedFor = substitute(argline, '.*-p \(.\{-}\)\( .*\|$\)', '\1', '')
    call eclim#util#EchoInfo("Pattern '" . searchedFor . "' not found.")
  endif

endfunction " }}}

" UpdateSrcFile(validate) {{{
" Updates the src file on the server w/ the changes made to the current file.
function! eclim#lang#UpdateSrcFile(lang, validate)
  let project = eclim#project#util#GetCurrentProjectName()
  if project != ""
    let file = eclim#project#util#GetProjectRelativeFilePath(expand("%:p"))
    let command = s:update_command
    let command = substitute(command, '<lang>', a:lang, '')
    let command = substitute(command, '<project>', project, '')
    let command = substitute(command, '<file>', file, '')
    if a:validate && !eclim#util#WillWrittenBufferClose()
      let command = command . " -v"
    endif

    let result = eclim#ExecuteEclim(command)
    if result =~ '|'
      let errors = eclim#util#ParseLocationEntries(split(result, '\n'))
      call eclim#util#SetLocationList(errors)
    else
      call eclim#util#ClearLocationList()
    endif
  endif
endfunction " }}}

" Validate(type, on_save) {{{
" Validates the current file. Used by languages which are not validated via
" UpdateSrcFile (pretty much all the xml dialects and wst langs).
function! eclim#lang#Validate(type, on_save)
  if eclim#util#WillWrittenBufferClose()
    return
  endif

  if !eclim#project#util#IsCurrentFileInProject(!a:on_save)
    return
  endif

  let project = eclim#project#util#GetCurrentProjectName()
  let file = eclim#project#util#GetProjectRelativeFilePath(expand("%:p"))
  let command = s:validate_command
  let command = substitute(command, '<type>', a:type, '')
  let command = substitute(command, '<project>', project, '')
  let command = substitute(command, '<file>', file, '')

  let result = eclim#ExecuteEclim(command)
  if result =~ '|'
    let errors = eclim#util#ParseLocationEntries(split(result, '\n'))
    call eclim#util#SetLocationList(errors)
  else
    call eclim#util#ClearLocationList()
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
