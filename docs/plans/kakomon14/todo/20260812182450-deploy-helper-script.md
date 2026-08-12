priority: 5

# 運用補助スクリプト(deploy.sh)

## 目的

チューニング作業中に、コード変更→再ビルド→再起動を素早く回せるようにする。

## やること

- isurenユーザー用の`deploy.sh`(go buildしてisuride-goをrestartするだけの短いスクリプト)を用意する
- ログの確認方法(`journalctl -u isuride-go -f`等)をREADMEにまとめる

## 完了条件

isurenでログインして1コマンドで再デプロイできること

## 関連

- docs/isuren-kakomon-strategy.md
