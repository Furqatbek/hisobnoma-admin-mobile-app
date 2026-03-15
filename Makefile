.PHONY: help get analyze test format build-apk build-aab build-ios clean gen icons splash

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

get: ## Install dependencies
	flutter pub get

analyze: ## Run static analysis
	flutter analyze --no-fatal-infos

test: ## Run all tests
	flutter test

format: ## Format code
	dart format .

format-check: ## Check formatting without changes
	dart format --set-exit-if-changed .

build-apk: ## Build release APK
	flutter build apk --release

build-aab: ## Build release App Bundle
	flutter build appbundle --release

build-ios: ## Build release iOS (no codesign)
	flutter build ios --release --no-codesign

clean: ## Clean build artifacts
	flutter clean && flutter pub get

gen: ## Run build_runner code generation
	dart run build_runner build --delete-conflicting-outputs

icons: ## Generate app icons
	dart run flutter_launcher_icons

splash: ## Generate splash screen
	dart run flutter_native_splash:create

ci: format-check analyze test ## Run full CI checks locally

version-bump-patch: ## Bump patch version (1.0.x)
	@current=$$(grep 'version:' pubspec.yaml | head -1 | sed 's/version: //'); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	patch=$$(echo $$current | cut -d. -f3 | cut -d+ -f1); \
	build=$$(echo $$current | cut -d+ -f2); \
	new_patch=$$((patch + 1)); \
	new_build=$$((build + 1)); \
	new_version="$$major.$$minor.$$new_patch+$$new_build"; \
	sed -i "s/version: $$current/version: $$new_version/" pubspec.yaml; \
	echo "Version bumped: $$current -> $$new_version"

version-bump-minor: ## Bump minor version (1.x.0)
	@current=$$(grep 'version:' pubspec.yaml | head -1 | sed 's/version: //'); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	build=$$(echo $$current | cut -d+ -f2); \
	new_minor=$$((minor + 1)); \
	new_build=$$((build + 1)); \
	new_version="$$major.$$new_minor.0+$$new_build"; \
	sed -i "s/version: $$current/version: $$new_version/" pubspec.yaml; \
	echo "Version bumped: $$current -> $$new_version"
