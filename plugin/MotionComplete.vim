" MotionComplete.vim: Insert mode completion for chunks covered by queried {motion} or text object.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - MotionComplete.vim autoload script
"
" Copyright: (C) 2008-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.002	02-Oct-2012	Change the way the functions are invoked to
"				simplify and enable building additional mappings
"				with a static motion.
"	001	02-Jan-2012	Split off autoload script and documentation.
"				file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_MotionComplete') || (v:version < 700)
    finish
endif
let g:loaded_MotionComplete = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:MotionComplete_complete')
    let g:MotionComplete_complete = '.,w'
endif
if ! exists('g:MotionComplete_maxCaptureLength')
    let g:MotionComplete_maxCaptureLength = &columns * 3
endif
if ! exists('g:MotionComplete_searchScopeLines')
    let g:MotionComplete_searchScopeLines = 5
endif


"- mappings --------------------------------------------------------------------

inoremap <script> <expr> <Plug>(MotionComplete) MotionComplete#Expr(MotionComplete#Input([]))
nnoremap <silent> <expr>  <SID>(MotionComplete) MotionComplete#Selected(MotionComplete#Input(MotionComplete#GetVisualBase()))
" Note: Must leave selection first; cannot do that inside the expression mapping
" because the visual selection marks haven't been set there yet.
vnoremap <silent> <script> <Plug>(MotionComplete) <C-\><C-n><SID>(MotionComplete)

if ! hasmapto('<Plug>(MotionComplete)', 'i')
    imap <C-x><C-m> <Plug>(MotionComplete)
endif
if ! hasmapto('<Plug>(MotionComplete)', 'v')
    vmap <C-x><C-m> <Plug>(MotionComplete)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
