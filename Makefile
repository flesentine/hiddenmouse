.PHONY: bootstrap generate open clean

bootstrap:
	@command -v brew >/dev/null 2>&1 || (echo "Homebrew is required: https://brew.sh" && exit 1)
	@command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	$(MAKE) generate

generate:
	xcodegen generate

open: generate
	open ParkHunt.xcodeproj

clean:
	rm -rf ParkHunt.xcodeproj DerivedData build
