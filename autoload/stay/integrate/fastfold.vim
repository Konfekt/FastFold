" VIM-STAY INTEGRATION MODULE
" https://github.com/kopischke/vim-stay
let s:cpoptions = &cpoptions
set cpoptions&vim

" - register integration autocommands
function! stay#integrate#fastfold#setup() abort
  autocmd User BufStaySavePre  unsilent call stay#integrate#fastfold#save_pre()
  autocmd User BufStaySavePost unsilent call stay#integrate#fastfold#save_post()
  autocmd User BufStayLoadPost,BufStaySavePost let b:isPersistent = 1
endfunction

" - on User event 'BufStaySavePre': restore original 'foldmethod'
function! stay#integrate#fastfold#save_pre() abort
  let [l:fdmlocal, l:fdmorig] = s:foldmethods()
  if l:fdmorig isnot l:fdmlocal
\ && index(split(&viewoptions, ','), 'folds') isnot -1
    noautocmd silent let &l:foldmethod = l:fdmorig
  endif
endfunction

" - on User event 'BufStaySavePost': restore FastFold 'foldmethod'
function! stay#integrate#fastfold#save_post() abort
  let [l:fdmlocal, l:fdmorig] = s:foldmethods()
  if l:fdmorig isnot l:fdmlocal
    noautocmd silent let &l:foldmethod = 'manual'
  endif
endfunction

" - return tuple of current local and FastFold stored 'foldmethod'
function! s:foldmethods() abort
  let l:fdmlocal = &l:foldmethod
  return [l:fdmlocal, get(w:, 'lastfdm', l:fdmlocal)]
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
