#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK

import os
import build_helper


NORM_PATH = os.path.join(os.getenv("TOP_DIR"), "cvi_alios/solutions/normboot/customization/")
FAST_PATH = os.path.join(os.getenv("TOP_DIR"), "cvi_alios/solutions/fastboot/customization/")
PIPELINE_KCONFIG_PATH = build_helper.PIPELINE_KCONFIG_PATH


KCONFIG_TMPL = """choice
    prompt "Alios customization pipeline"
{default_lines}
    depends on ENABLE_ALIOS

{config_blocks}
endchoice

config ALIOS_CUSTOMIZATION_PIPELINE
    string
{selected_defaults}
    help
      Name of the selected pipeline as a string macro.
"""


NORM_DEFAULT_PIPELINE = "cv1842hp_gc8613"


def find_pipelines(base_path):
    """search direcotries contains customization pipeline"""
    pipelines = []
    if os.path.exists(base_path):
        for item in os.listdir(base_path):
            item_path = os.path.join(base_path, item)
            if os.path.isdir(item_path) and os.path.exists(os.path.join(item_path, "package.yaml.turnkey")):
                pipelines.append(item)
    return sorted(pipelines)


def generate_kconfig():
    """generate Kconfig"""
    norm_pipelines = find_pipelines(NORM_PATH)
    fast_pipelines = find_pipelines(FAST_PATH)

    default_lines = []
    if norm_pipelines:
        norm_default = NORM_DEFAULT_PIPELINE if NORM_DEFAULT_PIPELINE in norm_pipelines else norm_pipelines[0]
        default_lines.append(
            '    default {} if NORM_SOLUTION'.format(
                norm_default.upper().replace('-', '_')))
    if fast_pipelines:
        default_lines.append(
            '    default {} if FAST_SOLUTION'.format(
                fast_pipelines[0].upper().replace('-', '_')))

    config_blocks = []
    selected_defaults = []

    for pipeline in norm_pipelines:
        config_name = pipeline.upper().replace('-', '_')
        config_blocks.append(
            'config {}\n    bool "{} pipeline"\n    depends on NORM_SOLUTION\n    help\n      Select pipeline for {} project.\n'.format(
                config_name, pipeline, pipeline))
        selected_defaults.append(
            '    default "{}" if {}'.format(
                pipeline, config_name))

    for pipeline in fast_pipelines:
        config_name = pipeline.upper().replace('-', '_')
        config_blocks.append(
            'config {}\n    bool "{} pipeline"\n    depends on FAST_SOLUTION\n    help\n      Select pipeline for {} project.\n'.format(
                config_name, pipeline, pipeline))
        selected_defaults.append(
            '    default "{}" if {}'.format(
                pipeline, config_name))

    kconfig_content = KCONFIG_TMPL.format(
        default_lines = '\n'.join(default_lines),
        config_blocks = '\n'.join(config_blocks),
        selected_defaults = '\n'.join(selected_defaults)
    )

    return kconfig_content


def main():
    kconfig_content = generate_kconfig()

    with open(PIPELINE_KCONFIG_PATH, "w") as fp:
        fp.write(kconfig_content)


if __name__ == "__main__":
    main()
