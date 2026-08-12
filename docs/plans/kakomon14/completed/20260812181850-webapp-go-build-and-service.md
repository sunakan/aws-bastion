priority: 9

# webapp(Go)のビルドとsystemd化(70-webapp-go.sh) 【マイルストーンA】

## 目的

Ansibleの`roles/webapp/tasks/go.yaml`相当を再現し、Goアプリを実際に動く状態にする。ここまでできれば、nginx/frontendなしでもベンチのPrepare(初期化+初期データ検証)まで到達できるはず。

## やること

- `go build -o /home/isuren/webapp/go/isuride -ldflags "-s -w"` を実行する(cwd: `/home/isuren/webapp/go`)
- `isuride-go.service`をisuren版(User/Group/WorkingDirectory/EnvironmentFileのパスを`/home/isuren/...`に変更、サービス名・ExecStartは据え置き)として`/etc/systemd/system/`に配置する
- `WorkingDirectory=/home/isuren/webapp/go`を必ず設定する(`/api/initialize`が相対パス`../sql/init.sh`を呼ぶため、ここがずれると失敗する)
- `systemctl daemon-reload && systemctl enable --now isuride-go`

## 完了条件

`cd isucon14/bench && go run . run --target http://localhost:8080 -s -t 0` が成功すること

## 決定事項

- **重要な発見**: 以前のDocker検証(`development/compose-go.yml`、`/home/ubuntu/works/github.com/isucon/isucon14/development`)のコンテナ(nginx/webapp-go/matcher)が起動したまま残っており、nginxコンテナがホストの8080番ポートを掴んでいたため、ネイティブの`isuride-go`がbindできず再起動ループになった。`docker compose -f compose-go.yml down`で停止して解消した。ネイティブ構築を進める際はDocker検証環境が動いていないことを都度確認する必要がある
- ExecStopの`$MAINPID`が空になるエラーは、上記のポート競合でメインプロセスが即終了を繰り返していたことの副次的な症状であり、systemd unit定義自体の不具合ではなかった
- `scripts/kakomon14/70-webapp-go.sh`をbastion上で実行し(ポート競合解消後)、`systemctl is-active isuride-go`が`active`になることを確認済み
- 完了条件のベンチPrepare実行で`pass=true`・`errors=[]`を確認済み(マイルストーンA達成)

## 関連

- docs/isuren-kakomon-strategy.md
