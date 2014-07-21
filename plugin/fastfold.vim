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
  autocmd BufNew,BufReadPost ?* if s:FastFoldCheck() | call s:FastFoldEnter() | endif
  autocmd BufWinLeave ?* if s:FastFoldCheck() | call s:FastFoldLeave() | endif
  " update folds on saving...
  autocmd BufWritePost    ?* call s:FastFoldEnterAll()
  autocmd BufWritePre     ?* call s:FastFoldLeaveAll()
  " ... and default to last foldmethod of current buffer.
  autocmd WinLeave ?* if  exists('w:last_fdm')                         | let b:last_fdm=w:last_fdm | endif
  autocmd WinEnter ?* if !exists('w:last_fdm') && exists('b:last_fdm') | let w:last_fdm=b:last_fdm | endif
augroup end

function! s:FastFoldEnterAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:FastFoldEnter() | endif
endfunction

function! s:FastFoldLeaveAll()
  let s:curbuf = bufnr('%')
  windo if bufnr('%') == s:curbuf | call s:FastFoldLeave() | endif
endfunction

function! s:FastFoldEnter()
  if exists('w:last_fdm') && (&foldmethod ==# 'manual')
    return
  endif

  let w:last_fdm=&foldmethod
  setlocal foldmethod=manual
endfunction

function! s:FastFoldLeave()
  if !(exists('w:last_fdm') && (&foldmethod ==# 'manual'))
    return
  endif

  let &foldmethod=w:last_fdm
  unlet w:last_fdm
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
