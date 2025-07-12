#!/usr/bin/env python3

import argparse
import difflib
import logging
import re
from pathlib import Path

import openstack

# Simple coloured output
logging.addLevelName(logging.DEBUG, "🐛")
logging.addLevelName(logging.INFO, "✅")
logging.addLevelName(logging.WARNING, "⚠️ ")
logging.addLevelName(logging.ERROR, "❌")
logging.addLevelName(logging.CRITICAL, "🔥")

logging.basicConfig(format="%(levelname)s %(message)s", level=logging.WARNING)

LOG = logging.getLogger(__name__)

IMAGE_MAP = {
    "NeCTAR AI Ready Base": "base",
    "NeCTAR AI Ready with GenAI and LLMs": "genai-llm",
    "NeCTAR AI Ready with PyTorch": "pytorch",
    "NeCTAR AI Ready with PyTorch and TorchVision": "torchvision",
    "NeCTAR AI Ready with TensorFlow": "tensorflow",
}


def get_latest_image(conn, name):
    images = conn.image.images(
        name=name,
        visibility="public",
        status="active",
        sort="updated_at:desc",  # Sort by updated_at in descending order
        limit=1,  # Limit to 1 result
    )
    image_list = list(images)
    if image_list:
        return image_list[0]
    else:
        return None


def update_images(yaml_path, image_map, conn, dry_run=False, verbose=False):

    if verbose:
        LOG.setLevel(logging.INFO)

    original_content = yaml_path.read_text()
    updated_content = original_content
    updated = False

    for name, key in image_map.items():
        image = get_latest_image(conn, name)
        if not image:
            LOG.warning(f"No active public image found for: {name}")
            continue
        else:
            LOG.info(f"Found image {name}: {image.id}")

        # Define the regex pattern and replacement string
        pattern = r'("{}"\s*=>\s*)"(.*?)"'.format(re.escape(key))
        replacement = r'\1"{}"'.format(image.id)

        updated_content = re.sub(pattern, replacement, updated_content, count=1)

        if updated_content != original_content:
            updated = True

    if updated:
        LOG.info(f"Showing diff for {yaml_path}:\n")
        diff = difflib.unified_diff(
            original_content.splitlines(),
            updated_content.splitlines(),
            fromfile=str(yaml_path),
            tofile=f"{yaml_path} (updated)",
            lineterm="",
        )
        print("\n".join(diff))
        if not dry_run:
            yaml_path.write_text(updated_content)
            LOG.info(f"File updated: {yaml_path}")
    else:
        LOG.info("No changes required.")


def main():
    parser = argparse.ArgumentParser(
        description="Update Murano UI YAML image UUIDs using OpenStack"
    )
    parser.add_argument(
        "--file",
        "-f",
        type=Path,
        default=Path("au.org.nectar.AIReady/UI/ui.yaml"),
        help="Path to the YAML UI config file",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show changes without modifying the file",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show messages for entries already up to date",
    )

    args = parser.parse_args()
    conn = openstack.connect(cloud="envvars")

    update_images(
        args.file, IMAGE_MAP, conn, dry_run=args.dry_run, verbose=args.verbose
    )


if __name__ == "__main__":
    main()
