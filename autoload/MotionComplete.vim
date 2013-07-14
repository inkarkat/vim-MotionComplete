" MotionComplete.vim: Insert mode completion for chunks covered by queried {motion} or text object.
"
" DEPENDENCIES:
"   - CompleteHelper.vim autoload script
"
" Copyright: (C) 2008-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.011	02-Oct-2012	CHG: Rework and document completion base
"				selection rules to better handle text objects
"				like "i)": Also allow non-keyword non-whitespace
"				base. Allow whitespace before the cursor.
"   			    	Change the way the functions are invoked to
"				simplify and enable building additional mappings
"				with a static motion.
"				Refactoring: Replace s:isSelectedBase with
"				s:selectedBase = [startCol, endCol] to enable
"				additional mappings that set a particular base
"				(like a custom motion "a)" that is always based
"				off the starting "(").
"	010	02-Jan-2012	Split off separate autoload script and
"				documentation.
"				Enable testing through more exposed functions.
"	009	04-Oct-2011	Move s:Process() to CompleteHelper#Abbreviate().
"	008	14-Jan-2011	FIX: Text extraction clobbered the blockwise
"				mode of the unnamed register.
"	007	03-Mar-2010	BUG: Visual / select mode mappings still used
"				old <SID>MotionComplete.
"	006	07-Aug-2009	Using a map-expr instead of i_CTRL-O to set
"				'completefunc', as the temporary leave of insert
"				mode caused a later repeat via '.' to only
"				insert the completed fragment, not the entire
"				inserted text.
"	005	09-Jun-2009	Made mapping configurable.
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
function! MotionComplete#ExtractText( startPos, endPos, matchObj )
    let l:save_cursor = getpos('.')

    " Yanking in a closed fold would yield much additional text, so disable
    " folding temporarily.
    let l:save_foldenable = &l:foldenable
    let &l:foldenable = 0

    let l:save_clipboard = &clipboard
    set clipboard= " Avoid clobbering the selection and clipboard registers.

    let l:save_reg = getreg('"')
    let l:save_regmode = getregtype('"')
    let @@ = ''

	" Position the cursor at the start of the match.
	call setpos('.', [0, a:startPos[0], a:startPos[1], 0])

	" Yank with the supplied s:motion.
	" No 'normal!' here, we want to allow user re-mappings and custom
	" motions. 'silent!' is used to avoid the error beep in case s:motion is
	" invalid.
	silent! execute 'normal y' . s:GetMotion(a:startPos[0])

	let l:text = s:CaptureText(a:matchObj)

    call setreg('"', l:save_reg, l:save_regmode)
    let &clipboard = l:save_clipboard
    let &l:foldenable = l:save_foldenable
    call setpos('.', l:save_cursor)

    return l:text
endfunction
function! s:LocateStartCol()
    if ! empty(s:selectedBase)
	" User explicitly specified base via active selection.
	return s:selectedBase[0]
    endif

    " Locate the start of the base before the cursor, according to
    " |MotionComplete-base|.
    let l:startCol = searchpos('\%(\k\+\|\k*\%(\k\@!\S\)\+\)\s*\%#', 'bnW', line('.'))[1]
    return (l:startCol == 0 ? col('.') : l:startCol)
endfunction
function! s:GetBaseText()
    let l:startCol = s:LocateStartCol()
    return strpart(getline('.'), l:startCol - 1, ((empty(s:selectedBase) ? col('.') : s:selectedBase[1]) - l:startCol))
endfunction

function! MotionComplete#MotionComplete( findstart, base )
    if a:findstart
	return s:LocateStartCol() - 1 " Return byte index, not column.
    else
	let l:options = {}
	let l:options.complete = s:GetCompleteOption()
	let l:options.extractor = function('MotionComplete#ExtractText')

	" Find matches starting with a:base; no further restriction is placed;
	" the s:motion will extract the rest, starting from the beginning of
	" a:base.
	" In case of an empty a:base, extraction is started at the beginning of
	" each keyword. This limits the completion candidates to text fragments
	" starting with a keyword and ought to help keeping a good match
	" performance. The latter is especially important for matches with text
	" objects, where a completion base is given less often, and there are
	" many duplicate matches (inside the same text object).
	" In case of automatic base selection starting with a keyword, matches
	" must start at a word border, in case of a user-selected base, matches
	" can start anywhere.
	let l:matches = []
	let l:pattern = '\V' . ((! empty(s:selectedBase) || a:base !~# '^\k') && ! empty(a:base) ? '' : '\<') . escape(a:base, '\')
	call CompleteHelper#FindMatches( l:matches, l:pattern, l:options )
	call map( l:matches, 'CompleteHelper#Abbreviate(v:val)')
	return l:matches
    endif
endfunction

function! MotionComplete#SetSelectedBase( selectedBase )
    let s:selectedBase = a:selectedBase
endfunction
function! MotionComplete#SetMotion( motion )
    let s:motion = a:motion
endfunction
function! MotionComplete#Input( selectedBase )
    " Need to set this first so that the correct base is used.
    call MotionComplete#SetSelectedBase(a:selectedBase)

    call inputsave()
	let l:motion = input('Motion to complete from "' . s:GetBaseText() . '": ')
    call inputrestore()

    return l:motion
endfunction

function! MotionComplete#Expr( motion, ... )
    call MotionComplete#SetMotion(a:motion)
    call MotionComplete#SetSelectedBase(a:0 ? a:1 : [])

    set completefunc=MotionComplete#MotionComplete
    return "\<C-x>\<C-u>"
endfunction
function! MotionComplete#GetVisualBase()
    return [col("'<"), col("'>")]
endfunction
function! MotionComplete#Selected( motion )
    call MotionComplete#SetMotion(a:motion)
    call MotionComplete#SetSelectedBase(MotionComplete#GetVisualBase())

    set completefunc=MotionComplete#MotionComplete
    return "g`>" . (col("'>") == (col('$')) ? 'a' : 'i') . "\<C-x>\<C-u>"
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
