
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Fast Filewise Git Blame",
        "date": "2024-05-18T00:00:00-0000",
        "root": ".."
      }
    }


When was each file in a git repository last changed, and who changed it? [Here's a one liner shell script](https://gist.github.com/acg/41e147c15e36c6db87db5bd286c03ba3) that produces a fast filewise git blame report:

```sh
#!/bin/sh
TZ=UTC git log --name-status --date=iso-strict-local --pretty="%ad%x09%ae" "$@" |
perl -F'/\t/' -lane '
  if (/^[ACDMRTUXB]/) {
    $path = @F>2 ? $F[2] : $F[1];
    print "$date\t$email\t$path" if -e "$path";
  } elsif (@F) {
    ($date, $email) = @F;
  }
' |
sort -k3,3 -k1,1r |
uniq -f2
```

The report looks roughly like this:

    ~/src/coreutils $ git-filewise-blame src | head
    2024-01-01T13:22:42    a@b.com    basename.c
    2024-03-19T15:55:18    a@b.com    basenc.c
    2023-10-27T15:56:39    x@y.com    blake2/b2sum.c
    2021-11-01T05:30:38    x@y.com    blake2/b2sum.h
    2021-12-18T17:34:31    x@y.com    blake2/blake2b-ref.c
    2021-12-18T17:34:31    x@y.com    blake2/blake2.h
    2022-09-15T05:30:31    x@y.com    blake2/blake2-impl.h
    2016-10-31T13:29:34    a@b.com    blake2/.gitignore
    2024-04-06T22:13:23    x@y.com    cat.c
    2024-01-01T13:22:42    a@b.com    chcon.c
    ...

The keyword here is **fast**. All other approaches I've found execute `git log` for every file in your checkout. Here's [one example](https://stackoverflow.com/a/5183273) of the slow approach:

```sh
git ls-files | while read file; do
  git log -n 1 --pretty="Filename: $file, commit: %h, date: %ad" -- "$file"
done
```

If your repository has many files and deep history, an exec-for-every-file approach will be horrifically slow – on the order of minutes or even hours. By contrast, the [`git-filewise-blame`](https://gist.github.com/acg/41e147c15e36c6db87db5bd286c03ba3) approach consumes the output of a single `git log` command. On my laptop, it takes 1 minute to filewise blame the entire `webkit` git repository, which has 405k files and 275k commits (!).
