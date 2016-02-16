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

if !exists('g:fastfold_savehook')    | let g:fastfold_savehook   = 1 | endif
if !exists('g:fastfold_fold_command_suffixes')
  let g:fastfold_fold_command_suffixes = ['x','X','a','A','o','O','c','C']
endif
if !exists('g:fastfold_fold_movement_commands')
  let g:fastfold_fold_movement_commands = [']z', '[z', 'zj', 'zk']
endif
if !exists('g:fastfold_force')       | let g:fastfold_force     = 0  | endif
if !exists("g:fastfold_skipfiles")   | let g:fastfold_skipfiles = [] | endif

function! s:EnterWin()
  if s:Skip()
    if exists('w:lastfdm') | unlet w:lastfdm | endif
    return
  endif

  let w:lastfdm = &l:foldmethod
  setlocal foldmethod=manual
endfunction

function! s:LeaveWin()
  if exists('w:lastfdm') && &l:foldmethod ==# 'manual'
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
  " avoid errors in CmdWin
  if exists('*getcmdwintype') && getcmdwintype() != ''
    return
  endif
  silent! execute 'keepjumps noautocmd windo ' . a:command
  silent! execute curaltwin . 'wincmd w'
  silent! execute currwin . 'wincmd w'
endfunction

" WinEnter then TabEnter then BufEnter then BufWinEnter
function! s:UpdateWin(check)
  " skip if another session still loading
  if a:check && exists('g:SessionLoad') | return | endif

  let s:curwin = winnr()
  call s:WinDo("if winnr() == s:curwin | call s:LeaveWin() | endif")
  call s:WinDo("if winnr() == s:curwin | call s:EnterWin() | endif")
endfunction

function! s:UpdateBuf(feedback)
  let s:curbuf = bufnr('%')
  call s:WinDo("if bufnr('%') == s:curbuf | call s:LeaveWin() | endif")
  call s:WinDo("if bufnr('%') == s:curbuf | call s:EnterWin() | endif")

  if !a:feedback | return | endif

  if !exists('w:lastfdm')
    echomsg "'" . &l:foldmethod . "' folds already continuously updated"
  else
    echomsg "updated '" . w:lastfdm . "' folds"
  endif
endfunction

function! s:UpdateTab()
  " skip if another session still loading
  if exists('g:SessionLoad') | return | endif

  call s:WinDo("call s:LeaveWin()")
  call s:WinDo("call s:EnterWin()")
endfunction

function! s:Skip()
  if !s:isReasonable() | return 1 | endif
  if !&l:modifiable    | return 1 | endif
  if s:inSkipList()    | return 1 | endif

  return 0
endfunction

function! s:isReasonable()
  if &l:foldmethod ==# 'manual' | return 0 | endif

  if g:fastfold_force | return 1 | endif
  if &l:foldmethod ==# 'syntax' || &l:foldmethod ==# 'expr'
    return 1
  endif

  return 0
endfunction

function! s:inSkipList()
  let file_name = expand('%:p')
  for ifiles in g:fastfold_skipfiles
    if file_name =~# ifiles
      return 1
    endif
  endfor
  return 0
endfunction

command! -bar -bang FastFoldUpdate call s:UpdateBuf(<bang>0)

nnoremap <silent> <Plug>(FastFoldUpdate) :<c-u>FastFoldUpdate!<CR>

if !hasmapto('<Plug>(FastFoldUpdate)', 'n') && mapcheck('zuz', 'n') ==# ''
  nmap zuz <Plug>(FastFoldUpdate)
endif

for suffix in g:fastfold_fold_command_suffixes
  execute 'nnoremap <silent> z'.suffix.' :<c-u>call <SID>UpdateWin(0)<CR>z'.suffix
endfor

for cmd in g:fastfold_fold_movement_commands
  exe "nnoremap <silent><expr> " . cmd. " ':<c-u>call <SID>UpdateWin(0)<CR>'.v:count." . "'".cmd."'"
  exe "xnoremap <silent><expr> " . cmd. " ':<c-u>call <SID>UpdateWin(0)<CR>gv'.v:count." . "'".cmd."'"
  exe "onoremap <silent><expr> " . cmd. " '<esc>:<c-u>call <SID>UpdateWin(0)<CR>'.v:operator.v:count1." . "'".cmd."'"
endfor

augroup FastFold
  autocmd!
  autocmd VimEnter * call s:init()
augroup end

function! s:init()
  call s:UpdateTab()
  augroup FastFold
    autocmd!
    " Make &l:foldmethod local to Buffer and NOT Window.
    " UpdateWin(1) = Skip if another session still loading.
    " BufWinEnter = to change &l:foldmethod by modelines.
    autocmd BufWinEnter,BufEnter,WinEnter *
      \ if exists('b:lastfdm') | let w:lastfdm = b:lastfdm | call s:LeaveWin() | call s:EnterWin() | endif
    autocmd BufLeave,WinLeave             *
      \ call s:LeaveWin() | call s:EnterWin() |
      \ if exists('w:lastfdm')     | let b:lastfdm = w:lastfdm |
      \ elseif exists('b:lastfdm') | unlet b:lastfdm | endif

    autocmd FileType                      * call s:UpdateWin(1)
    " So that FastFold functions correctly after :loadview.
    autocmd SessionLoadPost               * call s:UpdateWin(0)

    autocmd TabEnter                      * call s:UpdateTab()

    " Update folds on saving.
    if g:fastfold_savehook
      autocmd BufWritePost                * call s:UpdateBuf(0)
    endif
  augroup end
endfunction

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
