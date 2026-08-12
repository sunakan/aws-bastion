priority: 6

# 冪等性と再起動耐性の確認

## 目的

ここまで作った`scripts/kakomon14/all.sh`が、AMI化(cloud-init化)に耐えられる品質かを確認する。

## やること

- `sudo bash all.sh`を2回連続で実行し、2回目のログに`changed`が出ないことを確認する
- `sudo reboot`後に再接続し、全サービス(mysql/nginx/isuride-go/isuride-matcher)が自動起動していることを確認する
- `go run . run --only-post-validation` でデータ保持・自動起動を検証する

## 完了条件

- 2回目の実行で差分(changed)が出ないこと
- 再起動後もベンチのスコアが出ること

## 決定事項

- 本タスク着手時点で`scripts/kakomon14/all.sh`は`log "start"`のみの空実装だったため、まず`10-base.sh`〜`90-nginx.sh`を順に呼ぶ実装を追加した
- `sudo ENABLE_TLS=true bash scripts/kakomon14/all.sh`をbastion上で2回連続実行し、2回目の標準出力に`changed`という文字列が1件も含まれないことを`grep`で確認済み。`60-initdb.sh`(DBリセット)・`70-webapp-go.sh`(go build)・`80-frontend.sh`(pnpm build)は仕様上毎回実行されるが、ログメッセージに`changed`という単語を使わない設計になっているため、この判定方法と両立している
- `sudo reboot`後、`systemctl is-active`/`is-enabled`で`mysql`/`nginx`/`isuride-go`/`isuride-matcher`全てが`active`かつ`enabled`であることを確認済み
- 再起動後に`go run . run --target https://xiv.isucon.net --addr 127.0.0.1:443 -t 60`を実行し`pass=true`・スコア=1165を確認(完了条件を満たす)。続けて`--only-post-validation`(`-t`なし)を実行し、直前の負荷走行データに対するpost validationがエラーなく終了することも確認済み
- **重要な発見**: `all.sh`実行時は`sudo ENABLE_TLS=true bash ...`のように`sudo`の後に環境変数を置く必要がある(`sudo`はデフォルトで環境変数をリセットするため)。ENABLE_TLSを指定し忘れると`90-nginx.sh`がHTTP版設定に巻き戻り、2回目の判定が`changed`になる

## 関連

- docs/isuren-kakomon-strategy.md
