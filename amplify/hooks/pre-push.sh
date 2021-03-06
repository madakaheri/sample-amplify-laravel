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