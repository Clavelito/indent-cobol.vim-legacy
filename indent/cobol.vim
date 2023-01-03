" Vim indent file
" Language:         Cobol
" Author:           Clavelito <maromomo@hotmail.com>
" Last Change:      Wed, 04 Jan 2023 04:30:40 +0900
" Version:          0.2-legacy
" License:          http://www.apache.org/licenses/LICENSE-2.0
"
" Description:      The current line is often indented at line breaks.
"                   Commands that are not registered will not be indented
"                   correctly. To add commands, follow the example below.
"                   let g:cobol_indent_commands = 'ALTER\|ENTER\|NOTE'


if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetCobolInd()
setlocal indentkeys+=0*,0/,0$,0-,0=~D\ ,0=~THEN,0=~ELSE,0=~WHEN,=~DIVISION
setlocal indentkeys+=0=~AND\ ,0=~OR\ ,=,<<>,<>>
setlocal indentkeys+=00,01,02,03,04,05,06,07,08,09,.,*<CR>,*<NL>
setlocal expandtab
let b:undo_indent = 'setlocal indentexpr< indentkeys< expandtab<'

if exists('*GetCobolInd')
  finish
endif
let s:cpo_save = &cpo
set cpo&vim

function GetCobolInd()
  let cline = getline(v:lnum)
  call s:SetBaseLevel()
  if &indentkeys =~# '<Space>'
    setlocal indentkeys-=<Space>
  elseif mode() == 'i' && cline =~ '^\s*\d$'
    setlocal indentkeys+=<Space>
    return indent(v:lnum)
  endif
  let lnum = prevnonblank(v:lnum - 1)
  let line = getline(lnum)
  let snum = lnum
  while lnum && (s:Comment(line) && indent(lnum) == s:c_ind || s:Direct(line) || s:Debug(line))
    if snum == lnum
      setlocal indentkeys+=<Space>
    endif
    let lnum = prevnonblank(lnum - 1)
    let line = getline(lnum)
  endwhile
  let pnum = prevnonblank(lnum - 1)
  let pline = getline(pnum)
  while pnum && (s:Comment(pline) && indent(pnum) == s:c_ind || s:Direct(pline) || s:Debug(pline))
    let pnum = prevnonblank(pnum - 1)
    let pline = getline(pnum)
  endwhile
  let line = s:CleanLine(line)
  let pline = s:CleanLine(pline)
  let ind = s:GetBaseInd(lnum)
  if (s:Comment(cline) || s:Dash(cline)) && !s:Muth2(line) && !s:Compute(line) || s:Debug(cline)
    return s:c_ind
  elseif cline =~? '^\s*>>\s*SOURCE'
    return cline =~? '\sFREE\%(\s\|$\)' || !lnum ? 7 : ind
  elseif line =~? '^\s*PROCEDURE\s\+DIVISION\%(\s\|[.]\|$\)'
        \ || line =~? '^\s*\S\+\s\+SECTION\s*[.]\s*$'
        \ || s:Para(line) && !s:Prop(line)
    let ind = s:b_ind
  elseif (s:Expr(line) || s:When(line)) && !s:Dot(line)
    let ind = s:ExprInd(line, cline, ind)
  elseif s:Expr(line. cline) && !s:Dot(line)
    let ind += s:TwoOrOneHalf()
  elseif (s:Prop2(line) || s:Prop3(line)) && !s:Dot(line)
        \ || s:Prop(line) && !s:Dot(line) && (s:Opt(line) || s:Prop2(cline) && !s:Not(cline))
        \ || (s:Num(line) || s:One(line)) && s:Dot(pline) && !s:Dot(line)
    let ind += shiftwidth()
  elseif s:Dot(line) && !s:Prop(line) && !s:End(line) && pnum && !s:Dot(pline) && ind > s:b_ind
        \ || !s:Muth(line) && s:Muth(pline) || s:Dash(line) && ind == s:c_ind
    let ind = s:TurnInd(line, pnum, ind)
  elseif s:Into(line) && !s:With(cline) && !s:Prop(cline)
        \ || s:Open(line) && s:Mode(cline)
        \ || (s:Prop(line) || s:Mode(line))
        \ && (!s:Dot(line) && !empty(cline) || s:Muth(line))
        \ && !s:Prop(cline) && !s:Expr(cline) && !s:Mode(cline) && !s:End(cline) && !s:Prop2(cline)
    let ind = s:GapInd(line, cline, ind)
  elseif !s:Dot(line) && !s:Prop(line) && !s:End(line)
        \ && (s:Prop(cline) || s:Expr(cline) || s:Mode(cline) || s:End(cline)|| s:With(cline))
        \ || s:Prop2(cline) && !s:Dot(line)
    let ind = s:TurnInd(cline, lnum, ind)
  endif
  if line =~? '\S\s\+END-\a\+\%(\s\|[.]\|$\)'
    let ind = s:EndInd(line, ind, lnum)
  elseif s:Dot(line) && !s:Dot(pline) && ind > s:b_ind
    let ind = s:b_ind
  elseif s:Open(line) && empty(cline)
        \ || !s:Expr(line) && !s:Prop(line) && !s:Prop2(line) && !s:Prop3(line) && empty(cline) && ind > s:b_ind
    setlocal indentkeys+=<Space>
  endif
  if s:Para(cline) && !s:Prop(cline) && (s:Dot(line) || !lnum)
        \ || s:One(cline) && s:Dot(line)
        \ || cline =~? '^\s*\S\+\s\+\%(SECTION\|DIVISION\)\%(\s\|[.]\|$\)'
        \ || cline =~? '^\s*END\s\+PROGRAM\s'
        \ || cline !~ '^\d\{6}' && !lnum
    let ind = s:p_ind
  elseif s:End(cline)
    let ind = s:EndInd(cline, ind)
  elseif s:Num(cline) && s:Dot(line)
    let ind = s:LevelInd(line, lnum, cline, ind)
  elseif s:When(cline) && !s:Expr(line) && !s:Prop3(line)
    let ind = s:TurnInd(cline, lnum, ind)
  elseif cline =~? '^\s*\%(ELSE\|THEN\)\%(\s\|$\)'
    let ind -= shiftwidth()
  elseif s:AndOr(cline) && s:Operator(line)
    let ind -= 1
  elseif s:Operator(cline) && s:AndOr(line)
    let ind += 1
  endif
  return ind
endfunction

function s:SetBaseLevel()
  let s:c_ind = 6
  let s:p_ind = 7
  let s:b_ind = 11
  let s:f_num = search('\c>>\s*SOURCE', 'nbW')
  if s:f_num
    let line = s:CleanLine(getline(s:f_num))
    if line !~? '>>\s*SOURCE'
      let s:f_num = 0
    elseif line =~? '\sFREE\%(\s\|$\)'
      let s:c_ind = 0
      let s:p_ind = 0
      let s:b_ind = shiftwidth()
    endif
  endif
endfunction

function s:GetBaseInd(lnum)
  let ind = indent(a:lnum)
  if s:f_num && a:lnum < s:f_num && s:f_num < v:lnum
    if !s:p_ind
      let ind -= ind >= 11 ? (11 - shiftwidth()) : 7
    else
      let ind += ind > shiftwidth() ? s:b_ind : s:p_ind
      let ind = ind > s:p_ind && ind < s:b_ind ? s:b_ind : ind
    endif
  endif
  return ind
endfunction

function s:ExprInd(line, cline, ind)
  let width = s:GapInd(a:line, a:cline, a:ind)
  if s:AndOr(a:cline) && s:If(a:line)
    return width - 4 > a:ind ? width - 4 : a:ind + s:TwoOrOneHalf()
  elseif s:Operator(a:cline) && s:If(a:line)
    let len = strdisplaywidth(substitute(a:cline, '^\s*\(.\{-}[<>=]\).*$', '\1', ''))
    if width - 4 > a:ind && width - a:ind - 3 > len
      return width - len - 2
    elseif width - 4 > a:ind
      return a:ind + 2
    endif
    return a:ind + s:TwoOrOneHalf()
  elseif a:cline =~? '^\s*ALSO\s' && a:line =~? '^\s*EVALUATE\s'
    return width - 5
  endif
  let ind = a:ind + shiftwidth()
  if !empty(a:cline) && !s:Prop(a:cline) && !s:Expr(a:cline)
    if width > ind || s:If(a:line) && a:line =~? '\s\%(AND\|OR\|[=<>]\{1,2}\)\s*$'
      return width
    endif
    return ind + float2nr(round(shiftwidth() * 0.5))
  endif
  return ind
endfunction

function s:GapInd(line, cline, ind)
  if a:line =~ '^\s*\S\+$'
    return a:ind + shiftwidth()
  elseif s:Open(a:line) && !s:Mode(a:cline) || a:line =~? '^\s*ELSE\s\+IF\%(\s\|$\)'
    if a:line =~ '^\s*\S\+\s\+\S\+$'
      return strdisplaywidth(a:line) + 1
    endif
    return strdisplaywidth(matchstr(a:line, '^\s*\S\+\s\+\S\+\s\+'))
  endif
  return strdisplaywidth(matchstr(a:line, '^\s*\S\+\s\+'))
endfunction

function s:TurnInd(line, lnum, ind)
  let cline = a:line
  let lnum = a:lnum
  let ind = indent(lnum)
  while lnum && (a:ind > s:p_ind && ind >= a:ind || ind < s:p_ind)
    let cline =  getline(lnum)
    let lnum = prevnonblank(lnum - 1)
    let ind = indent(lnum)
    if !s:AndOr(getline(lnum))
      let ind = indent(lnum)
    endif
  endwhile
  let line = getline(lnum)
  if empty(a:line) && (s:Open(line) || s:Into(line))
    setlocal indentkeys+=<Space>
  endif
  if !lnum
        \ || s:With(a:line) && !s:Into(line)
        \ || !s:Dot(a:line) && (s:One(line) || s:Num(line))
        \ || empty(a:line) && (s:Into(line) || s:Muth(line))
    return a:ind
  elseif (s:With(a:line) || s:Prop2(a:line)) && s:Into(line)
        \ || (s:When(a:line) || s:Prop2(a:line)) && (s:When(line) || s:Prop2(line))
        \ || s:One(line)
        \ || s:Num(line)
  elseif s:Mode(a:line) && s:Open(line)
    return s:GapInd(line, a:line, ind)
  elseif s:Expr(line)
        \ || s:Prop(a:line) && s:When(line)
        \ || s:Expr(line. cline)
        \ || s:Prop2(a:line) && s:Prop(line)
    return ind + shiftwidth()
  elseif !s:Prop(line)
    return s:TurnInd(a:line, lnum, ind)
  endif
  return ind
endfunction

function s:LevelInd(line, lnum, cline, ind)
  let line = a:line
  let lnum = a:lnum
  while lnum && !s:Num(line)
    let lnum = prevnonblank(lnum - 1)
    let line = getline(lnum)
  endwhile
  if !lnum
    return a:ind
  endif
  let clev = str2nr(matchstr(a:cline, '\d\=\d\ze\%(\s\|$\)'))
  if clev == str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    return indent(lnum)
  elseif clev > str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    return indent(lnum) + shiftwidth()
  endif
  while lnum && clev != str2nr(matchstr(line, '\d\=\d\ze\%(\s\|$\)'))
    while lnum
      let lnum = prevnonblank(lnum - 1)
      let line = getline(lnum)
      if s:Num(line)
        break
      endif
    endwhile
    if s:One(line)
      return a:ind
    endif
  endwhile
  return lnum ? indent(lnum) : a:ind
endfunction

function s:EndInd(line, ind, ...)
  let pos = getpos('.')
  if !a:0
    if a:line =~ '\s'
      call cursor(0, 1)
    else
      call search('\s', 'bW')
    endif
    let tail = matchstr(a:line, '\cEND-\a\+')
    let expr = tail =~? '^END-IF$' ? 0 : a:ind. '<= indent(".")'
    let head = '\c\s'. tail[4 : ]. '\%(\s\|$\)'
    let tail = '\c\s'. tail. '\%(\s\|[.]\|$\)'
    let lnum = searchpair(head, '', tail, 'bW', 's:SkipLine(expr)')
    call setpos('.', pos)
    return lnum > 0 ? indent(lnum) : a:ind
  endif
  let ind = a:ind
  let wpos = matchend(a:line, '\c\S\s\+END-\a\+')
  while wpos > -1
    call cursor(a:1, wpos)
    let ind = s:EndInd(expand('<cword>'), ind)
    let wpos = matchend(a:line, '\cEND-\a\+', wpos)
  endwhile
  call setpos('.', pos)
  return ind
endfunction

function s:TwoOrOneHalf()
  return shiftwidth() < 3 ? shiftwidth() * 2 : float2nr(round(shiftwidth() * 1.5))
endfunction

function s:SkipLine(expr)
  let line = substitute(getline('.')[ : col('.')], s:quote, '', 'g')
  return line =~ '^\s*[*/$-]\|"\|\%o47\|[*]>' || eval(a:expr)
endfunction

function s:CleanLine(line)
  let line = substitute(a:line, s:quote, '\=repeat("x", strlen(submatch(0)))', 'g')
  return line[ : match(line, '.[*]>')]
endfunction

function s:Prop(line)
  if exists('g:cobol_indent_commands') && !empty('g:cobol_indent_commands')
    return a:line =~? s:cmds. '\|^\s*\%('. g:cobol_indent_commands. '\)\%(\s\|$\)'
  endif
  return a:line =~? s:cmds
endfunction

function s:Prop2(line)
  return a:line =~? s:prop2
endfunction

function s:Prop3(line)
  return a:line =~? s:prop3
endfunction

function s:Expr(line)
  return a:line =~? s:expr
endfunction

function s:Opt(line)
  return a:line =~? s:opts
endfunction

function s:AndOr(line)
  return a:line =~? '^\s*\%(AND\|OR\)\s'
endfunction

function s:Comment(line)
  return a:line =~ '^\s*[*/$]'
endfunction

function s:Compute(line)
  return a:line =~? '^\s*COMPUTE\s' && !s:Muth(a:line) && !s:Dot(a:line) && a:line !~? '\sEND-COMPUTE\>'
endfunction

function s:Dash(line)
  return a:line =~ '^\s*-' && s:c_ind > 0
endfunction

function s:Debug(line)
  return a:line =~? '^\s*D\s' && s:c_ind > 0
endfunction

function s:Direct(line)
  return a:line =~ '^\s*>>'
endfunction

function s:Dot(line)
  return a:line =~ '[.]\s*$'
endfunction

function s:End(line)
  return a:line =~? '^\s*END-\a\+\%(\s\|[.]\|$\)'
endfunction

function s:If(line)
  return a:line =~? '^\s*\%(IF\|ELSE\s\+IF\)\s'
endfunction

function s:Into(line)
  return a:line =~? '^\s*\%(INTO\|USING\)\%(\s\|$\)'
endfunction

function s:Mode(line)
  return a:line =~? '^\s*\%(INPUT\|OUTPUT\|I-O\|EXTEND\)\%(\s\|$\)'
endfunction

function s:Muth(line)
  return a:line =~ '\%(^\s*\)\@<!\%([-+*/=]\|[*][*]\)\s*$'
endfunction

function s:Muth2(line)
  return a:line =~ '^[ ]\{' .s:b_ind .',}\%([-+*/=]\|[*][*]\)' && a:line !~? '\sEND-COMPUTE\>' && !s:Dot(a:line)
endfunction

function s:Not(line)
  return a:line =~? '^\s*NOT\s'
endfunction

function s:Num(line)
  return a:line =~ '^\s*\%([1-9]\|\d\d\)\%(\s\|$\)'
endfunction

function s:One(line)
  return a:line =~? '^\s*\%(0\=1\|66\|77\|78\|SD\|FD\|RD\|COPY\)\%(\s\|$\)'
endfunction

function s:Open(line)
  return a:line =~? '^\s*OPEN\s'
endfunction

function s:Operator(line)
  return a:line =~? '^\s*\%(IS\s\+\)\=\%(NOT\s*\)\=[=<>]'
endfunction

function s:Para(line)
  return a:line =~ '^\s*[^.[:blank:]]\+\s*[.]\s*$'
endfunction

function s:When(line)
  return a:line =~? '^\s*WHEN\%(\s\|$\)'
endfunction

function s:With(line)
  return a:line =~? '^\s*\%(WITH\|TALLYING\)\s'
endfunction

let s:quote = "'[^']*'". '\|"\%(\\.\|[^"]\)*"'

let s:opts = '\%(\%(\sNOT\)\@4<!\&\%(^\s*\)\@<!\)\s\+\%(ON\s\+SIZE\s\+ERROR'
      \. '\|ON\s\+OVERFLOW\|ON\s\+EXCEPTION\|INVALID\s\+KEY'
      \. '\|\%(AT\s\+\)\=\%(END\|EOP\|END-OF-PAGE\)\)\%(\s\|$\)'

let s:prop2 = '^\s*\%(NOT\s\+\)\=\%(AT\s\+\)\=\%(END\|EOP\|END-OF-PAGE\)\%(\s\|$\)'
      \. '\|^\s*\%(NOT\s\+\)\=\%(INVALID\s\+KEY\|ON\s\+SIZE\s\+ERROR\)\%(\s\|$\)'
      \. '\|^\s*\%(NOT\s\+\)\=\%(ON\s\+OVERFLOW\|ON\s\+EXCEPTION\)\%(\s\|$\)'

let s:prop3 = '^\s*\%(READ\|RETURN'
      \. '\|SEARCH\|SELECT\|STRING\|UNSTRING\)\%(\s\|$\)'

let s:expr = '^\s*\%(IF\|ELSE\|EVALUATE'
      \. '\|PERFORM\s\+\%(UNTIL\|VARYING\|WITH\s\+TEST\|\S\+\s\+TIMES\)'
      \. '\|THEN\)\%(\s\|$\)'

let s:cmds = '^\s*\%(ACCEPT\|ADD\|CALL\|CANCEL\|CLOSE\|COMPUTE\|CONTINUE'
      \. '\|COPY\|DELETE\|DISPLAY\|DIVIDE\|EVALUATE\|GO\s\+TO\|IF\|INITIALIZE'
      \. '\|INSPECT\|MERGE\|MOVE\|MULTIPLY\|OPEN\|READ\|REDEFINES'
      \. '\|RELEASE\|RETURN\|REWRITE\|SEARCH\|SELECT\|SET\|SORT\|START\|STOP'
      \. '\|STRING\|SUBTRACT\|UNSTRING\|USE\|WHEN\|WRITE\)\%(\s\|$\)'
      \. '\|^\s*PERFORM\%(\s\+\|$\)\%(UNTIL\|VARYING\|WITH\|\S\+\s\+TIMES\)\@!'
      \. '\|^\s*\%(GOBACK\|EXIT\)\%(\s\|[.]\)'

let &cpo = s:cpo_save
unlet s:cpo_save
" vim: sw=2 et
