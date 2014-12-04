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

if exists("g:loaded_fastfold")
  finish
endif

let g:loaded_fastfold = 1

if !exists('g:fastfold_force')
  let g:fastfold_force = 0
endif

if !exists('g:fastfold_map')
  let g:fastfold_map = 1
endif

if !exists('g:fastfold_togglehook')
  let g:fastfold_togglehook = 0
endif

if !exists('g:fastfold_savehook')
  let g:fastfold_savehook = 1
endif

if !exists("g:fastfold_skipfiles")
  let g:fastfold_skipfiles = []
endif

function! s:locfdm()
  if &l:foldmethod !=# 'manual'
    return &l:foldmethod
  endif

  if exists('w:lastfdm') && w:lastfdm !=# 'manual'
    return w:lastfdm
  endif

  return &g:foldmethod
endfunction

function! s:lastfdm()
  if exists('w:lastfdm') && w:lastfdm !=# 'manual'
    return w:lastfdm
  endif

  if &l:foldmethod !=# 'manual'
    return &l:foldmethod
  endif

  return &g:foldmethod
endfunction

function! s:Enter()
  let w:lastfdm = s:locfdm()

  if s:Skip()
    return
  endif

  setlocal foldmethod=manual
endfunction

function! s:Leave()
  if s:Skip()
    return
  endif

  if &l:foldmethod == 'manual'
    let &l:foldmethod= s:lastfdm()
  endif
endfunction

" See http://vim.wikia.com/wiki/Run_a_command_in_multiple_buffers#Restoring_position
" Like windo but restore the current buffer.
function! s:WinDo( command )
  let curaltwin = winnr('#')
  let currwin=winnr()
  execute 'windo ' . a:command
  execute curaltwin . 'wincmd w'
  execute currwin . 'wincmd w'
endfunction

function! s:EnterAllWinOfTab()
  call s:WinDo("if exists('w:lastfdm') | call s:Enter() | endif")
endfunction

function! s:LeaveAllWinOfTab()
  " Because TabEnter triggers BEFORE the FileType (that sets local fdm) and
  " BufWinEnter (that sets mode line fdm) are executed, check if window fdm
  " already set up. But TabEnter triggers AFTER WinEnter, so w:Lastfdm check
  " sufficient. (No b:Lastfdm).
  call s:WinDo("if exists('w:lastfdm') | call s:Leave() | endif")
endfunction

function! s:UpdateTab()
  call s:LeaveAllWinOfTab()
  call s:EnterAllWinOfTab()
endfunction

function! s:EnterAllWinOfBuf()
  let s:curbuf = bufnr('%')
  call s:WinDo("if bufnr('%') == s:curbuf | call s:Enter() | endif")
endfunction

function! s:LeaveAllWinOfBuf()
  let s:curbuf = bufnr('%')
  call s:WinDo("if bufnr('%') == s:curbuf | call s:Leave() | endif")
endfunction

function! s:UpdateBuf(feedback)
  " !exists(w:lastfdm) => no valid buffer.
  if !exists('w:lastfdm')
    return
  endif

  call s:LeaveAllWinOfBuf()
  call s:EnterAllWinOfBuf()


  if !s:Skip() && a:feedback
    echo "updated '".w:lastfdm."' folds"
  endif
endfunction

function! s:isReasonable()
  if g:fastfold_force
    return 1
  endif
  " if !isValidBuf() then not exists('w:lastfdm')
  if exists('w:lastfdm') && (w:lastfdm ==# 'syntax' || w:lastfdm ==# 'expr')
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

function! s:Skip()
  if !s:isReasonable()
    return 1
  endif
  if s:inSkipList()
    return 1
  endif
  return 0
endfunction

" Copy of MakeViewCheck() in restore_view.vim by Yichao Zhou
function! s:isValidBuffer()
  if has('quickfix') && &buftype =~ 'nofile' | return 0 | endif
  if expand('%') =~ '\[.*\]' | return 0 | endif
  if empty(glob(expand('%:p'))) | return 0 | endif
  if &modifiable == 0 | return 0 | endif

  return 1
endfunction

function! s:OverwriteMaps()
  for mapsuffix in g:fastfold_mapsuffixes
    " execute 'nnoremap <silent> <SID>z'.mapsuffix.' '.(hasmapto('z'.mapsuffix,'n') ? maparg('z'.mapsuffix, 'n') : 'z'.mapsuffix)
    " execute 'nnoremap <silent> z'.mapsuffix.' :FastFoldUpdate<CR>:normal <SID>z'.mapsuffix.'<CR>'
    execute 'nnoremap <silent> z'.mapsuffix.' :FastFoldUpdate<CR>z'.mapsuffix
  endfor
endfunction

command! -bang FastFoldUpdate call s:UpdateBuf(<bang>0)

nnoremap <silent> <Plug>(FastFoldUpdate) :FastFoldUpdate!<CR>

if g:fastfold_map == 1 && !hasmapto('<Plug>(FastFoldUpdate)', 'n') && mapcheck('zuz', 'n') ==# ''
  nmap zuz <Plug>(FastFoldUpdate)
endif

if g:fastfold_togglehook == 1
  if !exists('g:fastfold_mapsuffixes')
    let g:fastfold_mapsuffixes = ['x','X','a','A','o','O','c','C','r','R','m','M','i','n','N']
  endif
  call s:OverwriteMaps()
endif

augroup FastFold
  autocmd!
  " for :loadview
  autocmd SessionLoadPost * call s:Enter()
  " nonmodifiable buffers do not need fold updates
  autocmd BufWinEnter ?* if s:isValidBuffer() |  call s:Enter() | endif
  " for :makeview autocmd in BufWinLeave
  autocmd BufWinLeave ?* if s:isValidBuffer() | call s:Leave() | endif
  " Default to last foldmethod of current buffer.
  autocmd WinLeave * if  exists('w:lastfdm')                        | let b:lastfdm=w:lastfdm | endif
  autocmd WinEnter * if !exists('w:lastfdm') && exists('b:lastfdm') | let w:lastfdm=b:lastfdm | endif
  autocmd TabEnter * call s:UpdateTab()

  if g:fastfold_savehook == 1
    " update folds on saving
    autocmd BufWritePost    ?* call s:EnterAllWinOfBuf()
    autocmd BufWritePre     ?* call s:LeaveAllWinOfBuf()
  endif
augroup end

