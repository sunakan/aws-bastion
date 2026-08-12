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

## 関連

- docs/isuren-kakomon-strategy.md
