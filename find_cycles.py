import os
import re
from collections import defaultdict

def find_dart_files(directory):
    dart_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def extract_imports(file_path):
    imports = []
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        
        # Match both absolute and relative imports
        abs_matches = re.finditer(r"import\s+['\"]package:hydroflow/([^'\"]+)['\"]", content)
        for match in abs_matches:
            # Convert package path back to relative file path for easier comparison
            imports.append(os.path.join('lib', match.group(1)))
            
        rel_matches = re.finditer(r"import\s+['\"]((?!package:)[^'\"]+)['\"]", content)
        for match in rel_matches:
            if not match.group(1).startswith('dart:'):
                current_dir = os.path.dirname(file_path)
                normalized = os.path.normpath(os.path.join(current_dir, match.group(1)))
                # Extract starting from 'lib'
                try:
                    lib_idx = normalized.index('lib/')
                    imports.append(normalized[lib_idx:])
                except ValueError:
                    pass
    return imports

def build_graph(project_root):
    graph = defaultdict(list)
    lib_dir = os.path.join(project_root, 'lib')
    dart_files = find_dart_files(lib_dir)
    
    for file in dart_files:
        try:
            lib_idx = file.index('lib/')
            node_name = file[lib_idx:]
            imports = extract_imports(file)
            graph[node_name] = imports
        except ValueError:
            pass
            
    return graph

def find_cycles(graph):
    visited = set()
    path = []
    path_set = set()
    cycles = []

    def dfs(node):
        if node in path_set:
            cycle_start = path.index(node)
            cycles.append(path[cycle_start:] + [node])
            return
        if node in visited:
            return

        visited.add(node)
        path.append(node)
        path_set.add(node)

        for neighbor in graph.get(node, []):
            dfs(neighbor)

        path.pop()
        path_set.remove(node)

    for node in graph:
        dfs(node)

    return cycles

if __name__ == '__main__':
    project_root = '/Users/vimaldas/Desktop/hydroflow'
    graph = build_graph(project_root)
    cycles = find_cycles(graph)
    
    if cycles:
        print(f"Found {len(cycles)} circular dependencies:")
        for i, cycle in enumerate(cycles[:10]):  # Print first 10
            print(f"Cycle {i+1}:")
            for node in cycle:
                print(f"  -> {node}")
    else:
        print("No circular dependencies found!")
