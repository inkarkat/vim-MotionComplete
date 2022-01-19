MOTION COMPLETE
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Most insert mode completions complete only the current word (or an entire
line), so one has to repeat i\_CTRL-X\_CTRL-N to complete the following words.
For longer completions, this is slow, especially because you sometimes have to
choose from multiple choices.
The completion provided by this plugin assumes that you know a Vim motion
(e.g. '3e', ')' or '/bar/e') or text object which covers the text you want
completed. When you invoke the completion, the completion base (some text
before the cursor, or the currently selected text) will be presented and the
motion to cover the completion text (including the completion base) will be
queried. Then, the list of completion candidates will be prepared and selected
in the usual way.

### SEE ALSO

- Check out the CompleteHelper.vim plugin page ([vimscript #3914](http://www.vim.org/scripts/script.php?script_id=3914)) for a full
  list of insert mode completions powered by it.

USAGE
------------------------------------------------------------------------------

    In insert mode, invoke the completion via CTRL-X CTRL-M.

    This completion method is probably only used for longer matches, as
    invoking this completion method with the querying of the {motion} isn't
    very fast. For motions that cover many words or entire sentences, an empty
    base isn't helpful, there would be far too many matches. To ensure a
    completion base, this completion includes more than the usual keyword
    characters directly before the cursor. It looks for the following before the
    cursor, possibly with whitespace between it and the cursor:
    - keyword character(s), e.g "foo" in "return (foo|"
    - non-keyword non-whitespace character(s), e.g. "/*" in "return 0; /* |"
    - keyword character(s) followed by non-keyword non-whitespace characters,
      e.g. "foo(" in "return foo(|"
    When the completion base starts with a keyword character, matches must start
    at a \<word border.
    Alternatively, you can pre-select the base (via select or visual mode) before
    invoking the completion. This ensures that the best context for completion is
    chosen.

    Input the {motion}.
    You can then search forward and backward via CTRL-N / CTRL-P, as usual.

    CTRL-X CTRL-M           The completion first queries for {motion} (press
                            <Enter> to conclude), then finds matches starting with
                            the MotionComplete-base text before the cursor,
                            covering {motion}.

    {Visual}CTRL-X CTRL-M   The completion first queries for {motion} (press
                            <Enter> to conclude), then finds matches starting with
                            the selected text, covering {motion}.
                            Use this to define the completion base text (quickly
                            done from insert mode via [CTRL-]SHIFT-<Left>) for
                            better matches.

### EXAMPLE

Trigger completion:
```
A quick|
       ^ cursor, just triggered motion completion.
```

Somewhere else, a match:
```
    v---v completion base
The quick brown fox jumps over the lazy dog.
    ^----------- "5w" --------^ completion via motion 5w
```

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-MotionComplete
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim MotionComplete*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.037 or
  higher.
- Requires the CompleteHelper.vim plugin ([vimscript #3914](http://www.vim.org/scripts/script.php?script_id=3914)), version 1.51 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

By default, the 'complete' option controls which buffers will be scanned for
completion candidates. You can override that either for the entire plugin, or
only for particular buffers; see CompleteHelper\_complete for supported
values.

    let g:MotionComplete_complete = '.,w'

Note that CompleteHelper.vim (in version 1.51 at least) does not support
extraction from buffers not visible in the current tab page.

To avoid that huge amounts of text are offered for completion, the maximum
number of characters to be captured by {motion} is limited:

    let g:MotionComplete_maxCaptureLength = &columns * 3

To speed up the search and to avoid that many lines are offered for
completion, the maximum number of lines to be searched for /pattern/ and
?pattern? motions is limited:

    let g:MotionComplete_searchScopeLines = 5

If you want to use different mappings, map your keys to the
&lt;Plug&gt;(MotionComplete) mapping targets _before_ sourcing the script (e.g.
in your vimrc):

    imap <C-x><C-m> <Plug>(MotionComplete)
    xmap <C-x><C-m> <Plug>(MotionComplete)
    smap <C-x><C-m> <Plug>(MotionComplete)

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-MotionComplete/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 1.01    RELEASEME
- Use a:options.abbreviate instead of explicit abbreviation loop.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.037!__

__You need to update to CompleteHelper.vim ([vimscript #3914](http://www.vim.org/scripts/script.php?script_id=3914)) version 1.51!__
- Remove default g:MotionComplete\_complete configuration and default to
  'complete' option value instead.

##### 1.00    12-Oct-2012
- First published version.

##### 0.01    13-Aug-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2022 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
