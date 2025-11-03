#!/usr/bin/python3
"""
配置检查工具：
用于检查和管理系统配置项，包括内核配置和编译配置。

功能：
1. 列出所有支持的配置项
2. 检查指定配置的启用状态
3. 显示相关驱动加载命令
4. 自动添加缺失的配置项到对应的配置文件

用法:
    config_check.py -l              # 列出所有支持的配置项
    config_check.py <配置名>        # 检查指定配置的启用情况

示例:
    config_check.py -l              # 显示所有可用的配置选项
    config_check.py adb             # 检查 adb 相关配置的状态
    config_check.py rndis           # 检查 rndis 相关配置的状态

输出说明:
    ✅(*) CONFIG_XXX     # 配置已启用 (built-in)
    ✅(m) CONFIG_XXX     # 配置已启用 (module)，后面可能会显示加载命令
    ⛔    CONFIG_XXX     # 配置未启用

环境要求:
    需要先设置以下环境变量：通过 source build/envsetup_soc.sh 设置
    - TOP_DIR           # 项目根目录
    - PROJECT_FULLNAME  # 项目全名
    - CHIP_ARCH        # 芯片架构
"""

import argparse
import json
import sys
import os
from pathlib import Path
import yaml  # 添加 yaml 导入

# 定义颜色代码
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def parse_args():
    parser = argparse.ArgumentParser(
        description="配置检查工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
    %(prog)s -l                # 列出所有支持的配置
    %(prog)s adb                # 检查 adb 配置的启用情况
        """
    )
    parser.add_argument("-l", "--list", action="store_true", help="列出所有支持的配置")
    parser.add_argument("config_name", nargs='?', help="配置名称")
    return parser.parse_args()

# 嵌入的配置数据
EMBEDDED_CONFIG = '''
# USB ADB配置
adb:
  kernel_configs:  # 内核配置项
    - CONFIG_USB
    - CONFIG_USB_GADGET
    - CONFIG_USB_CONFIGFS
    - CONFIG_USB_LIBCOMPOSITE
    - CONFIG_USB_CONFIGFS_F_FS
    - CONFIG_USB_DWC2
    - CONFIG_USB_F_FS
  build_configs:  # 构建配置项
    - CONFIG_TARGET_PACKAGE_ADBD
    - CONFIG_TARGET_PACKAGE_LIBCRYPTO
    - CONFIG_TARGET_PACKAGE_LIBZ

# RNDIS网络配置
rndis:
  kernel_configs:  # 内核配置项
    - CONFIG_USB
    - CONFIG_USB_GADGET
    - CONFIG_USB_CONFIGFS
    - CONFIG_USB_LIBCOMPOSITE
    - CONFIG_USB_CONFIGFS_F_FS
    - CONFIG_USB_DWC2
    - CONFIG_USB_U_ETHER
    - CONFIG_USB_F_ECM
    - CONFIG_USB_ETH
    - CONFIG_USB_F_RNDIS
  build_configs:  # 构建配置项
    - CONFIG_TARGET_PACKAGE_RNDIS_SCRIPT

# I2C GPIO配置
i2c_gpio:
  kernel_configs:
    - CONFIG_I2C
    - CONFIG_I2C_GPIO

# Ftrace是Linux内核中的一个跟踪工具，用于帮助开发人员了解内核的行为
ftrace:
  kernel_configs:
    - CONFIG_FTRACE                      # 启用ftrace基础功能
    - CONFIG_HAVE_FUNCTION_TRACER        # 支持函数跟踪器
    - CONFIG_HAVE_FUNCTION_GRAPH_TRACER  # 支持函数调用关系图跟踪
    - CONFIG_FUNCTION_TRACER             # 函数跟踪器
    - CONFIG_FUNCTION_GRAPH_TRACER       # 函数调用关系图跟踪器
    - CONFIG_DYNAMIC_FTRACE              # 动态ftrace支持
    - CONFIG_FUNCTION_PROFILER           # 函数性能分析器
    - CONFIG_STACK_TRACER                # 内核栈使用跟踪
    - CONFIG_IRQSOFF_TRACER              # 中断禁用延迟跟踪器
    - CONFIG_PREEMPT_TRACER              # 抢占禁用延迟跟踪器
    - CONFIG_SCHED_TRACER                # 调度延迟跟踪器
    - CONFIG_HWLAT_TRACER                # 硬件延迟跟踪器
    - CONFIG_FTRACE_SYSCALLS             # 系统调用跟踪
    - CONFIG_TRACER_SNAPSHOT             # 跟踪快照支持
    - CONFIG_KPROBE_EVENTS               # 内核探针事件
    - CONFIG_UPROBE_EVENTS               # 用户空间探针事件
    - CONFIG_BPF_EVENTS                  # BPF事件支持
    - CONFIG_FUNCTION_ERROR_INJECTION    # 函数错误注入支持

# SPI 屏幕
spi_panel:
  kernel_configs:
    - CONFIG_SPI
    - CONFIG_SPI_MASTER
    - CONFIG_SPI_DESIGNWARE     # 使能 SPI 驱动
    - CONFIG_SPI_DW_MMIO
    - CONFIG_FB                 # 使能 framebuffer
    - CONFIG_FB_TFT             # 使能 framebuffer TFT
    # - CONFIG_FB_TFT_ST7789V     # 使能屏幕驱动 ST7789V

# SPI 使用 DMA 传输数据
spi_panel_dma:
  kernel_configs:
    - CONFIG_SPI
    - CONFIG_SPI_MASTER
    - CONFIG_SPI_DESIGNWARE     # 使能 SPI 驱动
    - CONFIG_SPI_DW_MMIO
    - CONFIG_SPI_DW_DMA         # 使能 SPI DMA
    - CONFIG_FB                 # 使能 framebuffer
    - CONFIG_FB_TFT             # 使能 framebuffer TFT
    # - CONFIG_FB_TFT_ST7789V     # 使能屏幕驱动 ST7789V

gpio_keys:
  kernel_configs:
    - CONFIG_INPUT
    - CONFIG_INPUT_EVDEV
    - CONFIG_INPUT_POLLDEV
    - CONFIG_INPUT_KEYBOARD
    - CONFIG_KEYBOARD_GPIO

# 内核模块对应关系配置
configs_ko:
  CONFIG_USB: usbcore.ko  # USB核心模块
  CONFIG_USB_CONFIGFS_F_FS: none
  CONFIG_USB_CONFIGFS: none
  CONFIG_USB_DWC2: dwc2.ko
  CONFIG_USB_GADGET: usb-core.ko
  CONFIG_USB_LIBCOMPOSITE: libcomposite.ko
  CONFIG_I2C_GPIO: i2c-gpio.ko
  CONFIG_USB_U_ETHER: u_ether.ko
  CONFIG_USB_CONFIGFS_NCM: u_ncm.ko
  CONFIG_USB_F_NCM: f_ncm.ko
  CONFIG_USB_F_ECM: f_ecm.ko
  CONFIG_USB_ETH: g_ether.ko  # 以太网模块
  CONFIG_USB_F_RNDIS: usb_f_rndis.ko  # RNDIS功能模块
'''

def load_config(config_file):
    try:
        # 直接从嵌入的配置加载
        return yaml.safe_load(EMBEDDED_CONFIG)
    except yaml.YAMLError as e:
        print(f"{Colors.RED}错误: 嵌入的配置格式不正确: {str(e)}{Colors.ENDC}")
        sys.exit(1)

# 修改 check_environment 函数，移除配置文件检查
def check_environment(check_path=True):
    top_dir = os.getenv('TOP_DIR')
    if not top_dir:
        print(f"{Colors.RED}错误: 环境变量 TOP_DIR 未设置")
        print("请先运行: source build/envsoc_setup.sh{Colors.ENDC}")
        sys.exit(1)

    project_fullname = os.getenv('PROJECT_FULLNAME')
    if not project_fullname:
        print(f"{Colors.RED}错误: 环境变量 PROJECT_FULLNAME 未设置{Colors.ENDC}")
        sys.exit(1)

    chip_arch = os.getenv('CHIP_ARCH').lower()
    if not chip_arch:
        print(f"{Colors.RED}错误: 环境变量 CHIP_ARCH 未设置{Colors.ENDC}")
        sys.exit(1)

    # 检查 SCENES 环境变量
    scenes = os.getenv('SCENES')
    is_fastboot = scenes == '1'

    # 根据 SCENES 确定 defconfig 文件名
    defconfig_suffix = '_fastboot_defconfig' if is_fastboot else '_defconfig'

    config_paths = {
        'kernel_config': os.path.join(top_dir, f'linux_5.10/build/{project_fullname}/.config'),
        'build_config': os.path.join(top_dir, 'build/.config'),
        'kernel_defconfig': os.path.join(top_dir, f'build/boards/{chip_arch}/{project_fullname}/linux/cvitek_{project_fullname}{defconfig_suffix}'),
        'build_defconfig': os.path.join(top_dir, f'build/boards/{chip_arch}/{project_fullname}/{project_fullname}{defconfig_suffix}')
    }

    if check_path:
        print(f"{Colors.BLUE}TOP_DIR:{Colors.ENDC} {top_dir}")
        print(f"{Colors.BLUE}PROJECT_FULLNAME:{Colors.ENDC} {project_fullname}")
        print(f"{Colors.BLUE}SCENES:{Colors.ENDC} {'fastboot' if is_fastboot else 'normal'}")
        for name, path in config_paths.items():
            print(f"{Colors.GREEN}{name}:{Colors.ENDC} {path}")
            if not os.path.exists(path):
                print(f"{Colors.RED}错误: 文件不存在: {path}{Colors.ENDC}")
                sys.exit(1)

    return config_paths, chip_arch, project_fullname

def read_kconfig(config_file):
    configs = {}
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('CONFIG_'):
                    key, value = line.split('=', 1)
                    configs[key] = value
    except FileNotFoundError:
        print(f"{Colors.RED}错误: 找不到内核配置文件 {config_file}{Colors.ENDC}")
        sys.exit(1)
    return configs

def read_build_config(config_file):
    configs = {}
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('CONFIG_'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        configs[key] = value
                    else:
                        configs[line] = 'y'
    except FileNotFoundError:
        print(f"{Colors.RED}错误: 找不到编译配置文件 {config_file}{Colors.ENDC}")
        sys.exit(1)
    return configs

def list_configs(config):
    print(f"{Colors.BLUE}支持的配置项:{Colors.ENDC}")
    for name in config.keys():
        if name != 'configs_ko':
            print(f"  - {name}")

def check_config(config, config_name, kernel_config_file, build_config_file, kernel_defconfig_file, build_defconfig_file):
    # 配置名称不区分大小写
    config_name_lower = config_name.lower()
    config_key = next((k for k in config.keys() if k.lower() == config_name_lower), None)

    if not config_key:
        print(f"{Colors.RED}错误: 未找到配置 '{config_name}'{Colors.ENDC}")
        sys.exit(1)

    cfg = config[config_key]
    ko_map = config.get('configs_ko', {})
    kernel_configs = read_kconfig(kernel_config_file)
    kernel_defconfig = read_kconfig(kernel_defconfig_file)
    build_configs = read_build_config(build_config_file)
    build_defconfig = read_build_config(build_defconfig_file)

    print(f"\n{Colors.BLUE}{config_key} 配置检查结果:{Colors.ENDC}")

    if 'kernel_configs' in cfg:
        print(f"\n{Colors.GREEN}内核配置: {Colors.ENDC}")
        enabled_configs = []
        disabled_configs = []

        for kconfig in cfg['kernel_configs']:
            status = kernel_configs.get(kconfig, '')
            if not status:
                disabled_configs.append(kconfig)
                print(f"⛔    {kconfig.ljust(30)}")
            elif status == 'y':
                enabled_configs.append(kconfig)
                print(f"✅(*) {kconfig.ljust(30)}")
            elif status == 'm':
                enabled_configs.append(kconfig)
                ko_name = ko_map.get(kconfig, '')
                if ko_name == 'none':
                    ko_info = "\t none"
                else:
                    ko_info = f"\t insmod {ko_name}" if ko_name else ""
                print(f"✅(m) {kconfig.ljust(30)}{ko_info}")

        if disabled_configs:
            need_enable_configs = []
            warning_config = []

            # 检查 kernel_defconfig 中是否已经启用了这些配置
            for config in disabled_configs:
                if config in kernel_defconfig and kernel_defconfig[config] in ['y', 'm']:
                    warning_config.append(config)
                else:
                    need_enable_configs.append(config)

            if warning_config:
                print(f"\n{Colors.YELLOW}Warning: 以下配置在 defconfig 中已启用但未生效, build_kernel/menuconfig_kernel 后重试{Colors.ENDC}")
                for config in warning_config:
                    print(f"{config}=y")

            if need_enable_configs:
                print(f"\n{Colors.YELLOW}需要启用的配置项:{Colors.ENDC} {kernel_defconfig_file}")
                for config in need_enable_configs:
                    print(f"{config}=y")

                user_input = input(f"\n{Colors.YELLOW}是否需要将配置添加到 {kernel_defconfig_file}? (y/n): {Colors.ENDC}")
                if user_input.lower() == 'y':
                    with open(kernel_defconfig_file, 'a') as f:
                        f.write(f"\n# enable {config_key}\n")
                        for config in need_enable_configs:
                            f.write(f"{config}=y\n")
                    print(f"{Colors.GREEN}已将配置添加到 {kernel_defconfig_file}{Colors.ENDC}")

    if 'build_configs' in cfg:
        print(f"\n{Colors.GREEN}编译配置: {Colors.ENDC}")
        disabled_build_configs = []

        for bconfig in cfg['build_configs']:
            if bconfig in build_configs:
                print(f"✅    {bconfig.ljust(30)}")
            else:
                disabled_build_configs.append(bconfig)
                print(f"⛔    {bconfig.ljust(30)}")

        if disabled_build_configs:
            need_enable_configs = []
            warning_config = []

            # 检查 build_defconfig 中是否已经启用了这些配置
            for config in disabled_build_configs:
                if config in build_defconfig and build_defconfig[config] in ['y', 'm']:
                    warning_config.append(config)
                else:
                    need_enable_configs.append(config)

            if warning_config:
                print(f"\n{Colors.YELLOW}Warning: 以下配置在 defconfig 中已启用但未生效, defconfig {os.getenv('PROJECT_FULLNAME')} 后重试{Colors.ENDC}")
                for config in warning_config:
                    print(f"{config}=y")

            if need_enable_configs:
                print(f"\n{Colors.YELLOW}需要启用的编译配置项:{Colors.ENDC} {build_defconfig_file}")
                for config in need_enable_configs:
                    print(f"{config}=y")

                user_input = input(f"\n{Colors.YELLOW}是否需要将配置添加到 {build_defconfig_file}? (y/n): {Colors.ENDC}")
                if user_input.lower() == 'y':
                    with open(build_defconfig_file, 'a') as f:
                        f.write(f"\n# enable {config_key}\n")
                        for config in need_enable_configs:
                            f.write(f"{config}=y\n")
                    print(f"{Colors.GREEN}已将配置添加到 {build_defconfig_file}{Colors.ENDC}")

def main():
    args = parse_args()

    config_paths, chip_arch, project_fullname = check_environment(check_path=not args.list)
    config = load_config(None)

    if args.list:
        list_configs(config)
    else:
        if not args.config_name:
            print(f"{Colors.RED}错误: 请指定配置名称或使用 -l 列出所有配置{Colors.ENDC}")
            sys.exit(1)
        check_config(config, args.config_name,
                    config_paths['kernel_config'],
                    config_paths['build_config'],
                    config_paths['kernel_defconfig'],
                    config_paths['build_defconfig'])

if __name__ == "__main__":
    main()
