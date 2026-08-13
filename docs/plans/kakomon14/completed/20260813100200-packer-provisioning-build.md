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

## 決定事項

- `empty.pkr.hcl`(ファイル名はタスク指示通り据え置き)を本番プロビジョニング版に更新した
    - `launch_block_device_mappings.volume_size`を8→16GBに拡大
    - `user_data_file`に`kakomon14/cloud-init/generate-user-data.py`が生成するgzip版cloud-config(`user-data.yaml.gz`)を設定
    - `instance_type`を`t4g.small`→`t4g.medium`に変更した。ISUCON14公式の競技者VM(`c5.large`: 2vCPU/4GiB、`isucon14/README.md`より)とメモリ量を揃え、`t4g.small`(2GiB)でのOOMリスクを避けるため。前段のcloud-init検証ではt4g.smallでOOMは発生しなかったが、aws-bastion/CLAUDE.mdに過去`pnpm install`でOOM killerが発動した実績があり、安定性を優先した
    - `provisioner "shell"`を`echo hello from packer`から`cloud-init status --wait`に変更。user_dataのcloud-init(write_files+runcmdでall.shを実行)が完了するまで待ってからAMI化するようにし、all.sh側の`set -euo pipefail`によりエラー時は`cloud-init status --wait`が非ゼロ終了するため、プロビジョニングの成否がそのままPackerのビルド成否になる
    - `ami_name`の接頭辞を`kakomon14-empty-`から`kakomon14-`に変更(空ビルドではなくなったため)
- ビルド成果物(`node_modules`等)は「残す」方針のまま変更なし。provisioning側のスクリプトを変更しなかったため、追加のクリーンアップ処理は不要だった
- `verify-ami.yaml`のInstanceTypeデフォルトも`t4g.small`→`t4g.medium`に変更した(過去問間で共有するテンプレートだが、現状kakomon14しかなく、将来他の過去問が増えたときにデフォルト値の妥当性を再検討すればよいと判断)
- `user-data.yaml.gz`は`provisioning/`配下から再生成可能なビルド成果物のため`.gitignore`に追加し、`mise run build-kakomon14`タスク内で`generate-user-data.py`を自動実行するようにした(生成し忘れによる古いuser-dataでのビルドを防ぐため)
- 実行結果: `mise run build-kakomon14`でAMI `ami-034e27b5ff0dac694`を作成(cloud-init完走、所要14分55秒)。`mise run verify-ami ami-034e27b5ff0dac694`でインスタンスを起動し、全サービス(`isuride-go`/`isuride-matcher`/`nginx`/`mysql`)がactiveであることを確認。ベンチマーク(`go run . run --target https://xiv.isucon.net --addr 127.0.0.1:443 -t 60`)を実行し、`結果 pass=true スコア=1304 種別エラー数=map[26:1]`を確認した(コード26は警告的なエラーでpass判定には影響しない)。検証後、verify-ami用CloudFormationスタックは削除済み。作成したAMI(`ami-034e27b5ff0dac694`)とスナップショットは成果物として残している
- これにより`docs/isuren-kakomon-strategy.md`の進め方5ステップ(Docker再現確認→Packer疎通確認→bastion試行錯誤→cloud-init整形→Packer本番ビルド)がすべて完了した
