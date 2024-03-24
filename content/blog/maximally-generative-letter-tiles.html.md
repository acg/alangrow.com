
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Maximally Generative Letter Tiles",
        "date": "2024-03-23T00:00:00-0000",
        "root": ".."
      }
    }

---

While building [a word game](https://dfeldman.github.io/ambigame/game.html), Daniel Feldman ran into a problem that nerdsniped me instantly: what choice of twenty letter-pair tiles generates the most words?

A number of approaches were proposed in [the ensuing thread](https://twitter.com/d_feldman/status/1761611250776117504), with some folks even wondering if the problem might be NP-complete. In this post I'll present a greedy algorithm that's linear in the dictionary size. I believe this finds an optimal solution, but haven't proven that formally.

Let's first define the problem.

### The Problem Definition

There are 26 alphabet letters, and each tile has two letters on it, so that works out to a total of 26 * 26 = 676 possible tiles. We only get to choose a meager 20 of these 676 to form our tileset. Like in Scrabble, you can then rearrange subsets of the tileset to form dictionary words. The problem: find the tileset of size 20 that lets you form the most dictionary words.

### A Much Smaller Example Tileset

Here's all possible tiles, with a specific size-3 tileset <code class="chosen">ed,pi,ti</code> highlighted:

<style type="text/css">
table.tiles {
  margin: 2em 0 1em 1em;
  font-family: monospace;
  font-size: 80%;
}
table.tiles td {
  width: 2em;
  height: 2em;
  text-align: center;
  vertical-align: middle;
}
table.tiles td.chosen,
code.chosen {
  background-color: rgba(0, 0, 255, 0.15);
}
</style>
<table class="tiles">
<tr> <td>aa</td> <td>ab</td> <td>ac</td> <td>ad</td> <td>ae</td> <td>af</td> <td>ag</td> <td>ah</td> <td>ai</td> <td>aj</td> <td>ak</td> <td>al</td> <td>am</td> <td>an</td> <td>ao</td> <td>ap</td> <td>aq</td> <td>ar</td> <td>as</td> <td>at</td> <td>au</td> <td>av</td> <td>aw</td> <td>ax</td> <td>ay</td> <td>az</td> </tr>
<tr> <td>ba</td> <td>bb</td> <td>bc</td> <td>bd</td> <td>be</td> <td>bf</td> <td>bg</td> <td>bh</td> <td>bi</td> <td>bj</td> <td>bk</td> <td>bl</td> <td>bm</td> <td>bn</td> <td>bo</td> <td>bp</td> <td>bq</td> <td>br</td> <td>bs</td> <td>bt</td> <td>bu</td> <td>bv</td> <td>bw</td> <td>bx</td> <td>by</td> <td>bz</td> </tr>
<tr> <td>ca</td> <td>cb</td> <td>cc</td> <td>cd</td> <td>ce</td> <td>cf</td> <td>cg</td> <td>ch</td> <td>ci</td> <td>cj</td> <td>ck</td> <td>cl</td> <td>cm</td> <td>cn</td> <td>co</td> <td>cp</td> <td>cq</td> <td>cr</td> <td>cs</td> <td>ct</td> <td>cu</td> <td>cv</td> <td>cw</td> <td>cx</td> <td>cy</td> <td>cz</td> </tr>
<tr> <td>da</td> <td>db</td> <td>dc</td> <td>dd</td> <td>de</td> <td>df</td> <td>dg</td> <td>dh</td> <td>di</td> <td>dj</td> <td>dk</td> <td>dl</td> <td>dm</td> <td>dn</td> <td>do</td> <td>dp</td> <td>dq</td> <td>dr</td> <td>ds</td> <td>dt</td> <td>du</td> <td>dv</td> <td>dw</td> <td>dx</td> <td>dy</td> <td>dz</td> </tr>
<tr> <td>ea</td> <td>eb</td> <td>ec</td> <td class="chosen">ed</td> <td>ee</td> <td>ef</td> <td>eg</td> <td>eh</td> <td>ei</td> <td>ej</td> <td>ek</td> <td>el</td> <td>em</td> <td>en</td> <td>eo</td> <td>ep</td> <td>eq</td> <td>er</td> <td>es</td> <td>et</td> <td>eu</td> <td>ev</td> <td>ew</td> <td>ex</td> <td>ey</td> <td>ez</td> </tr>
<tr> <td>fa</td> <td>fb</td> <td>fc</td> <td>fd</td> <td>fe</td> <td>ff</td> <td>fg</td> <td>fh</td> <td>fi</td> <td>fj</td> <td>fk</td> <td>fl</td> <td>fm</td> <td>fn</td> <td>fo</td> <td>fp</td> <td>fq</td> <td>fr</td> <td>fs</td> <td>ft</td> <td>fu</td> <td>fv</td> <td>fw</td> <td>fx</td> <td>fy</td> <td>fz</td> </tr>
<tr> <td>ga</td> <td>gb</td> <td>gc</td> <td>gd</td> <td>ge</td> <td>gf</td> <td>gg</td> <td>gh</td> <td>gi</td> <td>gj</td> <td>gk</td> <td>gl</td> <td>gm</td> <td>gn</td> <td>go</td> <td>gp</td> <td>gq</td> <td>gr</td> <td>gs</td> <td>gt</td> <td>gu</td> <td>gv</td> <td>gw</td> <td>gx</td> <td>gy</td> <td>gz</td> </tr>
<tr> <td>ha</td> <td>hb</td> <td>hc</td> <td>hd</td> <td>he</td> <td>hf</td> <td>hg</td> <td>hh</td> <td>hi</td> <td>hj</td> <td>hk</td> <td>hl</td> <td>hm</td> <td>hn</td> <td>ho</td> <td>hp</td> <td>hq</td> <td>hr</td> <td>hs</td> <td>ht</td> <td>hu</td> <td>hv</td> <td>hw</td> <td>hx</td> <td>hy</td> <td>hz</td> </tr>
<tr> <td>ia</td> <td>ib</td> <td>ic</td> <td>id</td> <td>ie</td> <td>if</td> <td>ig</td> <td>ih</td> <td>ii</td> <td>ij</td> <td>ik</td> <td>il</td> <td>im</td> <td>in</td> <td>io</td> <td>ip</td> <td>iq</td> <td>ir</td> <td>is</td> <td>it</td> <td>iu</td> <td>iv</td> <td>iw</td> <td>ix</td> <td>iy</td> <td>iz</td> </tr>
<tr> <td>ja</td> <td>jb</td> <td>jc</td> <td>jd</td> <td>je</td> <td>jf</td> <td>jg</td> <td>jh</td> <td>ji</td> <td>jj</td> <td>jk</td> <td>jl</td> <td>jm</td> <td>jn</td> <td>jo</td> <td>jp</td> <td>jq</td> <td>jr</td> <td>js</td> <td>jt</td> <td>ju</td> <td>jv</td> <td>jw</td> <td>jx</td> <td>jy</td> <td>jz</td> </tr>
<tr> <td>ka</td> <td>kb</td> <td>kc</td> <td>kd</td> <td>ke</td> <td>kf</td> <td>kg</td> <td>kh</td> <td>ki</td> <td>kj</td> <td>kk</td> <td>kl</td> <td>km</td> <td>kn</td> <td>ko</td> <td>kp</td> <td>kq</td> <td>kr</td> <td>ks</td> <td>kt</td> <td>ku</td> <td>kv</td> <td>kw</td> <td>kx</td> <td>ky</td> <td>kz</td> </tr>
<tr> <td>la</td> <td>lb</td> <td>lc</td> <td>ld</td> <td>le</td> <td>lf</td> <td>lg</td> <td>lh</td> <td>li</td> <td>lj</td> <td>lk</td> <td>ll</td> <td>lm</td> <td>ln</td> <td>lo</td> <td>lp</td> <td>lq</td> <td>lr</td> <td>ls</td> <td>lt</td> <td>lu</td> <td>lv</td> <td>lw</td> <td>lx</td> <td>ly</td> <td>lz</td> </tr>
<tr> <td>ma</td> <td>mb</td> <td>mc</td> <td>md</td> <td>me</td> <td>mf</td> <td>mg</td> <td>mh</td> <td>mi</td> <td>mj</td> <td>mk</td> <td>ml</td> <td>mm</td> <td>mn</td> <td>mo</td> <td>mp</td> <td>mq</td> <td>mr</td> <td>ms</td> <td>mt</td> <td>mu</td> <td>mv</td> <td>mw</td> <td>mx</td> <td>my</td> <td>mz</td> </tr>
<tr> <td>na</td> <td>nb</td> <td>nc</td> <td>nd</td> <td>ne</td> <td>nf</td> <td>ng</td> <td>nh</td> <td>ni</td> <td>nj</td> <td>nk</td> <td>nl</td> <td>nm</td> <td>nn</td> <td>no</td> <td>np</td> <td>nq</td> <td>nr</td> <td>ns</td> <td>nt</td> <td>nu</td> <td>nv</td> <td>nw</td> <td>nx</td> <td>ny</td> <td>nz</td> </tr>
<tr> <td>oa</td> <td>ob</td> <td>oc</td> <td>od</td> <td>oe</td> <td>of</td> <td>og</td> <td>oh</td> <td>oi</td> <td>oj</td> <td>ok</td> <td>ol</td> <td>om</td> <td>on</td> <td>oo</td> <td>op</td> <td>oq</td> <td>or</td> <td>os</td> <td>ot</td> <td>ou</td> <td>ov</td> <td>ow</td> <td>ox</td> <td>oy</td> <td>oz</td> </tr>
<tr> <td>pa</td> <td>pb</td> <td>pc</td> <td>pd</td> <td>pe</td> <td>pf</td> <td>pg</td> <td>ph</td> <td class="chosen">pi</td> <td>pj</td> <td>pk</td> <td>pl</td> <td>pm</td> <td>pn</td> <td>po</td> <td>pp</td> <td>pq</td> <td>pr</td> <td>ps</td> <td>pt</td> <td>pu</td> <td>pv</td> <td>pw</td> <td>px</td> <td>py</td> <td>pz</td> </tr>
<tr> <td>qa</td> <td>qb</td> <td>qc</td> <td>qd</td> <td>qe</td> <td>qf</td> <td>qg</td> <td>qh</td> <td>qi</td> <td>qj</td> <td>qk</td> <td>ql</td> <td>qm</td> <td>qn</td> <td>qo</td> <td>qp</td> <td>qq</td> <td>qr</td> <td>qs</td> <td>qt</td> <td>qu</td> <td>qv</td> <td>qw</td> <td>qx</td> <td>qy</td> <td>qz</td> </tr>
<tr> <td>ra</td> <td>rb</td> <td>rc</td> <td>rd</td> <td>re</td> <td>rf</td> <td>rg</td> <td>rh</td> <td>ri</td> <td>rj</td> <td>rk</td> <td>rl</td> <td>rm</td> <td>rn</td> <td>ro</td> <td>rp</td> <td>rq</td> <td>rr</td> <td>rs</td> <td>rt</td> <td>ru</td> <td>rv</td> <td>rw</td> <td>rx</td> <td>ry</td> <td>rz</td> </tr>
<tr> <td>sa</td> <td>sb</td> <td>sc</td> <td>sd</td> <td>se</td> <td>sf</td> <td>sg</td> <td>sh</td> <td>si</td> <td>sj</td> <td>sk</td> <td>sl</td> <td>sm</td> <td>sn</td> <td>so</td> <td>sp</td> <td>sq</td> <td>sr</td> <td>ss</td> <td>st</td> <td>su</td> <td>sv</td> <td>sw</td> <td>sx</td> <td>sy</td> <td>sz</td> </tr>
<tr> <td>ta</td> <td>tb</td> <td>tc</td> <td>td</td> <td>te</td> <td>tf</td> <td>tg</td> <td>th</td> <td class="chosen">ti</td> <td>tj</td> <td>tk</td> <td>tl</td> <td>tm</td> <td>tn</td> <td>to</td> <td>tp</td> <td>tq</td> <td>tr</td> <td>ts</td> <td>tt</td> <td>tu</td> <td>tv</td> <td>tw</td> <td>tx</td> <td>ty</td> <td>tz</td> </tr>
<tr> <td>ua</td> <td>ub</td> <td>uc</td> <td>ud</td> <td>ue</td> <td>uf</td> <td>ug</td> <td>uh</td> <td>ui</td> <td>uj</td> <td>uk</td> <td>ul</td> <td>um</td> <td>un</td> <td>uo</td> <td>up</td> <td>uq</td> <td>ur</td> <td>us</td> <td>ut</td> <td>uu</td> <td>uv</td> <td>uw</td> <td>ux</td> <td>uy</td> <td>uz</td> </tr>
<tr> <td>va</td> <td>vb</td> <td>vc</td> <td>vd</td> <td>ve</td> <td>vf</td> <td>vg</td> <td>vh</td> <td>vi</td> <td>vj</td> <td>vk</td> <td>vl</td> <td>vm</td> <td>vn</td> <td>vo</td> <td>vp</td> <td>vq</td> <td>vr</td> <td>vs</td> <td>vt</td> <td>vu</td> <td>vv</td> <td>vw</td> <td>vx</td> <td>vy</td> <td>vz</td> </tr>
<tr> <td>wa</td> <td>wb</td> <td>wc</td> <td>wd</td> <td>we</td> <td>wf</td> <td>wg</td> <td>wh</td> <td>wi</td> <td>wj</td> <td>wk</td> <td>wl</td> <td>wm</td> <td>wn</td> <td>wo</td> <td>wp</td> <td>wq</td> <td>wr</td> <td>ws</td> <td>wt</td> <td>wu</td> <td>wv</td> <td>ww</td> <td>wx</td> <td>wy</td> <td>wz</td> </tr>
<tr> <td>xa</td> <td>xb</td> <td>xc</td> <td>xd</td> <td>xe</td> <td>xf</td> <td>xg</td> <td>xh</td> <td>xi</td> <td>xj</td> <td>xk</td> <td>xl</td> <td>xm</td> <td>xn</td> <td>xo</td> <td>xp</td> <td>xq</td> <td>xr</td> <td>xs</td> <td>xt</td> <td>xu</td> <td>xv</td> <td>xw</td> <td>xx</td> <td>xy</td> <td>xz</td> </tr>
<tr> <td>ya</td> <td>yb</td> <td>yc</td> <td>yd</td> <td>ye</td> <td>yf</td> <td>yg</td> <td>yh</td> <td>yi</td> <td>yj</td> <td>yk</td> <td>yl</td> <td>ym</td> <td>yn</td> <td>yo</td> <td>yp</td> <td>yq</td> <td>yr</td> <td>ys</td> <td>yt</td> <td>yu</td> <td>yv</td> <td>yw</td> <td>yx</td> <td>yy</td> <td>yz</td> </tr>
<tr> <td>za</td> <td>zb</td> <td>zc</td> <td>zd</td> <td>ze</td> <td>zf</td> <td>zg</td> <td>zh</td> <td>zi</td> <td>zj</td> <td>zk</td> <td>zl</td> <td>zm</td> <td>zn</td> <td>zo</td> <td>zp</td> <td>zq</td> <td>zr</td> <td>zs</td> <td>zt</td> <td>zu</td> <td>zv</td> <td>zw</td> <td>zx</td> <td>zy</td> <td>zz</td> </tr>
</table>

The <code class="chosen">ed,pi,ti</code> tileset generates these 6 words:

0. <code class="chosen">pi</code>
0. <code class="chosen">pied</code>
0. <code class="chosen">pitied</code>
0. <code class="chosen">ti</code>
0. <code class="chosen">tied</code>
0. <code class="chosen">tipi</code>

Note that throughout this post I'll be using `/usr/share/dict/american-english` as the dictionary.

### Initial Approach: Maximum Letter Pair Frequency

Before we get into the final greedy approach, let's try something more straightforward.

When Alfred Butts designed the Scrabble tileset, he looked at the front page of the New York Times and [hand-tabulated letter frequencies](https://en.wikipedia.org/wiki/Alfred_Mosher_Butts#Scrabble). He then added more copies of frequently occurring letters.

While our problem is different in a couple ways – unlike Scrabble, duplicate tiles aren't allowed, and also unlike Scrabble, we can only hope to generate a small fraction of all dictionary words — this approach feels intuitively promising.

We'll iterate through the dictionary, split each word into letter-pairs, and count pair occurrences. But note:

- Words of odd length get thrown out, because they can't be formed by a sequence of pairs.
- Words that use the same letter pair twice also get thrown out, since, per the problem definition, our tileset doesn't contain repeats.

Among the words that remain, we'll pick the most frequently occurring pairs as our tileset.

Here's the Python [code](https://github.com/acg/lettergen/blob/master/maxfreq/lettergen2):

```python
from collections import defaultdict
import sys
import re

args = sys.argv[1:]
NTILES = int(args.pop(0))
RE_VALID_WORD = re.compile(r'^([a-z][a-z]){1,%s}$' % NTILES)
RE_REPEATED_PAIR = re.compile(r'^(..)*(?P<letter1>.)(?P<letter2>.)(?P=letter1)(?P=letter2)')

freqs = defaultdict(lambda: 0)
words = []

for word in open(args.pop(0)) if args else sys.stdin:
  word = word.rstrip('\n')

  # discard words with odd letter counts, capitals, apostrophes, etc.
  if not RE_VALID_WORD.match(word):
    continue

  # split the word into letter pairs.
  pairs = re.findall(r'.{2}', word)

  # discard words with repeated pairs.
  if RE_REPEATED_PAIR.match(''.join(sorted(pairs))):
    continue

  # add to valid word list. update letter pair statistics.
  words.append(word)
  for pair in pairs:
    freqs[pair] += 1

# our tileset is the top N most frequently occurring pairs.
tileset = set(sorted(freqs.keys(), key=lambda pair: freqs[pair])[-NTILES:])

# report the tileset.
print(','.join(sorted(tileset)))

# report all generatable dictionary words.
for word in words:
  if not set(re.findall(r'.{2}', word)).difference(tileset):
    print(word)
```

You'll notice the program takes the tileset size, `NTILES`, as a command line argument. We can use this to run a sanity check on much smaller tilesets. When we do, we immediately see a problem:

```sh
./lettergen2 3 /usr/share/dict/american-english
ed,er,es
es
```

It's no surprise that <code class="chosen">ed,er,es</code> occur most frequently, since they're common English word endings. However, word endings by themselves don't play nice together. They need word beginnings and middles in order to form complete words. And we already know from the small example above that <code class="chosen">ed,pi,ti</code> generates 6 words. Generating 1 word, <code class="chosen">es</code>, is suboptimal.

This maximum letter pair frequency approach was a greedy algorithm, and its failure makes one despair of finding any optimal greedy (read: simple) algorithm. To construct the optimal tileset from scratch, perhaps you need to perform search on a graph of successively longer words, so you're passing from word beginnings to word middles to word endings? [I pursued this approach myself](https://twitter.com/alangrow/status/1761638946939994133) before giving up. Ruminate long enough, and your thoughts may even turn to dark subjects like the [set cover problem](https://en.wikipedia.org/wiki/Set_cover_problem), which is NP-Complete.

That level of despair didn't feel right to me though. Our problem isn't the same as the set cover problem, which seeks a set-of-sets that **union** together to form a bigger set. If we accept a set-theoretic framing and decide we're working with 676 sets, one for each letter pair, and each one containing all the words that particular letter pair occurs in, then what we seek is a set-of-sets with maximal **intersection**.

And that's when it occurred to me to try a new greedy approach, but this time working backwards. Instead of constructing the tileset from scratch by greedily picking the next best tile to add, what if we started with the full size 676 tileset, and greedily picked the least-bad tile to remove, until only 20 tiles remained?

### Final Approach: Subtractive Minimum Damage

Without further ado, here's Python [code](https://github.com/acg/lettergen/blob/master/subtractive/lettergen2) for this new approach:

```python
from collections import defaultdict
import sys
import re

args = sys.argv[1:]
NTILES = int(args.pop(0))
RE_VALID_WORD = re.compile(r'^([a-z][a-z]){1,%s}$' % NTILES)
RE_REPEATED_PAIR = re.compile(r'^(..)*(?P<letter1>.)(?P<letter2>.)(?P=letter1)(?P=letter2)')

words = defaultdict(set)

for word in open(args.pop(0)) if args else sys.stdin:
  word = word.rstrip('\n')

  # discard words with odd letter counts, capitals, apostrophes, etc.
  if not RE_VALID_WORD.match(word):
    continue

  # split the word into letter pairs.
  pairs = re.findall(r'.{2}', word)

  # discard words with repeated pairs.
  if RE_REPEATED_PAIR.match(''.join(sorted(pairs))):
    continue

  # add the word to a separate set for each of its letter pairs.
  for pair in pairs:
    words[pair].add(word)

# work backwards from 676 to NTILES.
# remove the letter pair that causes the least damage at every step.
while len(words) > NTILES:
  least_damaging_pair = min(words.keys(), key=lambda pair: len(words[pair]))
  lost_words = words.pop(least_damaging_pair)
  words = dict((pair, words.difference(lost_words)) for pair, words in words.items())

# report the tileset.
print(','.join(sorted(words.keys())))

# report all generatable dictionary words.
for word in sorted(set().union(*words.values())):
  print(word)
```

As you can see, the setup is substantially the same. This time, instead of counting appearances of each letter pair, we're establishing a separate set of words for each of the 676 letter pairs. If a word uses a letter pair, it appears in that pair's set.

This gives us a direct and `O(1)` way of measuring the damage incurred by removing a letter pair: it is simply the size of its set.

After the dictionary has been scanned, we start with all letter pairs in play, and we can begin greedy removal. At each step we pick the letter that inflicts the least amount of damage in terms of formable words. Note that any word longer than 2 letters will appear in multiple sets, and we have to remember to remove these extra copies of every "lost" word. Python's [`set` data type](https://docs.python.org/3.8/library/stdtypes.html#set) is doing a lot of the heavy lifting this time.

### Results

You can use [acg/lettergen](https://github.com/acg/lettergen) to compare the results of the two approaches, which I'm calling `maxfreq` and `subtractive`. Simply type `make` and wait a few seconds:

```sh
make
maxfreq/lettergen1 20 /usr/share/dict/words > maxfreq/results1
maxfreq/lettergen2 20 /usr/share/dict/words > maxfreq/results2
subtractive/lettergen1 20 /usr/share/dict/words > subtractive/results1
subtractive/lettergen2 20 /usr/share/dict/words > subtractive/results2

maxfreq/results1: a,b,c,d,e,f,g,h,i,k,l,m,n,o,p,r,s,t,u,y (12392 words)
maxfreq/results2: al,at,co,de,ed,en,er,es,in,le,li,ly,ng,on,re,ri,rs,st,te,ti (172 words)
subtractive/results1: a,b,c,d,e,f,g,h,i,k,l,m,n,o,p,r,s,t,u,y (12392 words)
subtractive/results2: ar,ca,co,de,di,ed,er,es,in,li,ng,nt,ra,re,ri,si,st,te,ti,ve (292 words)
```

For completeness, I wrote Python scripts that handle the 1-letter tile case (`lettergen1`). There are only 26 tiles to pick the 20 from, and you can see that both approaches arrive at the same result of 12,302 formable words.

The 2-letter tile case (`lettergen2`) is another story. Maximum Letter Pair Frequency comes up with a tileset that generates 172 words, but Subtractive Minimum Damage does substantially better by finding a 292-word-generating tileset (1.7x better). You'll find the full lists of formable words at `{maxfreq,subtractive}/results2`.

So according to Subtractive Minimum Damage, the optimal tileset is the following:

<code class="chosen">ar,ca,co,de,di,ed,er,es,in,li,ng,nt,ra,re,ri,si,st,te,ti,ve</code>

It's also interesting to experiment with different tileset sizes. For instance, try `make -B NTILES=100`. You'll notice as `NTILES` gets larger, the `maxfreq` approach converges on the `subtractive` approach. This makes sense: they should agree for `NTILES=676` because there are no letter pair decisions to make. And in fact they should agree even earlier than that, since English [doesn't use all possible letter pairs](./how-many-consonant-pairs).

### Open Questions & Further Research

**Yes, but is Subtractive Minimum Damage optimal?** The answer is I don't know! I vaguely remember proving greedy optimality once in undergrad computer science, but that was two decades ago. Pointers welcome.

**What happens if the tileset can have repeats?** I haven't thought about this too deeply, but it seems like it would spell trouble for a greedy approach, which can no longer make stepwise progress towards [optimal subproblems](https://en.wikipedia.org/wiki/Greedy_algorithm#Specifics).

**What about words of odd length?** Yeah it's awkward we have to exclude those, and it makes even less sense when you look at what motivated this problem ([Daniel's Ambigame](https://dfeldman.github.io/ambigame/game.html)). One approach would be to pad all odd-lettered dictionary words with a trailing period, and then add `a.`, `b.`, `c.`, and so on to the possible letter tiles. A similar trick with leading padding might let you split words after the 1st, 3rd, 5th etc character instead of always splitting at even indexes.

**Is this a known problem?** I mean surely Knuth solved this like 50 years ago? I found many related problems, but not this specific one. I worry this means it's considered too easy / too obvious, and I should feel embarrassed for writing a whole blog post about it. Anyway, please reach out if you know.

**Is Scrabble's tileset optimal?** I dabble in Scrabble myself, and I'd always heard it wasn't. In researching this, I learned that Peter Norvig has calculated [more accurate English letter frequencies](https://norvig.com/scrabble-letter-scores.html) than Alfred Butt's. Norvig has a couple proposals for a better Scrabble tileset at the link. TL;DR no.