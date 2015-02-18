au BufRead,BufNewFile * let b:isPersistent = get(b:, 'isPersistent', s:isPersistent())
au BufFilePost * let b:isPersistent = s:isPersistent()

function! s:isPersistent()
    " From VIM-STAY:
    let bufnr = bufnr('%')
    if !(bufexists(bufnr)
    \ && getbufvar(bufnr, '&buflisted') is 1
    \ && index(['', 'acwrite'], getbufvar(bufnr, '&buftype')) isnot -1
    \ && getbufvar(bufnr, '&previewwindow') isnot 1
    \ && getbufvar(bufnr, '&diff') isnot 1
    \ && index(['', 'hide'], getbufvar(bufnr, '&bufhidden')) isnot -1
    \ && filereadable(fnamemodify(bufname(bufnr), ':p')))
        return 0
    endif

    " From RESTORE_VIEW.Vim:
    " Recognize a volatile buffer by its name. Works in
    " pratice most of the time but strictly speaking incorrect because the
    " buffer name is file name independent. See discussion at
    " https://Github.Com/kopischke/vim-stay/issues/2

    " buffers with a volatile file name
    if expand('%') =~ '\[.*\]' | return 0 | endif
    if len($TEMP) && expand('%:p:h') == $TEMP | return 0 | endif
    if len($TMP) && expand('%:p:h') == $TMP | return 0 | endif

    return 1
endfunction
