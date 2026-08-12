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

## 関連

- docs/isuren-kakomon-strategy.md
