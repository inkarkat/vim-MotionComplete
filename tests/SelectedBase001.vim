" Test: Completion of multiple words from selected base.

runtime tests/helpers/completetest.vim
call vimtest#StartTap()
call vimtap#Plan(4)
edit MotionComplete.txt

set completefunc=MotionComplete#MotionComplete
let g:SelectBase = 'call MotionComplete#SetSelectedBase(MotionComplete#GetVisualBase())'

call MotionComplete#SetMotion('t,')
call IsMatchesInContext('Be', '', 'Everyeeee', [], 'no matches')
call IsMatchesInContext('Be', '', 'Everything i', [
\   'Everything in moderation',
\   'Everything is actually everything else',
\], 'multiple sentence fragments')

call MotionComplete#SetMotion('3e')
call IsMatchesInContext('_n_', '', 'ought to ha', ['ought to have'], 'duplicate match')

call MotionComplete#SetMotion(')')
call IsMatchesInContext('Be', '', 'Everybody ought', [
\   "Everybody ought to have a friend.\n",
\   "Everybody ought to have a maid.\n",
\], 'multiple 2-words')

call vimtest#Quit()
