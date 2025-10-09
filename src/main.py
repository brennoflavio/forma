from src.ut_components import setup
setup("forma.brennoflavio")

from src.converter import convert
from src.ut_components.config import get_cache_path
from typing import List
from dataclasses import dataclass
from src.ut_components.utils import dataclass_to_dict
import os

@dataclass
class StandardResponse:
    success: bool
    message: str
    image_paths: List[str]

def replace_extension(filepath: str, new_extension: str):
    if not new_extension.startswith('.'):
        new_extension = '.' + new_extension
    base, _ = os.path.splitext(filepath)    
    return base + new_extension

def get_filename(filepath):
    return os.path.basename(filepath)

@dataclass_to_dict
def convert_images(images: List[str], output_format: str, quality: int, optimize: bool) -> StandardResponse:
    try:
        converted_images = []
        for image in images:
            file_name = get_filename(image)
            output_file = replace_extension(file_name, output_format)
            output_path = os.path.join(get_cache_path(), output_file)

            if os.path.exists(output_path):
                os.remove(output_path)

            convert(image, output_path, quality=quality, optimize=optimize)
            converted_images.append(output_path)
        return StandardResponse(success=True, message="Images converted successfully.", image_paths=converted_images)
    except Exception as e:
        return StandardResponse(success=False, message=str(e), image_paths=[])
