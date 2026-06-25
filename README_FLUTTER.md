# StudySync — Flutter版（lib/ 一式）

## 🆕 v0.3 での変更点

- ✅ 計測中のタイマー画面：×ボタンが反応しない不具合を修正し、下にスワイプして
  閉じても自動で記録が保存されるように（閉じ方を問わず保存される設計に変更）
- ✅ 通知が届かない不具合を修正（**端末の設定アプリから直接許可した場合でも**、
  起動時に許可状態を正しく読み直すように変更）
- ✅ 元のタスクを削除すると、そこから自動生成された復習タスクも一緒に削除
- ✅ 教科の「テスト期間（開始・終了日）」機能を削除（使われていなかったため）
- ✅ 用語を変更：**「プロジェクト」→「教科」**、**「グループ」→「プロジェクト」**
  （内部のクラス名・変数名は変更していません。表示上の文言だけです）
- ✅ 初回起動時のデモタスクを3件程度に削減（多すぎたため）
- ✅ 設定 → アプリ情報をタップすると、バージョンごとの変更履歴が見られるように

### 通知が来ない件について（重要）

これまでに作成済みのタスク（特に、デバッグ中に作った古いデモデータ）は、
「期限の何分前に知らせるか」を計算した結果の通知予定時刻が、**もう過去に
なっている**場合があります。その場合は仕様として通知を送りません。

確認のため、**期限を数分後に設定した新しいタスクを1件作って**、通知が届くか
試してみてください。それでも届かない場合は、設定→通知の「現在の状態」が
「許可済み」になっているか再確認してください（今回の修正で、端末の設定から
直接許可した場合も正しく反映されるようになっています）。

---

## 🆕 Version 2 での変更点

- ✅ アイコン画像を変更（添付いただいた曲線+チェックマークのデザイン）
- ✅ アプリ名を「StudySync」に変更
- ✅ 起動時に、忘却曲線が描かれるアニメーションを追加
- ✅ 学習記録（タイマーのセッション）を個別に削除できるように
- ✅ タイマー画面の×ボタンが押せない不具合を修正
- ✅ タスク一覧に「締切が近い順」を追加（科目をまたいで、期限が近い順にフラット表示）
- ✅ 通知を再設計：1日1回のまとめ通知 → **タスクごとに、期限の何分前に知らせるか**を
  「復習リマインダー」「期限が近いタスク」それぞれ別に設定できる方式に変更
  （15分前 / 30分前 / 1時間前 / 3時間前 / 前日 から選択）
- ✅ グループ名（「期末試験」など）を一度使うと、別の科目のタスクでも候補として
  ずっと表示されるように（設定 → タスク欄から削除も可能）
- ✅ 新規タスクの期限の既定値を「今日の23:00」に変更。設定 → タスク →
  「タスクの既定の期限時刻」から自由に変更可能

### Version 2 を反映するための追加作業

1. **アイコン**：別添の `android_icons.zip` の中身を、プロジェクトの
   `android/app/src/main/res/` にコピー（同名フォルダ・ファイルは上書きでOK）
2. **アプリ名**：`android/app/src/main/AndroidManifest.xml` を開き、
   `<application>` タグの `android:label="..."` の値を `"StudySync"` に変更
   ```xml
   <application
       android:label="StudySync"
       ...
   ```
3. **起動アニメーション用のアイコン画像**：このzipの `assets/icon/icon.png` を、
   プロジェクトの `assets/icon/icon.png` に配置し、`pubspec.yaml` に以下を追記
   ```yaml
   flutter:
     assets:
       - assets/icon/icon.png
   ```
   （既に`flutter:`セクションがある場合は、その中に`assets:`を追記してください）
4. 反映後：
   ```bash
   flutter clean
   flutter run
   ```

---

HTMLプロトタイプの構成・操作仕様をFlutterに移植したものです。状態管理は
**Provider（ChangeNotifier）**。今回のアップデートで以下を実装しました。

- ✅ Googleアカウント連携 → **実際に動くサインイン＋クラウド同期**（Firebase）
- ✅ 通知 → **実際に端末に届くローカル通知**（時刻を自分で設定可能）
- ✅ 科目（プロジェクト）の追加・編集・削除を、設定画面からも直接行えるように
- ✅ GitHub Pages からの配布用ページ（Android apkダウンロード／iOS TestFlightリンク）と、
  タグpushで自動的にapkをビルドするGitHub Actionsを追加（9章）
- ❌ ホーム画面ウィジェットは削除（Flutter単体では実装できないため）
- 🛠 ボトムナビ（ホーム/カレンダー/統計/設定）は `Scaffold.bottomNavigationBar`
  なので、もともと画面下部に固定されています（HTML版にあった「上に表示される」
  不具合はHTML側だけの問題で、Flutter版には影響していません。HTML版は修正済みです）

このコードはDart/Flutter SDKの無い環境で書いたため、**実機でのコンパイル確認は
できていません。** 構文・import・型の整合性はスクリプトで全ファイルチェック
済みですが、`flutter analyze` で何か出たらエラーメッセージを貼ってください。

---

## 1. ファイルの配置

zip内の `lib/` をプロジェクトの `lib/` に配置してください。新規追加された
主なファイルは以下です。

```
lib/
  firebase_options.dart        ★仮ファイル。flutterfire configure で上書きされる
  services/
    sync_service.dart          Firestoreへの保存・復元（クラウド同期の中身）
    notification_service.dart  実際の通知スケジューリング
  sheets/
    project_list_sheet.dart    設定画面から開く「科目の管理」シート
```

`models/app_settings.dart`・`state/app_state.dart`・`sheets/settings_sheets.dart`・
`screens/settings_screen.dart`・`main.dart` も更新されているので、まとめて
上書きしてください。

## 2. 依存パッケージの追加

```bash
flutter pub add provider google_fonts shared_preferences image_picker path_provider \
  permission_handler firebase_core firebase_auth cloud_firestore google_sign_in \
  flutter_local_notifications timezone
```

`flutter_localizations` はSDK同梱なので、pubspec.yamlに直接追記してください。

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

## 3. Firebaseのセットアップ（Google連携・クラウド同期に必須）

これをやらないと **アプリが起動しません**（`firebase_options.dart` が仮の
ファイルのままだとエラーを出す作りにしています）。無料で、10〜15分程度です。

### 3-1. Firebaseプロジェクトを作る
1. https://console.firebase.google.com/ にアクセスし、「プロジェクトを作成」
2. プロジェクト名は何でもOK（例：StudySync）

### 3-2. Authentication を有効化
1. 左メニュー「Authentication」→「始める」
2. 「Sign-in method」タブで **Google** を有効化

### 3-3. Firestore を有効化
1. 左メニュー「Firestore Database」→「データベースの作成」
2. 本番モードでOK（後述のルールを設定するため）
3. 「ルール」タブで、以下に置き換えて公開（自分のデータだけ読み書きできるようにする設定）：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /studysync_users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### 3-4. FlutterFire CLIで自動設定
プロジェクトのルートで：

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

対話形式で、3-1で作ったFirebaseプロジェクトと、対象プラットフォーム
（iOS / Android）を選びます。これで `lib/firebase_options.dart` が自動生成され
（このzipに入っている仮のファイルが上書きされます）、
`android/app/google-services.json` と `ios/Runner/GoogleService-Info.plist`
も自動的に配置されます。

### 3-5. Google Sign-In のプラットフォーム追加設定

**Android：**
- デバッグ用の署名鍵のSHA-1を取得して、Firebaseコンソールの
  「プロジェクトの設定」→「マイアプリ」→対象のAndroidアプリ に登録してください。
  ```bash
  cd android && ./gradlew signingReport
  ```
  （リリースビルドを配布する際は、リリース鍵のSHA-1も追加で登録が必要です）

**iOS：**
- `ios/Runner/GoogleService-Info.plist` を開き、`REVERSED_CLIENT_ID` の値を確認
- `ios/Runner/Info.plist` に、URLスキームとして追記：
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>（ここにREVERSED_CLIENT_IDの値を貼る）</string>
      </array>
    </dict>
  </array>
  ```

## 4. 通知のプラットフォーム設定

### Android（android/app/src/main/AndroidManifest.xml）
Android 13以降で許可を求めるために必要：
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS（ios/Runner/Info.plist）
写真ライブラリ（壁紙用）の許可説明も合わせて追加してください。
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>壁紙の画像を選ぶために使用します</string>
```

## 5. 動作確認の手順

```bash
flutter pub get
flutterfire configure   # 初回のみ（3章参照）
flutter analyze
flutter run
```

## 6. 通知・同期の仕組み（実装メモ）

- **通知**：設定 → 通知 で時刻（既定 20:00）とON/OFFを設定すると、毎日その
  時刻に1件、ローカル通知（`flutter_local_notifications`）が届きます。
  「復習リマインダー」「期限が近いタスク」のどちらかがONかつ通知が許可
  されていれば有効になります（タスクごとに個別通知が増えていく形ではなく、
  1日1回のまとめ通知というシンプルな設計です）。
  - Androidは端末再起動で予約が消える場合がありますが、アプリを開き直すと
    起動時の処理で自動的に再設定されます。
- **Google連携／同期**：サインインすると、Firestoreの
  `studysync_users/{あなたのUID}` というドキュメントに、タスク・科目・設定が
  JSON文字列として保存されます。別の端末で同じアカウントでサインインすると、
  そのデータを取り込みます（最後にログインした内容がベースになる、
  シンプルな「上書き型」の同期です。複数端末で同時に編集する用途には
  向きません）。
- カレンダーAPI連携（Googleカレンダーへの自動反映）は今回の要望どおり
  実装していません。

## 7. 削除した機能

ホーム画面ウィジェットは、Flutter単体（Dartのみ）では実装できないため
（iOSはWidgetKit/Swift、AndroidはApp Widget/Kotlinのネイティブコードが
必須）、今回すべて削除しました。設定画面・モデルからも関連コードを除去
しています。

## 8. 科目（プロジェクト）の追加

これまでも左ドロワーから追加できましたが、見つけやすいように
**設定 → 科目 → 科目（プロジェクト）の管理** からも追加・編集・削除できる
ようにしました（`sheets/project_list_sheet.dart`）。ドロワーと同じデータを
参照しているので、どちらから追加してもすぐ両方に反映されます。

## 9. 配布する（GitHub Pages + Android apk + iOS TestFlight）

家族・友人など少人数に配ることを想定した構成を、`.github/workflows/release_apk.yml`
と `docs/index.html` として用意しました。

### 10-1. GitHub Pagesを有効化する
1. このプロジェクトをGitHubリポジトリにpush
2. リポジトリの「Settings」→「Pages」
3. 「Source」を `Deploy from a branch`、ブランチを `main`、フォルダを `/docs` に設定
4. しばらくすると `https://あなたのユーザー名.github.io/リポジトリ名/` でページが見られます

### 10-2. `docs/index.html` の置き換え箇所
ファイル内の以下2箇所を、実際の値に書き換えてください。

- `YOUR_GITHUB_USERNAME/YOUR_REPO_NAME` → あなたのGitHubユーザー名とリポジトリ名
- TestFlightの `href="#"` → 10-4で発行される招待リンク

### 10-3. Android版を自動ビルドする
バージョンタグをpushすると、GitHub Actionsが自動でapkをビルドし、
GitHub Releasesに添付します（`docs/index.html` のダウンロードボタンは
「最新リリースのapk」を自動的に指すURLなので、これ以降は何もしなくてOK）。

```bash
git tag v1.0.0
git push origin v1.0.0
```

数分後、リポジトリの「Releases」にapkが付いたリリースができていれば成功です。
（初回は Settings → Actions → General で「Workflow permissions」が
「Read and write permissions」になっているか確認してください。）

### 10-4. iOS版をTestFlightで配る
1. Apple Developer Program に登録（年$99）
2. https://appstoreconnect.apple.com で新規アプリを作成（Bundle IDは
   `flutterfire configure` 時に設定したものと合わせる）
3. Mac上で `flutter build ipa` を実行 → 生成された `.ipa` を
   Xcodeの Organizer、または無料ツール「Transporter」でアップロード
4. App Store Connectの「TestFlight」タブで、内部テスター（あなたの
   Apple Developerチームのメンバー）か、外部テスター（メールアドレスを
   登録するだけでOK、最大100人・審査不要のグループを作成可能）を追加
5. 発行された招待リンクを `docs/index.html` のTestFlightボタンに貼る

外部テスターグループの審査は通常、簡易ベータレビューのみで数時間〜1日程度
なので、家族・友人向けには十分です。

## 10. 既知の制限・deprecation 警告

- `Color.value` / `Color.withOpacity()` は最近のFlutterで deprecated 表示に
  なりますが、互換性のためそのまま使用しています。動作には影響しません。
- 同期はあくまで「最後にログインした内容で上書き」という簡易方式です。
  本格的な複数端末同時編集（競合解消）が必要になったら、Firestoreの
  リアルタイムリスナー（`snapshots()`）やフィールド単位の差分更新への
  作り直しを検討してください。
