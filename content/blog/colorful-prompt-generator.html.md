
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Colorful Bash Prompt Generator",
        "date": "2004-12-30T00:00:00-0000",
        "root": ".."
      }
    }

(A very old post, but I've used this prompt ever since.)

Customizing a shell prompt often culminates in an impressive plumage display like

```bash
export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\n\[\e[0m\]$ '
```

the idea being that lots of escape sequences = eliteness. Though, I'd guess most people just copy someone else's bash prompt and foist it off as their own, rather than learn ansi / xterm / bash escape sequences. Like me initially. :)

However, you can easily make your prompt setup readable by breaking it down.

```bash
# ansi color escape sequences
prompt_black='\[\e[30m\]'
prompt_red='\[\e[31m\]'
prompt_green='\[\e[32m\]'
prompt_yellow='\[\e[33m\]'
prompt_blue='\[\e[34m\]'
prompt_magenta='\[\e[35m\]'
prompt_cyan='\[\e[36m\]'
prompt_white='\[\e[37m\]'
prompt_default_color='\[\e[0m\]'
```

My motivation initially was to avoid beeping console prompts. The xterm escape sequence to set the window title contains a bell character, which was of course interpreted by xterm and friends, but not when I'd sit down at system consoles (where usually `TERM=cons25`). I needed to set `$PS1` according to `$TERM`.

In the course of things, I discovered the `\t` bash escape sequence, which gives you the current time in `hh:mm:ss` form. Nice. By incorporating this into the prompt you can now tell by inspection how long you've been sitting with your jaw open trying to remember what you were about to do. Or, how severe one's random spastic `ls`-ing has gotten.

<div class="image">
<a href="../images/blog/bash-prompt-with-time.png">
<img src="../images/blog/bash-prompt-with-time-small.png" />
</a>
</div>

For emergencies, there's also the no-color prompt.

```bash
prompt_nocolor='\n\u@\h \w\n$ '
```

For nostalgia (or out of masochism) there's the old dos prompt.

```bash
prompt_dos='\n\w>'
```

