priority: 10

# miseでのランタイム導入(30-runtime.sh)

## 目的

Ansibleの`roles/xbuild`(xbuildでGoをビルド・インストール)をmiseで代替する。xbuildは単にバージョン固定インストールをするだけのツールで、パフォーマンスへの影響はないためmiseに置き換えて保守性を優先する。

## やること

- isurenユーザーにmiseを導入する
- go/node/pnpmをmiseで管理する設定を用意する(preflightで決めたバージョンに固定)
- `mise install`を実行し、isurenのログインシェルでPATHが有効になることを確認する

## 完了条件

`runuser -u isuren -- mise exec -- go version` 等で期待バージョンが取得できること

## 決定事項

- `runuser -u isuren -- mise ...`は`.bashrc`を経由しないため単体では動かない。`mise`はフルパス(`/home/isuren/.local/bin/mise`)で呼ぶ必要がある(systemdや今後のスクリプトでも同様の制約)
- `pnpm`はカレントディレクトリからworkspace定義を探索するため、`/home/ubuntu/...`配下(isurenから読めない)をcwdにしたまま実行すると`EACCES`になる。isurenのホームに`cd`してから呼ぶ必要がある
- go 1.26.5 / node v24.19.0 / pnpm 11.21.0をフルパス実行で確認済み(完了条件を満たす)
- go/node/pnpmのバージョン定義を`scripts/kakomon14/mise.kakomon14.toml`に切り出し、isurenの`~/.config/mise/config.toml`として配置する方式にした(aws-bastionリポジトリのパスを直接参照しない。理由は30-runtime.shのコメント参照)
- チェックサム固定のため`scripts/kakomon14/mise.kakomon14.lock`(`mise lock -g -p linux-arm64`で生成)も追加し、`~/.config/mise/mise.lock`として配置する。対象プラットフォームはarm64のみに絞った(このAMIがarm64(Graviton)専用のため)
- `scripts/kakomon14/30-runtime.sh`をbastion上で2回実行し、1回目changed→2回目already up to dateを確認済み

## 関連

- docs/isuren-kakomon-strategy.md
