au BufRead,BufNewFile * let b:isTemporary = get(b:, 'isTemporary', s:isTemporary())
au BufFilePost * let b:isTemporary = s:isTemporary()

function! s:isTemporary()
    " From RESTORE_VIEW.Vim:
    " Recognize a volatile buffer by its name. Works in
    " pratice most of the time but strictly speaking incorrect because the
    " buffer name is file name independent. See discussion at
    " https://Github.Com/kopischke/vim-stay/issues/2

    if !empty($TMPDIR) && expand('%:p:h') == $TMPDIR | return 1 | endif
    if !empty($TEMP) && expand('%:p:h') == $TEMP | return 1 | endif
    if !empty($TMP) && expand('%:p:h') == $TMP | return 1 | endif

    return 0
endfunction
