priority: 3

# OrbStack VMでのローカル事前検証

## 目的

isuren-mondai側のprovisioningスクリプトは、直近のリファクタで各スクリプトのif判定(changed/already)を
廃し冪等コマンドの無条件実行に変更した上で、`99-verify.sh`(goss)による状態検証をprovisioning最後に
一本化した(fail fast方式)。この設計自体は決定済みだが、副作用として「goss.yamlの1項目が
間違っているだけでPacker buildごと失敗する」というコストが常につきまとう。
修正→確認のサイクルが「フルAMIビルド(課金・時間がかかるPacker+AWS)」単位になっており、
特にgoss.yaml導入直後の現状(実機未検証)は初回ビルドで複数箇所同時に落ちる可能性が高い。

このコストを緩和するため、AWS/Packerに頼らずローカルで`all.sh`(provisioning一式+goss検証)を
リハーサルできる環境を用意したい。

## 方式の検討結果(決定事項)

DockerではなくOrbStack(macOS用の軽量VM)を使う方針に決定。

- `goss.yaml`が検証する内容(systemdサービスのenable/running状態、apt installしたパッケージ、
  mysql/nginxの実プロセス、ポート待受)は本質的に「実カーネル+実init(systemd)」前提の検証であり、
  Dockerコンテナでsystemdを PID1として動かすには`--privileged`・cgroupマウント・専用ベースイメージ
  等の不自然な回避策が必要になる。系統的に別物を検証してしまうリスクがある
- OrbStackは実Linux VM(Apple Silicon対応、高速起動)のため、EC2/cloud-init環境に近い状態を
  忠実に再現でき、`all.sh`をそのまま実行して検証できる

## やること

- OrbStackでUbuntu(ARM64、AMIのベースOSに近いバージョン)VMを起動するmiseタスクを作る
  (例: `kakomon14:verify-local`。既存の`verify-ami`/`down-verify-ami`と対になるイメージ)
- provisioning内容をVMに渡す方法を決める
  - 案1: 本番と同じgit clone方式(cloud-initのuser-data生成と同じロジックを流用)。
    ただし未コミットの変更は反映されない
  - 案2: ローカルディレクトリをVMにマウント(OrbStackのファイル共有機能)し、
    未コミットの変更もそのまま試せるようにする。イテレーション速度を優先するならこちら
- `all.sh`(`ENABLE_TLS=true`)をVM内で実行し、`99-verify.sh`(goss)の結果でpass/failを判定する
- 検証後はVMを破棄する(使い捨て。`down-verify-ami`と同様の運用)

## 検討事項(未決定)

- OrbStackのUbuntu標準イメージが、AMIのベースOS(Ubuntu 26.04 resolute arm64)とどこまで
  一致させられるか(バージョン差異による挙動差のリスク)
- mysql-server/nginxのapt installがOrbStack VM上で問題なく動くか(未検証)
- 案1と案2のどちらを採用するか、または両対応にするか

## 関連

- isuren-mondaiリポジトリ commit `fd49ad0`(gossの導入)・`2c309af`
  (provisioningのif簡略化+goss検証への一本化)
- isuren-mondaiリポジトリ `kakomon14/provisioning/goss.yaml`・`99-verify.sh`
- `mise-tasks/verify-ami`・`mise-tasks/down-verify-ami`(対になる既存のAWS側検証タスク)
