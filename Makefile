# =========================
# Flutter Web Deploy
# =========================

APP_NAME=remote-kattedon
LOCAL_FIREBASE_PROJECT=demo-kattedon
LOCAL_PROXY_URL=http://127.0.0.1:5001/$(LOCAL_FIREBASE_PROJECT)/asia-northeast1/ishikawaOpenDataProxy

# Flutter Web build
build:
	flutter build web

# Firebase deploy
deploy:
	firebase deploy

# Build + Deploy
release:
	flutter clean
	flutter pub get
	flutter build web --release
	firebase deploy
# build deploy

# Clean build cache
clean:
	flutter clean
	flutter pub get

# Local web run
run:
	flutter run -d chrome

# Install Functions dependencies
functions-install:
	cd functions && npm install

# Start local Functions emulator (Terminal A)
proxy-emulator:
	npx firebase-tools emulators:start --only functions --project $(LOCAL_FIREBASE_PROJECT)

# Run Flutter Web with local proxy (Terminal B)
run-open-data-local:
	flutter run -d chrome --dart-define=ISHIKAWA_OPEN_DATA_URL=$(LOCAL_PROXY_URL)

# open hosting site
open:
	npx open-cli https://fishxtech-hackathon-teamd.web.app