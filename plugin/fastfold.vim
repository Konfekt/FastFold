" LICENCE PUBLIQUE RIEN À BRANLER
" Version 1, Mars 2009
"
" Copyright (C) 2009 Sam Hocevar
" 14 rue de Plaisance, 75014 Paris, France
"
" La copie et la distribution de copies exactes de cette licence sont
" autorisées, et toute modification est permise à condition de changer
" le nom de la licence.
"
" CONDITIONS DE COPIE, DISTRIBUTON ET MODIFICATION
" DE LA LICENCE PUBLIQUE RIEN À BRANLER
"
" 0. Faites ce que vous voulez, j’en ai RIEN À BRANLER.

if exists("g:loaded_fastfold") || &cp
  finish
endif
let g:loaded_fastfold = 1

let s:keepcpo         = &cpo
set cpo&vim
" ------------------------------------------------------------------------------

if !exists('g:fastfold_map')         | let g:fastfold_map        = 1 | endif
if !exists('g:fastfold_savehook')    | let g:fastfold_savehook   = 1 | endif
if !exists('g:fastfold_togglehook')  | let g:fastfold_togglehook = 0 | endif
if !exists('g:fastfold_mapsuffixes')
  let g:fastfold_mapsuffixes = ['x','X','a','A','o','O','c','C','r','R','m','M','i','n','N']
endif
if !exists('g:fastfold_force')       | let g:fastfold_force     = 0  | endif
if !exists("g:fastfold_skipfiles")   | let g:fastfold_skipfiles = [] | endif

function! s:Enter()
  " skip if another session still loading
  if exists('g:SessionLoad') | return | endif

  if &l:foldmethod ==# 'manual' | return | endif

  if s:Skip()
    if exists('w:lastfdm') | unlet w:lastfdm | endif
    return
  endif

  let w:lastfdm = &l:foldmethod
  setlocal foldmethod=manual
endfunction

function! s:Leave()
  if exists('w:lastfdm') && &l:foldmethod == 'manual'
    let &l:foldmethod= w:lastfdm
  endif
endfunction

" Like windo but restore the current buffer.
" See http://vim.wikia.com/wiki/Run_a_command_in_multiple_buffers#Restoring_position
function! s:WinDo( command )
  " Work around Vim bug.
  " See https://groups.google.com/forum/#!topic/vim_dev/LLTw8JV6wKg
  let curaltwin = winnr('#') ? winnr('#') : 1
  let currwin=winnr()
  execute 'windo ' . a:command
  execute curaltwin . 'wincmd w'
  execute currwin . 'wincmd w'
endfunction

function! s:UpdateTab()
  " WinEnter then TabEnter then BufEnter then BufWinEnter
  call s:WinDo("if exists('w:lastfdm') | call s:Enter() | endif")
  call s:WinDo("call s:Leave()")
endfunction

function! s:UpdateBuf(feedback)
  call s:LeaveAllWinOfBuf()
  call s:EnterAllWinOfBuf()

  if !a:feedback | return | endif

  if !exists('w:lastfdm')
    echomsg "'".&l:foldmethod."'"." folds already continuously updated"
  else
    echomsg "updated '".w:lastfdm."' folds"
  endif
endfunction

function! s:EnterAllWinOfBuf()
  let s:curbuf = bufnr('%')
  call s:WinDo("if bufnr('%') == s:curbuf | call s:Enter() | endif")
endfunction

function! s:LeaveAllWinOfBuf()
  let s:curbuf = bufnr('%')
  call s:WinDo("if bufnr('%') == s:curbuf | call s:Leave() | endif")
endfunction

function! s:isValidBuffer()
  if exists('b:lastfdm')                           | return 1 | endif
  if &modifiable == 0                              | return 0 | endif

  return 1
endfunction

function! s:Skip()
  if !s:isReasonable() | return 1 | endif
  if s:inSkipList()    | return 1 | endif

  return 0
endfunction

function! s:isReasonable()
  if g:fastfold_force | return 1 | endif
  if &l:foldmethod ==# 'syntax' || &l:foldmethod ==# 'expr'
    return 1
  endif
  return 0
endfunction

function! s:inSkipList()
  let file_name = expand('%:p')
  for ifiles in g:fastfold_skipfiles
    if file_name =~? ifiles
      return 1
    endif
  endfor
  return 0
endfunction

command! -bar -bang FastFoldUpdate call s:UpdateBuf(<bang>0)

nnoremap <silent> <Plug>(FastFoldUpdate) :FastFoldUpdate!<CR>

if g:fastfold_map == 1 && !hasmapto('<Plug>(FastFoldUpdate)', 'n') && mapcheck('zuz', 'n') ==# ''
  nmap zuz <Plug>(FastFoldUpdate)
endif

if g:fastfold_togglehook == 1
  for mapsuffix in g:fastfold_mapsuffixes
    execute 'nnoremap <silent> z'.mapsuffix.' :FastFoldUpdate<CR>z'.mapsuffix
  endfor
endif

augroup FastFold
  autocmd!
  " Default to last foldmethod of current buffer. This BufWinEnter autocmd
  " must come before that calling s:Enter().
  autocmd BufWinEnter ?* if exists('b:lastfdm') | let &l:foldmethod = b:lastfdm | endif
  autocmd WinLeave    *  if exists('w:lastfdm') | let b:lastfdm     = w:lastfdm | endif

  " isValidBuffer() = nonmodifiable and temp buffers do not need fold updates.
  autocmd BufWinEnter ?* if s:isValidBuffer() | call s:Enter() | endif
  " So that a :makeview autocmd loaded AFTER FastFold saves correct foldmethod.
  autocmd BufWinLeave ?* if s:isValidBuffer() | call s:Leave() | endif
  " So that FastFold functions correctly after :loadview.
  autocmd SessionLoadPost * call s:Enter()

  autocmd TabEnter * call s:UpdateTab()

  " Update folds on saving. Split into Pre and Post event so that a :makeeview
  " BufWrite(Pre) autocmd loaded AFTER FastFold can tap into it.
  if g:fastfold_savehook == 1
    autocmd BufWritePre     ?* call s:LeaveAllWinOfBuf()
    autocmd BufWritePost    ?* call s:EnterAllWinOfBuf()
  endif
augroup end

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
