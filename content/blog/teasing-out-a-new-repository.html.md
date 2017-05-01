
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Teasing Out a New Git Repository",
        "date": "2011-03-02T00:00:00-0000",
        "root": ".."
      }
    }

*The Ideal Git Law states that the documentation surrounding git(1) will expand to fill all available volume.*

I'm building a suite of record processing tools. Up to now, the development has taken place inside the [lwpb](https://github.com/acg/lwpb) git repository. But it doesn't really belong there, since other record formats besides protobuf are supported: the classic unix tab-separated text format, and soon json.

So how does one extract *part* of a git repository into a new repository, preserving history where possible?

All of the files I want to extract from the main repository live under the same subdirectory, which should become the top-level directory of the new repository. So a good place to start is this [stack overflow thread](http://stackoverflow.com/questions/359424/detach-subdirectory-into-separate-git-repository) which explains `git filter-branch --subdirectory-filter subdir`. It goes something like this:

```bash
mkdir newrepo
cd newrepo
git clone --no-hardlinks /oldrepo ./
git filter-branch --subdirectory-filter subdir HEAD
git reset --hard
git gc --aggressive
git prune
```

As a comment on the stackoverflow thread mentions, it's also a good idea to remove the old repo as a remote of the new repo, so you don't accidentally push changes back to it:

```bash
git remote rm origin
```

So far so good. But I only want *some* of the files under this subdirectory in the new repo. The rest shouldn't be there. Can I rewrite the commit history again, this time file-wise?

Yes. For this I used `git filter-branch --tree-filter command`. This works by checking out each commit, running `$SHELL -c "$command"`, looking at what changes were made to the checkout, and then formulating a new commit. If the command removes a file in the checkout, it will be removed from the commit. If a command creates a file, it will be added to the commit.

In my case, I only want to remove certain files, so the filter command is a shell script that looks like this:

```bash
#!/bin/sh
find . -type f -not -path "*/.git/*" | \
sed -e 's#^./##' | \
grep -v -E '^(pb.*\.py|flat\.py|percent.*)$' | \
xargs rm -v
```

The `rm -v` lets me see all the deletions this script makes for each commit. I saved this as my-git-filter and ran

```bash
git filter-branch -f --prune-empty --tree-filter my-git-filter HEAD
```

The `-f` option forces the operation even if there's already a backup of the original repo from a previous `git filter-branch` run.

Follow this up with the same cleanup procedure from the `--subdirectory-filter` example:

```bash
git reset --hard
git gc --aggressive
git prune
```

