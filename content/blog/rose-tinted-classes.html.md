
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Rose Tinted Classes: An SVG Filter Function CSS Trick",
        "date": "2025-08-12T00:00:00-0000",
        "root": ".."
      }
    }


In this post, we'll use CSS and SVG filter functions to tint an element's content Rose Quartz, [Pantone's 2016 Color of the Year](https://www.pantone.com/articles/color-of-the-year/color-of-the-year-2016).

The exact hex triplet for Rose Quartz is probably a trade secret, so I'll be using <span class="swatch" style="--color: #F7CAC9" data-color="#F7CAC9"></span> and praying I don't get sued by Big Color.

Here's the content we're trying to rose tint:

<div class="illustration">
<figure>
  <h3>Homesteading in Pie Town</h3>
  <img src="../images/blog/caudill-homesteaders.jpg" />
  <figcaption><i>Faro and Doris Caudill, homesteaders, Pie Town, New Mexico.</i> Faro and Doris got divorced a couple years after this picture was taken; she ended up homesteading in Alaska. Kodachrome by Russell Lee, 1940.</figcaption>
</figure>
</div>

### The Old Solution

Alas, there's no CSS filter function that colorizes content. For many years, the [recommended hack](https://stackoverflow.com/a/29958459) was to apply the [`sepia()`](https://developer.mozilla.org/en-US/docs/Web/CSS/filter-function/sepia) filter, then [`hue-rotate()`](https://developer.mozilla.org/en-US/docs/Web/CSS/filter-function/hue-rotate) your way to the target tint color. The `sepia()` filter did double duty in this approach. It desaturated the content to grayscale, then applied a common tint color to everything.

If traveling back to the 1800s to introduce color seems bonkers, you're not alone. That part was strange, but the hard part was figuring out how to rotate sepia to your target hue, then adjusting brightness and saturation to match the target. People even wrote [calculators for this](https://codepen.io/sosuke/pen/Pjoqqp).

Unfortunately, the whole sepia rotation approach is doomed. You can't precisely reach all target colors this way. For some target colors, things will always look a little bit off.

There must be a better way!

### The New Solution

Enter [`<feColorMatrix>`](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/feColorMatrix). This SVG filter element lets you define an `(R,G,B,A)` `->` `(R',G',B',A')` color transform in matrix multiplication terms. Armed with [this](https://stackoverflow.com/a/46536304), you can finally do precise colorization. After desaturating the content with a `grayscale()` filter, the new solution uses `<feColorMatrix>` to tint it with the target color:

```xml
<svg id="tint" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="colorize" color-interpolation-filters="sRGB">
      <feColorMatrix type="matrix" values="0.969 0 0 0 0
                                           0 0.792 0 0 0
                                           0 0 0.788 0 0
                                           0 0 0 1 0" />
    </filter>
  </defs>
</svg>
```

Note how our Rose Quartz tint color – `#F7CAC9` `=` `(0.969,0.792,0.788)` – appears along the diagonal. Change that to whatever tint color you're targeting.

Using these SVG filters from CSS is easy. Just chain them:

```css
.rose {
  filter: grayscale(1) url(#colorize);
}
svg#tint {
  display: none;
}
```

And here's the result:

<div class="illustration">
<figure class="rose">
  <h3>Homesteading in Pie Town</h3>
  <img src="../images/blog/caudill-homesteaders.jpg" />
  <figcaption><i>Faro and Doris Caudill, homesteaders, Pie Town, New Mexico.</i> Faro and Doris got divorced a couple years after this picture was taken; she ended up homesteading in Alaska. Kodachrome by Russell Lee, 1940.</figcaption>
</figure>
</div>

Notice how only the content is tinted, and the background behind the photograph is unchanged. This approach will work even for image content with transparent and translucent pixels. The final row of the `feColorMatrix` passes the alpha channel through unchanged.

What doesn't quite work: the resulting brightness falls off more steeply than it should. This is because we're effectively squaring a `[0,1]` brightness value when grayscale pixels are multiplied by the original color. Ideally, like translucency, luminance would also be conserved. If you have a suggestion here, please drop me a line!

<svg id="tint" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="colorize" color-interpolation-filters="sRGB">
      <feColorMatrix type="matrix" values="0.969 0 0 0 0
                                           0 0.792 0 0 0
                                           0 0 0.788 0 0
                                           0 0 0 1 0" />
    </filter>
  </defs>
</svg>

<style>
.swatch {
 --color: attr(data-color);
  white-space: nowrap;
}
.swatch::before {
  content: '■';
  color: var(--color);
}
.swatch::after {
  content: attr(data-color);
}
.illustration {
  background-color: rgb(32, 32, 32);
  padding: 0.5em 0;
  margin: 1.5em 0;
}
.illustration h3 {
  margin: 0.5em 0;
}
.illustration img {
  width: 100%;
}
.illustration figcaption {
  color: white;
  margin: 1em 0;
}
.rose {
  filter: grayscale(1) url(#colorize);
}
svg#tint {
  width: 0;
  height: 0;
}
</style>
