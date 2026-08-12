priority: 1

# Packerで本番相当ビルドを実行する

## 目的

cloud-init化した内容を使い、Packerで実際にプロビジョニング済みのAMIをビルドする。ここまで通れば「過去問をGo版AMIとして焼く」フェーズが完了する。

## やること

- `isuren-kakomon/kakomon14/packer/empty.pkr.hcl`を本番プロビジョニング版に更新する
  - ルートボリュームを16GB以上に拡大する(bastion実測: mysqlデータ242MB+isucon14リポジトリ427MB+mise(go/node/pnpm本体+モジュールキャッシュ)624MBで計約1.3GB。ベースイメージ+aptパッケージ分を足しても8GBは不足する見込みのため)
  - `user_data`にcloud-init-userdataタスクで作ったcloud-configを設定する
- AMIにビルド成果物(`node_modules`等)を残すかビルド後に消すかを判断する。チューニング中にAMI起動直後から素早く再ビルドできることを優先し、残す方針を軸に検討する
- `mise run build-kakomon14`でPackerビルドを実行する

## 完了条件

- 作成したAMIから`mise run verify-ami <ami-id>`でインスタンスを起動できること
- そのインスタンス上で`go run . run --target https://xiv.isucon.net --addr <ip>:443 -t 60`が`pass=true`になること

## 関連

- docs/isuren-kakomon-strategy.md
- docs/plans/kakomon14/todo/20260813100100-cloud-init-userdata.md
