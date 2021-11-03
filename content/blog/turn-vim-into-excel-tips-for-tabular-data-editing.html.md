
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Turn Vim Into Excel: Tips for Editing Tabular Data",
        "date": "2013-03-29T00:00:00-0000",
        "root": "..",
        "image": "../images/blog/vim-as-spreadsheet.png"
      }
    }

<div class="center image">
  <a href="../images/blog/vim-as-spreadsheet.png"><img src="../images/blog/vim-as-spreadsheet-thumbnail.png" /></a><br/>
  <small>Vim editing <a href="http://www.census.gov/econ/cbp/download/">some 2010 US census data</a></small>
</div>

[Vim](https://www.vim.org/) can edit just about anything, including tabular data. This post has a few tips for making stock Vim more spreadsheet-like.

We'll assume you're editing files in tab-separated value format (TSV). CSV is a [notoriously thorny](http://en.wikipedia.org/wiki/Comma-separated_values#Lack_of_a_standard) file format with plenty of edge cases and surprises, so if you have CSV files, it's simpler to sidestep all that and roundtrip CSV to TSV for editing.


## A Note on the TSV Format ##

To do TSV right, you should escape newline and tab characters in data. Here are two scripts, [csv2tsv](https://gist.github.com/acg/5312217) and [tsv2csv](https://gist.github.com/acg/5312238), that will handle escaping during CSV <-> TSV conversions.

Converting CSV to TSV, with C-style escaping:

    csv2tsv -e < file.csv > file.tsv

Converting TSV back to CSV, with C-style un-escaping:

    tsv2csv -e < file.tsv > file.csv


## Setting up Tabular Editing in Vim ##

Open the file:

    :e file.tsv

Excel numbers the rows, why can't we?

    :set number

Adjust your tab settings so you're editing with hard tabs:

    :setlocal noexpandtab

Now, widen the columns enough so they're aligned:

    :setlocal shiftwidth=20
    :setlocal softtabstop=20
    :setlocal tabstop=20

Fiddle with that number 20 as needed. As far as I can tell, Vim doesn't support variable tab stops. It would be real nifty if I was wrong about this. It would be even niftier if column width detection / tabstop setting could be automated.


## Tall Spreadsheets: Always-Visible Column Names Above ##

Typically, the first line of the tsv file is a header containing the column names. We want those column names to always be visible, no matter how far down in the file we scroll. The way we'll do this is by splitting the current window in two. The top window will only be 1 line high and will show the headers. The bottom window will be for data editing.

    :sp
    :0
    1 CTRL-W _
    CTRL-W j

At this point you should have two windows, one above the other showing the first row of column headers. If you don't have very many columns, then you're done.


## Wide Spreadsheets: Horizontal Scrolling ##

If you do have lots of columns, or very wide columns, you're probably noticing how confusing it looks when lines wrap. Your columns don't line up so well anymore. So turn off wrapping for both windows:

    :set nowrap
    CTRL-W k
    :set nowrap
    CTRL-W j

One problem remains: when you scroll right to edit columns in the data pane, the header pane doesn't scroll to the right with it. Once again, your columns aren't aligned.

Fortunately Vim has a solution: you can "bind" horizontal scrolling of the two windows. This forces them to scroll left and right in tandem.

    :set scrollopt=hor
    :set scrollbind
    CTRL-W k
    :set scrollbind
    CTRL-W j


## But What About Formulas and Calculations?! ##

It's true, Excel does way more than just edit tabular data. Vim is "just" an editor.

If you're up for some programming, this approach might work for you:

1. Start with your data tsv.
2. Mirror it with a second "formula tsv" that contains interpreted cells.
3. Write a program that will apply (2) to (1), "rendering" a tsv with calculated data.
4. View (3) in a read-only buffer. Separately edit the data and formula tsvs.

If you're not up for that, I [hear good things](https://twitter.com/hillelogram/status/1455949281165250561) about [VisiData](https://www.visidata.org).
