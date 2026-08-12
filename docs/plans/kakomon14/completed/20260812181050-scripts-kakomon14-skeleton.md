priority: 12

# scripts/kakomon14の骨組みと実行規約を決める

## 目的

以降のタスクで書くbashスクリプトの置き場・分割方針・実行規約を先に固定し、以降のタスクをスムーズに進められるようにする。

## やること

- `scripts/kakomon14/`ディレクトリを作成する(`lib.sh`, `all.sh`の空の骨組みのみ)
- 実行規約を決める: 全スクリプトroot前提、ユーザー権限が必要な箇所は`runuser -u isuren --`、`set -euo pipefail`、`log()`でプレフィックス付き出力
- 設定値は`lib.sh`で`: "${VAR:=default}"`形式にして環境変数で上書き可能にする
- `mise.toml`の`lint-sh`が`ls -1 scripts/*.sh`で非再帰なので、サブディレクトリ(`scripts/kakomon14/`)にも対応するよう修正する

## 完了条件

`mise fmt-sh` / `mise lint-sh` が新しい配置(`scripts/kakomon14/*.sh`)に対しても通ること

## 関連

- docs/isuren-kakomon-strategy.md
