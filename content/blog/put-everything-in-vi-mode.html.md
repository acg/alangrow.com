
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Put *Everything* in vi Mode",
        "date": "2011-05-17T00:00:00-0000",
        "root": ".."
      }
    }

If you're a vi user like me, try adding these two lines to your `~/.inputrc` file:

    set keymap vi
    set editing-mode vi

Now, every program that uses the readline library for tty input (`perl -d`, the `python` REPL, `psql`, `gdb`, anything you run under `rlwrap`, etc.) has vi key bindings instead of the default emacs bindings.

In short, this means things like:

* `0` and `$` for beginning and end of line
* `k` and `j` for navigating history forwards and backwards
* `b` and `e` for skipping words
* `u` for undo

See this [readline vi mode cheatsheet](https://readline.kablamo.org/vi.html) for a longer list.

I've been using this for years with bash, where one can do `set -o vi`. Apparently vi mode has been present since GNU readline 2.0, released in 1994, so I really have no excuse for this one!
