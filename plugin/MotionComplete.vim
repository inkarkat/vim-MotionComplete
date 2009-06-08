" MotionComplete.vim: Insert mode completion that completes a text chunk
" determined by {motion}. 
"
" DESCRIPTION:
"   Most insert mode completions complete only the current word (or an entire
"   line), so one has to repeat |i_CTRL-X_CTRL-N| to complete the following
"   words. For longer completions, this is slow, especially because you
"   sometimes have to choose from multiple choices. 
"   The completion provided by this plugin assumes that you know a Vim motion
"   (e.g. '3e', ')' or '/bar/e') which covers the text you want completed. When
"   you invoke the completion, completion base (the keyword before the
"   cursor, or the currently selected text) will be presented and the motion to
"   cover the completion text will be queried. Then, the list of completion
"   candidates will be prepared and selected in the usual way. 
"
" USAGE:
"							       *i_CTRL-X_CTRL-M*
" CTRL-X CTRL-M		The completion first queries for {motion} (press <Enter>
"			to conclude), then finds matches starting with the
"			keyword before the cursor, covering {motion}. 
"							       *v_CTRL-X_CTRL-M*
" {Visual}CTRL-X CTRL-M	The completion first queries for {motion} (press <Enter>
"			to conclude), then finds matches starting with the
"			selected text, covering {motion}. 
"			Use this to define the completion base text (quickly
"			done from insert mode via [CTRL-]SHIFT-<Left>) for
"			better matches. 
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
"				Completion menu now shows truncation note. 
"				Refactored MotionComplete_ExtractText(). 
"	003	18-Aug-2008	Made /pattern/ and ?pattern? motions work. 
"				Added limits for search scope and capture
"				length. 
"	002	17-Aug-2008	Completed implementation. 
"	001	13-Aug-2008	file creation

" Avoid installing twice or when in unsupported Vim version. 
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

function! s:GetMotion( line )
    " A '/pattern' or '?pattern' motion must be concluded with <CR> and limited
    " in scope to avoid huge captures. 
    if s:motion !~# '^[/?]'
	return s:motion
    else
	" Automatically limit the search scope to the next n lines to avoid that
	" HUGE amounts of text are yanked. 
	let l:motionType = strpart(s:motion, 0, 1)
	let [l:boundLow, l:boundHigh] = (l:motionType == '/' ? [a:line - 1, a:line + g:MotionComplete_searchScopeLines] : [max([l:line - g:MotionComplete_searchScopeLines, 0]), l:line + 1])
	let l:scopeLimit = '\%>' . l:boundLow . 'l\%<' . l:boundHigh . 'l'

	return l:motionType . l:scopeLimit . strpart(s:motion, 1) . "\<CR>"
    endif
endfunction
function! s:CaptureText( matchObj )
    " Capture a maximum number of characters; too many won't fit comfortably
    " into the completion display, anyway. 
    if byteidx(@@, g:MotionComplete_maxCaptureLength + 1) == -1
	return @@
    else
	" Add truncation note to match object. 
	let a:matchObj.menu = '(truncated)' . (! empty(get(a:matchObj, 'menu', '')) ? ', ' . a:matchObj.menu : '')

	return strpart(@@, 0, byteidx(@@, g:MotionComplete_maxCaptureLength))
    endif
endfunction
function! MotionComplete_ExtractText( startPos, endPos, matchObj )
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
    execute 'silent! normal y' . s:GetMotion(a:startPos[0])

    let l:text = s:CaptureText(a:matchObj)

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
    " Alternatively, the user can pre-select the base (via select or visual
    " mode) before invoking the completion. This ensures that the best context
    " for completion is chosen. 

    if s:isSelectedBase
	" User explicitly specified base via active selection. 
	let l:startCol = col("'<")
    else
	" Locate the start of the base via keyword(s) before the cursor. 
	let l:startCol = searchpos('\k\+\%(\k\@!.\)*\%#', 'bn', line('.'))[1]
	if l:startCol == 0
	    let l:startCol = col('.')
	endif
    endif

    return l:startCol
endfunction
function! s:GetBaseText()
    let l:startCol = s:LocateStartCol()
    return strpart(getline('.'), l:startCol - 1, (col((s:isSelectedBase ? "'>" : '.')) - l:startCol))
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
	" In case of automatic base selection via keyword, matches must start at
	" a word border, in case of a user-selected base, matches can start
	" anywhere. 
	let l:matches = []
	call CompleteHelper#FindMatches( l:matches, '\V' . (s:isSelectedBase ? '' : '\<') . escape(a:base, '\'), l:options )
	call map( l:matches, 's:Process(v:val)')
	return l:matches
    endif
endfunction

function! s:MotionInput(isSelectedBase)
    let s:isSelectedBase = a:isSelectedBase

    call inputsave()
    let s:motion = input('Motion to complete from "' . s:GetBaseText() . '": ')
    call inputrestore()
endfunction

inoremap <silent> <C-x><C-m> <C-\><C-o>:call <SID>MotionInput(0)<Bar>set completefunc=<SID>MotionComplete<CR><C-x><C-u>
nnoremap <expr> <SID>ReenterInsertMode (col("'>") == (col('$')) ? 'a' : 'i')
xnoremap <silent> <script> <C-x><C-m>      :<C-u>call <SID>MotionInput(1)<Bar>set completefunc=<SID>MotionComplete<CR>`><SID>ReenterInsertMode<C-x><C-u>
snoremap <silent> <script> <C-x><C-m> <C-g>:<C-u>call <SID>MotionInput(1)<Bar>set completefunc=<SID>MotionComplete<CR>`><SID>ReenterInsertMode<C-x><C-u>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
