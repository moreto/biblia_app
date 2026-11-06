#!/bin/bash

#   Script
#   1. Remove os pubspec.lock de todos os modulos
#   2. flutter clean / flutter pub get -> para todos os modulos
#   3. Verifica se existe o arquivo .env, se não existir cria um com conteúdo padão
#   4. Executa o build_runner e flutter_gen -> para gerar assets / classes
#   5. Instala e configura o mason
#   6. Executa o dart fix -> para aplicar correções automáticas

#   1. Remove os pubspec.lock de todos os modulos
rm -f pubspec.lock
echo " "
echo "=> pubspec.lock removido..."

rm -f ../commons/pubspec.lock
echo " "
echo "=> ../commons/pubspec.lock removido..."

rm -f ../components/pubspec.lock
echo " "
echo "=> ../components/pubspec.lock removido..."

rm -f ../service/pubspec.lock
echo " "
echo "=> ../service/pubspec.lock removido..."

rm -f ios/Podfile.lock
echo " "
echo "=> ios/Podfile.lock removido..."

#   2. flutter clean / flutter pub get -> para todos os modulos
flutter clean
flutter pub get

cd ../service
echo " "
echo " "
echo "=> flutter pub get services"
flutter clean
flutter pub get 
#cd ..
cd ../components
echo " "
echo "=> flutter pub get components"
flutter clean
flutter pub get
#cd ..
cd ../commons
echo " "
echo "=> flutter pub get commons"
flutter clean
flutter pub get

echo " "
echo " "
#   5. Instala e configura o mason
echo "=> mason"
cd ../app
dart pub global activate mason_cli
mason get
mason list

echo "... "
wait
echo "=> Execução finalizada..."

echo " "
echo " "
#   6. Executa o dart fix -> para aplicar correções automáticas
dart fix --dry-run
echo "=> Execução finalizada..."