NDC9 Fetcher - A Simple API Server for NDC9
===========================================
dev: [![Build Status dev](https://travis-ci.org/tsunekawa/ndc9-fetcher.svg?branch=dev)](https://travis-ci.org/tsunekawa/ndc9-fetcher)
master: [![Build Status master](https://travis-ci.org/tsunekawa/ndc9-fetcher.svg?branch=master)](https://travis-ci.org/tsunekawa/ndc9-fetcher)

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/tsunekawa/ndc9-fetcher)

## About
* ISBNに対応するNDC番号を返すAPIサーバです。
* NDC番号の取得には[NDLサーチの外部インタフェース](http://iss.ndl.go.jp/information/api/)を利用しています。

## 要件 / Requirements
* Ruby (2.0.0以降)
* Redis

## インストール / Install

### Herokuで動かす場合

1. Herokuにログイン
2. 本ドキュメント冒頭の「Deploy to Heroku」ボタンを押下

### 任意のサーバーで動かす場合
インストールを実施する前に、Redisをインストール・起動しておいてください。

```sh
$ git clone git://github.com/tsunekawa/ndc9-fetcher
$ cd ndc9-fetcher
$ gem install bundler
$ gem install foreman
$ bundle install
$ foreman start
```

## APIの使用方法

### 特定のISBNからNDC番号を取得する場合

* URL: https://ndc9.herokuapp.com/v1/isbn/(ISBN)
* 例:
  * テキスト形式で出力： [https://ndc9.herokuapp.com/v1/isbn/978-4061190696](https://ndc9.herokuapp.com/v1/isbn/978-4061190696)
  * JSON形式で出力： [https://ndc9.herokuapp.com/v1/isbn/978-4061190696.json](https://ndc9.herokuapp.com/v1/isbn/978-4061190696.json)
  * RDF/XML形式で出力： [https://ndc9.herokuapp.com/v1/isbn/978-4061190696.rdf](https://ndc9.herokuapp.com/v1/isbn/978-4061190696.rdf)

## 開発者

* 常川真央(Tsunekawa Mao) < twitter: @kunimiya , github:tsunekawa >

## ライセンス

MITライセンスです。
