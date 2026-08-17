# randomware

A personal apt meta-package bundling wifi auditing, cracking, and network recon tools — so a fresh Debian/Ubuntu box (or Tails) can get the whole toolkit in one install instead of grabbing everything one by one.

## Install

curl -fsSL https://guniscodin.github.io/Randomware/bootstrap.sh | sudo bash
sudo apt install randomware

This adds the repo as a trusted apt source (signed with GPG, no [trusted=yes] shortcuts) and pulls in every tool as a dependency.

## What's included

- Wifi auditing: aircrack-ng, mdk4, hcxdumptool, hcxtools, reaver, pixiewps, wifite, bettercap, macchanger
- Cracking: hashcat, john, hydra, crunch
- Recon/scanning: nmap, arp-scan, sqlmap
- Traffic analysis: wireshark, tcpdump, ettercap-text-only
- Utilities: ncat, git, gcc, make, pkg-config, and required build/dev libraries

Full live list is always in tools.txt — that file is the source of truth, the package Depends field is generated from it.

## Wordlists

On install, a postinst script pulls a few wordlists into /usr/share/wordlists/:
- rockyou.txt
- probable-v2-wpa-top4800.txt

These are best-effort — a failed/slow download won't break the install, it just skips with a warning.

## Trust / signing

The repo is GPG-signed. Fingerprint:

CD01C33406E0A9FC2316FCB268014A519BCDFC3D

The public key is fetched automatically by bootstrap.sh, or manually via:

curl -fsSL https://guniscodin.github.io/Randomware/randomware-archive-keyring.gpg

## Notes

Built and maintained for personal use across my own devices (Tails, Ubuntu). Public, but no support/warranty implied — use at your own judgement.

Versioning bumps automatically (patch number) every time a tool or wordlist is added.
