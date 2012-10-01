" Test: Completion of multiple words. 

source ../helpers/completetest.vim
call vimtest#StartTap()
call vimtap#Plan(6) 
edit MotionComplete.txt

set completefunc=MotionComplete#MotionComplete

call MotionComplete#SetMotion('t,')
call IsMatchesInIsolatedLine('Everyting', ['Everyting should be built top-down'], 'single sentence fragment')
call IsMatchesInIsolatedLine('Everyeeee', [], 'no matches')
call IsMatchesInIsolatedLine('Everything', [
\   'Everything in moderation',
\   'Everything is actually everything else',
\   'Everything worthwhile is mandatory',
\   'Everything you know is wrong'
\], 'multiple sentence fragments')

call MotionComplete#SetMotion('3e')
call IsMatchesInIsolatedLine('ought', ['ought to have'], 'duplicate match')
call MotionComplete#SetMotion(')')
call IsMatchesInIsolatedLine('Everybody', [
\   "Everybody lies, but it doesn't matter since nobody listens.  ",
\   "Everybody needs a little love sometime; stop hacking and fall in love!\n",
\   "Everybody ought to have a friend.\n",
\   "Everybody ought to have a maid.\n",
\   "Everybody wants to go to heaven, but nobody wants to die.\n"
\], 'multiple sentences')
call MotionComplete#SetMotion('2e')
call IsMatchesInIsolatedLine('Everybody', [
\   "Everybody lies",
\   "Everybody needs",
\   "Everybody ought",
\   "Everybody wants"
\], 'multiple 2-words')

call vimtest#Quit()
