
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Blog Refresh: Now With Less",
        "date": "2017-05-01T02:13:42-0000",
        "root": ".."
      }
    }

To readers who enjoyed the 3-column layout, the Edgar Allen Poe quote, and the engraving of the fragile rowboat disappearing into the mighty maelstrom: I'm sorry. It's all gone. To me, minimalism is less an aesthetic than it is the search for time invariants, and well...here we are.

It's actually a bit more practical than all that. After porting this blog from [jekyll](https://jekyllrb.com/) to [tinysite](https://github.com/acg/tinysite) a few years ago, I discovered that the very problem I set out to solve -- fast incremental site rebuilds -- was still a problem. (No comment on why this seems to be a pattern with shiny two-point-oh-y things.) The index of all posts in the right column was the culprit. The simple act of fixing a typo on a single page would cause `posts.json` to rebuild, and then every post would be rebuilt in a cascade, since the right column of every post depended on `posts.json`. Other static site generators probably learned to avoid this years ago. I finally came around to it this weekend.

In the interim, editing posts was pretty unpleasant. Doubly so because I had no one to blame but myself. Now incremental site rebuilds are quick, and can still be accelerated further with `make -j`.

With that out of the way, I decided to take advantage of the "let's optimize the shit out of everything" mental state I was in and see what could be done to speed up publishing. I really like the Heroku / Github Pages approach of "just git push and we'll do the rest," and have spent the last few years building and fine-tuning systems to make that the modus operandi for everything at [Endcrawl](https://endcrawl.com). Maybe those years would have been better spent learning docker or kube, and maybe the people who regard deploying-via-git as an antipattern are right, but I can't shake the idea that we're overengineering the hell out of this problem right now. As [one HN commenter](https://news.ycombinator.com/item?id=14216655) put it:

> In the long term I predict that base OS everywhere will improve support for deployment, workload scheduling, resource allocation, endpoint discovery, and dependency management. These will match and eventually surpass the additional capabilities that containers offer, and **then we can all go back to putting files on a server and restarting a process**, which is all that 99% of us actually need.

There's a bit more to it than that part I emphasized, but that's for another day. Suffice to say there's tooling now that fully realizes the ["dream deploys"](./dream-deploys-atomic-zero-downtime-deployments/) idea, it may get opensourced, and this site uses it.

I also took a stab at the horribly clunky `{% highlight lang %} ... {% endhighlight %}` template syntax this blog used for code highlighting. When I started there was no good standard for this kind of thing, but now it seems [fenced code](https://help.github.com/articles/creating-and-highlighting-code-blocks/) has won. Switching `tinysite` to fenced code turned out to be [trivial](https://github.com/acg/tinysite/commit/d6ea6fe0bf58ef6a28776a7f4f0b622f8c47c747), mainly because the original approach was a small regex hack rather than a more evolved approach. That Yagni guy they're always invoking knows what's up!

Oh yeah. The Disqus comments section is gone. [Good riddance](http://donw.io/post/github-comments/). It's been broken for years, ever since I migrated from `acg.github.io` to this domain. I probably made a mistake somewhere in the Disqus migration tool but could never figure out what. If you feel a burning desire to rebutt or high-five something, [hit me up on twitter](https://twitter.com/alangrow) and I may link to it. Better yet, [open a github issue against this blog](https://github.com/acg/alangrow.com/issues/new).

