# AmplifyでサーバーレスLaravelをデプロイするサンプル

## 1. Laravelをインストールしてbrefを追加します。

[bref](https://bref.sh/) は簡単に AWS Lambda でPHPを動かすためのカスタムランタイム + パッケージです。  

まずはlaravelをインストールし
```
composer create-project laravel/laravel:^8.0 laravel
```
laravelにbrefをインストールします。
```
cd laravel
composer require bref/bref bref/laravel-bridge --update-with-dependencies
```

## 2. Amplifyプロジェクトを立ち上げて、Lambda関数を追加します。

このコマンドでamplifyフォルダを作成します。（細かい設定は割愛します。）
```
amplify init
```
次のコマンドでLambda関数をnode.jsで２つ作成します。＊これは仮作成なので後で改造します。
```
amplify function add
```
大まかな設定
```
# 関数１
- name: laravel
- runtime: node.js

# 関数2
- name: artisan
- runtime: node.js
```

/amplify/backend/function に laravelとartisanが作成されているので、それぞれ {関数名}-cloudformation-template.json を編集します。編集内容は以下。

laravel
```
Resources.LambdaFunction.Properties.Handler = "public/index.php"
Resources.LambdaFunction.Properties.Runtime = "provided.al2"
Resources.LambdaFunction.Properties.Layers = [
  "arn:aws:lambda:ap-northeast-1:209497400698:layer:php-81-fpm:13"
]
Resources.LambdaFunction.Properties.Timeout = 25
```
artisan
```
Resources.LambdaFunction.Properties.Handler = "artisan"
Resources.LambdaFunction.Properties.Runtime = "provided.al2"
Resources.LambdaFunction.Properties.Layers = [
  "arn:aws:lambda:ap-northeast-1:209497400698:layer:php-81:13",
  "arn:aws:lambda:ap-northeast-1:209497400698:layer:console:52"
]
Resources.LambdaFunction.Properties.Timeout = 300
```

＊ Layerは[こちら](https://bref.sh/docs/runtimes/)から最新のものを参照して設定して下さい。  
＊ 実際にはRDSやRDS Proxyに接続すると思います。VPC内に接続することになるため、VpcConfigを適切に設定して下さい。  

## 3. API Gateway を laravel に接続します。

次のコマンドでAPI Gatewayを作成します。
```
amplify api add
```
設定内容
```
- type: REST
- name: RestApi
- path: /api
- function: laravel
```
＊ apiはlaravelの方にのみ接続します。  

## 4. hooksにLaravelのセットアップを仕込みます。
amplify/hooksにて```amplify push```コマンドでデプロイする前後で ```composer install```するようシェルスクリプトを書き込みます。

amplify/hooks/pre-push.sh
```
ROOT_PATH=$(pwd)

echo '# Copy laravel to amplify laravel and artisan'

rm -f -r amplify/backend/function/laravel/src/*
rm -f -r amplify/backend/function/artisan/src/*

cp -r laravel/* amplify/backend/function/laravel/src
cp -r laravel/* amplify/backend/function/artisan/src

echo '# Building laravel'
cd amplify/backend/function/laravel/src
composer install --optimize-autoloader --no-dev
php artisan config:clear
cd $ROOT_PATH

echo '# Building artisan'
cd amplify/backend/function/artisan/src
composer install --optimize-autoloader
php artisan config:clear
cd $ROOT_PATH
```
amplify/hooks/post-push.sh
```
echo '# Removing laravel and artisan artifacts'

rm -f -r amplify/backend/function/laravel/src/*
rm -f -r amplify/backend/function/artisan/src/*

echo "*\n!/.gitignore" > amplify/backend/function/laravel/src/.gitignore
echo "*\n!/.gitignore" > amplify/backend/function/artisan/src/.gitignore
```

**これでとりあえずpushできるようになりました！**

## ex. 自動ビルドを設定する

ここからはブランチののpushから AmplifyConsole でCI/CDするための設定をします。ルートディレクトリにamplify.ymlを作成し、以下のビルド設定をして下さい。（preBuildでPHPとComposerをインストールするだけです）  

amplify.yml
```
version: 1
backend:
  phases:
    preBuild:
      commands:
        - '# Install PHP'
        - amazon-linux-extras install php8.0
        - yum install --enablerepo=remi,remi-php80 php-xml -y
        - php -v
        - '# Install Composer'
        - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        - php composer-setup.php ;
        - php -r "unlink('composer-setup.php');" ;
        - mv composer.phar /usr/local/bin/composer
    build:
      commands:
        - '# Execute Amplify CLI with the helper script'
        - amplifyPush --simple
frontend:
  artifacts:
    baseDirectory: /dist
    files:
      - '**/*'
  cache:
    paths: []
```
＊ AmplifyConsoleでのCI/CDにはフロントエンドが必須なため、フロントソースがない場合は .gitignore から /dist をコメントアウトして、distにダミーのindex.htmlを配置してください。

以上になります。