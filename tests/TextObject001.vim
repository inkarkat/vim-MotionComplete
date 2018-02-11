" Test: Completion of text objects.

source ../helpers/completetest.vim
call vimtest#StartTap()
call vimtap#Plan(3)
edit MotionComplete.txt

set completefunc=MotionComplete#MotionComplete

call MotionComplete#SetMotion('a)')

call IsMatchesInIsolatedLine('', [
\   '( l:matches, ''\V\<'' . escape(a:base, ''\''), l:options )',
\   '(\k\@!.\)*\%#'', ''bn'', line(''.''))',
\   '(a:base, ''\'')',
\   '(conflicting)',
\   '(contents)',
\   '(e.g. 2, 4 or 8 spaces)',
\   "(e.g. the\n\"   alignment)",
\   "(only\n\"   tabs, only spaces, or a mix of tabs and spaces that minimizes the number of\n\"   spaces and is called 'softtabstop' in VIM)"
\], 'all text in brackets')

call IsMatchesInIsolatedLine('(e.g.', [
\   '(e.g. 2, 4 or 8 spaces)',
\   "(e.g. the\n\"   alignment)",
\], 'text with start anchor in brackets')

call IsMatchesInIsolatedLine('spaces', [
\   '(e.g. 2, 4 or 8 spaces)',
\   "(only\n\"   tabs, only spaces, or a mix of tabs and spaces that minimizes the number of\n\"   spaces and is called 'softtabstop' in VIM)"
\], 'text with keyword in brackets')

call vimtest#Quit()
