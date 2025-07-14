NAME=AI Ready
TARGET=au.org.nectar.AIReady

IMAGE_NAMES := \
	"NeCTAR AI Ready Base" \
	"NeCTAR AI Ready with GenAI and LLMs" \
	"NeCTAR AI Ready with PyTorch" \
	"NeCTAR AI Ready with TensorFlow" \
	"NeCTAR AI Ready with PyTorch and TorchVision"

.PHONY: all build clean upload check public update-image

all: clean update-images package.zip

build: package.zip

clean:
	rm -rf package.zip

upload: package.zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u package.zip

public:
	@echo "Searching for $(TARGET) package ID..."
	@package_id=$$(murano package-list --fqn $(TARGET) | grep $(TARGET) | awk '{print $$2}'); \
	echo "Found ID: $$package_id"; \
	murano package-update --is-public true $$package_id

update-images:
	python3 update_image_ids.py

package.zip:
	cd $(TARGET) && zip -r ../$@ *
