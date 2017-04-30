
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "How to printf a length-delimited string",
        "date": "2012-11-15T00:00:00-0000",
        "root": ".."
      }
    }

Sometimes you're dealing with a string that isn't null-delimited, but rather length-delimited, and you wind up doing somersaults just to print it out:

{% highlight c %}
void logit(const char *string, size_t length) {
  char buf[255];
  strncpy(buf, string, sizeof(buf));
  buf[sizeof(buf) - 1] = '\0';
  fprintf(stderr, "debug: %s\n", buf);
}
{% endhighlight %}

The extra copying isn't necessary, and you don't have to live with the potential length-truncation either. Did you know `printf(3)` can format length-delimited strings directly? Buried in the man page is this little gem:

    The precision

    An optional precision, in the form of a period ('.') followed by an optional decimal digit string. Instead of a decimal digit string one may write "*" or "*m$" (for some decimal integer m) to specify that the precision is given in the next argument, or in the m-th argument, respectively, which must be of type int. This gives ... the maximum number of characters to be printed from a string for s and S conversions.

With that in mind, we can just write:

{% highlight c %}
void logit(const char *string, size_t length) {
  fprintf(stderr, "debug: %.*s\n", (int)length, string);
}
{% endhighlight %}

