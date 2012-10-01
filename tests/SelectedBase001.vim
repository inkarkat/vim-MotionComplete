" Test: Completion of multiple words from selected base. 

source ../helpers/completetest.vim
call vimtest#StartTap()
call vimtap#Plan(4) 
edit MotionComplete.txt
call MotionComplete#SetSelectedBase(1)

set completefunc=MotionComplete#MotionComplete
let g:isSelectBase = 1

call MotionComplete#SetMotion('t,')
call IsMatchesInIsolatedLine('Everyeeee', [], 'no matches')
call IsMatchesInIsolatedLine('Everything i', [
\   'Everything in moderation',
\   'Everything is actually everything else',
\], 'multiple sentence fragments')

call MotionComplete#SetMotion('3e')
call IsMatchesInIsolatedLine('ought to ha', ['ought to have'], 'duplicate match')

call MotionComplete#SetMotion(')')
call IsMatchesInIsolatedLine('Everybody ought', [
\   "Everybody ought to have a friend.\n",
\   "Everybody ought to have a maid.\n",
\], 'multiple 2-words')

call vimtest#Quit()
