"How to build vim with python
" 1. install the vim74 by download the binary, which by default doesn't have PYTHON support.
" 2. Using the VS2012 on windows, execute following commands, more variable than PYTHON can be find in Make_mvc.mak
"call "c:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\Tools\vsvars32.bat"
"set SDK_INCLUDE_DIR=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include
"set PYTHON=c:\Python27
"set DYNAMIC_PYTHON=yes
"set PYTHON_VER=27
"nmake -f Make_mvc.mak clean
"nmake -f Make_mvc.mak 
" 3. replace the vim.exe with the build output.

if !has('python3')
    echo "Error: Required vim compiled with +python3"
    finish
endif

set encoding=utf-8
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set nocompatible
syntax on
set hlsearch
set incsearch
set smartcase
set clipboard=unnamed

" disable the beep which does goes to system mic instead of USB headset on mac.
set noeb vb t_vb=
let g:swift_suppress_showmatch_warning = 1


highlight Pmenu ctermbg=238 gui=bold
highlight PmenuSel ctermbg=200 gui=bold
highlight Search ctermfg=Black ctermbg=Yellow cterm=NONE

"source $VIMRUNTIME/../base64.vim
autocmd FileType make setlocal noexpandtab

filetype on
filetype plugin on
filetype indent on

set complete-=i
set foldmethod=indent foldlevel=4

set shiftwidth=4 softtabstop=4 expandtab tabstop=4
if ($LONG_TAB == "1")
    set shiftwidth=8 softtabstop=8 expandtab tabstop=8
endif

if ($YCM_FOLDER != "")
   "source $YCM_FOLDER/autoload/youcompleteme.vim
   "source $YCM_FOLDER/plugin/youcompleteme.vim
   "let g:ycm_collect_identifiers_from_comments_and_strings = 1
   "let g:ycm_collect_identifiers_from_tags_files = 1
   "let g:ycm_complete_in_comments = 1
endif

set undofile
set ignorecase smartcase linebreak number autowriteall autowrite showmatch
set history=400
set isfname+=$,(,),%
set includeexpr=NormalizeFilePath(v:fname)

" We have trouble to copy paste on linux, it will goto visual mode when we
" using mouse to select line, so we need to disable mouse and then we can copy
" and past.
if (has("unix"))
   set mouse=
endif

if (has("mac"))
   map <C-V> <ESC>:r !pbpaste<CR>
endif

set laststatus=2

set statusline=%!StatusLine()
function! StatusLine()
    let standStatusLine='%<%F %h%m%r%=%-14.(%l/%L,%c%V%) %P'
    let barWidth = &columns - 140 " <-- wild guess
    let barWidth = barWidth < 3 ? 3 : barWidth
    if line('$') > 1
        let progress = (line('.') - 1) * (barWidth - 1) / (line('$') - 1)
    else
        let progress = barWidth / 2
    endif
    " leave some padding here;
    let pad = 2
    let bar = repeat(' ',pad).' [%'.barWidth.'.'.barWidth.'(' . repeat('>',progress) . '%0*|%0*' . repeat('-',barWidth - progress - 1).'%)%<]'
    return standStatusLine . '%=' .bar
endfunction

function CopyFile(srcPath, dstPath)
    if (has("mac") || has("unix"))
        exec "silent !cp -f " . shellescape(a:srcPath) . " " . shellescape(a:dstPath)
    else
        exec "silent !copy /Y " . shellescape(a:srcPath) . " " . shellescape(a:dstPath)
    endif
endfunction


"it will not care if it already contains separator
function JoinPath(parentPath, subPath)
    let pathSep = "\\"
    if (has("mac") || has("unix"))
        let pathSep = "/"
    endif
    return a:parentPath . pathSep . a:subPath
endfunction

function! GetLastVisualSelectText()
  try
    let a_save = @a
    normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

function FormatSpace() range
    for linenum in range(a:firstline, a:lastline)
        exec linenum . "s/->/kxk0/ge"
        exec linenum . "s/\\\\n/kxk1/ge"
        exec linenum . "s/\\\\r/kxk2/ge"
        exec linenum . "s/!=/kxk3/ge"
        exec linenum . "s/\\s*\\([\\+\\-\\*\\/><=|]\\)\\s*/ \\1 /ge"
        exec linenum . "s/\\s*\\([,]\\)\\s*/\\1 /ge"
        exec linenum . "s/kxk0/->/ge"
        exec linenum . "s/kxk1/\\\\n/ge"
        exec linenum . "s/kxk2/\\\\r/ge"
        exec linenum . "s/kxk3/!=/ge"
    endfor
    0,$s///ge
endfunction

" search text
function SearchText(defaultText)
    let text = input("Search text:", a:defaultText)
    if (text == "")
        return
    endif

    let currentFolder = getcwd() 
    let pyScirpt = shellescape(JoinPath($myEnvFolder, "search_service.py"))
    let result = system("python3 " . pyScirpt . " " . shellescape(text))
    if (Trim(result) == "")
       "TODO by zijwu print the first 2 line
       echo "Result find."
    endif
    cexpr result 
    copen
endfunction

function GotoFile()
    let str = NormalizeFilePath(expand("<cfile>"))
    call FindAndOpenFile(str)
endfunction

function OpenClipFileList()
    let fileListStr = @+
    let fileList = split(fileListStr, "\n")
    if (len(fileList) > 10)
       "Miss operation?
       return 
    endif

    let num = len(fileList)
    if (num > 5)
        let num = 5
    endif

    let index = 0
    while(index < num)
        let filePath = fileList[index]
        execute "tabedit " . filePath
        let index = index + 1
    endwhile
endfunction

function PromptForFile()
    let a:name = input("Goto file:")
    if (a:name != "")
        let a:name = escape(a:name, '\.')
        let a:name = substitute(a:name, "*", ".*", "")
        let a:name = substitute(a:name, "?", ".", "")
        let a:name = a:name . "[^\\/]*$"
        call FindAndOpenFile(a:name)
    endif
endfunction

function FilePathWeightCompare(filePath1, filePath2)
    let weight1 = 1000 - strlen(a:filePath1)
    if (a:filePath1 =~ "\\<request\\>" || a:filePath1 =~ "\\<response\\>" || a:filePath1 =~ "\\<schema\\>" || a:filePath1 =~ "\\<srcgen\\>")
       let weight1 = -1
    endif

    let weight2 = 1000 - strlen(a:filePath2)
    if (a:filePath2 =~ "\\<request\\>" || a:filePath2 =~ "\\<response\\>" || a:filePath2 =~ "\\<schema\\>" || a:filePath2 =~ "\\<srcgen\\>")
       let weight2 = -1
    endif

    return weight2 - weight1
endfunction

" go to current file with line number
function FindAndOpenFile(filePath)
    let fileListDir = FindFileInUpfolder(10, "filelist.filtered")
    if (filereadable(JoinPath($ROOT, "filelist.filtered")) && fileListDir == "")
        let fileListDir = $ROOT
    endif

    " first try to split the path, and check if the file exist.
    let fileNameAndLineNum = split(a:filePath, "\\(:\\|(\\)\\ze\\d")
    if (filereadable(fileNameAndLineNum[0]))
        let fileName = a:filePath
        let lineNum = -1
        if (len(fileNameAndLineNum) >= 2)
            let fileName = fileNameAndLineNum[0]
            let lineNum = str2nr(fileNameAndLineNum[1])
        endif

        "echo fileName . lineNum
        if (lineNum != -1)
            exec " e +" . lineNum . " ". fileName
        else
            exec "e " . fileName
        endif
    elseif (strlen(fileListDir) != 0)
        " Find the file in filelist (which should be exist in project root,
        " and contain all the interesting file list.
        let fileName = a:filePath
        let fileListFile = readfile(JoinPath(fileListDir, "filelist.filtered") , '', 60000)
        let matchFileList = []
        let matchedNum = 0
        for line in fileListFile
            " we also support ui/windows
            if (line =~? fileName)
                let matchFileList = matchFileList + [line]
                let matchedNum = matchedNum + 1
                if (matchedNum > 500)
                    echo "There are more than 500 files contain the pattern, just return the first 500"
                    break
                endif
            endif
        endfor

        let matchFileList = sort(matchFileList, "FilePathWeightCompare")

        "If we find more, then we use quickfix list, else we directly goto it.
        if (len(matchFileList) == 1)
            exec "e " . matchFileList[0]
            return
        elseif (len(matchFileList) > 1)
            let quickFixList = []
            for line in matchFileList
                let line = line . ":0:0: "
                let quickFixList = quickFixList + [line]
            endfor
            cexpr quickFixList
            echo "More than one file find. Use quick fix list."
        else
            echo "Cannot found the file:" . a:filePath
        endif
    endif
endfunction

" for handle the diff in svn diff result
function RemoveDiffItem()
    let separator = "^Index: "
    let result = search(separator, "bc")
    if (result == 0)
        return
    endif
    normal ma

    let result = search(separator, "")
    normal kd'a
endfunction

function NormalizeFilePath(path)
    let result = ReplaceEnvVariable(a:path)
    " git diff start with a/ or b/
    if (stridx(result, 'a/') == 0 || stridx(result, 'b/') == 0)
        let result = result[2:] 
    endif
    return result
endfunction

function ReplaceEnvVariable(path)
    let result = a:path
    while (1==1)
        let enVar = matchstr(result, "\\$(\\([^)]*\\))")
        if (enVar == "")
            break
        endif

        let enValue = expand(substitute(enVar, "(\\|)", "", "g"))
        let enValue = escape(enValue, "\\")
        let result = substitute(result, enVar, enValue, "")
        "echo result
    endwhile
    "echo "-->" . result
    return result
endfunction

function RenameLocalSym()
    normal mA
    let currentFileName = expand("%")
    let name = input("rename to:")
    if (name == "")
        return
    endif
    let word = expand("<cword>")
    exec ":%s/\\<" . word . "\\>/" . name . "/gce"

    "search alternative file to rename variables.
    while (AlternativeFile())
        if (expand("%") == currentFileName)
            break
        endif
        exec ":%s/\\<" . word . "\\>/" . name . "/gce"
    endwhile
    normal 'A
endfunction

let rnd = localtime() % 0x10000 
function! Random() 
  let g:rnd = (g:rnd * 31421 + 6927) % 0x10000 
  return g:rnd 
endfun 

function! RandomChoose(n) " 0 n within 
  return (Random() * a:n) / 0x10000 
endfun 

function! AddNameSpace(namespace)
    normal ma0gg
    execute "normal /using System/\<CR>"
    execute "normal o" . a:namespace . "\<Tab>\<ESC>"
    normal \\nn
    normal `a
    return ""
endfun

function Go_though_all_diff()
    if !&diff
        return
    endif 
       
    execute "goto"
    let lineNum = 0
    while (1==1)
        let oldLineNum = line(".")
        normal ]c
        redraw
        let lineNum = line(".")
        if (lineNum == oldLineNum)
            echo "Finished."
            return 
        endif
        execute "echohl Question | echo \"p/g/s". lineNum . "?\" | echohl None"
        execute "sleep 500ms"
        let c = nr2char(getchar())
        if (c == "p")
           " after normal finished, it will check the syncbind related flag
           " and update scroll in other window.
           " but diffget will not, so here using normal do/dp instead of
           " diffget/put.
           normal dp
        elseif (c == "g")
           normal do
        elseif (c == "s")
        elseif (c == "\<Esc>")
           break
        endif
    endwhile 
endfunction

function ReverseLine()
    let a:regularExpr = input("Using (<pattern>) to include the pattern self, and you doesn't need escape:")
    execute "'<,'>!python3 $myEnvFolder/reverse_words.py \"" . a:regularExpr . "\""
endfunction

function SaveReg(fileName)
    let regs = "01234567890abcdefghijklmnopqrstuvwxyz"
    let index = 0
    let lines = []
    while index < strlen(regs)
        let registerName = regs[index]
        let index = index + 1
        execute "let value = @". registerName
        if (len(value) == 0)
            continue
        endif
        let encodedValue = Base64Encode(value)
        let line = registerName . " " . encodedValue
        let lines = lines + [line]
    endwhile
    let dirPath = JoinPath($ROOT, "_registers_")
    if (isdirectory(dirPath) == 0)
        call mkdir(dirPath)
    endif
    let filePath = JoinPath(dirPath, a:fileName)
    call writefile(lines, filePath)
endfunction

function LoadReg(fileName)
    let dirPath = JoinPath($ROOT, "_registers_")
    let filePath = JoinPath(dirPath, a:fileName)

    if (!filereadable(filePath))
        echo "Cannot find the save: " . a:fileName
        return
    endif

    let index = 0
    let lines = readfile(filePath, '', 60000)
    while index < len(lines)
        let line = lines[index]
        let index = index + 1
        let regName = line[0]
        let encodedValue = line[2:]
        let value = Base64Decode(encodedValue)
        echo "set reg @" . regName . " to " . value
        execute "let @" . regName . " = value"
    endwhile
endfunction

function Add_To_Sources()
    if (!filereadable("sources"))
        execute "echoerr \"source file are not in current folder\""
        return
    endif
    normal mA
    let relativePath = expand("%:.")
    exec "silent !attrib -R sources"
    e sources
    exec "normal /SOURCES\\s*=\\s*\\\\$/\n"
    exec "normal o\t" . relativePath . " \\"
    "Sort it. Because normal V1} wil not create marker for < and >, so we
    "create it manually, and we cannot using '>, '< which is build in, so
    "let's using 'a and 'b
    normal ma
    normal 1}

    normal mb
    exec "'a,'b-1sort iu"
    redraw
    sleep 1
    w
    normal `A
endfunction

" another choose is findfile and finddir but it doesn't support max_deep.
function FindFileInUpfolder(max_deep, fileName)
     let path=expand("%:p:h")
     let max_deep = a:max_deep

     while max_deep > 0 
         let max_deep = max_deep -1
         if (file_readable(path . '\' . a:fileName)==1)
             return path
         endif
         let path = path . "\\.." 
     endwhile
     return ""
endfunction


function Always_change_dir()
     let current_path=expand("%:p:h")
     " skip unc path. what about ftp or http?
     if current_path =~ "^\\\\"
         return
     endif

     if current_path =~? "appdata" && current_path =~? "temp"
         return
     endif

     execute "lcd ". current_path

     " find the parent folder, where sources or dirs exist.
     let filePath = current_path
     let sourcesPath = FindFileInUpfolder(5, 'sources')
     if (sourcesPath != "")
         let filePath = sourcesPath
     endif
     let dirsPath = FindFileInUpfolder(5, 'dirs')
     if (dirsPath != "")
         let filePath = dirsPath
     endif

     if (filePath != "")
         execute "lcd " . filePath
     endif
endfunction

function Write_file_path()
    let current_path = expand("%:p:h")
    call writefile(["cd \"" . current_path . "\""], JoinPath($ROOT, "last_edit_file.txt"))
endfunction

set noautochdir
autocmd BufEnter * call Always_change_dir()
"we write the file path, so we can navigate to it quickly from terminal after exist vim.
autocmd VimLeave * call Write_file_path()

autocmd FileType cs set omnifunc=syntaxcomplete#Complete
"autocmd FileType html set omnifunc=htmlscriptcomplete#CompleteTags
"autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags

set errorformat+=%f:%l:%c:%m
set errorformat+=%f(%l):%m
set errorformat+=%f
set laststatus=2
if ($HIDESTATUSBAR == "1")
    set laststatus=0
endif
set isfname-=[
set isfname-=]

set makeprg=build.exe\ -cZP&perl\ %INIT%\\lcsbuild_filter.pl\ buildchk.err\ buildchk.wrn
set grepprg=grep

"if launch outside of project, we treat the current folder as project root
if ($ROOT == "")
    let $ROOT = expand("%:p:h")
endif

set tag=$ROOT/mytags
if (has("mac") || has("unix"))
	set tag=$ROOT/mytags
else
    set tag=%ROOT%\mytags
endif
python3 << EOF
import os
import vim
import md5
sys.path.append(os.environ['myEnvFolder'])
import util
import ConfigManager

#By default val
rootVariable = util.getEnv('ROOT')
if (not rootVariable or rootVariable == ""):
    rootVariable = vim.eval("expand(\"%:p:h\")")
rootVariable = rootVariable.replace("\\", "/")
vim.command("let $ROOT='" + rootVariable + "'")
rootVariable = vim.eval("$ROOT");

hasMac = vim.eval("has(\"mac\")");
hasUnix = vim.eval("has(\"unix\")");
vim.command("set tag='" + os.path.join(rootVariable, "mytags") + "'");

if (not "_backup" in rootVariable):
    backupFolder = os.path.join(os.path.join(rootVariable, ".."), "_backup_" + os.path.basename(rootVariable) + "_" + md5.new(rootVariable).hexdigest())
    if (not os.path.exists(backupFolder)):
        os.makedirs(backupFolder)
    vim.command("set backupdir=" + backupFolder + ",.")
    vim.command("set backup")
EOF

cabbrev wc w<CR>:!python3 $myEnvFolder/fly_check.py  %:p
nnoremap <leader>cr :!taskkill /F /IM olyncsubmit.exe & rd /s /q \%userprofile\%\\olyncsubmit & robocopy /e  \%userprofile\%\\olyncsubmit_\%_PROJECT_\% \%userprofile\%\\olyncsubmit & \\\\OCGCFILE1\\Public\\yuboxie\\OLyncSubmit\\public\\Launcher\\OLyncSubmitLauncher.exe
nnoremap <leader>ie :silent !perl \%INIT\%\\launchexe.pl IE<CR>
nnoremap <leader>sf :silent !perl \%INIT\%\\launchexe.pl Safari<CR>
nnoremap <leader>fx :silent !perl \%INIT\%\\launchexe.pl FireFox<CR>
nnoremap <leader>vs :silent !pushd. & cd /d \%ROOT\%\\dev\\server\\lcs\\admin\\TenantAdminUI\\ & Admin.sln &  popd<CR>

set dictionary+=$VIMRUNTIME/../dictionary.txt
"remove the preced '/' or '\'
"\\ means \ because of escape
set includeexpr=substitute(v:fname,'^\\(\\/\\\\|\\\\\\)','','') 
let $path=$path . ";" . $VIM . "\\UnxTools"
let $path=$path . ";" . $VIM . "..\\..\\GnuWin32\\bin"
let $path=$VIMRUNTIME . ";" . $path
let $path=$path . ";" . "%programfiles%\\Haskell Platform\\2012.2.0.0\\bin"
set path+=%ROOT%\dev\server\lcs\admin\TenantAdminUI\**
set path+=%ROOT%\dev\server\lcs\admin\Setup\**
set path+=%ROOT%\test\server\stress_performance\VStools\**
set path+=%ROOT%\test\common\**
set path+=%ROOT%\test\server\common\**

"we select it as objc instead of matlab
let g:filetype_m = 'objc'
"let g:acp_completeOption = '.,w,b,i,d'
let g:acp_ignorecaseOption = 0
let g:haddock_browser= $programfiles . "\\Internet Explorer\\iexplore.exe"
let g:haddock_docdir= $programfiles . "\\Haskell Platform\\2012.2.0.0\\doc\\html"

" disable load auto include.
" Disable it because it need ruby.
let g:loaded_cpp_auto_include = "true"

" auto import the python3 module.
let g:PythonAutoAddImports = 0


let g:VCSCommandMappings = [
			\['a', 'VCSAdd'],
			\['D', 'VCSDelete'],
			\['d', 'VCSDiff'],
			\['G', 'VCSClearAndGotoOriginal'],
			\['l', 'VCSLog'],
			\['N', 'VCSSplitAnnotate'],
			\['n', 'VCSAnnotate'],
			\['q', 'VCSRevert'],
			\['u', 'VCSUpdate'],
			\['v', 'VCSVimDiff'],
			\]

let g:swap_lists = [
            \{'name':'bool_operator', 'options': ['||','&&']},
            \{'name':'and/or', 'options': ['and','or']},
            \{'name':'continue/break', 'options': ['continue','break']},
            \{'name':'private/public/protected', 'options': ['public','private','protected']},
            \{'name':'svn_status', 'options':['added', 'unversioned', 'missing', 'deleted']},
            \{'name':'pointer', 'options':['->', '.']},
            \]
"disable netrw plugin because it make vim a folder super slow.
let g:loaded_netrw       = 1
let g:loaded_netrwPlugin = 1
"for DirDiff
let g:DirDiffExcludes = "obj,debug,bin,*.dll,*.log,*.prf,*.trc,*.wrn,*.err,*.pdb,*.exe,*~"
"for buffers_search_and_replace plugin
let g:Bs_auto_jump = 1 
"for NERDComment
let NERDCommentWholeLinesInVMode=1
"The default is 200, not engough
let g:fuf_mrufile_maxItem=500
let g:fuf_file_exclude = '\v\~$|\.(o|exe|dll|bak|orig|swp|svn\.log)$|(^|[/\\])\.(hg|git|bzr)($|[/\\])'
"for FufFind to enable MruFile and MruCmd mode
let g:fuf_modesDisable = [] 
"for YankRing
let g:yankring_enabled = 0  " Disables the yankring
"for ShowMark
let g:showmarks_include = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
" for AmbiCompletion
set completefunc=g:AmbiCompletion
noremap <leader>smt <Plug>ShowmarksShowMarksToggle
noremap <leader>smo <Plug>ShowmarksShowMarksOn
noremap <leader>smd <Plug>ShowmarksClearMark
noremap <leader>smc <Plug>ShowmarksClearAll
noremap <leader>smp <Plug>ShowmarksPlaceMark

"scroll four lines down, so we can see the function header.
noremap [[ [[kkkkjjj

"for easy motion
hi EasyMotionTarget ctermbg=none ctermfg=green
hi EasyMotionShade  ctermbg=none ctermfg=blue


" this script need to be full tested before check-in.
let g:fuf_dataDir = JoinPath($ROOT, "fuf")
let backupFolder = $ROOT .  "/_backup_/"
if (!isdirectory(backupFolder))
    silent execute "!mkdir " . backupFolder
endif
execute "set backupdir=" . backupFolder . ",."
set backup

let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

map class /\(^\s*\<BAR>public\<BAR>internal\<BAR>private\<BAR>static\<BAR>partial\)\s*class/gj<CR> 0gg n
map method ?private\\|public\\|protected\\|procedure\\|function\\s\\+\\.*(<CR>
" Map Y to act like D and C.
map Y y$

imap jj <ESC>
nnoremap <Down> gj
" doesn't go to next item when press *
nnoremap * *N
nnoremap j gj
nnoremap k gk
nnoremap <Up>   gk
nnoremap <Left> :w!<CR>:bn<CR>
nnoremap <Right> :w!<CR>:bp<CR>

nnoremap <Space> <C-F>
nnoremap <S-Space> <C-B>
nnoremap <C-Space> <C-W><C-W>

" format operator
noremap  <leader>fo :call FormatSpace()<CR>
vnoremap <leader>fo :call FormatSpace()<CR>

noremap  <leader>rt :set expandtab<CR>:retab<CR>:w!<CR>
vnoremap <leader>yk :y+<CR>
nnoremap <leader>yk :y+<CR>
nnoremap <leader>ps "+]p
nnoremap <leader>qf :copen<CR>

nnoremap <leader>cd f;xo{<CR>}<ESC>

" declaration, copy the declaration to .h file, later may support to .cpp/.cc
" file.
nnoremap <leader>de :call Declaration()

"jump to next file
nnoremap <leader>nf :call JumpToPreviousNextFile(1)<CR>
nnoremap <leader>pf :call JumpToPreviousNextFile(0)<CR>

" for programming languages using a semi colon at the end of statement.
nmap <silent> <leader>; :call <sid>appendsemicolon()<cr>
vmap <silent> <leader>; :call <sid>appendsemicolon()<cr>

vmap <C-A> :s#\d\+#\=submatch(0) + 1#g<CR>
vmap <C-X> :s#\d\+#\=submatch(0) - 1#g<CR>

map <leader>ma :make<CR>
map <leader>ms :lcd \%ROOT\%\dev\server\lcs\admin\TenantAdminUI\ScriptSharp\<CR>:make<CR>

" override existing gf
nnoremap gf :call GotoFile()<CR>
nnoremap <leader>gf :call GotoFile()<CR>
"Open for file, the <leader>pf has been used by JumpToPreviousNextFile
noremap  <leader>cf :call OpenClipFileList()<CR>
nnoremap <leader>of :call PromptForFile()<CR>
nnoremap <leader>ni :call SearchText(expand("<cword>"))<CR>
vnoremap <leader>ni :call SearchText(GetLastVisualSelectText())<CR>
" Only this window
nnoremap <leader>ow :only<CR>

" set the hilight color inside the command map, so some plugin clear the hi when switch file and we still work.
nnoremap + :hi SecondSearchKeyWord term=bold ctermbg=DarkYellow ctermfg=black gui=bold<CR>:syntax clear SecondSearchKeyWord<CR>:syntax match SecondSearchKeyWord /\<<C-R><C-W>\>/<CR>
nnoremap _ :hi ThirdSearchKeyWord term=bold ctermbg=lightcyan ctermfg=black gui=bold<CR>:syntax clear ThirdSearchKeyWord<CR>:syntax match ThirdSearchKeyWord /\<<C-R><C-W>\>/<CR>
nnoremap & :hi FourthSearchKeyWord term=bold ctermbg=lightgreen ctermfg=black gui=bold<CR>:syntax clear FourthSearchKeyWord<CR>:syntax match FourthSearchKeyWord /\<<C-R><C-W>\>/<CR>
hi link SecondSearchKeyWord SecondSearchKeyWord
hi link ThirdSearchKeyWord ThirdSearchKeyWord
hi link FourthSearchKeyWord FourthSearchKeyWord

"nnoremap ; :
"nnoremap : ;
nnoremap <leader>s :w!<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>
nnoremap <leader>O :only<CR>
nnoremap <leader><  :<C-U>execute ".,.+" . v:count . " left"<CR>
vnoremap <leader><  :left<CR>
nnoremap g* #*
nnoremap ' `
nnoremap ` '

map <F1><F1> <ESC>0ggVG=
" doens't work when the cursor line num < 10 or > $ - 10
map <F1> <ESC>ma10kV20j=10j'a
" Current file
map <F3> :clo

nmap <silent> <F3> :call ToggleList("Quickfix List", 'c')<CR>
" using " to make < > doesn't need escape because dos
map <F4> :grep! -R -H -n -m 5000 -I --exclude=mytags --exclude=*.err --exclude=*.wrn --exclude=*.log --exclude=*.dll --exclude=*.pdb --exclude=*.exe --exclude=*~ -e "\<<C-R><C-W>\>" *<CR>:copen<CR>
map <F5> :grep! -R -H -n -m 5000 -I --exclude=mytags --exclude=*.err --exclude=*.wrn --exclude=*.log --exclude=*.dll --exclude=*.pdb --exclude=*.exe --exclude=*~ -e "\<<C-R><C-W>\>" *
" make sure the cursor in the file content window by append <C-W>w.
map <F6> :call Toggle_NERDTree_and_chang_dir()<CR><C-W>w

if ($REMOTE_SHELL == "" || $REMOTE_SHELL_PORT == "")
    if (has("mac") || has("unix"))
        map <F7> :silent !open "http://www.google.com.hk/search?q=<C-R><C-W>"<CR>:redraw!<CR>
        map <F7><F7> :silent !open "http://developer.apple.com/library/mac/search?q=<C-R><C-W>"<CR>:redraw!<CR>
    else
        map <F7> :silent !explorer "http://www.google.com.hk/search?q=<C-R><C-W>"<CR>
    endif
else
    map <F7> :!python3 $myEnvFolder/remote_command_agent.py  openurl http://www.google.com.hk/search?q=<C-R><C-W><CR>
endif

map <F8> :call Go_though_all_diff()<CR>
map <F9> :silent !cp <C-R>=expand("%:p")<CR> /Users/zjwu/code/cmad2/source/mp/MediaProcessor/SWEP/Mac
"map <F9> @q
map <F10> :call Add_To_Sources()<CR>
map <F11> :lcd ..\..\.. <CR> :grep! -R -H -n -m 5000 -I --include=*.wxs -e "\<<C-R><C-W>\>" *<CR>:copen<CR>
map <F12> :cn<CR>zO
map <S-F12> :cp<CR>zO

map <leader>xd :!"c:\Program Files\Microsoft SDKs\Windows\v7.0A\Bin\xsd.exe" /classes /namespace:FrontEnd.Schema /out:%:p:h %
map <leader>sv :!start cmd /c sdv %<CR>

"got the file log list.
map <leader>lg :!start cmd /c cd %:p:h<CR>:let filename = expand("%")<CR>:vsplit %.svn.log<CR>:normal "0ggVGd"<CR>:execute "silent read !svn log " . filename<CR>
map <leader>df :call VersionDiff()<CR>

map <leader>da :!start cmd /c windiff -lo ...<CR>
" for rf, we should not too smart and try to find it in filelist, we may got
" revert wrong file.
map <leader>rf :!python3 $myEnvFolder/source_control_util.py -a revert_local -f <C-R>=NormalizeFilePath(expand("<cfile>"))<CR><CR>
map <leader>rv :setlocal autoread<CR>:!python3 $myEnvFolder/source_control_util.py -a revert_local -f %<CR>
map <leader>ol :silent !sd online %<CR> 
map <leader>sy :silent !sd sync %<CR> 

"Lets put this into the diff filetype plugin after we have enough feature and
"diff related code
map <leader>ri :call RemoveDiffItem()<CR>

"Pick text
nnoremap <leader>pt "Pyiw:let @P=@P ."\n"<CR>
vnoremap <leader>pt "Py:let @P=@P ."\n"<CR>

"Copy current file path, mac vim may doesn't have register + support
if (has("mac") || has("unix"))
    "We redraw it, because there is a bug vim on mac platform, it doesn't refresh screen after execute external command
    nnoremap <leader>cp :execute "silent !echo " . shellescape(expand("%:p")) . " \| pbcopy"<CR>:redraw!<CR>
else
    nnoremap <leader>cp :let @+ = expand("%:p")<CR>
endif

"Open or close tag list
noremap <leader>tlt  :TlistToggle<CR>

"Test binary
map <leader>tb :silent !perl  \%ROOT\%\test\server\management\LyncAdminTest\tools\copybinary.pl d:\tb<CR>:silent !cmd /C start d:\tb<CR>
map <leader>db :silent !cmd /C start \%_NTTREE\%\dev\server\TenantAdminUI\<CR>
map <leader>ff :FufFile<CR>
map <leader>fb :FufBuffer<CR>
map <leader>fm :FufMruFile<CR>
map <leader>fd :FufDir<CR>
map <leader>fn :FufRenewCache<CR>
" inline edit (edit inline to not conflict with launch browser ie)
map <leader>ei :InlineEdit<CR>
"tags multi tag version of C-]
map <C-\> :execute "tselect " . expand("<cword>")<CR>

"first to copy to make sure the cursor is on the first letter of the word.
nmap <leader>sw "_yiw:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<CR>
nmap <leader>sW "_yiW:s/\(\%#\S\+\)\(\_W\+\)\([^ ;]\+\)/\3\2\1/<CR>
"Switch parameter of function simple version, doesn't handle complex
"parameter.
nmap <leader>s, :s/\([^,()]*\%#[^,()]*\)\s*,\s*\([^,()]\+\)/\2, \1/<CR>

map <leader>tc <ESC>~h
map <leader>r\ :s/\\/\//g<CR>%
map <leader>r/ :s/\//\\/g<CR>
map <leader>es :s/\(["\\]\)/\\\1/g<CR>
"escape string data.
map <leader>ess :s/^\([^"]*\)"/\1####/g<CR>:s/"\([^"]*\)$/####\1/g<CR>:s/\(["\\]\)/\\\1/g<CR>:s/####/"/g<CR>

map <leader>ue :s/\\\(["\\]\)/\1/g<CR>
" peek the output of last external command.
map <leader>bg :!echo<CR>
map <leader>sh :shell<CR>
map <leader>ru :silent !cmd /c start %:p<CR>
"remove header
map <leader>rh :execute "!python3 \"$myEnvFolder\"/update_func_header.py % remove " . line('.')<CR>
"add header
map <leader>ah :execute "!python3 \"$myEnvFolder\"/update_func_header.py % add " . line('.')<CR>

if (has("mac") || has("unix"))
    "redraw it on mac, because the vim has a bug of not refresh screen after execute external command
    map <leader>ex :silent !open %:h<CR>:redraw!<CR>
    map <leader>bk :silent !python3 "$VIMRUNTIME"/../PerlTools/file_backup_service.py % backup<CR>
    map <leader>rs :silent !python3 "$VIMRUNTIME"/../PerlTools/file_backup_service.py % restore<CR>
else
    map <leader>ex :silent !cmd /c start %:h<CR>
    map <leader>bk :silent !python3 "\%VIMRUNTIME\%"\..\PerlTools\file_backup_service.py % backup<CR>
    map <leader>rs :silent !python3 "\%VIMRUNTIME\%"\..\PerlTools\file_backup_service.py % restore<CR>
endif

"for auto close. we doesn't auto complete "]" to let the auto complete [] for objective-c works.
let g:AutoClosePairs = {'(': ')', '{': '}', '"': '"', "'": "'"}

map <Leader>er :ErrorAtCursor<CR>
map <leader>rn :call RenameLocalSym()<CR>
" set the minimaize the indent
map <leader>mi :set shiftwidth=2<CR>:set tabstop=2<CR>
" partial revert (conflit with perl run).
map <leader>plr :call CopyFile(expand("%"), expand("%").".bak")<CR>:setlocal autoread<CR>:silent !!python3 \"$myEnvFolder\"/source_control_util.py revert_local %:p<CR>:vertical diffsplit %.bak<CR>

"Surround p with {
nnoremap <leader>sp :call RemoveTailSpace()<CR>j1{o{<ESC>lx1}i}<ESC>o<ESC>k>i}1{
"delete surround
nnoremap <leader>ds :call RemoveTailSpace()<CR><i{[{ma%mb'bdd'add

" for visual  mode
vnoremap <leader>if cif_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>el cel_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>foreach cforeach_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>do cdo_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>wh cwh_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>for cfor_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>forr cforr_reg<C-R>=TriggerSnippet()<CR>
vnoremap <leader>try ctry_reg<C-R>=TriggerSnippet()<CR>
" for normal mode.
nnoremap <leader>if ccif_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>el ccel_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>foreach ccforeach_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>do ccdo_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>wh ccwh_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>for ccfor_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>forr ccforr_reg<C-R>=TriggerSnippet()<CR>
nnoremap <leader>try cctry_reg<C-R>=TriggerSnippet()<CR>


"Change namespace <xxx> as using xxx.namespace;
map <leader>un :call RemoveTailSpace()<CR>^ciw    using<ESC>$a;<ESC>:call NormalizeNamespace()<CR>
map <leader>nn :call NormalizeNamespace()<CR>

command WeeklyReport call WeeklyReport()
function WeeklyReport()
    :g/Pending Verifi/m $
    :v/Zijing/d
    :g/Zijing WU update/d
    :g/Zijing WU started progress/d
    :g/Zijing WU change the Summary/d
endfunction

command -nargs=1 LoadReg call LoadReg("<args>")
command -nargs=1 SaveReg call SaveReg("<args>")
command -range Reverse call ReverseLine()

command Kill !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl kill
command Buildmp !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl buildmp
command Rebuildmp !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rebuildmp
command Buildrpd !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl buildrpd
command Rebuildrpd !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rebuildrpd
command Cleanappdata !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl cleanappdata
command Windbg !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl windbg
command Copydir !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl copydir
command Rebuildcmadmp !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rebuildcmadmp
command Buildcc !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl buildcc
command Rebuildcc !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rebuildcc
command HotbuildRPD !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl hotbuildRPD
command Buildother !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl buildother
command Buildchannel !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl buildchannel
command Rebuildchannel !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rebuildchannel
command Reloadcue !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl reloadcue
command Ewindbg !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl ewindbg
command Rpdsln !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rpdsln
command Rpd !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl rpd
command Copybinforsln !perl "\%VIMRUNTIME\%"\..\PerlTools\alias_command.pl copybinforsln


"Alternative file
map <leader>af :call AlternativeFile()<CR>
"delete duplicate
map <leader>dd :g/^/kl\|if search('^'.escape(getline('.'),'\.*[]^$/').'$','bW')\|'ld<CR>
"merge conflict
map <leader>me :/++++++++++++++++++++++/<CR>

"map <leader>ut :silent !ctags -f \%ROOT\%\\mytags --recurse=yes --langdef=keyvaluepaires --langdef=css --langmap=keyvaluepaires:.strings.ini --langmap=css:.css --regex-css=/^.*\.([a-zA-Z0-9_-]+)\s.*$/\1/ --regex-keyvaluepaires=/^\s*([a-zA-Z0-9_-]+)\s*=.*$/\1/ \%ROOT\%\\dev\\server\\lcs\\admin\\tenantadminui \%ROOT\%\\test\\server\\management \%ROOT\%\\test\\common<CR>
"map <leader>ut :silent !ctags -f \%ROOT\%\\mytags --recurse=yes --langdef=keyvaluepaires --langdef=css --langmap=keyvaluepaires:.strings.ini --langmap=css:.css --regex-css=/^.*\.([a-zA-Z0-9_-]+)\s.*$/\1/ --regex-keyvaluepaires=/^\s*([a-zA-Z0-9_-]+)\s*=.*$/\1/ \%ROOT\%\\dev\\server\\lcs\\admin\\tenantadminui <CR>

if (has("mac") || has("unix"))
	map <leader>ut :silent !call "$myEnvFolder"/update_ctag_index.cmd<CR>
	"Update file list.
	map <leader>uf :silent !call "$myEnvFolder"/update_file_list.cmd<CR>
	"Update nani index file
	map <leader>un :silent !call "$myEnvFolder"/update_nani_index.cmd<CR>
	" Update cscope data base
	map <leader>uc :silent cd $ROOT<CR>:silent !cscope -i filelist.filtered<CR>
	
else
	map <leader>ut :silent !call "\%myEnvFolder\%"\update_ctag_index.cmd<CR>
	"Update file list.
	map <leader>uf :silent !call "\%myEnvFolder\%"\update_file_list.cmd<CR>
	"Update nani index file
	map <leader>un :silent !call "\%myEnvFolder\%"\update_nani_index.cmd<CR>
	" Update cscope data base
	map <leader>uc :silent cd \%ROOT\%<CR>:silent !cscope -i filelist.filtered<CR>
endif

"if (!has("unix"))
"cs add \%ROOT\%\\cscope.out \%ROOT\%
"else
"cs add $ROOT\\cscope.out $ROOT
"endif
cs add $ROOT/cscope.out $ROOT

"cscope
"Add g<C-]> g<C-\> for similar as ctags.
map g<C-]> :cs find c <C-R>=expand("<cword>")<CR><CR>
map g<C-\> :cs find g <C-R>=expand("<cword>")<CR><CR>
map <leader>ss :cs find s <C-R>=expand("<cword>")<CR><CR>
map <leader>sg :cs find g <C-R>=expand("<cword>")<CR><CR>
map <leader>sc :cs find c <C-R>=expand("<cword>")<CR><CR>
map <leader>st :cs find t <C-R>=expand("<cword>")<CR><CR>
map <leader>se :cs find e <C-R>=expand("<cword>")<CR><CR>
map <leader>sf :cs find f <C-R>=expand("<cfile>")<CR><CR>
map <leader>sd :cs find d <C-R>=expand("<cword>")<CR><CR>

map <C-=> <C-W>}

"find code
map <leader>fs :call FindSym("g")<CR>
map <leader>ft :call FindSym("t")<CR>
function FindSym(type)
    let a:name = input("Find symbole/text:")
    if (a:name != "")
        "echo ":cs find " . a:type . " " .  a:name
        exe ":cs find " . a:type . " " .  a:name
    endif
endfunction

"perl edit
map <leader>pe :call ScriptEdit("", ".pl")<CR>
map <leader>ae :call ScriptEdit("", ".awk")<CR>
"perl new
map <leader>pn :call ScriptEdit("force", ".pl")<CR>
map <leader>an :call ScriptEdit("force", ".awk")<CR>
"perl run
map <leader>pr :call ScriptRun("perl", ".pl")<CR>
map <leader>ar :call ScriptRun("awk -f", ".awk")<CR>
map <leader>sl :!dir /s d:\Scripts\*.pl d:\Scripts\*.awk<CR>

"<CR>
" Map Y to act like D and C.
map Y y$

command Buildmeta e $ROOT\dev\buildmeta.txt
command Policymap e $ROOT\dev\server\lcs\admin\Setup\Sources\OCOnline\Provision\PolicyDoc\DefaultPolicyMap.xml
command Testmix e $ROOT\test\common\tools\uctest\lcstestsuites.xml
command Host e $SystemRoot\system32\drivers\etc\hosts
command Createpolicy e $ROOT\dev\server\lcs\admin\Setup\Sources\OCOnline\Provision\PolicyDoc\CreateCOPolicies.ps1
command Vimrc e $VIMRUNTIME\..\_vimrc
command Copytest !perl \%ROOT\%\test\server\management\lyncadmintest\tools\copybinary.pl d:\tmp
command Cue e $CUE\cue.pri

iab cls  class
iab Mic  Microsoft
iab Man  Management
iab Pro  Provider
iab Exc  Exception
iab jav  javascript
iab pub  public
iab inte internal
iab pri  private
iab tish this
iab tihs this
iab addSubView addSubview
iab hte  the
iab teh  the
iab u.   Utilities.

iab TODO  TODO by zijwu
iab #b   /*********************************************
iab #e    **********************************************/

iab REGSCRIPTB this.Page.ClientScript.RegisterClientScriptBlock(TYPE, ID, BLOCK, true);
iab GLO Globalization
iab LOC Localization

iab STYLESHEETREF <ocs:StyleSheetRef ID=# runat="server" StyleUrl=# />
iab JAVASCRIPTREF <ocs:JavaScriptRef ID=# runat="server" ScriptUrl=# />
iab TABLE <table class=# cellpadding="0" cellspacing="0">
iab TR <tr></tr>
iab TD <td class=#></td>                        
iab DIV <div class=#></div>
iab SPAN <span class=#></span>
iab UL <ul class=#></ul>
iab LI <li>
iab IFREAME <iframe id="iframeUpload" style="display: none;" runat="server"></iframe>
iab SCRIPT <script type="text/javascript"></script>
iab RADIOBUTTON <ocs:RadioButton ID=# runat="server" onclick=# />
iab LABEL <ocs:Label runat="server" ID=# Text=# CssClass=# meta:resourceKey=# />
iab HYPERLINK <ocs:HyperLink runat="server" ID=# Text=# Target=# meta:resourceKey=#/>
iab BUTTON <ocs:Button runat="server" ID=# OnClick=# />
iab ALERTBAR <ocs:AlertBar runat="server" ID=# Visible="false" />
iab REGISTER <%@ Register TagPrefix="ocs" Namespace=# Assembly=# %>
iab INPUT <input type="file" id=# name=# onchange=# />                      
iab BUTTON <ocs:Button ID=# OnClientClick=# Text=# runat="server" meta:resourceKey=# ></box:Button>

au BufEnter * call MyLastWindow()
"Still get error if no fold, so comments it out
"au BufEnter *.cs execute "try | normal zO | endtry"
autocmd BufNewFile *.pl :r $VIMRUNTIME\..\vimfiles\skeleton\perl.skeleton | normal "0gg"

autocmd BufEnter *.hs :set makeprg=ghc\ %

autocmd BufEnter *.py :set equalprg=python3\ $myEnvFolder/tools/PythonTidy/PythonTidy.py
autocmd BufWritePre * call MyRollingBackup()

function! MyRollingBackup()
python3 << EOF
import os
import vim
import md5
import shutil
sys.path.append(os.environ['myEnvFolder'])
import util
import ConfigManager

#By default val
rootVariable = util.getEnv('ROOT')
print(rootVariable)
if (not rootVariable or rootVariable == ""):
    rootVariable = vim.eval("expand(\"%:p:h\")")
rootVariable = rootVariable.replace("\\", "/")
vim.command("let $ROOT='" + rootVariable + "'")
rootVariable = vim.eval("$ROOT");

if (not "_backup" in rootVariable):
    backupFolder = os.path.join(os.path.join(rootVariable, ".."), "_backup_" + os.path.basename(rootVariable) + "_" + md5.new(rootVariable).hexdigest())
    backupFolder = os.path.normpath(backupFolder)
    if (not os.path.exists(backupFolder)):
        os.makedirs(backupFolder)
    currentFilePath = vim.eval("expand(\"%:p\")")
    currentFileName = vim.eval("expand(\"%\")")
    currentFileName = os.path.basename(currentFileName)
    backupMetaFile = os.path.join(backupFolder, currentFileName + ".backup_meta")
    lastBackupIndex = -1 
    lines = []
    if (os.path.isfile(backupMetaFile)):
        lines = util.getLinesWithoutLineEnd(backupMetaFile)
    if (len(lines) > 0):
        lastBackupIndex = int(lines[0])

    nextBackupIndex  = lastBackupIndex + 1
    nextBackupIndex = nextBackupIndex % 20
    backupFilePath = os.path.join(backupFolder, currentFileName + "." + str(nextBackupIndex))

    if (os.path.isfile(backupFilePath)):
        os.unlink(backupFilePath)
    shutil.copyfile(currentFilePath, backupFilePath)
    util.writeSmallFileAsString(backupMetaFile, util.concateLines([str(nextBackupIndex)]))
EOF
endfunction

function! MyLastWindow()
  " if the window is quickfix go on
  if &buftype=="quickfix" || &buftype=="help" || &diff
    " if this window is last on screen quit without warning
    if winbufnr(2) == -1
      quit
    endif
  endif
endfunction

let g:scriptFiles = {} 
function ScriptEdit(force, extension)
    let toolsFolder = "d:\\Scripts\\"
    let currentFileName = expand("%")

    if (tolower(a:force) == "force" || !has_key(g:scriptFiles, a:extension))
        let g:scriptFiles[a:extension] = ""
    endif

    " Current file is perl file, run it, else create one in file map.
    if (g:scriptFiles[a:extension] == "")
        let fileName = input("The file name(". a:extension. "):")
        if (fileName == "")
            return
        endif
        " append ".pl" if user doesn't input.
        if (match(fileName, a:extension) != strlen(fileName) - strlen(a:extension))
            let fileName = fileName . a:extension
        endif
        let g:scriptFiles[a:extension] = toolsFolder.fileName
    endif
    let x=input("new ". g:scriptFiles[a:extension])
    execute "new " . g:scriptFiles[a:extension]
endfunction
function ScriptRun(command, extension)
    " Goto the next window.
    if (!has_key(g:scriptFiles, a:extension) || g:scriptFiles[a:extension] == "")
        echo "There is not script."
        return
    endif
    execute "%!". a:command. " " . g:scriptFiles[a:extension]
endfunction

"autocmd BufWrite * silent !attrib -R %

function Toggle_NERDTree_and_chang_dir()
    "" Check if NERDTree is open
    if exists("t:NERDTreeBufName")
        let s:ntree = bufwinnr(t:NERDTreeBufName)
    else
        let s:ntree = -1
    endif
    if (s:ntree != -1)
        "" If NERDTree is open, close it.
        :NERDTreeClose
    else
        "" Open NERDTree in the file path
        :NERDTreeFind
    endif
endfunction

" change this. to this->
imap . <C-R>=AccessOperatorCheck(".")<CR>
imap -> <C-R>=AccessOperatorCheck("->")<CR>
" TODO by zijwu, handle the *this. case
function AccessOperatorCheck(text)
    if (&ft ==? "cpp" || &ft ==? "c")
        let lineText = getline('.')
        let cursorPos = getpos(".")
        "1 based instead of zero based.
        let col = cursorPos[2]
        let beginIndex = col - 2
        while beginIndex >= 0
            let c = tolower(lineText[beginIndex])
            if ((char2nr(c) <= char2nr('z') && char2nr(c) >= char2nr('a')) || (char2nr(c) <= char2nr('9') && char2nr(c) >= char2nr('0')))
                let beginIndex = beginIndex - 1
            else
                break
            endif
        endwhile
        let word = lineText[beginIndex + 1:col - 2]
        if (word ==? "this")
            return "->"
        endif
        
        if (word ==? "")
            return a:text
        endif

        " otherwise we find int the 100+- context line to determinate it.
        let beginLine = cursorPos[1] - 100
        if (beginLine < 0)
            let beginLine = 0
        endif
        let maxLine = line("$")
        let endLine = cursorPos[1] + 100
        if (endLine > maxLine)
            let endLine = maxLine
        endif

        let pointWeight = 0
        let arrowWeight = 0
        let temp = beginLine
        while (temp < endLine)
            let tempLine = getline(temp)
            if (match(tempLine, "\\<" . escape(word . ".", ".\\")) != -1)
                let pointWeight = pointWeight + 1
            endif
            if (match(tempLine, "\\<" . escape(word . "->", ".\\")) != -1)
                let arrowWeight = arrowWeight + 1
            endif
            let temp = temp + 1
        endwhile

        if (arrowWeight - pointWeight > 2)
            return "->"
        elseif (pointWeight - arrowWeight > 2)
            return "."
        else
            return a:text
        endif
    endif
    return a:text
endfunction

function VersionDiff()
    let launchDiffScriptPath = JoinPath($myEnvFolder, "launch_diff.py")
    if expand("%") !~ "svn.log"
        execute "silent !python3 " . shellescape(launchDiffScriptPath) . " " . expand("%:p")
    else
        let targetFileName = substitute(expand("%:p"), ".svn.log", "", "g") 
        let line = line(".")
        let versionNum = -1 
        while line > 0
            if (getline(line) =~ "r\\d" && getline(line - 1) =~ "---")
                let lineStr = getline(line)
                let startIndex = stridx(lineStr, "r") + 1
                let endIndex = stridx(lineStr, " ", startIndex) - 1
                let versionNum = str2nr(lineStr[startIndex : endIndex], "10")
                break
            endif
            let line = line - 1
        endwhile

        if (versionNum == -1)
            return
        endif
        execute "silent !python3 " . shellescape(launchDiffScriptPath) . " " targetFileName . " " . versionNum
    endif
endfunction

function RemoveDuplicateLine()
    let maxLine = getpos("$")[1]
    let minLine = 0
    let temp = maxLine
    while 1
      if (temp <= minLine)
        break
      endif
      let index = minLine
      let find = 0
      while (index < temp)
        if (getline(index) == getline(temp))
           let find = 1
           break
        endif
        let index = index + 1
      endwhile

      if (find == 1)
        exec "normal " . temp . "gg"
        exec "normal dd"
      endif
      let temp = temp -1
    endwhile
endfunction


function Declaration()
endfunction

function JumpToPreviousNextFile(nextFile)
    let currentFileName = expand("%:p")
    let currentLine = line(".")
    let currentCol = col(".")
    while currentFileName == expand("%:p")
        if (a:nextFile == 1)
            exec "normal 1\<C-I>"
        else
            exec "normal \<C-O>"
        endif
        let newLine = line(".")
        let newCol = col(".")
        if (newLine == currentLine && newCol == currentCol)
            return
        endif
        let currentLine = newLine
        let currentCol = newCol
    endwhile
endfunction

function AlternativeFile()
    let extensionCircleList = [[[".aspx"], [".aspx.cs"], [".aspx.designer.cs"]], [[".ascx"], [".ascx.cs"], [".ascx.designer.cs"]], [[".xaml"], [".xaml.cs"]], [[".cc", ".cpp", ".c", ".m", ".mm"], [".h", ".hpp"]]]
                           
    let fileName = expand("%:p")
    for circle in extensionCircleList
        let matchedExtension = ""
        let index = 0
        while (index < len(circle))
            let extensionGroup = circle[index]
            for extension in extensionGroup
                if (match(fileName, escape(extension, '.') . "$") > 0)
                    let matchedExtension = extension
                endif
            endfor

            let nextIndex = index + 1
            if (index + 1 >= len(extensionGroup))
                let nextIndex = nextIndex - len(circle)
            endif
            let nextExtensionGroup = circle[nextIndex]
            if (matchedExtension != "")
                echo "matched extension" . matchedExtension
                for extension in nextExtensionGroup
                    let altFileName = substitute(fileName, escape(matchedExtension, ".")."$", extension, "")
                    if (filereadable(altFileName))
                        execute ":silent :e " . altFileName
                        return 1
                    endif
                endfor
            endif
            let index = index + 1
        endwhile
    endfor
    return 0
endfunction

function FormatParameter()
    exec "normal %%"
    exec "normal \"kdi("
    let pos = getpos(".")
    let col = pos
    let parameters = @k 
    let lines = split(parameters, ",\zs\n\S*")
    let firstParam = remove(lines, 0)
    normal "i" . firstParam . "\r"
    let restParams = ""
    for line in lines
        restParams = restParams . "\r" . line
    endfor
    let restParams = Indent(line, repeat(" ", col))
    normal "i" . restParams
endfunction

function RemoveTailSpace()
    normal ma
    :%s/^\s\+$//ge
    normal 'a
endfunction

function Trim(str)
    return substitute(a:str, "^\\s\\+\\|\\s\\+$", "", "g")
endfunction

" if there isn't one, append a semi colon to the end of the current line.
function s:appendsemicolon()
    let original_cursor_position = getpos('.')
    " for python3, we append : instead.
    if &ft == "python"
        if getline('.') !~ ':$'
            exec("s/$/:/")
        else
            exec("s/:\s*$//")
        endif
    else
        if getline('.') !~ ';$'
            exec("s/$/;/")
        else
            exec("s/;\s*$//")
        endif
    endif 
    call setpos('.', original_cursor_position)
endfunction

"Remove indent for text, it doesn't handle the \t charactor
function RemoveIndent(text)
    "echo "->" . a:text . "<-"
    let line = ""
    let minLeadingSpaceLen = 1000
    for line in split(a:text, "\n")
      " Only do non-blank lines.
      if (line =~ '^\\s*$')
          continue
      endif

      let leadingSpace = matchstr(line, "\\s*")
      if (strlen(leadingSpace) < minLeadingSpaceLen)
          let minLeadingSpaceLen = strlen(leadingSpace)
      endif
    endfor
    "echo "->" . minLeadingSpaceLen . "<-"

    let result = ""
    for line in split(a:text, "\n")
      " Only do non-blank lines.
      if (line =~ '^\\s*$')
          let line = ""
      endif
      let line = strpart(line, minLeadingSpaceLen)
      if (result == "")
          let result = line
      else
          let result = result . "\n" . line
      endif
    endfor
    "echo "->" . result . "<-"
    return result
endfunction

"add indentStr to each line of text
function Indent(text, indentStr)
    "echo "->" . a:text . "<-"
    "echo "->" . a:indentStr . "<-"
    let result = ""
    let line = ""
    for line in split(a:text, "\n")
      "echo "->" . line . "<-"
      " Only do non-blank lines.
      if !(line =~ '^\\s*$')
          let line = a:indentStr . line
      endif
      if (result == "")
          let result = line
      else
          let result = result . "\n" . line
      endif
    endfor
    "echo "->" . result . "<-"
    return result
endfunction

function NormalizeNamespace()
    let minNum = line(".")
    let maxNum = line(".")
    let totalLines = line("$")

    while (minNum > 0)
        let minNum = minNum - 1
        let line = getline(minNum)
        let trimedLine = Trim(line)
        if (strlen(trimedLine) > 0 && stridx(trimedLine, "using") != 0)
            break
        endif
    endwhile

    while (maxNum < totalLines)
        let maxNum = maxNum + 1
        let line = getline(maxNum)
        let trimedLine = Trim(line)
        if (strlen(trimedLine) > 0 && stridx(trimedLine, "using") != 0)
            break
        endif
    endwhile

    "Separate the System namespace and other space.
    let systemNamespace = []
    let userNamespace = []
    let index = minNum
    while (index < maxNum - 1)
        let index = index + 1
        let line = getline(index)
        let trimedLine = Trim(line)
        if (strlen(trimedLine) == 0)
            continue
        endif 

        let trimedLine = substitute(trimedLine, ";", "", "g")
        if (stridx(trimedLine, " System") >= 0)
            call add(systemNamespace, trimedLine)
        els
            call add(userNamespace, trimedLine)
        endif
    endwhile
    execute printf("%d", minNum + 1) . "," . printf("%d", maxNum - 1) . "d"
    call sort(systemNamespace)
    call sort(userNamespace)

    "append back the ';'
    call map(systemNamespace, 'v:val . ";"')
    call map(userNamespace, 'v:val . ";"')

    call append(minNum, "")
    call append(minNum, userNamespace)
    call append(minNum, "")
    call append(minNum, systemNamespace)
    execute "normal " . printf("%d", minNum + 1) . "gg" . printf("%d", len(userNamespace) . len(systemNamespace) + 1) . "=="
endfunction

au VimEnter * nested call GotoLastOpenFile()
au VimLeavePre * call SaveLastOpenFile()
function SaveLastOpenFile()
    let lastEditFile = expand("%:p")
    if (lastEditFile == "")
        return
    endif
    call writefile([lastEditFile], JoinPath($ROOT, "_last_edit_file_"))
endfunction

function GotoLastOpenFile()
    " launch vim by editing one file
    if (expand("%:p") != "")
        return
    endif

    " cannot found lastEditFile
    let filePath = JoinPath($ROOT, "_last_edit_file_")
    if (!filereadable(filePath))
        return
    endif

    let line = readfile(filePath, '', 1)

    if (empty(line))
        return
    endif
    exec ":e " . line[0]
endfunction

function! GetBufferList()
  redir =>buflist
  silent! ls
  redir END
  return buflist
endfunction

function! ToggleList(bufname, pfx)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      exec(a:pfx.'close')
      return
    endif
  endfor
  if a:pfx == 'l' && len(getloclist(0)) == 0
      echohl ErrorMsg
      echo "Location List is Empty."
      return
  endif
  let winnr = winnr()
  exec(a:pfx.'open')
  if winnr() != winnr
    wincmd p
  endif
endfunction

nmap <silent> <leader>tl :call ToggleList("Location List", 'l')<CR>
nmap <silent> <leader>tq :call ToggleList("Quickfix List", 'c')<CR>

" support SCO termnal type for function key
"if &term=="vt100"
    nmap <ESC>[X <F12>
    nmap <ESC>[W <F11>
    nmap <ESC>[V <F10>
    nmap <ESC>[U <F9>
    nmap <ESC>[T <F8>
    nmap <ESC>[S <F7>
    nmap <ESC>[R <F6>
    nmap <ESC>[Q <F5>
    nmap <ESC>[P <F4>
    nmap <ESC>[O <F3>
    nmap <ESC>[N <F2>
    nmap <ESC>[M <F1>
    nmap <ESC>[M<ESC>[M <F1><F1>

nmap <ESC>[Y <S-F1>
nmap <ESC>[Z <S-F2>
nmap <ESC>[a <S-F3>
nmap <ESC>[b <S-F4>
nmap <ESC>[c <S-F5>
nmap <ESC>[d <S-F6>
nmap <ESC>[e <S-F7>
nmap <ESC>[f <S-F8>
nmap <ESC>[g <S-F9>
nmap <ESC>[h <S-F10>
nmap <ESC>[i <S-F11>
nmap <ESC>[j <S-F12>

nmap <ESC>[@ <C-Space>
"endif

"if &term=~ "xterm"
"    if has("terminfo")
"        set t_Co=8
"        set t_Sf=[3%p1%dm
"        set t_Sb=[4%p1%dm
"    else
"        set t_Co=8
"        set t_Sf=[3%dm
"        set t_Sb=[4%dm
"    endif
"endif
colorscheme elflord
