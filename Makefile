# =========================
# Flutter Web Deploy
# =========================

APP_NAME=remote-kattedon

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

# open hosting site
open:
	npx open-cli https://fishxtech-hackathon-teamd.web.app