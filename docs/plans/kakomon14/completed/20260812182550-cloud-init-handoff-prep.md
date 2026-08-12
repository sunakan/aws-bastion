priority: 4

# cloud-init化への引き継ぎ準備(このフェーズの締め)

## 目的

bastion上で固めた内容を、次フェーズ(cloud-init化してPackerで本番相当ビルド)に引き継げる状態にする。

## やること

- 確定した`scripts/kakomon14/`の内容を`isuren-kakomon/kakomon14/`へ移設する
- cloud-init(UserData)への分割方針を決める(`runcmd`で`all.sh`を1本呼ぶ形にするか、`write_files`で個別配置するか)
- Packerのルートボリュームを16GB以上に拡大する(MySQLデータ+node_modules+Goモジュールキャッシュで8GBでは不足する見込み)
- AMIに`node_modules`等のビルド成果物を残すか、ビルド後に消すかを判断する

## 完了条件

次フェーズ(cloud-init化)のタスクが`docs/plans/kakomon14/todo/`に起票できる状態になっていること

## 決定事項

- `scripts/kakomon14/`の`isuren-kakomon/kakomon14/`への実際の移設(コピー)は本タスクでは行わず、次フェーズ最初のタスクとして起票するに留めた。`isuren-kakomon/`は`aws-bastion`とは別のgitリポジトリ(独立した`.git`、リモート未設定)であり、そちらへの変更はcloud-init化の設計判断と切り離して次フェーズで着手する方が扱いやすいと判断した
- cloud-init分割方針は「`write_files`で全スクリプト(`lib.sh`〜`95-deploy-helper.sh`)を配置し、`runcmd`で`all.sh`を1本呼ぶ」形を採用する方針とした。個々のスクリプトをruncmdに列挙する方式は、今回bastion上で検証済みの`all.sh`の実行順序・冪等性を再現する手間が増えるだけで利点が薄いため採らなかった
- Packerルートボリュームは、bastionでの実測(mysqlデータ242MB+isucon14リポジトリ427MB+mise本体・モジュールキャッシュ624MB≒計1.3GB)を踏まえ、現行の8GBから16GB以上への拡大を次フェーズタスクの実施事項として明記した。実測値の3倍以上の余裕を持たせる
- AMIのビルド成果物(`node_modules`等)は、チューニング中にAMI起動直後から素早く再ビルドできることを優先し「残す」方針を軸にする(次フェーズのPackerタスクで最終判断)
- 次フェーズのタスクを3件、`docs/plans/kakomon14/todo/`に起票した(`20260813100000-migrate-scripts-to-isuren-kakomon.md`/`20260813100100-cloud-init-userdata.md`/`20260813100200-packer-provisioning-build.md`)

## 関連

- docs/isuren-kakomon-strategy.md
