echo '# Removing laravel and artisan artifacts'

rm -f -r amplify/backend/function/laravel/src/*
rm -f -r amplify/backend/function/artisan/src/*

echo "*\n!/.gitignore" > amplify/backend/function/laravel/src/.gitignore
echo "*\n!/.gitignore" > amplify/backend/function/artisan/src/.gitignore