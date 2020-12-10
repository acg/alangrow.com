
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "Slippery Device Names and Portable AMIs",
        "date": "2020-12-10T21:12:32-0000",
        "root": ".."
      }
    }

Pain, thy name is hotpluggable device name assignment.

In the course of migrating some EC2 servers from C3 to C5, I learned why this feature in newer linux kernels is controversial.

To be clear, most people couldn't care less whether their primary network interface is called `eth0` or `enx0150b6e42dfe`, or whether a drive appears as `/dev/xvda` or `/dev/nvme9n5`, as long as they can continue to do their Computer Stuff. For ops folks trying to make a portable system image, though, this can be a real problem.

My goal was to create an AMI that can be booted on a variety of EC2 instance types. Here's how I got there.

### Network Interfaces

Hotpluggable network interface names make sense for multi-homed systems, and systems that might change network configuration later.

They also make sense for consumer devices that don't need to be portably imaged. When was the last time you pulled the hard drive out of your laptop, put it in a different brand of laptop, and had everything just work? Would you even expect this to work? No, this is crazy talk.

However, those of us who operate and upgrade servers have different (higher?) expectations.

The essential problem is described in gory detail on debian's [NetworkInterfaceNames wiki page](https://wiki.debian.org/NetworkInterfaceNames). "We're not in the 90s anymore, network devices come and go, deal with it. That said, here are a dozen different ways to avoid this new nonsense..."

Adding `net.ifnames=0` boot parameters to `/etc/default/grub` worked for me:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="... net.ifnames=0"
GRUB_CMDLINE_LINUX="net.ifnames=0"
```

Follow this up with a perfunctory `update-grub`.

Importantly for portability, this means any config files under `/etc/` can refer to `eth0` directly, and that will continue to work even if you make an AMI and boot it on another instance type — so long as it has just one network interface.

### NVMe Disks

Next we have the disk problem. C5 instances use NVMe throughout, even for EBS storage. [The AWS docs warn us](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html) that:

> The block device driver can assign NVMe device names in a different order than you specified for the volumes in the block device mapping.

And oh boy, do they ever like to assign in different order.

If you only have one disk, you might never have this problem. I use multiple disks because:

1. Different subsystems have different access patterns and performance requirements. Using separate disks for, say, `/var/lib/postgresql/` and `/var/log/` lets you provision and tune them separately.
2. The disk boundary is a convenient blast radius. Have you ever had a server fill up with log files and grind to a halt? A separate `/var/log/` disk will contain the problem and let other subsystems continue to run normally.

So I've got 5 different NVMe disks attaching to an EC2 instance in random order. Once in a while it works, but usually home directories have become the database, logfiles are now volatile runtime state, and so on. A real Mister Potato Head mess.

[Russell Ballestrini](https://russell.ballestrini.net/contact/) ran into this same issue and wrote a nice script called [`ebsnvme-id`](https://russell.ballestrini.net/aws-nvme-to-block-mapping/). This lets you match up your randomly-ordered NVMe disks with the original names you specified in your EC2 block device mapping.

But we're not quite there yet. Armed with `ebsnvme-id`, you can create symlinks like `/dev/nvme1n1 -> /dev/xvdb`, but how and when you should you do this?

The `/dev` directory gets populated anew via `udev` during boot. So there's a right time to do this, and there are many wrong times to do this. My first attempt via `/etc/rc.local` failed horribly. It ran too late.

Eventually I came around to the idea of using `udev`, and I learned from this [nice udev primer](http://www.reactivated.net/writing_udev_rules.html) that udev rules can be flexible in the extreme. You can pattern match on device names. You can also run an external program that figures out how to rename a device. This culminated in the following magical one liner:

```sh
KERNEL=="nvme[0-9]*n1", PROGRAM="ebsnvme-namer %k", SYMLINK+="%c"
```

Save this to `70-persistent-ebsnvme.rules` under `/etc/udev/rules.d/`. You'll notice it doesn't hardcode any device names, so it's safe to include in a portable machine image. It creates `/dev` symlinks that look like:

```text
lrwxrwxrwx 1 root root 7 Dec  9 14:34 xvda1 -> nvme0n1
lrwxrwxrwx 1 root root 7 Dec  9 14:34 xvdd -> nvme1n1
lrwxrwxrwx 1 root root 7 Dec  9 14:34 xvde -> nvme3n1
lrwxrwxrwx 1 root root 7 Dec  9 14:34 xvdf -> nvme4n1
lrwxrwxrwx 1 root root 7 Dec  9 14:34 xvdg -> nvme2n1
```

These match the old disk device names on my C3 instances. All my scripts and config files that reference specific `xvd*` names? In the end, not a single one needed changing for the C3 -> C5 upgrade!

Finally, here's the `ebsnvme-namer` script:

```sh
#!/bin/sh -e
ebsdev=`ebsnvme-id --block-dev /dev/"$1"`
echo xvd${ebsdev##sd}
```
