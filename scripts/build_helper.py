#!/usr/bin/env python3

import logging
import sys
import os
from os.path import normpath, split, join
import json

try:
    import coloredlogs
except ImportError:
    coloredlogs = None


# Ubuntu 16.04 LTS contains Python v3.5.2 by default
PYTHON_MIN_VERSION = (3, 5, 2)

MODULE_PATH = normpath(split(__file__)[0])

BUILD_REPO_DIR = normpath(join(MODULE_PATH, ".."))
BUILD_OUTPUT_DIR = join(BUILD_REPO_DIR, "output")
KCONFIG_PATH = join(BUILD_REPO_DIR, "Kconfig")
BOARD_DIR = join(BUILD_REPO_DIR, "boards")
BOARD_KCONFIG_SAVED_GLOB = join(BOARD_DIR, "*/*/*_defconfig")
CHIP_LIST_PATH = join(BOARD_DIR, "chip_list.json")
SENSOR_LIST_PATH = join(BUILD_REPO_DIR, "../middleware/v2/component/SensorSupportList/sensor_list/sensor_list.json")
SENSOR_KCONFIG_PATH = join(BUILD_REPO_DIR, "output/Kconfig.sensors")
PANEL_LIST_PATH = join(BUILD_REPO_DIR, "panels/panel_list.json")
PANEL_KCONFIG_PATH = join(BUILD_REPO_DIR, "output/Kconfig.panels")


def check_python_min_version():
    if sys.version_info < PYTHON_MIN_VERSION:
        print("Python >= %r is required" % (PYTHON_MIN_VERSION,))
        sys.exit(-1)


def dump_debug_info():
    logging.debug("MODULE_PATH=%s", MODULE_PATH)
    logging.debug("BUILD_REPO_DIR=%s", BUILD_REPO_DIR)
    logging.debug("BOARD_DIR=%s", BOARD_DIR)
    logging.debug("BOARD_KCONFIG_SAVED_GLOB=%s", BOARD_KCONFIG_SAVED_GLOB)


def init_logging(log_file=None, file_level="DEBUG", stdout_level="WARNING"):
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.NOTSET)

    fmt = "%(asctime)s %(levelname)8s:%(module)s:%(message)s"

    if log_file is not None:
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setFormatter(logging.Formatter(fmt))
        file_handler.setLevel(file_level)
        root_logger.addHandler(file_handler)

    if coloredlogs:
        os.environ["COLOREDLOGS_DATE_FORMAT"] = "%H:%M:%S"

        field_styles = {
            "asctime": {"color": "green"},
            "hostname": {"color": "magenta"},
            "levelname": {"color": "black", "bold": True},
            "name": {"color": "blue"},
            "module": {"color": "blue"},
            "programname": {"color": "cyan"},
        }
        level_styles = coloredlogs.DEFAULT_LEVEL_STYLES
        level_styles["debug"]["color"] = "cyan"

        coloredlogs.install(
            level=stdout_level,
            fmt=fmt,
            field_styles=field_styles,
            level_styles=level_styles,
            milliseconds=True,
        )


def get_isp_tuning_arch_alias():
    return {
        "sophon": "88a2",
    }


def map_isp_tuning_arch_to_board_arch(isp_tuning_arch):
    return get_isp_tuning_arch_alias().get(isp_tuning_arch.lower(), isp_tuning_arch)


def map_board_arch_to_isp_tuning_arch(board_arch):
    alias = {v: k for k, v in get_isp_tuning_arch_alias().items()}
    return alias.get(board_arch.lower(), board_arch)


def get_segment_from_chip(chip):
    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)

    if 'architectures' in din:
        for arch, arch_info in din['architectures'].items():
            if 'chips' in arch_info and chip in arch_info['chips']:
                logging.debug("Found chip %s in architecture %s", chip, arch)
                return arch
    
    logging.error("Chip %s not found in any architecture in chip_list.json", chip)
    raise IndexError("%s is not in chip_list.json" % chip)


def get_chip_list():
    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)
    
    all_chips_set = {chip for arch_info in din['architectures'].values() for chip in arch_info['chips']}
    all_chips_list = list(all_chips_set)
    
    return all_chips_list

def get_api_type_list():
    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)
    
    all_apis_set = {api for arch_info in din['architectures'].values() for api in arch_info['apis']}
    all_apis_list = list(all_apis_set)
    
    return all_apis_list

def get_chip_arch_list():
    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)
    
    chip_arch_dict = list(din['architectures'].keys())
    
    return chip_arch_dict

def get_arch_api_dict():

    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)
    
    arch_api_dict = {}
    if 'architectures' in din:
        for arch, arch_info in din['architectures'].items():
            if 'apis' in arch_info:
                arch_api_dict[arch] = arch_info['apis']
            else:
                arch_api_dict[arch] = []
                logging.warning(f"Architecture {arch} does not have 'apis' key.")
    else:
        logging.error("'architectures' key not found in JSON structure.")
    
    return arch_api_dict

def get_arch_chip_dict():
    with open(CHIP_LIST_PATH, "r", encoding="utf-8") as fp:
        din = json.load(fp)
    
    arch_chip_dict = {} 
    if 'architectures' in din:
        for arch, arch_info in din['architectures'].items():
            if 'chips' in arch_info:
                arch_chip_dict[arch] = arch_info['chips'] 
            else:
                arch_chip_dict[arch] = [] 
                logging.warning(f"Architecture {arch} does not have 'chips' key.")
    else:
        logging.error("'architectures' key not found in JSON structure.")
    
    return arch_chip_dict