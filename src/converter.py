import sys
import os

current_dir = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(current_dir, 'lib')
sys.path.insert(0, lib_path)

from PIL import Image
import pillow_heif
import os

pillow_heif.register_heif_opener()


def get_format_from_extension(file_path: str) -> str:
    ext = os.path.splitext(file_path)[1].lower()
    format_map = {
        '.jpg': 'JPEG',
        '.jpeg': 'JPEG',
        '.png': 'PNG',
        '.gif': 'GIF',
        '.bmp': 'BMP',
        '.tiff': 'TIFF',
        '.tif': 'TIFF',
        '.webp': 'WEBP',
        '.heic': 'HEIF',
        '.heif': 'HEIF',
        '.avif': 'AVIF',
        '.ico': 'ICO'
    }
    return format_map.get(ext, ext[1:].upper() if ext else 'JPEG')


def prepare_image_for_format(img: Image.Image, output_format: str) -> Image.Image:
    if output_format in ('JPEG', 'HEIF'):
        if img.mode in ('RGBA', 'LA', 'P'):
            rgb_img = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'RGBA':
                rgb_img.paste(img, mask=img.split()[-1])
            elif img.mode == 'LA':
                rgb_img.paste(img, mask=img.split()[-1])
            else:
                img = img.convert('RGBA')
                rgb_img.paste(img, mask=img.split()[-1])
            return rgb_img
        elif img.mode != 'RGB':
            return img.convert('RGB')
    elif output_format in ('PNG', 'WEBP', 'TIFF'):
        if img.mode in ('RGBA', 'LA', 'P'):
            return img
        elif output_format == 'PNG' and img.mode == 'RGB':
            return img
    return img


def get_save_params(output_format: str, quality: int, optimize: bool) -> dict:
    params = {}

    if output_format == 'JPEG':
        params['quality'] = quality
        params['optimize'] = optimize
        params['progressive'] = True
    elif output_format == 'HEIF':
        params['quality'] = quality
    elif output_format == 'PNG':
        params['optimize'] = optimize
        if optimize:
            params['compress_level'] = 9
    elif output_format == 'WEBP':
        params['quality'] = quality
        params['method'] = 6 if optimize else 0
    elif output_format in ('TIFF', 'BMP', 'GIF'):
        pass
    elif output_format == 'AVIF':
        params['quality'] = quality
    return params


def convert(input_path: str, output_path: str, quality: int = 95, optimize: bool = True) -> bool:
    try:
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Input file not found: {input_path}")
        img = Image.open(input_path)
        output_format = get_format_from_extension(output_path)
        img = prepare_image_for_format(img, output_format)
        save_params = get_save_params(output_format, quality, optimize)
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        if output_format:
            save_params['format'] = output_format
            img.save(output_path, **save_params)
        else:
            img.save(output_path, **save_params)
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return True
        else:
            raise IOError(f"Failed to create output file: {output_path}")
    except FileNotFoundError as e:
        return False
    except PermissionError:
        return False
    except (IOError, OSError) as e:
        return False
    except Exception as e:
        return False
