# AMIスナップショットが8GiBフル(100%)になる原因が未特定

## きっかけ

OTel trace送信のフル検証中、`provisioning.all` spanのdisk使用量属性を見ると実際のファイルシステム
使用量は3.13GiB程度(`disk.after_bytes=3362086912`)なのに対し、AMIスナップショット(8GiBのルート
ボリューム)はブロック使用率がほぼ100%になっている(コンソール上の課金表示で確認)。

## 調査した内容

1. **暗号化コピーが原因か検証** → `encrypt_boot = false` にしてビルドしても症状は変わらず。
   暗号化(`Copying/Encrypting AMI ...`)が原因ではないと判明
2. **TRIM未解放のブロック残骸が原因か検証** → Packerのshell provisioner内でAMI化直前に
   `sudo fstrim -v /` を実行するデバッグステップを追加したところ、`fstrim: /: the discard operation
   is not supported` で失敗(exit 1)。bastion(同じUbuntu 26.04 arm64・Nitro系インスタンス、
   `t4g.small`)でも同様に再現し、コマンド自体は存在する(`util-linux 2.41.3`、Rust実装ではない)が、
   カーネルからこの環境のブロックデバイスがTRIM/discard未対応と認識されていることを確認した

## 現時点の判断

原因は未特定のまま。デバッグ用に変更していた`encrypt_boot = false`とfstrimステップは
`kakomon14/packer/empty.pkr.hcl`から元に戻した(暗号化復元・fstrim削除。isuren-mondaiリポジトリ
コミット参照)。

次に試すなら候補は以下(未着手)。

- EBS Direct API(`ListSnapshotBlocks`等)で実際にスナップショットが保持しているブロック数を
  直接確認する(AWSコンソールの表示だけでは推測の域を出ないため)
- 別のインスタンスファミリ/ボリュームタイプでTRIMサポートの有無を比較する
- 8GiBという設定自体が妥当か再検討する(実データ3.2GB程度なら、スナップショット課金上は
  フル100%でも大差ない可能性があり、優先度を下げてよいかもしれない)

## 関連

- isuren-mondaiリポジトリ `kakomon14/packer/empty.pkr.hcl`
- isuren-mondaiリポジトリ commit(`bba6fbc` encrypt_boot一時false化、`166ef77` fstrimデバッグ追加、
  その後元に戻したコミット)
- 直前の意思決定: `docs/plans/kakomon14/completed/`配下のAMIサイズ縮小(16→8GiB)関連のcompletedメモ
