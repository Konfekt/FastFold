" Headless tests for FastFold.
" vint: -ProhibitCommandRelyOnUser (mappings are exercised on purpose)
" Run via test/run.sh, or: vim -Nu NONE -i NONE -es -S test/test_fastfold.vim
" Each Test_* function runs in a fresh buffer; failures are collected in
" v:errors and reported in the output file given by $FASTFOLD_TEST_OUT.

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:out = empty($FASTFOLD_TEST_OUT) ? 'fastfold_test.log' : $FASTFOLD_TEST_OUT

" User configuration that must survive loading the plug-in.
let g:fastfold_minlines = 0
let g:fastfold_foldmethods = ['syntax', 'expr']
let g:fastfold_skip_filetypes = ['skipme']

execute 'set runtimepath^=' . fnameescape(s:root)
runtime plugin/fastfold.vim
if !exists('#FastFoldEnter')
  doautocmd FastFold VimEnter
endif

" Three nested indent levels, repeated so the buffer is reasonably long.
function! s:Setup(...) abort
  enew!
  setlocal buftype= modifiable shiftwidth=2
  call setline(1, repeat(['a', '  b', '    c', '      d', '      d', '    c', '  b'], 30))
  let &l:foldmethod = a:0 ? a:1 : 'expr'
  setlocal foldexpr=indent(v:lnum)/2 foldlevel=0
  FastFoldUpdate
endfunction

function! Test_user_foldmethods_are_kept() abort
  call assert_equal(['syntax', 'expr'], g:fastfold_foldmethods)
endfunction

function! Test_update_switches_to_manual() abort
  call s:Setup()
  call assert_equal('manual', &l:foldmethod)
  call assert_equal('expr', w:lastfdm)
  call assert_equal(2, foldclosed(4))
endfunction

function! Test_update_feedback() abort
  call s:Setup()
  let msg = execute('FastFoldUpdate!')
  call assert_match("updated 'expr' folds", msg)
endfunction

function! Test_other_foldmethods_untouched() abort
  call s:Setup('indent')
  call assert_equal('indent', &l:foldmethod)
  call assert_false(exists('w:lastfdm'))
endfunction

function! Test_skip_filetypes() abort
  call s:Setup()
  setlocal filetype=skipme
  setlocal foldmethod=expr
  FastFoldUpdate
  call assert_equal('expr', &l:foldmethod)
endfunction

function! Test_skip_special_buffers() abort
  call s:Setup()
  setlocal buftype=nofile foldmethod=expr
  FastFoldUpdate
  call assert_equal('expr', &l:foldmethod)
endfunction

function! Test_skip_small_buffers() abort
  let g:fastfold_minlines = 1000
  try
    call s:Setup()
    call assert_equal('expr', &l:foldmethod)
  finally
    let g:fastfold_minlines = 0
  endtry
endfunction

function! Test_fold_command_keeps_count() abort
  call s:Setup()
  normal! zR
  call cursor(4, 1)
  normal 2zc
  call assert_equal(3, foldclosed(4))
  normal! zM
  call cursor(4, 1)
  normal 3zo
  call assert_equal(-1, foldclosed(4))
  call assert_equal('manual', &l:foldmethod)
endfunction

" Without a count, the remapped motion must not move the cursor by itself;
" here zk finds no fold to move to, so the cursor stays put as with plain zk.
function! Test_fold_motion_without_count_keeps_cursor() abort
  call s:Setup()
  normal! zR
  call cursor(5, 7)
  normal zk
  call assert_equal([5, 7], [line('.'), col('.')])
  call cursor(5, 7)
  execute "normal vzk\<Esc>"
  call assert_equal([5, 7], [line("'>"), col("'>")])
endfunction

function! Test_fold_motion_keeps_count() abort
  call s:Setup()
  normal! zR
  call cursor(1, 1)
  normal 2zj
  call assert_equal(3, line('.'))
endfunction

function! Test_fold_motion_operator() abort
  call s:Setup()
  normal! zR
  call cursor(4, 1)
  normal d]z
  " same result as the built-in (exclusive) motion
  call assert_equal(209, line('$'))
  call assert_equal(['      d', '    c'], getline(4, 5))
endfunction

function! Test_update_all_windows_of_buffer() abort
  call s:Setup()
  split
  setlocal foldmethod=expr
  wincmd p
  setlocal foldmethod=expr
  FastFoldUpdate
  call assert_equal('manual', getwinvar(1, '&foldmethod'))
  call assert_equal('manual', getwinvar(2, '&foldmethod'))
  only
endfunction

function! Test_fold_command_updates_current_window_only() abort
  call s:Setup()
  split
  setlocal foldmethod=expr
  wincmd p
  setlocal foldmethod=expr
  normal zx
  call assert_equal('manual', &l:foldmethod)
  call assert_equal('expr', getwinvar(winnr('#'), '&foldmethod'))
  only
endfunction

function! Test_diff_restores_foldmethod() abort
  call s:Setup()
  diffthis
  call assert_equal('diff', &l:foldmethod)
  FastFoldUpdate
  diffoff
  FastFoldUpdate
  call assert_equal('manual', &l:foldmethod)
  call assert_equal('expr', w:lastfdm)
endfunction

function! Test_update_on_save() abort
  let file = tempname()
  try
    call s:Setup()
    execute 'silent write ' . fnameescape(file)
    setlocal foldmethod=expr
    silent write
    call assert_equal('manual', &l:foldmethod)
  finally
    enew!
    call delete(file)
  endtry
endfunction

function! Test_no_global_leaks() abort
  call assert_false(exists('g:suffix'), 'g:suffix leaked')
  call assert_false(exists('g:cmd'), 'g:cmd leaked')
endfunction

let s:results = []
let s:failed = 0
for s:test in sort(filter(map(split(execute('function /^Test_'), "\n"),
      \ 'matchstr(v:val, ''\<Test_\w\+'')'), '!empty(v:val)'))
  let v:errors = []
  try
    call call(s:test, [])
  catch
    call add(v:errors, s:test . ': ' . v:exception . ' @ ' . v:throwpoint)
  endtry
  if empty(v:errors)
    call add(s:results, 'ok   ' . s:test)
  else
    let s:failed += 1
    call add(s:results, 'FAIL ' . s:test)
    call extend(s:results, map(copy(v:errors), '"     " . v:val'))
  endif
endfor
call add(s:results, s:failed ? s:failed . ' test(s) failed' : 'all tests passed')
call writefile(s:results, s:out)
if s:failed
  cquit!
endif
qall!
