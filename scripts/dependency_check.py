#!/usr/bin/env python3
"""
依赖关系检查工具

功能：
1. 分析文件间的依赖关系，支持 .ko、.a 和 .so 文件
2. 以树形结构可视化展示依赖关系
3. 针对内核模块(.ko)，生成正确的加载顺序
4. 详细模式下可显示文件间的具体依赖符号

用法：
    dependency_check.py {ko|static_lib|dynamic_lib} <文件夹路径> [-v|--verbose]

参数说明：
    ko          - 分析内核模块(.ko)文件
    static_lib  - 分析静态库(.a)文件
    dynamic_lib - 分析动态库(.so)文件
    --verbose   - 显示详细的依赖符号信息

示例：
    dependency_check.py ko /path/to/modules --verbose
    dependency_check.py static_lib /path/to/libs
    dependency_check.py dynamic_lib /path/to/libs
"""
import os
import sys
import subprocess
from collections import defaultdict
from typing import Dict, List, Set
import argparse
from colorama import init, Fore, Style

# 初始化colorama以支持彩色输出
init()

class DependencyChecker:
    def __init__(self, file_type: str, path: str, verbose: bool = False):
        self.file_type = file_type
        self.path = path
        self.verbose = verbose
        self.dependencies = defaultdict(set)
        self.all_files = set()
        self.symbols_defined = defaultdict(set)    # 每个文件定义的符号
        self.symbols_undefined = defaultdict(set)  # 每个文件未定义的符号
        # 存储文件间的依赖符号关系
        self.dependency_symbols = defaultdict(lambda: defaultdict(set))

    def get_symbols(self, file_path: str):
        """使用nm获取文件的符号表信息"""
        try:
            output = subprocess.check_output(['nm', file_path],
                                          stderr=subprocess.DEVNULL).decode()
            defined = set()
            undefined = set()

            for line in output.split('\n'):
                if not line.strip():
                    continue

                # nm输出格式：[地址] 类型 符号名
                parts = line.strip().split()
                if len(parts) < 2:
                    continue

                # 如果有地址字段，符号类型在第1个位置，否则在第0个位置
                symbol_type = parts[1] if len(parts) == 3 else parts[0]
                symbol_name = parts[2] if len(parts) == 3 else parts[1]

                # U表示未定义符号，T/D/B/R等表示已定义符号
                if symbol_type == 'U':
                    undefined.add(symbol_name)
                elif symbol_type in 'TDBR':
                    defined.add(symbol_name)

            # 从undefined中移除已定义的符号
            undefined = undefined - defined

            return defined, undefined
        except subprocess.CalledProcessError:
            return set(), set()

    def build_dependency_tree(self):
        """构建依赖关系树"""
        # 首先获取所有文件的符号信息
        for root, _, files in os.walk(self.path):
            for file in files:
                # 根据文件类型选择要处理的文件
                if ((self.file_type == "ko" and file.endswith(".ko")) or
                    (self.file_type == "static_lib" and file.endswith(".a")) or
                    (self.file_type == "dynamic_lib" and
                     (file.endswith(".so") or
                      (file.startswith("lib") and ".so." in file)))):
                    file_path = os.path.join(root, file)
                    self.all_files.add(file)
                    defined, undefined = self.get_symbols(file_path)
                    self.symbols_defined[file] = defined
                    self.symbols_undefined[file] = undefined

        # 根据符号信息建立依赖关系
        for file in self.all_files:
            for other_file in self.all_files:
                if file != other_file:
                    # 找出file中未定义但在other_file中定义的符号
                    common_symbols = self.symbols_undefined[file] & self.symbols_defined[other_file]
                    if common_symbols:
                        self.dependencies[file].add(other_file)
                        # 记录依赖的具体符号
                        self.dependency_symbols[file][other_file] = common_symbols

    def print_tree(self, root: str, visited: Set[str] = None, prefix: str = "", is_last: bool = True, is_root: bool = True, parent: str = None):
        """以树形结构打印依赖关系"""
        if visited is None:
            visited = set()
            print(f"{Fore.GREEN}# {root}{Style.RESET_ALL}")  # 在根节点前加上"# "
            parent = root
        else:
            # 使用更标准的tree格式
            branch = "└── " if is_last else "├── "
            if is_root:
                prefix = "  " + prefix  # 根节点的子节点从两个空格开始缩进

            # 如果是verbose模式，显示依赖的符号
            if self.verbose and parent in self.dependency_symbols:
                symbols = self.dependency_symbols[parent][root]
                if symbols:
                    symbol_str = ", ".join(sorted(symbols))
                    print(f"{prefix}{branch}{root} ({symbol_str})")
                else:
                    print(f"{prefix}{branch}{root}")
            else:
                print(f"{prefix}{branch}{root}")

        if root in visited:
            return
        visited.add(root)

        deps = sorted(list(self.dependencies[root]))
        deps = [dep for dep in deps if dep in self.all_files]

        for i, dep in enumerate(deps):
            is_last_dep = (i == len(deps) - 1)
            new_prefix = prefix + ("    " if is_last else "│   ")
            self.print_tree(dep, visited, new_prefix, is_last_dep, False, root)

    def get_all_dependencies(self, root: str, visited: Set[str] = None) -> Set[str]:
        """获取指定文件的所有依赖库（包括间接依赖）"""
        if visited is None:
            visited = set()

        if root in visited:
            return set()

        visited.add(root)
        deps = set()
        deps.add(root)

        for dep in self.dependencies[root]:
            if dep in self.all_files:
                deps.update(self.get_all_dependencies(dep, visited))

        return deps

    def format_lib_name(self, lib_name: str) -> str:
        """将库文件名转换为链接器参数格式"""
        # 移除 'lib' 前缀和 '.a'/'.so' 后缀
        if lib_name.startswith('lib'):
            lib_name = lib_name[3:]
        lib_name = lib_name.split('.')[0]
        # 处理包含版本号的动态库，如 'libxxx.so.1.2.3'
        lib_name = lib_name.split('.so.')[0]
        return f"-l{lib_name}"

    def print_all_trees(self):
        """打印所有文件的依赖树"""
        # 按字母顺序打印每个文件的依赖树
        sorted_files = sorted(self.all_files)
        for file in sorted_files:
            self.print_tree(file)

            # 对于静态库和动态库，打印链接器参数
            if self.file_type in ['static_lib', 'dynamic_lib']:
                all_deps = self.get_all_dependencies(file)
                if len(all_deps) > 1:
                    # 转换为链接器参数格式,去重并按字母顺序排序
                    link_args = sorted(list(set([self.format_lib_name(lib) for lib in all_deps])))
                    print("\n" + " ".join(link_args))

            print()

    def get_load_order(self) -> List[str]:
        """获取ko文件的加载顺序"""
        if self.file_type != "ko":
            return []

        visited = set()
        load_order = []

        def visit(node: str):
            if node in visited:
                return
            visited.add(node)
            for dep in self.dependencies[node]:
                if dep in self.all_files:
                    visit(dep)
            load_order.append(node)

        for file in self.all_files:
            visit(file)

        return load_order

def main():
    parser = argparse.ArgumentParser(description='依赖关系检查工具')
    parser.add_argument('type', choices=['ko', 'static_lib', 'dynamic_lib'],
                       help='文件类型: ko/static_lib/dynamic_lib')
    parser.add_argument('path', help='要检查的文件路径')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='显示依赖的符号信息')
    args = parser.parse_args()

    checker = DependencyChecker(args.type, args.path, args.verbose)
    checker.build_dependency_tree()

    # 使用新的打印方法
    checker.print_all_trees()

    # 如果是ko文件，打印加载顺序
    if args.type == "ko":
        print("\n加载顺序:")
        for module in checker.get_load_order():
            print(f"insmod /mnt/system/ko/{module}")

if __name__ == "__main__":
    main()
