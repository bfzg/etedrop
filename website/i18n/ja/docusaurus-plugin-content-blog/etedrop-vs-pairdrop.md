---
slug: etedrop-vs-pairdrop
title: "EteDrop vs PairDrop：ローカルネットワークを超える P2P 共有"
description: "EteDrop と PairDrop はどちらも P2P — ただし EteDrop は LAN 外でも使え、プレビュー付き、受信側インストール不要。今すぐ比較。"
authors: [etedrop]
tags: [pairdrop, snapdrop, p2p, comparison]
date: 2026-06-03
---

EteDrop — 直伝設計 — は P2P をローカルネットワークの外へ広げます。PairDrop（Snapdrop 系）は同じ Wi-Fi 内が前提。どちらも P2P、どちらもクラウドなし — ただし「ネットワークの境界」が決定的な違いです。

## 要点

| | **EteDrop** | **PairDrop** |
|---|---|---|
| **仕組み** | WebRTC P2P — LAN + 公網 | WebRTC P2P — ローカルのみ |
| **到達範囲** | LAN モード + 公網 | ローカルネットワークのみ |
| **プレビュー** | DL 前に PDF・画像・動画等 | なし |
| **共有** | リンク + 受取コード | 同一 LAN 自動発見 |
| **受信** | インストール不要 | インストール不要 |

## LAN を超える：決定的な差

PairDrop は自動発見 — 同じ Wi-Fi の端末同士。在宅で相手が別大陸？ PairDrop では無理。VPN か別ツールが必要になりがちです。

EteDrop はリンク + 受取コードで、相手がどこにいても届きます。同じ P2P 技術、より広い射程。

## プレビュー：保存前に中身を確認

PairDrop は届いて DL で終わり。EteDrop は PDF・画像・動画・音声・コードを先にプレビュー — P2P ツールが省きがちな体験層です。

## リンク + コード vs 自動発見

PairDrop は同一 LAN では friction ほぼゼロ。EteDrop は手順が少し増えますが、どこでも使え、コードでアクセス制御の層が増えます。

## 効率

同一 LAN では LAN モードで PairDrop に匹敵する速度。公網では NAT 越えで依然端末間直送 — クラウド中継なし。

## PairDrop が向く場合

- 転送がすべて同一 LAN 内
- 自動発見を好む
- Snapdrop 的な UX

## EteDrop が向く場合

- LAN 外の相手へ送りたい
- DL 前プレビュー
- 受取コードによるアクセス制御
- オフィス・在宅・リモートを行き来する

## FAQ

**EteDrop は Snapdrop 代替？** Snapdrop 原版、PairDrop が後継。EteDrop は別ニーズ — LAN 外 P2P + プレビュー内蔵。

**PairDrop はインターネット越え？** いいえ。同一 LAN 専用。越え P2P は EteDrop。

**同一 LAN でも EteDrop？** はい。LAN モード自動。PairDrop 並みの速度 + プレビュー + 越え能力。

**受取コードの意味は？** 意図した受信者だけがファイルにアクセス — リンクは広く配れ、コードが第二因子。

**モバイルブラウザ？** どちらもモダンブラウザで OK。受信側インストール不要。

**LAN を超える P2P が必要？** [EteDrop を無料で試す →](/down)
