
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Matrix Chat in the Terminal with weechat-matrix",
        "date": "2020-08-30T19:27:00-0000",
        "root": ".."
      }
    }

<div class="image">
<img src="../images/blog/weechat-matrix.png" width="100%"/>
</div>

I've been using the [Element iOS App](https://apps.apple.com/app/vector/id1083446067) to chat with a few security-conscious friends. It works fine, but at some point you outgrow chatting with your thumbs, and long for the full ten-fingered chat experience. (A 5x improvement!!)

Fortunately the [Matrix protocol](https://en.wikipedia.org/wiki/Matrix_(protocol)) is an open standard with [plenty of clients](https://matrix.org/clients/). I like terminal programs, and [this Slack plugin for weechat](https://github.com/wee-slack/wee-slack) has been a pleasant surprise of late. It turns out there's a [Matrix plugin for weechat](https://github.com/poljar/weechat-matrix) too. A few months back I tried and failed to set up `weechat-matrix`, but today things went a little better.

So here's what worked for me. But first...

### Are You Sure You Want to Do This

The Matrix ecosystem is new, peopled with technical users, and hardcore about security. This doesn't make for a pleasant experience for most human beings. If you don't like messing around with tech for its own sake, and you just want 1:1 secure chats, might I recommend [Signal](https://signal.org/)?

Still here? Onward...

### Forget Python2

Although weechat still supports Python2, and `weechat-matrix` claims to support it, its [`matrix-nio` dependency doesn't](https://pypi.org/project/matrix-nio/). Don't waste your time. Start with Python3.

### Isolate the Install

To avoid hosing my existing weechat setup or my base system, I started from a clean [Debian 10 `debootstrap`](https://wiki.debian.org/Debootstrap). If you're hipper than me maybe you prefer docker. Either way, it pays to isolate!

### Use the Weechat Development Packages

Once your environment is up and running, you'll want to grab the [`weechat-devel`](https://weechat.org/download/debian/active/files/) packages for maximum Python3 compat.

### Follow the README

Follow the [`weechat-matrix` README](https://github.com/poljar/weechat-matrix#installation). If all goes well you'll be connected, logged in, and automatically joined to your channels. But there's a problem: your new "device" isn't verified.

### Verify Devices

Immediately after `weechat-matrix` successfully connected, Element popped up a modal that it was verifying the new device. This was the interactive verification flow, and it didn't work for me. Close out of it.

What worked instead was going to Element -> Settings -> Security, finding my new "Weechat Matrix" session, and manually verifying it. To make sure things match on the other end, switch to any Matrix channel in weechat, type `/olm info`, then switch back to the first weechat buffer. You should see your new weechat device's identity keys. If they match, you can verify them in Element.

You can also verify devices from weechat's perspective via `/olm verify <username>`. There's even some pattern syntax that lets you verify multiple devices at once — but be careful with this.

At this point, you should be able to chat safely with other devices you've done the verification dance with, but there's still a problem: you can't read channel history. You'll see usernames and timestamps in weechat, but each message will start with `<Unable to decrypt>`.

### Decrypt Old Messages

To decrypt channel history, you'll need to export keys from Element and import them into `weechat-matrix`. Element makes this pretty easy: go to Settings -> Security -> "Export keys manually." Create a passphrase for the key file, and email it to yourself.

Back in weechat, use `/olm import ~/path/to/riot-keys.txt <passphrase>`. This may take a bit, and `weechat` will likely hit 100% cpu during the process.

On success, you still can't read channel history...that is, until you restart weechat!

### Feedback

Did it work? Did I miss something? [Let me know](https://twitter.com/alangrow).

### More Info

Here's [another useful guide to weechat + matrix](https://hispagatos.org/post/weechat-matrix/).

I'd be remiss if I didn't mention that `weechat-matrix` is in maintenance mode, and a [new Rust port is underway](https://github.com/poljar/weechat-matrix-rs). At the time of this writing it isn't very far along.
