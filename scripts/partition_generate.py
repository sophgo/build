# -*- coding: utf-8 -*-
import os
import kconfiglib
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.dom import minidom


def generate_partition_xml(partitions, output_file, storage_type):

    # 校验总大小 TODO:根据flash大小自适应这部分
    total_size_kb = sum(partition["size_in_kb"] for partition in partitions)
    if storage_type == "spinor" and total_size_kb > 32 * 1024:
        raise ValueError("Error: Total partition size exceeds 32MB for spinor.")
    elif storage_type == "spinand" and total_size_kb > 128 * 1024:
        raise ValueError("Error: Total partition size exceeds 128MB for spinand.")
    elif storage_type == "emmc" and total_size_kb > 32 * 1024 * 1024:
        raise ValueError("Error: Total partition size exceeds 32GB for emmc.")

    # 创建根节点
    root = ET.Element("physical_partition", type=storage_type)

    # 添加注释
    comment = ET.Comment("This is an auto-generated file. DO NOT EDIT manually.")
    root.append(comment)

    # 遍历分区信息，生成 XML 节点
    for partition in partitions:
        partition_node = ET.SubElement(root, "partition")
        partition_node.set("label", partition.get("label", ""))
        partition_node.set("size_in_kb", str(partition.get("size_in_kb", 0)))
        partition_node.set("readonly", str(partition.get("readonly", "false")).lower())
        partition_node.set("file", partition.get("file", ""))
        partition_node.set("mountpoint", partition.get("mountpoint", ""))
        partition_node.set("type", partition.get("type", ""))

    # 格式化 XML 输出
    xml_string = ET.tostring(root, encoding="utf-8")
    pretty_xml = minidom.parseString(xml_string).toprettyxml(indent="  ")

    # 写入文件
    with open(output_file, "w") as f:
        f.write(pretty_xml)
    print(f"Flash xml generated: {output_file}")


def parse_kconfig(kconfig_file, config_file):

    kconfig_dir = Path(kconfig_file).parent
    os.environ["srctree"] = str(kconfig_dir)
    kconf = kconfiglib.Kconfig(kconfig_file)
    kconf.load_config(config_file)  # 加载 .config 文件
    partitions = []

    # 获取存储类型 TODO:支持更多类型 e.g. SD/SATA......
    storage_type = kconf.syms["STORAGE_TYPE"].str_value
    if storage_type not in ["emmc", "spinor", "spinand"]:
        raise ValueError("Error: STORAGE_TYPE must be one of 'emmc', 'spinor', or 'spinand'.")

    # 获取分区数量
    partition_count = int(kconf.syms["PARTITION_COUNT"].str_value)

    # 遍历每个分区
    for i in range(1, partition_count + 1):
        partition_key = f"PARTITION_{i}"
        if partition_key in kconf.syms and kconf.syms[partition_key].tri_value == 2:
            size_in_kb = int(kconf.syms[f"{partition_key}_SIZE"].str_value)

            # SPINOR 检查 64K 对齐，因为nor flash的block size为64KB TODO:根据驱动数据可配
            if size_in_kb % 64 != 0 and storage_type == "spinor":
                raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 64KB.")
            # SPINAND 检查 128K 对齐，因为nand flash的block size为128KB 
            if size_in_kb % 128 != 0 and storage_type == "spinand":
                raise ValueError(f"Error: {storage_type} Partition {i} size ({size_in_kb} KB) is not aligned to 128KB.")

            partition = {
                "label": kconf.syms[f"{partition_key}_LABEL"].str_value,
                "size_in_kb": size_in_kb,
                "readonly": kconf.syms[f"{partition_key}_READONLY"].tri_value == 2,
                "file": kconf.syms[f"{partition_key}_FILE"].str_value,
                "mountpoint": kconf.syms[f"{partition_key}_MOUNTPOINT"].str_value,
                "type": kconf.syms[f"{partition_key}_TYPE"].str_value,
            }
            # 如果是 spinand 类型，检查 fip 分区大小, Uboot 会用前10个block做fip备份，所以至少预留2.5MB空间，且单个fip size不能超过1.25MB
            if storage_type == "spinand" and partition["label"] == "fip" and size_in_kb < 2560:
                raise ValueError(f"Error: The 'fip' partition size ({size_in_kb} KB) cannot be less than 2560KB for spinand.")

            partitions.append(partition)
    return partitions, storage_type


if __name__ == "__main__":
    kconfig_file = os.path.join(Path(__file__).resolve().parent.parent, "Kconfig")
    config_file = os.path.join(Path(__file__).resolve().parent.parent, ".config")
    # 解析 Kconfig 配置
    partitions, storage_type = parse_kconfig(kconfig_file, config_file)

    # 输出 XML 文件路径
    output_file = os.path.join(Path(__file__).resolve().parent.parent, "partitions.xml")

    # 生成 XML 文件
    generate_partition_xml(partitions, output_file, storage_type)
