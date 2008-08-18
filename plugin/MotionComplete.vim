" MotionComplete.vim: Insert mode completion that completes a text chunk
" determined by {motion}. 
"
" DESCRIPTION:
"   Most insert mode completions complete only the current word (or an entire
"   line), so one has to repeat |i_CTRL-X_CTRL-N| to complete the following
"   words. For longer completions, this is slow, especially because you
"   sometimes have to choose from multiple choices. 
"   The completion provided by this plugin assumes that you know a VIM motion
"   (e.g. '3e', ')' or '/bar/e') which covers the text you want completed. When
"   you invoke the completion, completion base (i.e. the keyword before the
"   cursor) will be presented and the motion to cover the completion text will
"   be queried. Then, the list of completion candidates will be prepared and
"   selected in the usual way. 
"
" USAGE:
" i_CTRL-X_CTRL-M	First query for {motion} (press <Enter> to conclude or
"			<Esc> to cancel), then finds matches starting with the
"			keyword before the cursor and covering {motion}. 
"
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
"	004	19-Aug-2008	<Tab> characters now replaced with 'listchars'
"				option value. 
"				BF: Completion capture cap cut off at beginning,
"				not at end. 
"	003	18-Aug-2008	Made /pattern/ and ?pattern? motions work. 
"				Added limits for search scope and capture
"				length. 
"	002	17-Aug-2008	Completed implementation. 
"	001	13-Aug-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_MotionComplete') || (v:version < 700)
    finish
endif
let g:loaded_MotionComplete = 1

if ! exists('g:MotionComplete_complete')
    let g:MotionComplete_complete = '.,w'
endif
" Maximum number of lines to be searched for /pattern/ and ?pattern? motions. 
if ! exists('g:MotionComplete_searchScopeLines')
    let g:MotionComplete_searchScopeLines = 5
endif
" Maximum number of characters to be captured by {motion}. 
if ! exists('g:MotionComplete_maxCaptureLength')
    let g:MotionComplete_maxCaptureLength = &columns * 3
endif

function! s:GetCompleteOption()
    return (exists('b:MotionComplete_complete') ? b:MotionComplete_complete : g:MotionComplete_complete)
endfunction

function! MotionComplete_ExtractText( startPos, endPos )
    let l:save_cursor = getpos('.')
    let l:save_foldenable = &l:foldenable
    let l:save_register = @@
    let @@ = ''

    " Yanking in a closed fold would yield much additional text, so disable
    " folding temporarily. 
    let &l:foldenable = 0

    " Position the cursor at the start of the match. 
    call setpos('.', [0, a:startPos[0], a:startPos[1], 0])

    let l:motion = s:motion
    " A '/pattern' or '?pattern' motion must be concluded with <CR> and limited
    " in scope to avoid huge captures. 
    if l:motion =~# '^[/?]'
	" Automatically limit the search scope to the next n lines to avoid that
	" HUGE amounts of text are yanked. 
	let l:motionType = strpart(l:motion, 0, 1)
	let l:line = a:startPos[0]
	let [l:boundLow, l:boundHigh] = (l:motionType == '/' ? [l:line - 1, l:line + g:MotionComplete_searchScopeLines] : [max([l:line - g:MotionComplete_searchScopeLines, 0]), l:line + 1])
	let l:scopeLimit = '\%>' . l:boundLow . 'l\%<' . l:boundHigh . 'l'

	let l:motion =  l:motionType . l:scopeLimit . strpart(l:motion, 1) . "\<CR>"
"****D echomsg '////' l:motion
    endif

    " Yank with the supplied s:motion. 
    " No 'normal!' here, we want to allow user re-mappings and custom motions. 
    " 'silent!' is used to avoid the error beep in case s:motion is invalid. 
    execute 'silent! normal y' . l:motion

    " Capture a maximum number of characters; too many won't fit comfortably
    " into the completion display, anyway. 
    let l:text = strpart(@@, 0, byteidx(@@, g:MotionComplete_maxCaptureLength))

    let @@ = l:save_register
    let &l:foldenable = l:save_foldenable
    call setpos('.', l:save_cursor)
    return l:text
endfunction
function! s:LocateStartCol()
    " This completion method is probably only used for longer matches, as
    " invoking this completion method with the querying of the {motion} isn't
    " very fast. For motions that cover many words or entire sentences, using
    " just the keyword before the cursor may result in an empty base, which
    " isn't helpful for this completion method. So instead, we include
    " mandatory keyword characters followed by optional non-keyword
    " characters before the cursor. 

    " Locate the start of the base. 
    let l:startCol = searchpos('\k\+\%(\k\@!.\)*\%#', 'bn', line('.'))[1]
    if l:startCol == 0
	let l:startCol = col('.')
    endif
    return l:startCol
endfunction
function! s:GetBaseText()
    let l:startCol = s:LocateStartCol()
    return strpart(getline('.'), l:startCol - 1, (col('.') - l:startCol))
endfunction

function! s:TabReplacement()
    if ! exists('s:tabReplacement')
	let s:tabReplacement = matchstr(&listchars, 'tab:\zs..')
	let s:tabReplacement = (empty(s:tabReplacement) ? '^I' : s:tabReplacement)
    endif
    return s:tabReplacement
endfunction
function! s:Process( match )
    " Shorten the match abbreviation; also change (invisible) <Tab> characters. 
    let l:abbreviatedMatch = substitute(a:match.word, '\t', s:TabReplacement(), 'g')
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
	let l:options.extractor = function('MotionComplete_ExtractText')

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
    let s:motion = input('Motion to complete from "' . s:GetBaseText() . '": ')
    call inputrestore()
endfunction

inoremap <C-x><C-m> <C-\><C-o>:call <SID>MotionInput()<Bar>set completefunc=<SID>MotionComplete<CR><C-x><C-u>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
