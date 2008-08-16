" TODO: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
" DEPENDENCIES:
"   - CompleteHelper.vim autoload script. 
"
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	13-Aug-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_MotionComplete') || (v:version < 700)
    finish
endif
let g:loaded_MotionComplete = 1

if ! exists('g:MotionComplete_complete')
    let g:MotionComplete_complete = '.,w'
endif

function! s:GetCompleteOption()
    return (exists('b:MotionComplete_complete') ? b:MotionComplete_complete : g:MotionComplete_complete)
endfunction

function! ExtractText( startPos, endPos )
    let l:save_cursor = getpos('.')
    let l:save_foldenable = &l:foldenable
    let l:save_register = @@
    let @@ = ''

    " Yanking in a closed fold would yield much additional text, so disable
    " folding temporarily. 
    let &l:foldenable = 0

    " Position the cursor at the start of the match. 
    call setpos('.', [0, a:startPos[0], a:startPos[1], 0])

    " Yank with the supplied s:motion. 
    " No 'normal!' here, we want to allow user re-mappings and custom motions. 
    " 'silent!' is used to avoid the error beep in case s:motion is invalid. 
    execute 'silent! normal y' . s:motion   
    let l:text = @@

    let @@ = l:save_register
    let &l:foldenable = l:save_foldenable
    call setpos('.', l:save_cursor)
    return l:text
endfunction
function! s:HasMatchesInCurrentWindow( pattern )
    "TODO
    return 0
endfunction
function! s:HasMatchesInOtherWindows( pattern )
    let l:hasMatches = 0
    let l:searchedBuffers = { bufnr('') : 1 }
    let l:originalWinNr = winnr()

    for l:winNr in range(1, winnr('$'))
	execute l:winNr 'wincmd w'

	if ! has_key( l:searchedBuffers, bufnr('') )
	    if s:HasMatchesInCurrentWindow( a:pattern )
		let l:hasMatches = 1
		break
	    endif
	    let l:searchedBuffers[ bufnr('') ] = 1
	endif
    endfor

    execute l:originalWinNr 'wincmd w'
    return l:hasMatches
endfunction
function! s:LocateStartCol()
    " This completion method is probably only used for longer matches, as
    " invoking this completion method with the querying of the {motion} isn't
    " very fast. For motions that cover many words or entire sentences, using
    " just the keyword before the cursor doesn't provide enough context. 
    " Thus, we want to narrow down the results by using as much context before
    " the cursor as possible. 

    " Locate the start of the base. 
    let l:startCol = searchpos('\S\+\s*\%#', 'bn', line('.'))[1]
    if l:startCol == 0
	let l:startCol = col('.')
    endif
"****D echomsg '****' l:startCol col('.') col('$')
    "let l:base = strpart(getline('.'), l:startCol - 1, (col('.') - l:startCol))
"****D echomsg '****' l:base
    return l:startCol
endfunction

function! s:Process( match )
    " Shorten the match abbreviation; also change (invisible) <Tab> characters
    " to 2 spaces. 
    let l:abbreviatedMatch = substitute(a:match.word, '\t', '  ', 'g')
    let l:maxDisplayLen = &columns / 2
    if len(l:abbreviatedMatch) > l:maxDisplayLen
	let a:match.abbr = EchoWithoutScrolling#TruncateTo( l:abbreviatedMatch, l:maxDisplayLen )
    endif

    return a:match
endfunction
function! s:MotionComplete( findstart, base )
    if a:findstart
	return s:LocateStartCol() - 1 " Return byte index, not column. 
    else
	let l:options = {}
	let l:options.complete = s:GetCompleteOption()
	let l:options.extractor = function('ExtractText')

	" Find matches starting with a:base; no further restriction is placed;
	" the s:motion will extract the rest, starting from the beginning of
	" a:base. 
	let l:matches = []
	call CompleteHelper#FindMatches( l:matches, '\V\<' . escape(a:base, '\'), l:options )
	call map( l:matches, 's:Process(v:val)')
	return l:matches
    endif
endfunction

function! s:MotionInput()
    call inputsave()
    let s:motion = input('')
    call inputrestore()
endfunction

inoremap <C-X><C-M> <C-O>:call <SID>MotionInput()<Bar>set completefunc=<SID>MotionComplete<CR><C-X><C-U>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
