
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Qmail with a Let's Encrypt SSL Cert",
        "date": "2024-05-04T00:00:00-0000",
        "root": ".."
      }
    }


After a long hiatus, I am once again running a mailserver.

### Are You Crazy? It's 2024

A lot of us nerds got lazy and switched to hosted gmail about a decade ago. This consolidation has gradually corrupted some of our email ecosystem norms, and I think it's important to push back on that.

But it's also important to have an email that's fully under your control, even if you only use it as the recovery email for your primary gmail account. Watching [a friend](https://www.jacobcammack.com/) lose access to his primary gmail recently – with no working recovery email, and no recourse – scared me into action.

Finally, I also wanted to generate a [new gpg key](/alangrow.asc) now that [ed25519](https://musigma.blog/2021/05/09/gpg-ssh-ed25519.html) is widely supported. A gpg key with a gmail identity feels silly and unserious. My new key's identity is `i@` this domain. That's cool factor! In the apocalypse, you can send me email at this new address, and sleep well knowing that it's both encrypted-in-transit and encrypted-at-rest.

That's three reasons why. Onward with the writeup.

### Let's Encrypt

The world of mail evolved over the past decade, and TLS is now a must. Luckily, the world also evolved a free and easy way to get an SSL cert: [Let's Encrypt](https://letsencrypt.org/). It's great. This site uses it.

But that's https. We'd like to reuse the Let's Encrypt cert for smtp.

### Patching Qmail

Out of the box, `qmail` doesn't support SSL for inbound or outbound mail. To get both, you can apply the [`qmail-tls` patch](https://inoa.net/qmail-tls/) from [this `qmail` patch directory](https://notes.sagredo.eu/en/qmail-notes-185/patching-qmail-82.html). You may also want the `force-tls` patch.

I've also found the `any-to-cname` and `remove-cname-check` patches necessary to avoid DNSSEC-related nonsense and deferred / delayed emails. Like I said, things have evolved, and not always in a good way.

### Networking

Here's another revolting development: gmail will not attempt mail delivery to ports 465 of 587. It sure would be nice if it did, because then we could use always-on SSL. That would let us run stock `qmail-smtpd` under [`sslserver`](https://www.fehcom.de/ipnet/ucspi-ssl.html).

Alas, you need to run an smtp server with STARTTLS support on port 25. So make sure that most-intimidating-of-ports is open. The silver lining is that you'll be able to test your setup with `telnet`. So will the spammers, but SSL doesn't seem to slow them down these days anyway.

### Configuring Qmail for SSL

To do one-time generation of DH conversation keys:

```sh
/var/lib/qmail/bin/update_tmprsadh
```

Our patched `qmail` expects a combined public cert + chain + private key at `/var/lib/qmail/control/servercert.pem`. Since Let's Encrypt rotates your cert every 60-90 days, we can't just cat some files into place and forget about it. We need to regenerate `qmail-smtpd`'s cert and bounce the service whenever rotation happens.

Fortunately Let's Encrypt has renewal hooks. Put the following in a `+x` file at the location on line 2:

```sh
#!/bin/sh
# /etc/letsencrypt/renewal-hooks/deploy/deploy-qmail-servercert 
set -e
cd /etc/qmail
touch servercert.pem.tmp
chmod go-rwx servercert.pem.tmp
chown qmaild servercert.pem.tmp
cat "$RENEWED_LINEAGE"/fullchain.pem "$RENEWED_LINEAGE"/privkey.pem > servercert.pem.tmp
mv servercert.pem.tmp servercert.pem
cd qmail-smtpd
svc -h .
```

Note the careful permissioning of `servercert.pem` – it contains private key material.

To generate the cert the first time, and test that the hook will work for future cert rotations, force a renewal as root:

```sh
certbot renew --force-renewal
```

Be careful during testing that you don't force too many renewals. Let's Encrypt will throttle you after a few.

If you have multiple domains under Let's Encrypt, the hook will run multiple times. I'm not sure how to avoid that. Maybe it could skip out unless the primary domain is renewing.

### Testing It

First try `telnet example.com 25`. After the smtp server's `220`, respond with `EHLO`. If TLS is available you should see `250-STARTTLS`. Example test session:

    $ telnet example.com 25
    Trying 1.2.3.4...
    Connected to example.com.
    Escape character is '^]'.
    220 example.com ESMTP
    EHLO
    250-example.com
    250-STARTTLS
    250-PIPELINING
    250 8BITMIME

If you don't see `250-STARTTLS`, try these [debug tips](https://inoa.net/qmail-tls/debug.html).

To test that the server's cert chain is trusted and you can send mail over SSL, use this:

```sh
openssl s_client -starttls smtp -ign_eof -crlf -connect example.com:25
```

As an smtp protocol refresher, you can type in mail to deliver by hand, like so:

    MAIL FROM:<you@home.example.com>
    250 ok
    RCPT TO:<you@example.com>
    250 ok
    DATA
    354 go ahead
    Subject: test subject

    test body
    .
    250 ok 1714841964 qp 843479
    QUIT
    221 example.com

Once this works, you can try sending mails to your server from gmail. If you're a gsuite admin, their [Email Log Search](https://admin.google.com/ac/emaillogsearch) will tell you about delivery errors, and whether successful deliveries were actually encrypted in transit.

Outbound mail from your server should also be encrypted thanks to the `qmail-tls` patch. You'll see a big fat warning in gmail if not. For better deliverability, you'll also want to configure SPF, DKIM, and DMARC, which is way beyond the scope of this humble post.
