
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Inconsistent split Behavior in Python",
        "date": "2011-11-05T00:00:00-0000",
        "root": "..",
        "buried": true
      }
    }

Here's a futile but cathartic [bug report](http://bugs.python.org/issue13346) I filed against Python recently.

In Python, string.split and re.split both take an optional argument that limits the number of splits that are done. This is unlike Perl's split builtin, which limits the number of *pieces*. But it makes sense I guess, and consistency between the two languages is not something I'd necessarily expect.

However, consistency *within* a language...a reasonable expectation, no?

The inconsistency lies in how the string.split and re.split handle the edge cases of "do an unlimited number of splits" and "don't do any splits." The two agree that "unlimited splits" is the default. They don't agree on how to interpret the value of an explicit maxsplit parameter.

<style type="text/css">
.post .matrix {
  margin-top: 0.50em;
  margin-bottom: 0.50em;
  margin-left: auto;
  margin-right: auto;
}

.post .matrix td {
  border: 0.01em solid gray;
  padding: 0.25em 0.50em;
}

.post .matrix .col-header,
.post .matrix .row-header {
  background: #ddd;
}

.post .matrix .col-header.row-header {
  border: none;
  background: inherit;
}
</style>

<table class="matrix">
  <thead>
    <td class="col-header row-header"></td>
    <td class="col-header">maxsplit=0</td>
    <td class="col-header">maxsplit=-1</td>
  </thead>
  <tr>
    <td class="row-header">string.split</td>
    <td>no splits</td>
    <td>unlimited splits</td>
  </tr>
  <tr>
    <td class="row-header">re.split</td>
    <td>unlimited splits</td>
    <td>no splits</td>
  </tr>
</table>

I think string.split is doing the sensible thing here.

Of course, the "bug" has zero chance of being fixed at this point. I pretty much just filed it to create a search result for others similarly bitten, annoyed, or both.

