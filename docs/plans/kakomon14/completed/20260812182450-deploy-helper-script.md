priority: 5

# 運用補助スクリプト(deploy.sh)

## 目的

チューニング作業中に、コード変更→再ビルド→再起動を素早く回せるようにする。

## やること

- isurenユーザー用の`deploy.sh`(go buildしてisuride-goをrestartするだけの短いスクリプト)を用意する
- ログの確認方法(`journalctl -u isuride-go -f`等)をREADMEにまとめる

## 完了条件

isurenでログインして1コマンドで再デプロイできること

## 決定事項

- `deploy.sh`は`scripts/kakomon14/95-deploy-helper.sh`が`/home/isuren/deploy.sh`に冪等に配置する構成にした。プロビジョニングの一部として`all.sh`にも組み込んだ
- `deploy.sh`はisurenの対話シェル(`.bashrc`でmise activate済み)からの実行を前提とし、`70-webapp-go.sh`と違い`mise`/`go`をフルパス指定しなかった(`runuser`経由の非対話実行ではなく、isuren自身のログインシェルでの利用を想定しているため)
- ログ確認方法は`scripts/kakomon14/README.md`を新規作成してまとめた(`journalctl -u isuride-go -f`等)
- `scripts/kakomon14/95-deploy-helper.sh`をbastion上で2回実行し、1回目`changed`→2回目`already up to date`を確認済み(冪等性)
- **重要な発見**: SSM経由でisurenのログインシェル相当を再現するには`sudo -u isuren -i bash -c "~/deploy.sh"`のように`bash -c`の中でチルダ展開させる必要がある。`sudo -u isuren -i ~/deploy.sh`のように直接パスを渡すと、`~`がSSM実行ユーザー(root)側で展開されてしまい`No such file or directory`になる
- 上記の方法で`~/deploy.sh`を実行し、`deploy.sh: isuride-go restarted`のログと`systemctl is-active isuride-go`が`active`であることを確認済み(完了条件を満たす)

## 関連

- docs/isuren-kakomon-strategy.md
