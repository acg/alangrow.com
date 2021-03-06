
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Recovering a Dying iPod Disk",
        "date": "2012-04-03T00:00:00-0000",
        "root": ".."
      }
    }

An [80GB iPod Classic](http://en.wikipedia.org/wiki/IPod_Classic#Sixth_generation) filled with 4 years of music started to die on us. The symptom: the menu screen suddenly showed "No Music," but disk usage was still nearly 100%. I figured this meant the internal 1.8" hard disk had started to go south and had taken some critical sectors with it.

That turned out to be the case. But here's how we recovered nearly 10,000 files from the iPod anyway...

### The Winning Ticket ###

Before things got any worse, I decided to grab an image of the entire disk:

```bash
sudo dd if=/dev/sdc bs=1M conv=noerror,sync | pv > ipod.img
```

The "conv=noerror" directive tells dd to keep on going if there are disk read errors instead of erroring out. (There were about a dozen. Sectors had probably been going bad for some time, and finally a critical one bit the dust.)

The "conv=sync" directive tells dd to write out an appropriately sized block of zeroes whenever there's an error reading a block. This is necessary, or file offsets will be wrong from the point of the error onward.

The pv command just shows some nice info about how much data is flowing through and how long it's taken. It's not essential here.

As described [below](#deadends_and_other_things_we_tried), I tried to fsck.vfat the first partition of the disk image, but this reported that an unusually high number of free cluster chains would be reclaimed. This indicated that FAT32 metadata had been damaged and that walking the complete filesystem directory structure wouldn't be possible anymore.

The new approach was to say, to hell with directory structure, let's just linearly scan the disk image for files and extract them. This needles-in-the-haystack approach isn't for everybody: you will lose filenames, permissions, directory locality etc. But most mp3s have self-identifying id3 tag metadata so we didn't care too much.

There are a couple programs that can find file needles in a disk image haystack. The one that worked was [PhotoRec](http://www.cgsecurity.org/wiki/PhotoRec), which can actually find much more than just photo files. For an opensource unix program it has a rather strange set of options and user interface. Anyway, I ran it with:

```bash
photorec /log /debug /d rescue ipod.img
```

All in all photorec recovered over 8,000 mp3s and some other files to boot.

    Pass 1 - Reading sector  135045680/155907592, 9944 files found
    Elapsed time 1h14m22s - Estimated time for achievement 0h11m29
    mp3: 8339 recovered
    mov: 1264 recovered
    txt: 129 recovered
    apple: 96 recovered
    tx?: 63 recovered
    jpg: 21 recovered
    aif: 13 recovered
    riff: 12 recovered
    mpg: 3 recovered
    gpg: 1 recovered
    others: 3 recovered

Afterwards, the files were scattered randomly in flat directories named rescue.1, rescue.2, rescue.3 etc:

```bash
ls rescue.1 | grep mp3 | head
```

    f0234384.mp3
    f0241008.mp3
    f0247536.mp3
    f0254352.mp3
    f0257680.mp3
    f0263664.mp3
    f0271120.mp3
    f0277872.mp3
    f0284784.mp3
    f0292176.mp3

If desired, they can be renamed into Artist + Album + Track + Title directories via a program like [supertag](http://search.cpan.org/~acg/supertag-0.2.1/supertag) (disclaimer: I'm the author). But I'm not sure iTunes even cares about filenames.

Addendum: as time has gone on, we've noticed that a fair percentage of the songs were truncated by photorec, something like 1 in 5. One of these rainy weekends I'm going to see if I can patch photorec's mp3 recognition.

### Dead-Ends and Other Things We Tried ###

The filesystem was W95 FAT32 but couldn't be mounted due to the bad sectors. Doing an fsck on the block device was also not possible because of read errors. The errors manifested themselves like this in dmesg:

    [64658.941382] sd 6:0:0:0: [sdc] Unhandled sense code
    [64658.941395] sd 6:0:0:0: [sdc] Result: hostbyte=DID_OK driverbyte=DRIVER_SENSE
    [64658.941407] sd 6:0:0:0: [sdc] Sense Key : Medium Error [current]
    [64658.941422] Info fld=0x0
    [64658.941428] sd 6:0:0:0: [sdc] Add. Sense: Unrecovered read error
    [64658.941442] sd 6:0:0:0: [sdc] CDB: Read(10): 28 00 00 00 00 40 00 00 01 00
    [64658.941470] end_request: I/O error, dev sdc, sector 512
    [64658.941484] Buffer I/O error on device sdc, logical block 64

After capturing the disk image, it was possible to run fsck.vfat directly on the partition file; it doesn't actually require a block device, which is cool.

To run fsck on the disk image file, we needed to extract the lone FAT32 partition into a file by itself. The trick here was figuring out where the partition started. Doing an fdisk on the actual block device for the iPod (/dev/sdc) to figure out the disk geometry helped. Using that geometry, this command let us figure out the sector offset of the first partition:

```bash
fdisk -u -C 14991 -b 4096 -l ipod.img
```

    Device Boot         Start         End      Blocks   Id  System
    ipod.img1              63    19488469    77953628    b  W95 FAT32

A trick to extract the partition image:

```bash
{ dd bs=4096 skip=63 count=0 ; pv ; } < ipod.img > ipod.img.part1
```

This took a while. Disks are slow.

Then I ran fsck.vfat on the partition image:

```bash
fsck.vfat -v -n ipod.img.part1
```

    ...
    Checking for unused clusters.
    Reclaimed 3561014 unused clusters (58343653376 bytes).
    ...

As you can see, it thought most of the disk consisted of free clusters -- this is bad. If I had tried to repair the disk via fsck, only a small fraction of the files would have been recovered.

You can see which file paths were traversed with the -l switch:

```bash
fsck.vfat -v -n -l ipod.img.part1
```

In our case this helped me verify that only a small number of files were actually going to be recovered by the fsck.

Once I gave up on fsck and embarked on needle-in-haystack file extraction, I tried [magicrescue](http://www.itu.dk/~jobr/magicrescue/). It found mp3s but kept saying "invalid mp3 file" and extracted almost none of them. It was also really slow -- it shells out to perl scripts and mpg123 to test mp3 validity. Yuck.

