" TODO: Correctly save fdm=diff in vimdiff!

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
  if !(&l:foldmethod ==# 'manual')
    return &l:foldmethod
  endif

  if exists('w:lastfdm') && !(w:lastfdm ==#'manual')
    return w:lastfdm
  endif

  return &g:foldmethod
endfunction

function! s:lastfdm()
  if exists('w:lastfdm') && !(w:lastfdm ==#'manual')
    return w:lastfdm
  endif

  if !(&l:foldmethod ==# 'manual')
    return &l:foldmethod
  endif

  return &g:foldmethod
endfunction

function! s:reasonable()
  if g:fastfold_force
    return 1
  endif
  if &l:foldmethod ==# 'syntax' || &l:foldmethod ==# 'expr'
    return 1
  endif
  return 0
endfunction

function! s:Enter()
  if !s:reasonable()
    return
  endif
  if s:Skip()
    return
  endif

  let w:lastfdm = s:locfdm()
  setlocal foldmethod=manual
endfunction

function! s:Leave()
  if !s:reasonable()
    return
  endif
  if s:Skip()
    return
  endif

  let &l:foldmethod=s:lastfdm()
endfunction

function! s:EnterAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:Enter() | endif
endfunction

function! s:LeaveAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:Leave() | endif
endfunction

function! s:Update(feedback)
  if !s:Check()
    return
  endif
  if !exists('w:lastfdm') || (w:lastfdm ==# 'manual')
    return
  endif

  call s:LeaveAll()
  call s:EnterAll()
  if a:feedback
    echo "updated '".w:lastfdm."' folds"
  endif
endfunction

" Copy of MakeViewCheck() in restore_view.vim by Yichao Zhou
function! s:Check()
  if has('quickfix') && &buftype =~ 'nofile' | return 0 | endif
  if expand('%') =~ '\[.*\]' | return 0 | endif
  if empty(glob(expand('%:p'))) | return 0 | endif
  if &modifiable == 0 | return 0 | endif

  return 1
endfunction

function! s:Skip()
  let file_name = expand('%:p')
  for ifiles in g:fastfold_skipfiles
    if file_name =~? ifiles
      return 1
    endif
  endfor
  return 0
endfunction

function! s:OverwriteMaps()
  for mapsuffix in g:fastfold_mapsuffixes
    " execute 'nnoremap <silent> <SID>z'.mapsuffix.' '.(hasmapto('z'.mapsuffix,'n') ? maparg('z'.mapsuffix, 'n') : 'z'.mapsuffix)
    " execute 'nnoremap <silent> z'.mapsuffix.' :FastFoldUpdate<CR>:normal <SID>z'.mapsuffix.'<CR>'
    execute 'nnoremap <silent> z'.mapsuffix.' :FastFoldUpdate<CR>z'.mapsuffix
  endfor
endfunction

command! -bang FastFoldUpdate call s:Update(<bang>0)

" Update folds when entering a Buffer and Saving it.
augroup FastFold
  autocmd!
  " for :loadview
  autocmd SessionLoadPost ?* call s:Enter()
  " nonmodifiable buffers do not need fold updates
  autocmd BufWinEnter ?* if s:Check() | call s:Enter() | endif
  " for :makeview autocmd in BufWinLeave
  autocmd BufWinLeave ?* if s:Check() | call s:Leave() | endif
  " Default to last foldmethod of current buffer.
  autocmd WinLeave ?* if  exists('w:lastfdm')                        | let b:lastfdm=w:lastfdm | endif
  autocmd WinEnter ?* if !exists('w:lastfdm') && exists('b:lastfdm') | let w:lastfdm=b:lastfdm | endif

  if g:fastfold_savehook == 1
    " update folds on saving
    autocmd BufWritePost    ?* call s:EnterAll()
    autocmd BufWritePre     ?* call s:LeaveAll()
  endif

  augroup end

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
