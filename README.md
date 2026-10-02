# Pi-hole streaming filters

Service and device rules extracted from the supplied `streaming-whitelist (1).txt` and `streaming-blacklist (1).txt`. Those files attribute the suggestions to a community post **last updated July 10, 2025**; no original post URL was supplied. This date describes the source, not a recent playback test.

DNS blocking cannot reliably remove streaming ads. Ads and video may share hosts, and server-side ad insertion can make DNS rules ineffective or break playback. These are candidates to test on your own devices, not a verified compatibility list.

## Files and downloads

Each rule file is UTF-8 plain text with one entry per line, without headings, comments, or blank lines. Original rule order and patterns are preserved; all literal dots in the supplied regexes were already escaped.

| File | Pi-hole type | Entries | Download |
| --- | --- | ---: | --- |
| [allowlist-exact.txt](allowlist-exact.txt) | Exact allow | 44 | [Raw file](https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main/allowlist-exact.txt) |
| [allowlist-regex.txt](allowlist-regex.txt) | Regex allow | 2 | [Raw file](https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main/allowlist-regex.txt) |
| [denylist-exact.txt](denylist-exact.txt) | Exact deny | 12 | [Raw file](https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main/denylist-exact.txt) |
| [denylist-regex.txt](denylist-regex.txt) | Regex deny | 9 | [Raw file](https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main/denylist-regex.txt) |
| [README.md](README.md) | Setup and service labels | — | [Raw file](https://raw.githubusercontent.com/cadenshub/pihole-streaming-filters/main/README.md) |

[Download the repository ZIP](https://github.com/cadenshub/pihole-streaming-filters/archive/refs/heads/main.zip), or save individual raw files.

## Service and device warnings

- **Roku / The Roku Channel:** Do not enable `^[^.]+\.(sr|sc)\.roku\.com$` if you use The Roku Channel; it blocks Channel subdomains. Channel allow entries below are optional and needed only for Channel users. `tis.cti.roku.com` and `ls.cti.roku.com` are troubleshooting suggestions that still need testing. The Roku admeasurement regex is labeled “overkill” in the source.
- **Peacock playback:** The source says “Use this for now” for `mt.ssai.peacocktv.com`. The broader Peacock VOD deny regex also matches the `-mc` playback hosts covered by the Peacock allow regex. Keep that allow regex enabled for the same client groups when using the deny regex; playback may still fail and needs testing. The source mentions a MediaTailor host with a random ID and region, but supplies no concrete rule. No guessed MediaTailor wildcard was added: inspect the Query Log for your own device first.
- **Paramount+ compatibility:** The supplied deny entries are ad/tracking candidates. The source's general warning says rules can break playback or other devices. Do not assume compatibility across Paramount+ apps, devices, or other services sharing these hosts; test sign-in, live video, VOD, and other affected apps, and disable problematic rules. The provided files do not contain a more detailed Paramount+ compatibility statement.
- **Disney+:** The `disneyadvertising.com` regex is not thoroughly tested; treat it as experimental. Its presence does not establish that it removes Disney+ ads or preserves playback.

The files include all supplied candidates, including optional and experimental entries. Review the service labels before importing, and omit rules that do not apply to your devices.

## Add entries in Pi-hole v6

These files are **domain allow/deny entries, not Adlists**. Do not add their URLs under Lists/Adlists or expect gravity updates to import them.

### Web interface

1. Sign in to your Pi-hole admin interface and open **Group Management → Domains** (the **Domain management** page).
2. For either exact file, select **Domain**, enter a domain, and leave **Add domain as wildcard** unchecked.
3. For either regex file, select **RegEx filter** and paste the complete expression without shell quotes or slash delimiters.
4. Use **Add to allowed domains** for allow files or **Add to denied domains** for deny files. Choose the relevant group and use the service label below as the optional comment.
5. Check the saved entry's type, enabled status, and group assignment. Repeat for the selected rules.

See the [official Pi-hole domain-management interface source](https://github.com/pi-hole/web/blob/master/groups-domains.lp) for these controls.

### Command line on the Pi-hole host

Use the command for the rule type. For example:

```sh
pihole allow 'api.roku.com'
pihole --allow-regex '^g[^.]+-vod-us-cmaf-prd-mc\.cdn\.peacocktv\.com$'
pihole deny 'mt.ssai.peacocktv.com'
pihole --regex '^g[^.]+-vod-us-cmaf-prd-[^.]+\.cdn\.peacocktv\.com$'
```

After reviewing and removing optional or unsuitable lines from your local copies, import the chosen rules from the directory containing the four files:

```sh
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  pihole allow "$entry" || break
done < allowlist-exact.txt

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  pihole --allow-regex "$entry" || break
done < allowlist-regex.txt

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  pihole deny "$entry" || break
done < denylist-exact.txt

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  pihole --regex "$entry" || break
done < denylist-regex.txt
```

`read -r` preserves backslashes and quoting keeps each regex intact. Inspect CLI output for rejected entries. Commands run on the Pi-hole host, not your desktop; for Docker, execute them inside your Pi-hole container.

CLI entries initially belong to the Default group. To limit changes to streaming devices, create a group, assign the appropriate clients, then adjust each rule's group assignment in the web interface; remove Default from rules intended only for that group. Matching allow and deny rules need the intended group assignments. See the official [allow/deny editing guide](https://docs.pi-hole.net/guides/misc/allowlist-denylist/) and [CLI reference](https://docs.pi-hole.net/core/pihole-command/).

### Test and undo

Use the Query Log filtered to your device while testing playback. If a rule causes a problem, disable it in Domains, or remove that specific entry with its corresponding command:

```sh
pihole allow remove 'api.roku.com'
pihole --allow-regex remove '^g[^.]+-vod-us-cmaf-prd-mc\.cdn\.peacocktv\.com$'
pihole deny remove 'mt.ssai.peacocktv.com'
pihole --regex remove '^g[^.]+-vod-us-cmaf-prd-[^.]+\.cdn\.peacocktv\.com$'
```

Do not remove a pre-existing entry solely because it also appears in this collection. Re-test after cached DNS responses expire or the affected app/device restarts. Review changes a service at a time.

## Regex format and validation

Pi-hole uses [POSIX Extended Regular Expressions](https://docs.pi-hole.net/regex/). These 11 regexes use anchors, groups, alternatives, character classes, and repetition supported by that format, without PCRE-only features. All literal domain separators use `\.`; the dot inside `[^.]` is already literal and intentionally excludes dots. All patterns are anchored at both ends.

All 11 patterns passed local POSIX ERE compilation checks with `grep -E` and representative matching/non-matching tests, including wrong separators and suffixes. Domain syntax, duplicates, line formatting, and preservation of all 67 supplied entries were checked. The Pi-hole FTL binary was unavailable on the build machine, so no FTL runtime or streaming playback validation is claimed.

Run the actual engine on your Pi-hole host, for example:

```sh
pihole-FTL regex-test 'g123-vod-us-cmaf-prd-mc.cdn.peacocktv.com' '^g[^.]+-vod-us-cmaf-prd-mc\.cdn\.peacocktv\.com$'
pihole-FTL regex-test 'g123-vod-us-cmaf-prd-mc.cdn.peacocktv.com' '^g[^.]+-vod-us-cmaf-prd-[^.]+\.cdn\.peacocktv\.com$'
```

Both individual regex tests should match that host. [Pi-hole allowlist priority](https://docs.pi-hole.net/regex/) means an enabled exact or regex allow entry takes precedence over a matching deny entry for the same client. A standalone `regex-test` checks matching, not full allow/deny policy or playback.

For a syntax pass over every pattern with Pi-hole's engine:

```sh
for file in allowlist-regex.txt denylist-regex.txt; do
  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    pihole-FTL regex-test 'validation.example' "$pattern"
    result=$?
    case "$result" in
      0|2) : ;;  # match or valid non-match
      *) printf 'Regex test failed: %s\n' "$pattern" >&2; exit 1 ;;
    esac
  done < "$file"
done
```

The [official regex test documentation](https://docs.pi-hole.net/regex/testmode/) defines exit codes 0 (match), 1 (error), and 2 (no match). These syntax tests do not establish service compatibility or ad removal.

## Rules by service and device

These annotated copies map every entry to its supplied service/device label. Import the plain-text files above, not the headings below.

### Allow entries

#### Roku core/device functionality — exact

```text
roku.com
rokutime.com
therokuchannel.roku.com
api.roku.com
api.rokutime.com
retail.rpay.roku.com
api.rpay.roku.com
image.roku.com
```

#### Roku Channel (only if you use The Roku Channel) — exact

```text
configsvc.sc.roku.com
keysvc.sc.roku.com
content.sr.roku.com
content-detail.sr.roku.com
playback-detail.sr.roku.com
images.sr.roku.com
api2.sr.roku.com
vod.delivery.roku.com
vod-playlist.sr.roku.com
rights-manager.sr.roku.com
wv-license.sr.roku.com
static-delivery.sr.roku.com
bookmarks.sr.roku.com
navigation.sr.roku.com
images-svc.sr.roku.com
```

#### optional Roku Channel troubleshooting (source says still needs testing) — exact

```text
tis.cti.roku.com
ls.cti.roku.com
```

#### Peacock — exact

```text
mytv.clients.peacocktv.com
bff-ext.clients.peacocktv.com
imageservice.disco.peacocktv.com
play.ovp.peacocktv.com
atom.peacocktv.com
cybertron.id.peacocktv.com
meg.disco.peacocktv.com
ovp.peacocktv.com
pconfig-prd.cdn.peacocktv.com
```

#### Peacock video host pattern to allow (escaped literal dots) — regex

```text
^g[^.]+-vod-us-cmaf-prd-mc\.cdn\.peacocktv\.com$
```

#### Paramount+ — exact

```text
saa.paramountplus.com
saa.cbsi.com
vod-gcs-cedexis.cbsaavideo.com
cbsinteractive.hb.omtrdc.net
cbsi.live.ott.irdeto.com
tags.tiqcdn.com
wwwimage-us.pplusstatic.com
wwwimage-secure.cbsstatic.com
thumbnails.cbsig.net
bakery.pplus.paramount.tech
```

#### Paramount+ video host pattern — regex

```text
^[^.]+\.cws\.conviva\.com$
```

### Deny entries

#### block Roku channel subdomains (do not use if you use The Roku Channel) — regex

```text
^[^.]+\.(sr|sc)\.roku\.com$
```

#### Roku ad/log/telemetry-related subdomains (source pattern) — regex

```text
^(([^.]+\.)*(logs|ads|web|prod\.mobile|cti|voice)(\.[^.]+)*\.)roku\.com$
```

#### Roku named subdomains (source pattern) — regex

```text
^(([^.]+\.)*[^.]*(amarillo|amoeba|austin|benjamin|bryan|camden|cooper|copper|digdug|external|giga|gilbert|griffin|hereford|lb|liberty|littlefield|longview|madison|marlin|midland|paolo|richmond|rollingwood|scribe|sugarland|tyler|victoria|windsor)[^.]*(\.[^.]+)*\.)roku\.com$
```

#### Roku domains (source pattern) — regex

```text
^((captive|cloudservices|wwwimg)\.)roku\.com$
```

#### additional Roku sr subdomains (source pattern) — regex

```text
^((bif|microsites|traces|track|userdata)\.sr\.)roku\.com$
```

#### ravm.tv subdomains (source pattern) — regex

```text
^([^.]+\.)*ravm\.tv$
```

#### Roku — exact

```text
lat-services.api.data.roku.com
roku.admeasurement.com
```

#### Roku admeasurement (source labels this overkill) — regex

```text
^([^.]+\.)*roku([^.]+\.)*\.admeasurement([^.]+\.)*\.com$
```

#### Peacock ads (source says "Use this for now") — exact

```text
mt.ssai.peacocktv.com
```

#### Peacock variable VOD ad hosts; escaped dots and anchored to domain — regex

```text
^g[^.]+-vod-us-cmaf-prd-[^.]+\.cdn\.peacocktv\.com$
```

#### Paramount+ ad/tracking candidates — exact

```text
imasdk.googleapis.com
enduser.adsrvr.org
cdn.privacy.paramount.com
www.googletagmanager.com
pagead2.googlesyndication.com
availability-fastly.syncbak-mediastore-cedexis.cbsaavideo.com
cbsi.demdex.net
vod-gcs-qwilt.cbsaavideo.com
vod-gcs-google.cbsaavideo.com
```

#### Disney advertising (source says not thoroughly tested) — regex

```text
^([^.]+\.)*disneyadvertising\.com$
```
