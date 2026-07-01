# Third-Party Notices

[简体中文](./THIRD_PARTY_NOTICES.zh-CN.md)

This repository uses third-party open-source projects across the Flutter client,
Nest server, React share page, and Docusaurus website. Dependency manifests are
kept in each subproject:

- `fast_send_flutter/pubspec.yaml`
- `fast_send_server/package.json`
- `share-page-app/package.json`
- `website/package.json`

## FFmpeg

The repository includes FFmpeg and FFprobe binaries under `ffmpeg_build/` for
development and packaging workflows. These binaries are not modified by this
notice.

FFmpeg has its own licensing terms, which vary by build configuration. Before
redistributing release packages, verify the exact FFmpeg build options, enabled
codecs, and linked libraries, then provide the license text and source offer
required by that build.

Official FFmpeg legal information:

- https://ffmpeg.org/legal.html

## Inter Font

The app and website include Inter font files. Inter is distributed under the SIL
Open Font License. Keep the corresponding license notice when redistributing
font files.

## Icons and Assets

This project contains application icons, file type icons, SVG assets, and
product imagery. Before reusing them outside this repository, verify whether
they are project-owned assets or third-party assets with separate license terms.
