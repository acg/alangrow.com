
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Shell Quirk: Assignment From a Heredoc",
        "date": "2017-06-10T20:30:00-0000",
        "root": ".."
      }
    }

I have a ~~fetish for~~ fascination with POSIX shell corner cases. It started 10 years ago with a segfault. A shell script with a certain `while read` loop ran find on every Unix I could find, except for [AIX](https://en.wikipedia.org/wiki/IBM_AIX) (don't ask).

Here's a new find. What will the following POSIX shell program print?

```bash
#!/bin/sh
paths=`tr '\n' ':' | sed -e 's/:$//'`<<EOPATHS
/foo
/bar
/baz
EOPATHS
echo "$paths"
```

If you said `/foo:/bar:/baz`, you're right...that is, if you're on Linux and `/bin/sh` is provided by [dash](https://en.wikipedia.org/wiki/Almquist_shell#dash:_Ubuntu.2C_Debian_and_POSIX_compliance_of_Linux_distributions).

If you're on MacOS [[1]](#1) or FreeBSD instead, this same script will wait for input and print nothing. This is probably the behavior on all BSD derivatives, and it's likely the correct behavior too, since the BSDs are usually right about these things.

Correct or not, the `dash` behavior is a bit more useful. It also points to a fundamental difference in the way [here-documents](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_04) work: `dash` interprets the heredoc _before_ anything else on the line. When the assignment is interpreted next, stdin already has the contents of the heredoc. I'm not even sure what the other POSIX shells do. Is the heredoc interpreted after the assignment? Where does it even go?

Fortunately there's an easy portable alternative: wrap the whole thing in backquotes.

```bash
#!/bin/sh
paths=`tr '\n' ':' | sed -e 's/:$//'<<EOPATHS
/foo
/bar
/baz
EOPATHS`
echo "$paths"
```

<a name="1">[1]</a> Note that on recent MacOS versions, `/bin/sh` is actually `bash` in POSIX mode. Don't believe me? Run `/bin/sh --help` and `/bin/sh -c 'echo $POSIXLY_CORRECT'`.

<style>
.highlight .s { color: #dd7700; }
</style>

