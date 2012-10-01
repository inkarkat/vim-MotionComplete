" MotionComplete.vim: Insert mode completion that completes a text chunk
" determined by {motion} or text object. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - MotionComplete.vim autoload script. 
"
" Copyright: (C) 2008-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	02-Jan-2012	split off autoload script and documentation. 
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

inoremap <script> <expr> <Plug>(MotionComplete) MotionComplete#Expr()
nnoremap <expr> <SID>ReenterInsertMode (col("'>") == (col('$')) ? 'a' : 'i')
xnoremap <silent> <script> <Plug>(MotionComplete)      :<C-u>call MotionComplete#MotionInput(1)<Bar>set completefunc=MotionComplete#MotionComplete<CR>`><SID>ReenterInsertMode<C-x><C-u>
snoremap <silent> <script> <Plug>(MotionComplete) <C-g>:<C-u>call MotionComplete#MotionInput(1)<Bar>set completefunc=MotionComplete#MotionComplete<CR>`><SID>ReenterInsertMode<C-x><C-u>

if ! hasmapto('<Plug>(MotionComplete)', 'i')
    imap <C-x><C-m> <Plug>(MotionComplete)
endif
if ! hasmapto('<Plug>(MotionComplete)', 'x')
    xmap <C-x><C-m> <Plug>(MotionComplete)
endif
if ! hasmapto('<Plug>(MotionComplete)', 's')
    smap <C-x><C-m> <Plug>(MotionComplete)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
