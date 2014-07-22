if exists("g:loaded_fastfold")
    finish
endif

let g:loaded_fastfold = 1

if !exists("g:fastfold_skipfiles")
    let g:fastfold_skipfiles = []
endif

" Update folds when entering a Buffer and Saving it.
augroup FastFold
  autocmd!
  " for :loadview
  autocmd SessionLoadPost ?* call s:FastFoldEnter()
  " nonmodifiable buffers do not need fold updates
  autocmd BufWinEnter ?* if s:FastFoldCheck() | call s:FastFoldEnter() | endif
  autocmd BufWinLeave ?* if s:FastFoldCheck() | call s:FastFoldLeave() | endif
  " update folds on saving...
  autocmd BufWritePost    ?* call s:FastFoldEnterAll()
  autocmd BufWritePre     ?* call s:FastFoldLeaveAll()
  " ... and default to last foldmethod of current buffer.
  autocmd WinLeave ?* if  exists('w:last')                         | let b:last=w:last | endif
  autocmd WinEnter ?* if !exists('w:last') && exists('b:last') | let w:last=b:last | endif
augroup end

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

function! s:FastFoldEnter()
  let w:lastfdm = s:locfdm()
  setlocal foldmethod=manual
endfunction

function! s:FastFoldLeave()
  let &l:foldmethod=s:lastfdm()
endfunction

function! s:FastFoldEnterAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:FastFoldEnter() | endif
endfunction

function! s:FastFoldLeaveAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:FastFoldLeave() | endif
endfunction

function! s:FastFoldCheck()
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
