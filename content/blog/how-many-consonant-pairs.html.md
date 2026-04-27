
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "How Many Consonant Pairs Do We Actually Use?",
        "date": "2012-02-26T00:00:00-0000",
        "root": ".."
      }
    }

Of all possible consonant pairs, how many are actually used in the English language?

The question came up at a party during a disappointing Ouija board session where the spirits conjured gibberish like "QHPEV." Someone wondered aloud how difficult it was to pick a valid pair of consonants at random. We suspected most were invalid.

This is a nice little problem for the unix text processing toolset. I used the [2006 Scrabble Tournament Word List](https://norvig.com/ngrams/TWL06.txt) because `/usr/share/dict/words` contains many proper names and non-words. To get the count:

```sh
curl https://norvig.com/ngrams/TWL06.txt |
sed -nEe 's/(..)/\1\n/gp; s/\n//g; s/^.//; s/(..)/\1\n/gp;' |
grep '[^AEIOUY][^AEIOUY]' |
sort -u |
wc -l
```

A quick rundown of the shell pipeline:

- `s/(..)/\1\n/gp` splits & print pairs at even boundaries.
- `s/\n//gp` undoes the splits.
- `s/^.//` shifts even pair boundaries to odd ones.
- `s/(..)/\1\n/gp` splits & print pairs at odd boundaries.
- `grep '[^AEIOUY][^AEIOUY]'` filters out pairs with vowels.
- `sort -u | wc -l` counts unique consonant pairs.

There are 20 consonants in the language after removing AEIOUY, so that makes 400 possible pairs of consonants. Surprisingly, the count comes to 320, so 80% of all consonant pairs are in use!
