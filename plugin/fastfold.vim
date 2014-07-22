if exists("g:loaded_fastfold")
    finish
endif

let g:loaded_fastfold = 1

if !exists('g:fastfold_no_mappings')
 let g:fastfold_no_mappings = 0
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

function! s:Enter()
  let w:lastfdm = s:locfdm()
  setlocal foldmethod=manual
endfunction

function! s:Leave()
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

function! s:Check()
    if has('quickfix') && &buftype =~ 'nofile' | return 0 | endif
    if expand('%') =~ '\[.*\]' | return 0 | endif
    if empty(glob(expand('%:p'))) | return 0 | endif
    if &modifiable == 0 | return 0 | endif
    if len($TEMP) && expand('%:p:h') == $TEMP | return 0 | endif
    if len($TMP) && expand('%:p:h') == $TMP | return 0 | endif

    let file_name = expand('%:p')
    for ifiles in g:fastfold_skipfiles
        if file_name =~ ifiles
            return 0
        endif
    endfor

    return 1
endfunction

" Update folds when entering a Buffer and Saving it.
augroup FastFold
  autocmd!
  " for :loadview
  autocmd SessionLoadPost ?* call s:Enter()
  " nonmodifiable buffers do not need fold updates
  autocmd BufWinEnter,TabEnter ?* if s:Check() | call s:Enter() | endif
  " for :makeview autocmd in BufWinLeave
  autocmd BufWinLeave,TabLeave ?* if s:Check() | call s:Leave() | endif
  " Default to last foldmethod of current buffer.
  autocmd WinLeave ?* if  exists('w:lastfdm')                        | let b:lastfdm=w:lastfdm | endif
  autocmd WinEnter ?* if !exists('w:lastfdm') && exists('b:lastfdm') | let w:lastfdm=b:lastfdm | endif
  " update folds on saving
  autocmd BufWritePost    ?* call s:EnterAll()
  autocmd BufWritePre     ?* call s:LeaveAll()
augroup end

nnoremap <Plug>FastFoldUpdate :call <SID>LeaveAll() <BAR> call <SID>EnterAll()<CR>:echo "folds updated"<CR>

if g:fastfold_no_mappings == 0 && !hasmapto('<Plug>FastFoldUpdate', 'n') && mapcheck('zuz', 'n') ==# ''
  nmap zuz <Plug>FastFoldUpdate
endif

if !exists("g:fastfold_skipfiles")
    let g:fastfold_skipfiles = []
endif

