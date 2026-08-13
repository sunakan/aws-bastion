priority: 3

# systemdユニットの静的ファイル化

## 目的

現状`70-webapp-go.sh`・`75-matcher.sh`・`77-payment-mock.sh`はsystemdユニットの中身を
bashのheredoc(`cat <<EOD ... EOD`)で組み立てて書き出している。
本家isucon14(`celestial-observability/isucon-kakomon/isucon14/provisioning/ansible/roles/webapp/files/`)
では`isuride-go.service`・`isuride-payment_mock.service`等が`ansible.builtin.copy`でコピーされる
**静的ファイル**(テンプレートエンジンなし)になっている。
heredoc方式ではなく、この本家に近い「静的.serviceファイルを置くだけ」の形にしたい。

## やること

- `70-webapp-go.sh`・`75-matcher.sh`・`77-payment-mock.sh`のheredoc部分を洗い出し、
  本家の`.service`ファイルとの差分(パス・ユーザー名・After/Requires行等)を整理する
- 差分の性質を踏まえて、以下のどちらの方式を採るか決定する
  - **案A(git管理)**: 本家からの実質コピーと言える場合、`kakomon14/upstream/isucon14/`配下に
    静的.serviceファイルを置き、isuren-mondai側でgit管理する(既存方針と整合)
  - **案B(ビルド時取得)**: 本家からの実質コピーと言えない場合、またはAMIビルドのたびに
    本家の最新内容を追従したい場合、`50-source.sh`が`webapp/sql`・`frontend/public`を
    本家から直接sparse-checkoutしているのと同様に、AMIビルド時に本家(`isucon/isucon14`)から
    直接取得する方式を検討する(ただしパス・ユーザー名の書き換えをどこで行うかが課題)
- 決定した方式でsystemdユニットを静的ファイル化する

## 検討事項(未決定)

isuren-mondai側はGoのみに絞りユーザー名も`isucon`→`isuren`に読み替えているため、本家の
`.service`ファイルをそのまま複製しても中身は変わる
(パス・ユーザー名の差分、`isuride-payment_mock.service`は`After=mysql.service`/
`Requires=mysql.service`を削るなど)。
そのため「静的ファイル化した結果が本家からの実質コピーと言えそうか」で案A/案Bを分ける。

## 関連

- `kakomon14/provisioning/77-payment-mock.sh`(payment_mock常駐化。isuren-mondai側commit 95bf92b)
- 参照先(ローカル参照専用): `/Users/user01/works/github.com/celestial-observability/isucon-kakomon/isucon14/provisioning/ansible/roles/webapp/`
- docs/plans/kakomon14/completed/20260813125100-payment-mock-wiring.md
  (過去にpayment_mockのsystemd化は「不要」と結論していたが、本家に近い分離サーバー構成を
  見据える方針転換により再度必要と判断し、`77-payment-mock.sh`として実装済み)
