au BufRead,BufNewFile * let b:isTemporary = get(b:, 'isTemporary', s:isTemporary())
au BufFilePost * let b:isTemporary = s:isTemporary()

function! s:isTemporary()
    " Recognize a volatile buffer by its name. Works in
    " pratice most of the time but strictly speaking incorrect because the
    " buffer name is file name independent. See discussion at
    " https://Github.Com/kopischke/vim-stay/issues/2
    let cwd = expand('%:p:h')
    "  [ ...] = set backupskip&?
    for tmpdir in [$TMPDIR, $TEMP, $TMP, '/tmp']
        if !empty(tmpdir) && (cwd ==# tmpdir || cwd =~# '\v^' . tmpdir . '[\/]') | return 1 | endif
    endfor

    return 0
endfunction
