
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "A Decade of Kill Bugs",
        "date": "2026-09-24T20:42:56-0000",
        "root": ".."
      }
    }

On the morning of September 24th 2026, [Endcrawl](https://endcrawl.com) had a brief outage. I'd just typed:

```sh
sudo kill -TERM -1490947
```

And instantly all services went down.

Right away I blamed myself. Maybe I mistyped that number! Maybe my code had a signal handling bug. Maybe I don't understand Unix as well as I think I do. Maybe I'm an idiot!

As it turned out, the outage was caused by a bug in [`kill(1)`](https://man7.org/linux/man-pages/man1/kill.1.html).

This is really surprising! The `kill` program is 50 years old. Its [spec](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/kill.html) is simple and stable. It's probably exercised a billion times day.

A bug in `kill` was so surprising that, once I'd found it, I couldn't stop there. I needed to know how this bug came to be, and what had led the programmers so badly astray. When I eventually found the root cause, there was an even bigger surprise. It didn't just cause this one bug. It had caused a whole series of unfortunate `kill` bugs that were shipped in Ubuntu 14, 16, 18, 22 and 24 LTS.

This post documents a decade of `kill` bugs, then makes some recommendations.

## An Outage Not Understood Happens Again

Back to the outage. I had a fire to put out. After that came a surprise second fire. By the end of all this I was pretty demoralized. I was ready to accept that I'd made a dumb mistake and ready to get on with the work day. There was this nagging feeling though…

Remember [that final scene in Burn After Reading](https://www.youtube.com/watch?v=kCXTq-fWWio)?

> "What did we learn Palmer?"

> "I don't know sir."

> "I don't f\*\*king know either. I guess we learned not to do it again."

> "Yes sir."

> "Although I'm f\*\*ked if I know what we did..."

What had just happened? Was I about to be hit with a third outage? How could I be sure?

An outage not understood is an outage that happens again. That nagging feeling I had was a call to understand. With a sigh, I put everything else on hold and started a proper post mortem.

## The Proximate Cause

Let's more closely examine the command that caused the outage:

```sh
sudo kill -TERM -1490947
```

The negative number here is a [process group identifier](https://en.wikipedia.org/wiki/Process_group), or pgid for short. A pgid is like a pid, but identifies a group of related processes. By convention, killing a positive number sends a signal to a single process, while killing a negative number signals all processes in that process group.

I was attempting to cancel a big Endcrawl 7k test render. A normal person would have killed one of the processes involved and let failures cascade to the others. But killing the whole group simultaneously strikes me as cleaner.

Process group signaling isn't some exotic operation. You use it all the time. Every time you `^C` a command, the tty sends `SIGINT` to the foreground process group. Interactive shells run all but the simplest commands in a new process group. This makes [job control](https://en.wikipedia.org/wiki/Job_control_(Unix)) possible.

I'll go even further and say that process group signaling is an awesome Unix innovation. I love it so much I [added it to daemontools](https://github.com/bruceg/daemontools-encore/pull/16), where `svc -+h` now avoids orphans in a multiprocess service bounce.

At any rate, imagine my surprise when the command didn't just kill those render processes, but killed *all processes on the machine* save one!

## The Bug

Here's the relevant snippet from [procps 4.0.4](https://gitlab.com/procps-ng/procps/-/releases/v4.0.4), the provider of `/bin/kill` in Ubuntu 24.04 LTS. Can you spot the bug?

```c
opterr=0; /* suppress errors on -123 */
while ((i = getopt_long(argc, argv, "l::Ls:hVq:", longopts, &optindex)) != -1)
  switch (i) {
    /* ... */
    case '?':
      if (!isdigit(optopt)) {
        xwarnx(_("invalid argument %c"), optopt);
        print_usage(stderr);
      } else {
        /* Special case for signal digit negative
         * PIDs */
        pid = (long)('0' - optopt);
        if (!execute_kill((pid_t) pid, signo, use_sigqueue, sigval))
          exitvalue = EXIT_FAILURE;
        exit(exitvalue);
      }
    /* ... */
  }
```

My guess going in was wrong. There's no underflow or overflow bug with `-1490947`.

Notice we're in the unrecognized option switch case. Here's what [`getopt(3)`](https://man7.org/linux/man-pages/man3/getopt.3.html) says about unrecognized options:

> By default, `getopt()` prints an error message on standard error, places the erroneous option character in optopt, and returns `'?'` as the function result.

Aha. The `optopt` variable only holds the first character after the dash, not the whole negative pid. When character `1` is subtracted from character `0` we get a pid of `-1`. What happens when you kill pid `-1`? [Bad things](https://man7.org/linux/man-pages/man2/kill.2.html):

> If pid equals -1, then sig is sent to every process for which the calling process has permission to send signals, except for process 1 (init). 

This ran as root, so the misparsing of `-1490947` as `-1` killed every process but init. Bug found, mystery solved.

## Wait But Why

Except for me this just raised more questions. Why is the code assuming the unrecognized option is a "signal \[sic\] digit negative PID"? Why is the single digit negative pid case special, and what handles the general case of a multidigit negative pid?

Moreover, how could a bug like this exist in 2026, and in a Ubuntu LTS release no less? Has it always been there?

No, that couldn't be. I've killed process groups in the past. And the `kill -TERM -12345` thing is an ancient Unix incantation. This used to work dammit!

Thinking back, I could vaguely remember some negative pid kills gone awry. Never in an "oops this killed everything in sight" way. More in a "weird, nothing happened" way, or a "poof there goes my shell" way. Minor ways more easily shrugged off as user error.

It turns out I wasn't imagining these. The last decade has been a rough one for negative pid killers. There have been no less than **FOUR** distinct bugs around negative pids. And they all shipped in Ubuntu LTS versions.

## The History

Before I tell the tale of four bugs, let's go even farther back in Unix history.

In the beginning Unix had processes. By 1973 it had the `kill(1)` program. But it took a decade to evolve process groups as we now know them. It wasn't until [Unix V9 in 1986](https://www.tuhs.org/cgi-bin/utree.pl?file=V9/cmd/kill.c) that you could kill a process group via negative pid. Near as I can tell, negative pid killing has worked fine in the BSDs all these years.

In the early 90s this thing called Linux came along. Although Linux initially borrowed a lot of BSD code for its userland, by the late 90s this approach was in legal jeopardy. Everything had to be rewritten, every wheel reinvented. And fast. It was an exciting time to be a Unix programmer.

And so it came to pass that Linux's `kill` was ~~reinvented~~ written by [Albert Calahan](https://lwn.net/Articles/851716/). After Albert DoSed himself by forking 5 children, Debian downstream maintainer [Craig Small](https://dropbear.xyz/software/) took over poor old neglected [procps](https://gitlab.com/procps-ng/procps).

Negative pid killing seems to have worked fine until 2013. Then the trouble began.

### Bug 1: Ubuntu 14 Can't Kill -1

Ubuntu 14.04 LTS included procps 3.3.9. Prior to this, the `kill` code did what the BSDs do and used pointer arithmetic to walk and parse `argv`.

Personally I'm fond of that approach. Stallman isn't so fond of it though. In GNU world, you're supposed to use `getopt_long(3)` and eschew cryptic, single-character options. This is probably a good idea in the general case. But as we'll see, it was probably the wrong choice for the specific case of `kill(1)`.

Here's the relevant code after the conversion to `getopt`:

```c
opterr=0; /* suppress errors on -123 */
while (loop == 1 && (i = getopt_long(argc, argv, "l::Ls:hV", longopts, NULL)) != -1)
  switch (i) {
    /* ... */
    case '?':
      if (!isdigit(optopt)) {
        xwarnx(_("invalid argument %c"), optopt);
        kill_usage(stderr);
      }
      loop=0;
      break;
    /* ... */
  }

argc -= optind + sigopt;
argv += optind;

for (i = 0; i < argc; i++) {
  pid = strtol_or_err(argv[i], _("failed to parse argument"));
  if (!kill((pid_t) pid, signo))
    continue;
  exitvalue = EXIT_FAILURE;
  continue;
}
```

The code worked fine for multidigit negative pids. However, if you were one of those freaks who delighted in a `kill -HUP -1` now and again to restart all your services, you noticed a bug: nothing happened.

The bug is due to [option bundling](https://www.matejka.ninja/software/argv.html#bundled-options).

1. **Multidigit case**: With `kill -HUP -123`, `getopt` acts as if `-1`, `-2`, and `-3` were all separately passed. The unrecognized option case will be hit three times, and only at `-3` will the `-123` argument be consumed by incrementing `optind`. Because the code breaks out of the `getopt` loop early at `-1`, an unconsumed `-123` argument correctly makes it to the pid killer.

2. **Single digit case**: With `kill -HUP -1`, `getopt` has fully consumed that argument and incremented `optind` when we break out of the loop. The pid killer sees no arguments and nothing happens.

### Bug 2: Ubuntu 16 Accidentally Kills -1

A cure was in order. Unfortunately it was worse than the disease.

Ubuntu 16.04 LTS shipped with procps 3.3.10. The `kill -HUP -1` bug was fixed at the expense of multidigit negative pid kills. A `kill -TERM -12345` now killed everything.

This is the same bug that caused the outage under Ubuntu 24. We've already unpacked this one [above](#the-bug). The only mystery here is why procps circa Ubuntu 24 resurrected the known-buggy code circa Ubuntu 16. My best guess is that the following bugs were deemed even worse.

### Bug 3: Ubuntu 18 Segfaults Killing -1

Ubuntu 18.04 LTS shipped with procps 3.3.12.

This attempted to fix multidigit negative pid killing. Instead of parsing `optopt`, which only corresponds to a single bundled character like `-1` when `-123` is passed, the new code stops and tries to parse the whole argument:

```c
opterr=0; /* suppress errors on -123 */
while (loop == 1 && (i = getopt_long(argc, argv, "l::Ls:hV", longopts, NULL)) != -1)
  switch (i) {
    /* ... */
    case '?':
      if (!isdigit(optopt)) {
        xwarnx(_("invalid argument %c"), optopt);
        kill_usage(stderr);
      } else {
        /* Special case for signal digit negative
         * PIDs */
        pid = atoi(argv[optind]);
        if (kill((pid_t)pid, signo) != 0)
        exitvalue = EXIT_FAILURE;
        exit(exitvalue);
      }
      loop=0;
      break;
    /* ... */
  }
```

This works correctly for multidigit negative pids. But if you passed a single digit negative pid, as in a `kill -TERM -1`, the final argument was fully consumed, and `optind` would run off the end of `**argv`. Segfault!

### Bug 4: Ubuntu 22 Kills Your Shell

Ubuntu 22.04 LTS shipped with procps 3.3.17.

This fixed the segfault by ensuring `optind` never ran off the end of `**argv`:

```c
opterr=0; /* suppress errors on -123 */
while ((i = getopt_long(argc, argv, "l::Ls:hVq:", longopts, NULL)) != -1)
  switch (i) {
    /* ... */
    case '?':
      if (!isdigit(optopt)) {
        xwarnx(_("invalid argument %c"), optopt);
        kill_usage(stderr);
      } else {
        /* Special case for signal digit negative
         * PIDs */
        pid = atoi(argv[optind-1]);
        if (kill((pid_t)pid, signo) != 0)
        exitvalue = EXIT_FAILURE;
        exit(exitvalue);
      }
      xerrx(EXIT_FAILURE, _("internal error"));
    /* ... */
  }
```

Once again, it seems the contributor didn't understood how `getopt` option bundling interacts with `optind`, and by this point I'm developing some sympathy for them. Now a `kill -TERM -1` works correctly and no longer segfaults. But multidigit negative pid killing was broken for a second time, in a brand new way.

Suppose we try to `kill -TERM -123`. Thanks to option bundling, `optind` isn't incremented yet when we hit the unrecognized option case. Per some [quirky behavior noted below](#oh-were-halfway-there), `argv[optind-1]` is now the string `kill`.

What does [`atoi(3)`](https://man7.org/linux/man-pages/man3/atoi.3.html) return for a non-integer like `"kill"`? It returns `0`.

What does the [kill](https://man7.org/linux/man-pages/man2/kill.2.html) system call do with zero?

> If pid equals 0, then sig is sent to every process in the process group of the calling process.

Run by itself as a simple command, your shell won't put `kill -TERM -123` in a new process group. So this bug will unexpectedly kill your shell. Poof!

## What Did We Learn, Palmer?

There are several takeaways.

### The Narrow Learning

For one, the way `getopt` only advances `optind` with the final bundled option is deeply non-obvious. I didn't find evidence that any contributor understood this. I didn't understand it myself at first — that took careful study.

It's a real surprise. Surprising behavior like this should be avoided.

I feel this learning is too myopic though. Can one even avoid this surprising `getopt` behavior? You can't disable option bundling.

### The Broader Learning

A broader learning: `getopt` usage is considered harmful.

At least in this specific case. The `kill(1)` program is just an unusual one. It accepts options that are actually signal names, like `-KILL`. You can also specify that same signal by number, like `-9`. And pgids are negative numbers that look like deceptively like options.

How should an argv like `kill -1 -9` be interpreted?

- Should it send SIGHUP to pgid 9?
- Should it send SIGKILL to pgid 1, aka everything?
- Should it send SIGTERM, the default signal, to pgids 1 and 9?

If any `**argv` element can be an option or an argument, all of these interpretations are potentially valid.

The answer is to instead parse `**argv` positionally. Don't use `getopt`. Abandon capabilities like option bundling and option reordering that are more footgun than feature in this context. The [POSIX spec](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/kill.html) says that only `argv[1]` can specify the signal to send, and that `argv[2]` and beyond are pids and pgids.

I think the BSD approach was right. [Here's the FreeBSD `kill(1)` code](https://github.com/freebsd/freebsd-src/blob/bd4975e5fb051c2b2e8d5218940b7e8ef87b5bdf/bin/kill/kill.c#L53-L136). It parses `**argv` positionally. The approach is simple and the code is simple. By contrast with Linux's `kill`, I've found no reports of command line parsing bugs in FreeBSD's `kill`.

I regard `getopt` dogma as the real root cause of the outage.

### Oh, We're Halfway There

If abandoning `getopt` for "primitive" `**argv` parsing still feels sinful, just look at what procps does before even calling `getopt_long`:

```c
if (argc < 2)
  print_usage(stderr);

signo = skill_sig_option(&argc, argv);
if (signo < 0)
  signo = SIGTERM;

opterr=0; /* suppress errors on -123 */
while ((i = getopt_long(argc, argv, "l::Ls:hVq:", longopts, &optindex)) != -1)
/* ... */
```

What does `skill_sig_option` do?

```c
int skill_sig_option(int *argc, char **argv)
{
  int i;
  int signo = -1;
  for (i = 1; i < *argc; i++) {
    if (argv[i][0] == '-') {
      signo = signal_name_to_number(argv[i] + 1);
      if (-1 < signo) {
        memmove(argv + i, argv + i + 1,
            sizeof(char *) * (*argc - i));
        (*argc)--;
        return signo;
      }
    }
  }
  return signo;
}
```

It scans `**argv` looking for the first element that looks like a signal spec. If it finds a `-KILL`, a `-9`, or similar, it modifies `argv` in place (!) so `getopt` doesn't have to deal with that.

This is already "primitive" `**argv` parsing! We're halfway there.

### Some Final Practical Advice

The previous takeaways were aimed at software developers. For users of `kill`, I'd recommend the following.

First, use `--` to separate options from pids and pgids:

```sh
kill -TERM -1490947     # no
kill -TERM -- -1490947  # yes
```

The second form is parsed correctly even by the buggy procps versions listed above.

Second, kill with least privilege. If I'd done a `sudo -u render kill` instead of a `sudo kill`, it would have only killed in-flight renders instead of all processes on the box. I feel a little insane recommending this kind of defensive shell programming — let's be clear, we're defending against bugs in `kill` — but here we are.

Finally, the good news is that a [bugfix for Ubuntu 24](https://lists.ubuntu.com/archives/ubuntu-sponsors/2026-September/088746.html) is already on its way at the time of this writing.
