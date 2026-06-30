"""
图片转 MJPEG 启动 Logo 工具

将一张或多张图片转换为嵌入式设备使用的 MJPEG 格式启动 Logo (logo.jpg)。

单张图片模式:
    直接输出 MJPEG 编码的 logo.jpg（经过旋转、缩放、YUV420P 格式转换）。

多张图片模式:
    将多张图片经 YUV420P 统一后编码为 JPEG，再直接合成为 MJPEG 裸流 (logo.jpg)。
    流程: 重命名+旋转 → 转 YUV420P → 重新编码 JPEG → 直接导出 MJPEG 裸流

用法:
    python process_images.py                                            # 默认参数
    python process_images.py -i ./input -o ./output -r 720 1280 --rotate 90
    python process_images.py -i ./input -o ./output --rotate 90 -f 15

参数说明:
    -i/--input      输入文件或文件夹路径 (默认: 当前目录)
                    单文件: 直接处理该图片
                    文件夹: 收集所有 .jpg/.jpeg/.png 文件

    -o/--output     输出目录路径 (默认: 当前目录)
                    生成 logo.jpg（单张/多张）和 logo.avi（多张）

    -r/--resolution 指定输出分辨率 WIDTH HEIGHT (默认: 以第一张图片为准)
                    示例: -r 720 1280

    --rotate        旋转角度, 可选 0/90/180/270 (默认: 0)

    -f/--fps        每秒帧数, 仅多张图片模式有效 (默认: 10)
    --jpeg-q        JPEG 质量参数(FFmpeg q:v, 2~31, 越小质量越高, 默认: 2)

依赖: ffmpeg, Pillow (python3-pil)

注意:
    - 先旋转，再缩放
    - 多张图片模式下，中间过程强制经过 YUV420P 格式转换以保证一致性
    - 输出的 logo.jpg 实际为 MJPEG 裸流格式（非标准 JPEG）
"""

import os
import shutil
import argparse
import subprocess
import tempfile
import math
from pathlib import Path

OUT_PREFIX = "logo"

def check_dependency():
    import shutil as s
    if not s.which("ffmpeg"):
        print("错误：未找到 ffmpeg，请先安装: apt install ffmpeg")
        exit(1)
    try:
        from PIL import Image
    except ImportError:
        print("错误：未找到 Pillow，请先安装: apt install python3-pil")
        exit(1)

def get_image_size(img_path):
    from PIL import Image
    with Image.open(img_path) as img:
        return img.size

def rotate_vf(angle):
    if angle == 90:
        return "transpose=2"
    elif angle == 180:
        return "transpose=2,transpose=2"
    elif angle == 270:
        return "transpose=1"
    elif angle == 0:
        return None
    else:
        print(f"错误：不支持的旋转角度 {angle}，仅支持 0/90/180/270")
        exit(1)

def get_default_resolution(image_path, rotate_angle):
    width, height = get_image_size(image_path)
    if rotate_angle in (90, 270):
        return (height, width)
    return (width, height)

def validate_even_resolution(resolution):
    width, height = resolution
    if width <= 0 or height <= 0:
        print(f"错误：分辨率必须为正整数: {width}x{height}")
        exit(1)
    if width % 2 != 0 or height % 2 != 0:
        print(f"错误：YUV420P 要求分辨率宽高均为偶数，当前: {width}x{height}")
        exit(1)

def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="")
        raise SystemExit(result.returncode)

def run_get_output(cmd):
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if result.returncode != 0:
        if result.stdout:
            print(result.stdout, end="")
        raise SystemExit(result.returncode)
    return result.stdout

def collect_images(input_path):
    path = Path(input_path)
    if path.is_file():
        if path.suffix.lower() not in {".jpg", ".jpeg", ".png"}:
            print(f"错误：输入文件必须是 jpg/jpeg/png: {input_path}")
            exit(1)
        return [str(path)]

    if not path.is_dir():
        print(f"错误：输入路径不存在或不是文件/目录: {input_path}")
        exit(1)

    images = sorted(
        str(p) for p in path.iterdir()
        if p.is_file()
        and p.suffix.lower() in {".jpg", ".jpeg", ".png"}
        and p.name.lower() != f"{OUT_PREFIX}.jpg"
    )
    return images

def validate_output_dir(output_path):
    out = Path(output_path)
    if out.exists() and out.is_file():
        print(f"错误：-o 需要指定输出目录，不能是文件: {output_path}")
        exit(1)
    if not out.exists() and out.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
        print(f"错误：-o 需要指定输出目录，不能指定输出文件名: {output_path}")
        exit(1)
    out.mkdir(parents=True, exist_ok=True)
    return out

def parse_psnr_log(psnr_log):
    values = []
    for line in psnr_log.splitlines():
        if "average:" not in line:
            continue
        parts = line.split("average:")
        if len(parts) < 2:
            continue
        v = parts[1].split()[0]
        try:
            values.append(float(v))
        except ValueError:
            pass
    return values

def split_mjpeg_stream(input_path, output_dir, prefix):
    data = Path(input_path).read_bytes()
    frames = []
    i = 0
    while True:
        start = data.find(b"\xff\xd8", i)
        if start < 0:
            break
        end = data.find(b"\xff\xd9", start + 2)
        if end < 0:
            break
        frame = data[start:end + 2]
        out = output_dir / f"{prefix}_{len(frames):02d}.jpg"
        out.write_bytes(frame)
        frames.append(out)
        i = end + 2
    return frames

def extract_test(output_dir, images, resolution, rotate_angle):
    print("=== 额外测试: 抽帧并统计大小/PSNR ===")
    logo_mjpeg = output_dir / f"{OUT_PREFIX}.jpg"
    test_dir = output_dir / "logo_extracted"
    test_dir.mkdir(parents=True, exist_ok=True)
    extracted = split_mjpeg_stream(logo_mjpeg, test_dir, OUT_PREFIX)

    if not extracted:
        print("警告：未抽取到帧，跳过测试统计")
        return

    print("帧大小统计:")
    sizes = []
    for path in extracted:
        kb = os.path.getsize(path) / 1024.0
        sizes.append(kb)
        print(f"  {path.name}  {kb:.1f} KB")
    print(f"  最小/最大/平均: {min(sizes):.1f}/{max(sizes):.1f}/{(sum(sizes)/len(sizes)):.1f} KB")

    if len(images) < len(extracted):
        print("提示：抽帧数大于输入图数，PSNR仅比较前 N 帧")
    n = min(len(images), len(extracted))
    if n == 0:
        return

    vf = rotate_vf(rotate_angle)
    with tempfile.TemporaryDirectory(prefix="bootlogo_psnr_", dir="/tmp") as tmp:
        ref_dir = Path(tmp) / "ref"
        ref_dir.mkdir()
        for i in range(n):
            ref = ref_dir / f"{OUT_PREFIX}_{i:02d}.yuv"
            if vf:
                run([
                    "ffmpeg", "-y", "-i", str(images[i]),
                    "-vf", f"{vf},scale={resolution[0]}:{resolution[1]},format=yuv420p",
                    "-f", "rawvideo", str(ref),
                ])
            else:
                run([
                    "ffmpeg", "-y", "-i", str(images[i]),
                    "-vf", f"scale={resolution[0]}:{resolution[1]},format=yuv420p",
                    "-f", "rawvideo", str(ref),
                ])

        psnrs = []
        for i in range(n):
            ref = ref_dir / f"{OUT_PREFIX}_{i:02d}.yuv"
            out = extracted[i]
            log = run_get_output([
                "ffmpeg", "-y",
                "-s", f"{resolution[0]}x{resolution[1]}",
                "-pix_fmt", "yuv420p",
                "-i", str(ref),
                "-i", str(out),
                "-lavfi", "psnr",
                "-f", "null",
                "-",
            ])
            vals = parse_psnr_log(log)
            if vals:
                psnrs.append(vals[-1])

        if psnrs:
            print(
                "PSNR统计(dB, 与旋转缩放后源图对比): "
                f"min={min(psnrs):.2f}, max={max(psnrs):.2f}, avg={sum(psnrs)/len(psnrs):.2f}"
            )
        else:
            print("警告：未获取到PSNR统计")

def process_single_image(image_path, output_dir, resolution, rotate_angle, jpeg_q):
    vf = rotate_vf(rotate_angle)

    if resolution is None:
        resolution = get_default_resolution(image_path, rotate_angle)
        print(f"未指定分辨率，使用默认输出分辨率: {resolution[0]}x{resolution[1]}")
    else:
        resolution = tuple(resolution)
        print(f"使用指定分辨率: {resolution[0]}x{resolution[1]}")
    validate_even_resolution(resolution)

    output_jpg = output_dir / f"{OUT_PREFIX}.jpg"
    with tempfile.NamedTemporaryFile(
        prefix=f"{OUT_PREFIX}_single_",
        suffix=".jpg",
        dir=output_dir,
        delete=False,
    ) as tmp_file:
        temp_output = Path(tmp_file.name)

    try:
        if vf:
            run([
                "ffmpeg", "-y", "-i", str(image_path),
                "-vf", f"{vf},scale={resolution[0]}:{resolution[1]},format=yuv420p",
                "-vcodec", "mjpeg", "-q:v", str(jpeg_q), str(temp_output),
            ])
        else:
            run([
                "ffmpeg", "-y", "-i", str(image_path),
                "-vf", f"scale={resolution[0]}:{resolution[1]},format=yuv420p",
                "-vcodec", "mjpeg", "-q:v", str(jpeg_q), str(temp_output),
            ])
        os.replace(temp_output, output_jpg)
    finally:
        if temp_output.exists():
            temp_output.unlink()

def process_images(input_path, output_dir, resolution, rotate_angle, fps, jpeg_q, preview_avi, do_extract_test):
    images = collect_images(input_path)

    if not images:
        print(f"错误：在 {input_path} 中未找到 *.jpg/*.jpeg/*.png 文件")
        exit(1)

    with tempfile.TemporaryDirectory(prefix="bootlogo_", dir="/tmp") as tmp:
        temp_dir = Path(tmp)
        if len(images) == 1:
            print("=== 单张图片输入，只执行一次转换 ===")
            process_single_image(images[0], output_dir, resolution, rotate_angle, jpeg_q)
            if do_extract_test:
                if resolution is None:
                    test_resolution = get_default_resolution(images[0], rotate_angle)
                else:
                    test_resolution = tuple(resolution)
                extract_test(output_dir, images, test_resolution, rotate_angle)
            print(f"=== ✅ 完成！输出文件：{output_dir / (OUT_PREFIX + '.jpg')} ===")
            return

        rotate_dir = temp_dir / "rotated"
        yuv_dir = temp_dir / "yuv"
        rotate_dir.mkdir()
        yuv_dir.mkdir()

        if resolution is None:
            resolution = get_default_resolution(images[0], rotate_angle)
            print(f"未指定分辨率，使用默认输出分辨率: {resolution[0]}x{resolution[1]}")
        else:
            resolution = tuple(resolution)
            print(f"使用指定分辨率: {resolution[0]}x{resolution[1]}")
        validate_even_resolution(resolution)

        vf = rotate_vf(rotate_angle)

        print(f"=== 1. 重命名并旋转图片 {'(' + str(rotate_angle) + '°)' if rotate_angle else ''} ===")
        for i, img in enumerate(images):
            ext = os.path.splitext(img)[1].lower()
            newname = f"{OUT_PREFIX}{i:02d}.jpg"
            if vf:
                print(f"处理 {img} → {newname} (旋转{rotate_angle}°)")
                run([
                    "ffmpeg", "-y", "-i", str(img),
                    "-vf", vf, str(rotate_dir / newname),
                ])
            else:
                print(f"处理 {img} → {newname}")
                if ext in {".jpg", ".jpeg"}:
                    shutil.copy(img, rotate_dir / newname)
                else:
                    run([
                        "ffmpeg", "-y", "-i", str(img),
                        "-q:v", "2", str(rotate_dir / newname),
                    ])

        print("=== 2. 转换为 YUV420P 格式 ===")
        for img in sorted(rotate_dir.iterdir()):
            if not img.is_file():
                continue
            run([
                "ffmpeg", "-y", "-i", str(img),
                "-vf", f"scale={resolution[0]}:{resolution[1]},format=yuv420p",
                str(yuv_dir / f"{img.name}.yuv"),
            ])

        print("=== 3. 将 YUV 转回 JPEG (YUV420 格式) ===")
        for yuv in sorted(yuv_dir.glob("*.yuv")):
            base = yuv.name.replace(".yuv", "")
            run([
                "ffmpeg", "-y",
                "-pix_fmt", "yuv420p",
                "-s", f"{resolution[0]}x{resolution[1]}",
                "-i", str(yuv),
                "-vcodec", "mjpeg",
                "-q:v", str(jpeg_q),
                str(rotate_dir / base),
            ])

        print("=== 4. 直接导出 MJPEG 裸流并重命名为 logo.jpg ===")
        output_mjp = output_dir / f"{OUT_PREFIX}.mjp"
        output_jpg = output_dir / f"{OUT_PREFIX}.jpg"
        run([
            "ffmpeg", "-y",
            "-framerate", str(fps),
            "-i", str(rotate_dir / f"{OUT_PREFIX}%02d.jpg"),
            "-c:v", "copy",
            "-f", "mjpeg",
            str(output_mjp),
        ])
        os.replace(output_mjp, output_jpg)

        output_files = [str(output_jpg)]
        if preview_avi:
            print("=== 5. 生成预览 AVI（可选） ===")
            output_avi = output_dir / f"{OUT_PREFIX}.avi"
            run([
                "ffmpeg", "-y",
                "-framerate", str(fps),
                "-i", str(rotate_dir / f"{OUT_PREFIX}%02d.jpg"),
                "-c:v", "copy",
                str(output_avi),
            ])
            output_files.append(str(output_avi))

        if do_extract_test:
            extract_test(output_dir, images, resolution, rotate_angle)

        print(f"=== ✅ 完成！输出文件：{', '.join(output_files)} ===")

def main():
    check_dependency()

    parser = argparse.ArgumentParser(
        description="图片转 MJPEG 启动 Logo 工具",
        epilog="""\
单张图片模式:
  直接输出 MJPEG 编码的 logo.jpg（旋转 → 缩放 → YUV420P）。

多张图片模式:
  输出 logo.jpg, 流程: 重命名+旋转 → YUV420P → 重新编码 JPEG → 直接导出 MJPEG 裸流

注意: 先旋转，再缩放；logo.jpg 实际为 MJPEG 裸流格式（非标准 JPEG）""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-i", "--input", default=".", help="输入文件或文件夹路径 (默认: 当前目录)。单文件直接处理，文件夹收集所有 .jpg/.jpeg/.png 文件")
    parser.add_argument("-o", "--output", default=".", help="输出目录路径 (默认: 当前目录)。默认生成 logo.jpg；多图模式可选生成 logo.avi")
    parser.add_argument("-r", "--resolution", nargs=2, type=int, metavar=("WIDTH", "HEIGHT"), help="指定输出分辨率，如: -r 720 1280 (默认: 以第一张图片为准)")
    parser.add_argument("--rotate", type=int, default=0, choices=[0, 90, 180, 270], help="旋转角度 (默认: 0)")
    parser.add_argument("-f", "--fps", type=int, default=10, help="每秒帧数，仅多张图片模式有效 (默认: 10)")
    parser.add_argument("--jpeg-q", type=int, default=2, help="JPEG 质量参数(FFmpeg q:v, 2~31，越小质量越高，默认: 2)")
    parser.add_argument("--preview-avi", action="store_true", help="多张图片模式额外输出预览 AVI (logo.avi)")
    parser.add_argument("--extract-test", action="store_true", help="生成后自动抽帧并输出每帧大小及PSNR统计")

    args = parser.parse_args()
    if not (2 <= args.jpeg_q <= 31):
        print("错误：--jpeg-q 仅支持 2~31（越小质量越高）")
        exit(1)
    output_dir = validate_output_dir(args.output)
    process_images(args.input, output_dir, args.resolution, args.rotate, args.fps, args.jpeg_q, args.preview_avi, args.extract_test)

if __name__ == "__main__":
    main()
