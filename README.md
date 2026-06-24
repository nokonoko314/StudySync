# gh-pages 用パッケージ

このzipの中身（`index.html` と `.nojekyll`）を、`main`とは別の `gh-pages` という
ブランチの**直下**に置くための一式です。

## `.nojekyll` について
空のファイルですが、これが無いと、GitHub Pagesの裏側で動くJekyllという仕組みが
一部のファイル（特にアンダースコアで始まるもの。Flutter Web のビルド結果に
含まれることがあります）を無視してしまい、ページが正しく表示されない場合が
あります。これを置いておくとJekyllの処理自体をスキップしてくれるので、
このまま一緒に置いてください。

## 初回のセットアップ手順

プロジェクトのルート（`main`ブランチ）で作業している状態から：

```bash
# 1. 履歴を持たない新しいブランチ gh-pages を作る
git switch --orphan gh-pages

# 2. 今 main にあるファイルを一旦すべて消す（ワークツリーから消すだけで、
#    main ブランチの履歴には影響しません）
git rm -rf .

# 3. このzipの中身（index.html と .nojekyll）をブランチのルートに置く
#    → エクスプローラー/Finderでコピーしてください

# 4. コミットしてpush
git add .
git commit -m "gh-pages: 配布ページを公開"
git push origin gh-pages

# 5. mainブランチに戻る（作業を続けるため）
git switch main
```

## GitHub側の設定
リポジトリの「Settings」→「Pages」→「Source」を
`Deploy from a branch` → ブランチ `gh-pages` → フォルダ `/ (root)` に設定。

数分後、`https://あなたのユーザー名.github.io/リポジトリ名/` で見られます。

## 今後の更新方法
このページ（`index.html`）の文言を変えたり、`APPS`配列に新しいアプリを
追加したりしたら、`gh-pages`ブランチ側のファイルだけ更新してpushしてください。
`main`ブランチ（Flutterのソースコード）とは完全に独立しているので、
お互いに影響しません。

## Web版アプリ（Flutter）を追加するとき
`flutter build web` の出力（`build/web`の中身）を、`gh-pages`ブランチの
ルートに作ったサブフォルダ（例：`studysync/`）にコピーしてpushしてください。
`index.html`内の`APPS`配列の`web.url`が`"./studysync/"`を指しているので、
そのフォルダ名と合わせればそのまま動きます。
