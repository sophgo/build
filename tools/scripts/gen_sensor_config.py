#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK

import os
import json
import build_helper

kconfig_tmpl = """
#
# Automatically generated by gen_sensor_config.py; DO NOT EDIT.
#

menu "Sensor settings"
menu "Sensor support list"
{0}
endmenu

menu "Sensor tuning param config"
{1}
endmenu
endmenu
"""

kconfig_sensor_tmpl = """
config SENSOR_{0}
    bool "Choose sensor {1}"
    default n
    help
      "y" Add sensor {1} to libsns_full.so.
"""

kconfig_param_config_menu_tmpl = """
if {0}
menu "{1}"
choice
  prompt "sensor tuning param"
  {2}
endchoice
endmenu
endif
"""

kconfig_param_config_tmpl = """
  config SENSOR_TUNING_PARAM_{0}
    bool "{1}"
"""

kconfig_param_config_str_tmpl = """
config SENSOR_TUNING_PARAM
  string{0}"""

kconfig_param_config_str_item_tmpl = """
  default "{1}" if SENSOR_TUNING_PARAM_{0}"""

kconfig_param_config_default_tmpl = """
menu "src"
choice
  prompt "sensor tuning param"

  config SENSOR_TUNING_PARAM_cv183x_src_sony_imx307
    bool "sony_imx307"

endchoice
endmenu

config SENSOR_TUNING_PARAM
  string
  default "sony_imx307" if SENSOR_TUNING_PARAM_cv183x_src_sony_imx307
"""


def gen_sensor_support_list():
    with open(build_helper.SENSOR_LIST_PATH, "r", encoding="utf-8") as fp:
        sensor_list_json = json.load(fp)

    sensor_list = sensor_list_json['sensor_list']

    kconfig_sensor_list = ""

    for sensor in sensor_list:
        sensor_name_u = sensor.upper()
        sensor_name_l = sensor.lower()
        kconfig_sensor_list = (kconfig_sensor_list
                               + kconfig_sensor_tmpl.format(sensor_name_u, sensor_name_l))

    return kconfig_sensor_list


def gen_sensor_tuning_param_list():
    menu_list = ""
    param_str = ""

    isp_tuning_path = os.path.normpath(os.path.join(build_helper.BUILD_REPO_DIR, "../isp_tuning"))

    if not os.path.exists(isp_tuning_path):
        print("isp_tuning_path: " + isp_tuning_path + " not exists....")
        return kconfig_param_config_default_tmpl

    chip_list = os.listdir(isp_tuning_path)

    for arch in chip_list:
        if os.path.isdir(os.path.join(isp_tuning_path, arch)) and arch != ".git":
            temp_path = os.path.join(isp_tuning_path, arch)
            customers_list = os.listdir(temp_path)
            for customers in customers_list:
                temp_path = os.path.join(isp_tuning_path, arch)
                if os.path.isdir(os.path.join(temp_path, customers)):
                    param_config_list = ""
                    temp_path = os.path.join(temp_path, customers)
                    param_list = os.listdir(temp_path)
                    for param in param_list:
                        if os.path.isdir(os.path.join(temp_path, param)):
                            temp_str = kconfig_param_config_tmpl.format(
                                arch + "_" + customers + "_" + param,
                                param
                            )
                            param_config_list = param_config_list + temp_str

                            temp_str = kconfig_param_config_str_item_tmpl.format(
                                arch + "_" + customers + "_" + param,
                                param
                            )
                            param_str = param_str + temp_str

                    chips = build_helper.get_chip_list()
                    temp_chip_list = []
                    for chip_arch, xlist in chips.items():
                        if chip_arch.upper() == arch.upper():
                            for x in xlist:
                                temp_chip_list.append("CHIP_" + x)

                    if len(temp_chip_list) == 0:
                        print("Error: chip list is mismatch between isp_tuning and build/boards, pls check!!!")
                        return kconfig_param_config_default_tmpl

                    temp_str = kconfig_param_config_menu_tmpl.format(
                        " || ".join(temp_chip_list),
                        customers,
                        param_config_list
                    )
                    menu_list = menu_list + temp_str

    param_str = kconfig_param_config_str_tmpl.format(param_str)

    return (menu_list + param_str)


def main():

    kconfig_sensor_list = gen_sensor_support_list()
    kconfig_param_list = gen_sensor_tuning_param_list()

    kconfig = kconfig_tmpl.format(
        kconfig_sensor_list,
        kconfig_param_list
    )

    with open(build_helper.SENSOR_KCONFIG_PATH, "w") as fp:
        fp.write(kconfig)


if __name__ == "__main__":
    main()
