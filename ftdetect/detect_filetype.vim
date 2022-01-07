au BufNewFile,BufRead sources set filetype=sources
au BufNewFile,BufRead dirs set filetype=sources
au BufNewFile,BufRead *.strings set filetype=strings
au BufNewFile,BufRead *.browser set filetype=xml
au BufNewFile,BufRead *.xml set filetype=xml
au BufNewFile,BufRead *.html set filetype=html
au BufNewFile,BufRead *.aspx set filetype=aspx
au BufNewFile,BufRead *.ascx set filetype=aspx
au BufNewFile,BufRead *.master set filetype=aspx
au BufNewFile,BufRead *.xaml set filetype=xaml
"detect if it is cpp/objc/objcppPath
au BufNewFile,BufRead *.h call s:DetectHeader()
    
function s:DetectHeader()
    let cppPath = expand("%:r") . ".cpp"
    let cPath = expand("%:r") . ".c"
    let objcPath = expand("%:r") . ".m"
    let objcppPath = expand("%:r") . ".mm"
    " if we find the alternative file, we are sure the file type can be guessed from that.
    if (filereadable(cppPath))
        set ft=cpp
    elseif (filereadable(cPath))
        set ft=c
    elseif (filereadable(objcPath))
        set ft=objc
    elseif (filereadable(objcppPath))
        set ft=objcpp
    endif
endfunction
