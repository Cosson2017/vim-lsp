function! s:not_supported(what) abort
    return lsp#utils#error(a:what.' not supported for '.&filetype)
endfunction

function! lsp#ui#vim#hover#balloon() abort
    let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_hover_provider(v:val)')

    if len(l:servers) == 0
        echom 'Retrieving hover not supported for ' . &filetype
        return ''
    endif

    for l:server in l:servers
        call lsp#send_request(l:server, {
            \ 'method': 'textDocument/hover',
            \ 'params': {
            \   'textDocument': lsp#get_text_document_identifier(),
            \   'position': { 'line': v:beval_lnum - 1, 'character': v:beval_col - 1 }
            \ },
            \ 'on_notification': function('s:handle_hover', [l:server, 'balloon']),
            \ })
    endfor

    echom 'Retrieving hover ...'
    return ''
endfunction


function! lsp#ui#vim#hover#get_hover_under_cursor() abort
    let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_hover_provider(v:val)')

    if len(l:servers) == 0
        call s:not_supported('Retrieving hover')
        return
    endif

    for l:server in l:servers
        call lsp#send_request(l:server, {
            \ 'method': 'textDocument/hover',
            \ 'params': {
            \   'textDocument': lsp#get_text_document_identifier(),
            \   'position': lsp#get_position(),
            \ },
            \ 'on_notification': function('s:handle_hover', [l:server]),
            \ })
    endfor

    echo 'Retrieving hover ...'
endfunction

function! s:handle_hover(server, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Failed to retrieve hover information for ' . a:server)
        return
    endif

    if !has_key(a:data['response'], 'result')
        return
    endif

     if a:type == 'balloon'
        call balloon_show(join(map(l:contents, 'v:val.text'), "\n"))
        return
    endif

    if !empty(a:data['response']['result']) && !empty(a:data['response']['result']['contents'])
        call lsp#ui#vim#output#preview(a:data['response']['result']['contents'])
        return
    else
        call lsp#utils#error('No hover information found')
    endif
endfunction
