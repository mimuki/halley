# msync_fzf

A fzf-based mastodon timeline browser. Uses msync at <https://github.com/Kansattica/msync> for actual interaction, and fzf at <https://github.com/junegunn/fzf> for presentation: this repo is just a bunch of scripts to glue it all.

## Screenshots

A picture is worth a thousands words, right

![screenshot of msync_fzf with the view filtered on "tim chambers"](./filtered.png)

## Usage

```sh
> ./msync_fzf
```

FZF launches with all statuses, last one at the bottom. Here's an example of line:

```
[1438] Rob Ricci (@ricci@discuss.systems) <mekka okereke :verified: (@mekkaokereke@hachyderm.io)
```

- an index that makes it easier to follow when updating the list
- the author
- if present, the reblogger

When a line is highlighted with fzf, the post is displayed in the preview window.

To interact with your instance, you need to install and use msync. This allows offline reading and queuing of interactions. To synchronize, run `msync sync`

### Shortcuts

- enter will open the link to the post in your browser
- F5 refreshes the list
- ctrl-u to boost/reblog a post
- ctrl-s to star/ack a post

### Hack / To Be Hacked

The goal here is to use msync and fzf as workhorses, and glue them to fit my needs. Feel free to change it on your side and make it *yours*

Things that are interesting to dig:

- Add your own shortcuts, or change them by editing the source code directly

- Check out `color.awk` to see what colors you can use, change them, etc..

- Turns out I don't want to see notifications, so I don't read the `notifications.list` file. If I'm mentioned I'll see it in my home timeline anyway
Maybe add a `@` at the beginning of the line to surface them ?

- No built-in reply yet, but it's coming

- Not tested with multiple accounts, does it make sense ?

- "One line per status" makes scrolling kinda easier because you skip by whole status, but it also means less information displayed at each time. Maybe FZF isn't the right approach ?

## License

Parity Public License 7.0.0

See [LICENSE](./LICENSE) for the full text, or <https://paritylicense.com/versions/7.0.0.html> for more details
