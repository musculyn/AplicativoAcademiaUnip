# Configuração do Firebase

Siga estes passos para configurar o Firebase no projeto:

## 1. Criar Projeto no Firebase Console
- Acesse [Firebase Console](https://console.firebase.google.com)
- Clique em "Adicionar projeto"
- Digite o nome: `AplicativoAcademia`
- Siga o assistente de configuração

## 2. Configurar Autenticação
- No menu lateral, clique em "Authentication"
- Clique em "Começar"
- Habilite "Email/senha"

## 3. Configurar Firestore Database
- No menu lateral, clique em "Firestore Database"
- Clique em "Criar banco de dados"
- Escolha "Modo de teste" (para desenvolvimento)
- Escolha uma localização (ex: southamerica-east1)

## 4. Configurar Android
- No projeto Firebase, clique no ícone Android
- Nome do pacote: `com.example.aplicativo_academia`
  (ou o package name do seu app - verifique em `android/app/build.gradle`)
- Apelido do app: `Aplicativo Academia`
- Baixe o arquivo `google-services.json`
- **Coloque o arquivo em:** `android/app/google-services.json`

## 5. Configurar iOS (se necessário)
- No projeto Firebase, clique no ícone iOS
- Bundle ID: `com.example.aplicativoAcademia`
- Apelido do app: `Aplicativo Academia`
- Baixe o arquivo `GoogleService-Info.plist`
- **Coloque o arquivo em:** `ios/Runner/GoogleService-Info.plist`

## 6. Gerar arquivo de configuração Flutter
Execute no terminal:
```bash
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth
flutter pub run flutterfire configure