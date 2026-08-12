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

## 関連

- docs/isuren-kakomon-strategy.md
