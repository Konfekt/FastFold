" Headless test: FastFold loaded after startup (e.g. :packadd or a plug-in
" manager loading it lazily) must still install its autocommands.
" Run via test/run.sh.
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:out = empty($FASTFOLD_TEST_OUT) ? 'fastfold_test.log' : $FASTFOLD_TEST_OUT

function! s:Run() abort
  execute 'set runtimepath^=' . fnameescape(s:root)
  runtime plugin/fastfold.vim
  let l:ok = exists('#FastFoldEnter#BufWritePost')
  call writefile([l:ok ? 'ok   late load installs autocommands'
        \ : 'FAIL late load installs autocommands'], s:out, 'a')
  execute l:ok ? 'qall!' : 'cquit!'
endfunction

" v:vim_did_enter is set once VimEnter fires; load the plug-in from there.
augroup FastFoldTest
  autocmd VimEnter * call s:Run()
augroup END
