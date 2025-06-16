NAME=AI Ready Base
TARGET=au.org.nectar.AIReadyBase
.PHONY: all build clean upload check public update-image

all: clean update-image package.zip

build: package.zip

clean:
	rm -rf package.zip

upload: package.zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u package.zip

check: package.zip
	tox -e check

public:
	@echo "Searching for $(TARGET) package ID..."
	@package_id=$$(murano package-list --fqn $(TARGET) | grep $(TARGET) | awk '{print $$2}'); \
	echo "Found ID: $$package_id"; \
	murano package-update --is-public true $$package_id

update-image:
	@echo "Searching for latest image of NeCTAR $(NAME)..."
	@image_id=$$(openstack image list -c ID -f value --public --status active --sort updated_at:desc --limit 1 --name "NeCTAR $(NAME)"); \
	if [ -z "$$image_id" ]; then echo "Image ID not found"; exit 1; fi; \
    echo "Found ID: $$image_id"; \
    sed -i "s/sourceImage:.*/sourceImage: $$image_id/g" $(TARGET)/UI/ui.yaml

package.zip:
	cd $(TARGET) && zip -r ../$@ *
